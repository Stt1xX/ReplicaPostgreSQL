#!/bin/bash
# settings to pg_hba.conf
grep -q "host    replication     $REPLICATION_USER" $PGDATA/pg_hba.conf || \
echo "host    replication     $REPLICATION_USER      all         trust" >> $PGDATA/pg_hba.conf
# settings to postgresql.conf
cat /docker-entrypoint-initdb.d/sync.conf >> "$PGDATA/postgresql.conf"