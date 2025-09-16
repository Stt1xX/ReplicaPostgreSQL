#!/bin/bash

while true; do
    echo "[$(date)] Inserting new data..."
    psql -h pgpool -p 9999 -U postgres -d demo <<EOF
INSERT INTO accounts (name, balance) VALUES ('user_$(date +%s)', (random()*100)::int);
INSERT INTO logs (note) VALUES ('inserted via pgpool at $(date)');
EOF

    sleep 5
done