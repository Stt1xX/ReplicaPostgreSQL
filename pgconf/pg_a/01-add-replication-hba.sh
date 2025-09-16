#!/bin/bash
echo "host    replication     postgres      all         trust" >> $PGDATA/pg_hba.conf
echo "host    replication     $REPLICATION_USER      all         trust" >> $PGDATA/pg_hba.conf