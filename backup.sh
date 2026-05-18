#!/bin/bash
# Скрипт резервного копирования PostgreSQL в пользовательском формате

DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="backup_$DATE.dump"

# Создаём бэкап в пользовательском формате (сжатый, гибкий)
docker exec postgres-1c pg_dump -U postgres -Fc testdb > $BACKUP_FILE

echo "Бэкап создан: $BACKUP_FILE"
ls -la $BACKUP_FILE
