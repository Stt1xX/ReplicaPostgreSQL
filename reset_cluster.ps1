$composeFile = "docker-compose.yml"

(Get-Content $composeFile) -replace '(^\s*#?\s*- RESTORE=.*)', '# $1' |
    Set-Content $composeFile

docker compose down -v
Start-Sleep -Seconds 3
docker compose build
Start-Sleep -Seconds 10
docker compose up -d
Start-Sleep -Seconds 10

docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('volodya', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('nicolya', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('bodyan', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "SELECT * FROM accounts;"


(Get-Content $composeFile) -replace '^\s*#?\s*- RESTORE=.*', '      - RESTORE=REPLICA' |
    Set-Content $composeFile

# 8. Запустить pg-a
docker compose up -d --force-recreate pg-a
Start-Sleep -Seconds 10

docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('bob', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('pit', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('taras', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('tristan', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "SELECT * FROM accounts;"

(Get-Content $composeFile) -replace '^\s*- RESTORE=.*', '      - RESTORE=PRIMARY' |
    Set-Content $composeFile

docker compose up -d --force-recreate pg-a
Start-Sleep -Seconds 10

docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('aaaaaa', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('bbbbbb', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('cccccc', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('dddddd', 1000);"
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "SELECT * FROM accounts;"