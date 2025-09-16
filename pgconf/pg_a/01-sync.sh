#!/bin/bash
cat /docker-entrypoint-initdb.d/00-sync.conf >> "$PGDATA/postgresql.conf"