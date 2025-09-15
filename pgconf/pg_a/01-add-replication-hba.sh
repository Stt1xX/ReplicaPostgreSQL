#!/bin/bash
  grep -q "host    replication     $REPLICATION_USER" $PGDATA/pg_hba.conf || \
  echo "host    replication     $REPLICATION_USER      all         trust" >> $PGDATA/pg_hba.conf