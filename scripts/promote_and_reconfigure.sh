#!/bin/bash
# promote_and_reconfigure.sh
# Скрипт для перевода pg-a в primary, остановки pg-b, перенастройки standby и pgpool
echo "[restore] --- Начало реконфигурации ---"
PG_A="pg-a"
PG_B="pg-b"
PG_C="pg-c"
PGPOOL="pgpool"
PGDATA="/var/lib/postgresql/data"
REPL_USER="replicator"
REPL_PASS="replpass"
DB_NAME="demo"
PRIMARY_PORT="5432"
PG_BIN="/usr/lib/postgresql/15/bin"

set -e

# Ожидание запуска postgres
until pg_isready -U postgres; do
  echo "Ожидание запуска postgres..."
  sleep 1
done
echo "Postgres запущен, продолжаем работу скрипта."

echo "[promote] Остановка текущего primary узлов $PG_B и $PG_C..."
docker stop $PG_B || echo "[promote] Ошибка остановки контейнера $PG_B"
docker stop $PG_C || echo "[promote] Ошибка остановки контейнера $PG_C"

echo "[promote] Перевод текущего узла (pg-a) в режим primary..."
CURRENT_ROLE=$(psql -U postgres -tAc "SELECT pg_is_in_recovery();")
if [ "$CURRENT_ROLE" = "t" ]; then
    su - postgres -c "$PG_BIN/pg_ctl -D $PGDATA promote"
    echo "[promote] pg-a переведен в primary"
else
    echo "pg-a уже primary, пропускаем promote"
fi


echo "[promote] Перенастройка standby $PG_B и $PG_C..."


echo "" | docker exec $PGPOOL /opt/pgpool-II/bin/pcp_attach_node -U pgpool 0
echo "" | docker exec $PGPOOL /opt/pgpool-II/bin/pcp_promote_node -U pgpool 0
echo "" | docker exec $PGPOOL /opt/pgpool-II/bin/pcp_detach_node -U pgpool 1
echo "" | docker exec $PGPOOL /opt/pgpool-II/bin/pcp_detach_node -U pgpool 2

for standby in $PG_B $PG_C; do
    echo "[promote] Подготовка $standby"

    docker start $standby
    docker exec -u postgres $standby \
      rm -rf $PGDATA/PG_VERSION # other branch in docker-entrypoint.sh

    # docker exec -u postgres $standby bash -c "
    # touch $PGDATA/standby.signal &&
    # echo \"primary_conninfo = 'host=$PG_A port=$PRIMARY_PORT user=$REPL_USER password=$REPL_PASS application_name=$standby'\" >> $PGDATA/postgresql.auto.conf &&
    # echo \"recovery_target_timeline = 'latest'\" >> $PGDATA/postgresql.auto.conf
    # "
    docker restart $standby
    echo "[promote] $standby синхронизирован и готов к работе"
done

echo "" | docker exec $PGPOOL /opt/pgpool-II/bin/pcp_attach_node -U pgpool 1
echo "" | docker exec $PGPOOL /opt/pgpool-II/bin/pcp_attach_node -U pgpool 2

echo "[promote] Перевод и перенастройка завершены."
