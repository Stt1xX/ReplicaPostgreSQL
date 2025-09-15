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

export PGDATA=/var/lib/postgresql/data

# If directory empty and role=primary -> run upstream init
if [ "$ROLE" = "primary" ]; then
  echo "Starting container as PRIMARY ($NODE_NAME)"
  # Ensure config applied via /docker-entrypoint-initdb.d scripts if present
  exec docker-entrypoint.sh postgres
else
  echo "Starting container as REPLICA ($NODE_NAME)"
  if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "No data found - performing base backup from $PRIMARY_HOST"
    # wait for primary
    until pg_isready -h $PRIMARY_HOST -p $PRIMARY_PORT -U postgres; do
      echo "Waiting for primary $PRIMARY_HOST:$PRIMARY_PORT..."
      sleep 2
    done

    # Clean PGDATA (should be empty)
    rm -rf ${PGDATA}/* || true
    mkdir -p ${PGDATA}
    chown -R postgres:postgres ${PGDATA}

    # create .pgpass for non-interactive pg_basebackup
    echo "$PRIMARY_HOST:$PRIMARY_PORT:*:postgres:postgres" > /tmp/.pgpass
    chmod 600 /tmp/.pgpass

    su postgres -c "PGPASSFILE=/tmp/.pgpass pg_basebackup -h $PRIMARY_HOST -p $PRIMARY_PORT -D $PGDATA -U $REPLICATION_USER -v -P --wal-method=stream"

    # create standby.signal (Postgres >=12)
    touch $PGDATA/standby.signal

    # write primary_conninfo
    cat >> $PGDATA/postgresql.auto.conf <<EOF
primary_conninfo = 'host=$PRIMARY_HOST port=$PRIMARY_PORT user=$REPLICATION_USER password=$REPLICATION_PASSWORD application_name=$APPLICATION_NAME'
recovery_target_timeline = 'latest'
EOF

    # ensure permissions
    chown -R postgres:postgres $PGDATA
  else
    echo "PGDATA already exists, starting as replica"
  fi

  exec docker-entrypoint.sh postgres
fi
