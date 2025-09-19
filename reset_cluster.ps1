# Сохраняем путь к файлу
$composeFile = "docker-compose.yml"

# 1. Закомментировать строку №12 с RESTORE
(Get-Content $composeFile) -replace '(^\s*#?\s*- RESTORE=.*)', '# $1' |
    Set-Content $composeFile

# 2. Остановить и удалить все контейнеры + volume
docker compose down -v
Start-Sleep -Seconds 10
# 3. Пересобрать образы
docker compose build
Start-Sleep -Seconds 6
# 4. Запустить все контейнеры
docker compose up -d
Start-Sleep -Seconds 12


Start-Sleep -Seconds 7
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('bob', 1000);"

# 5. Остановить pg-a
Start-Sleep -Seconds 3
docker compose down -v pg-a
Start-Sleep -Seconds 3

(Get-Content $composeFile) -replace '^\s*#?\s*- RESTORE=.*', '      - RESTORE=REPLICA' |
    Set-Content $composeFile

# 8. Запустить pg-a
docker compose up -d pg-a
Start-Sleep -Seconds 7

Start-Sleep -Seconds 7
docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('pit', 1000);"

Start-Sleep -Seconds 3
docker compose down -v pg-a
Start-Sleep -Seconds 3

(Get-Content $composeFile) -replace '^\s*- RESTORE=.*', '      - RESTORE=PRIMARY' |
    Set-Content $composeFile

# 12. Запустить pg-a
docker compose up -d pg-a

# Start-Sleep -Seconds 30
# docker exec pg-client psql -h pgpool -p 9999 -U postgres -d demo -c "INSERT INTO accounts(name, balance) VALUES ('taras', 1000);"