#!/bin/bash
# $1 - failed node id
# $2 - failed node host (имя контейнера в docker-compose)
# $3 - failed node port
# $4 - failed node data dir
# $5 - new main node id
# $6 - new main node host (имя контейнера в docker-compose)
# $7 - old main node id
# $8 - old primary node id
# $9 - new main port
# $10 - new main data dir
# $11 - old primary host
# $12 - old primary port

docker exec -u postgres $6 pg_ctl promote -D /var/lib/postgresql/data

