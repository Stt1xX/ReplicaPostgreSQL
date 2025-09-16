#!/bin/bash

while true; do
    echo "[$(date)] Reading current data..."
    psql -h pgpool -p 5432 -U postgres -d demo <<EOF
SELECT * FROM accounts ORDER BY id DESC LIMIT 5;
SELECT * FROM logs ORDER BY created_at DESC LIMIT 5;
EOF

    sleep 5 
done