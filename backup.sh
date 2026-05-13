#!/bin/bash
# Скрипт резервного копирования PostgreSQL

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup_$DATE.sql"

# Делаем дамп базы данных testdb
docker exec postgres-1c pg_dump -U postgres testdb > $BACKUP_FILE

# Выводим имя созданного файла
echo "Бэкап создан: $BACKUP_FILE"
ls -la $BACKUP_FILE
