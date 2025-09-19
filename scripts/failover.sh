#!/bin/bash
# $1 - failed node id
# $2 - failed node host
# $3 - failed node port
# $4 - failed node data dir
# $5 - new main node id
# $6 - new main node host
# $7 - old main node id
# $8 - old primary node id
# $9 - new main port
# $10 - new main data dir
# $11 - old primary host
# $12 - old primary port

PGDATA="/var/lib/postgresql/data"
REPL_USER="replicator"
REPL_PASS="replpass"

echo "[Failover script] Failover triggered!"
echo "[Failover script] New primary: $6 ($9)"
echo "[Failover script] Old primary: $2 ($3)"

# --- Шаг 1. Убираем primary_conninfo у нового primary ---
docker exec -u postgres $6 \
  bash -c "sed -i '/^primary_conninfo/d' $PGDATA/postgresql.auto.conf && rm -f $PGDATA/recovery.signal"

# --- Шаг 1.1. Сбрасываем synchronous_standby_names и отключаем synchronous_commit ---
docker exec -u postgres $6 \
  bash -c "psql -U postgres -d demo -c \"ALTER SYSTEM SET synchronous_standby_names TO '';\" && psql -U postgres -d demo -c \"ALTER SYSTEM SET synchronous_commit TO 'off';\" && pg_ctl reload -D $PGDATA"

# --- Шаг 2. Promote нового primary ---
CURRENT_ROLE=$(docker exec -u postgres $6 psql -tAc "SELECT pg_is_in_recovery();")
if [ "$CURRENT_ROLE" = "t" ]; then
    docker exec -u postgres $6 pg_ctl promote -D $PGDATA
    echo "[Failover script] Promoted $6"
else
    echo "$6 is already primary, skipping promote"
fi


# --- Шаг 3. Определяем список standby ---
ALL_CONTAINERS=("pg-a" "pg-b" "pg-c")
STANDBY_CONTAINERS=()

for node in "${ALL_CONTAINERS[@]}"; do
  if [[ "$node" != "$6" && "$node" != "$2" ]]; then
    STANDBY_CONTAINERS+=("$node")
  fi
done

# --- Шаг 4. Перенастройка standby ---
for standby in "${STANDBY_CONTAINERS[@]}"; do
  echo "[Failover script] Reconfiguring standby $standby to follow $6..."

  docker exec -u postgres $standby \
    bash -c "sed -i '/^primary_conninfo/d' $PGDATA/postgresql.auto.conf && \
             echo \"primary_conninfo = 'host=$6 port=$9 user=$REPL_USER password=$REPL_PASS application_name=$standby'\" >> $PGDATA/postgresql.auto.conf && \
             touch $PGDATA/recovery.signal"

  docker restart $standby

done

echo "[Failover script] Failover completed."
