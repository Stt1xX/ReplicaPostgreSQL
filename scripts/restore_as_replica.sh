#!/bin/bash

echo "[restore] --- Начало восстановления ---"
PGDATA="/var/lib/postgresql/data"
PRIMARY_HOST="pg-b"
PRIMARY_PORT="5432"
REPLICATION_USER="replicator"
REPLICATION_PASSWORD="replpass"
APPLICATION_NAME="pg-a"
PG_BIN="/usr/lib/postgresql/15/bin"
SLOT_NAME="replica_slot_${APPLICATION_NAME//-/_}"

echo "[restore] Остановка PostgreSQL..."

if [ -x "$PG_BIN/pg_ctl" ]; then
	su - postgres -c "$PG_BIN/pg_ctl -D $PGDATA -m fast stop" || echo "[restore] Ошибка остановки через pg_ctl"
else
	su - postgres -c "pg_ctl -D $PGDATA -m fast stop" || echo "[restore] Ошибка остановки через pg_ctl (альтернатива)"
fi


echo "[restore] Очистка данных..."
rm -rf ${PGDATA}/* || echo "[restore] Ошибка очистки данных"


echo "[restore] Получение базы с primary ($PRIMARY_HOST)..."
PGPASSFILE=/tmp/.pgpass
echo "$PRIMARY_HOST:$PRIMARY_PORT:*:postgres:postgres" > $PGPASSFILE
chmod 600 $PGPASSFILE

# Ожидание окончания promote (выхода из recovery)
while true; do
    RECOVERY=$(docker exec $PRIMARY_HOST psql -U postgres -tAc "SELECT pg_is_in_recovery();")
    if [ "$RECOVERY" = "f" ]; then
        echo "Promote завершён, узел стал primary"
        break
    fi
    echo "Ожидание завершения promote..."
    sleep 1
done

if [ -x "$PG_BIN/pg_basebackup" ]; then
	su - postgres -c "PGPASSFILE=$PGPASSFILE $PG_BIN/pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -D $PGDATA -U $REPLICATION_USER -v -P --wal-method=stream --slot=replica_slot_$SLOT_NAME --create-slot" || echo "[restore] Ошибка pg_basebackup (bin)"
		else
	su - postgres -c "PGPASSFILE=$PGPASSFILE pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -D $PGDATA -U $REPLICATION_USER -v -P --wal-method=stream --slot=replica_slot_$SLOT_NAME --create-slot" || echo "[restore] Ошибка pg_basebackup (альтернатива)"
fi

# Явно выставить права на каталог данных после basebackup
chown -R postgres:postgres $PGDATA
chmod 700 $PGDATA



echo "[restore] Создание standby.signal..."
if touch $PGDATA/standby.signal; then
	echo "[restore] standby.signal создан"
else
	echo "[restore] Ошибка создания standby.signal"
	exit 1
fi



echo "[restore] Запись primary_conninfo..."
echo "primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICATION_USER password=$REPLICATION_PASSWORD application_name=$APPLICATION_NAME'" > $PGDATA/postgresql.auto.conf || {
	echo "[restore] Ошибка записи primary_conninfo";
	exit 1;
}

echo "[restore] --- Восстановление завершено ---"
