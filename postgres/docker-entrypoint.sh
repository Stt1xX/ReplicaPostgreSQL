#!/bin/bash
set -e


ROLE=${ROLE:-primary}
NODE_NAME=${NODE_NAME:-pg}
REPLICATION_USER=${REPLICATION_USER:-replicator}
REPLICATION_PASSWORD=${REPLICATION_PASSWORD:-replpass}
PRIMARY_HOST=${PRIMARY_HOST:-pg-a}
PRIMARY_PORT=${PRIMARY_PORT:-5432}
REPL_MODE=${REPL_MODE:-asynchronous}
APPLICATION_NAME=${APPLICATION_NAME:-$NODE_NAME}
RESTORE=${RESTORE:-0}

export PGDATA=/var/lib/postgresql/data

# If directory empty and role=primary -> run upstream init


# Если RESTORE=1, запускаем restore и выходим, не стартуем второй postgres
if [ "$RESTORE" = "REPLICA" ]; then
  echo "[entrypoint] RESTORE mode REPLICA активирован, запускаем restore_as_replica.sh"
  /scripts/restore_as_replica.sh
  exec docker-entrypoint.sh postgres
fi

if [ "$RESTORE" = "PRIMARY" ]; then
  echo "[entrypoint] RESTORE mode PRIMARY активирован, запускаем promote_and_reconfigure.sh"
  ./scripts/promote_and_reconfigure.sh &
  exec docker-entrypoint.sh postgres
  exit 0
fi

if [ "$ROLE" = "primary" ]; then
  echo "Starting container as PRIMARY ($NODE_NAME)"
  exec docker-entrypoint.sh postgres
else
  echo "Starting container as REPLICA ($NODE_NAME)"
  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "No data found - performing base backup from $PRIMARY_HOST"
    until pg_isready -h $PRIMARY_HOST -p $PRIMARY_PORT -U postgres; do
      echo "Waiting for primary $PRIMARY_HOST:$PRIMARY_PORT..."
      sleep 2
    done
    rm -rf ${PGDATA}/* || true
    mkdir -p ${PGDATA}
    chown -R postgres:postgres ${PGDATA}
    echo "$PRIMARY_HOST:$PRIMARY_PORT:*:postgres:postgres" > /tmp/.pgpass
    chmod 600 /tmp/.pgpass
    SLOT_NAME="replica_slot_${APPLICATION_NAME//-/_}"
    su postgres -c "PGPASSFILE=/tmp/.pgpass pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -D $PGDATA -U $REPLICATION_USER -v -P --wal-method=stream --slot=$SLOT_NAME --create-slot"
    touch $PGDATA/standby.signal
    cat >> $PGDATA/postgresql.auto.conf <<EOF
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICATION_USER password=$REPLICATION_PASSWORD application_name=$APPLICATION_NAME'
recovery_target_timeline = 'latest'
EOF
    chown -R postgres:postgres $PGDATA
  else
    echo "PGDATA already exists, starting as replica"
  fi
  exec docker-entrypoint.sh postgres
fi
