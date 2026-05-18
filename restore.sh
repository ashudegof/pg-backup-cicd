#!/bin/bash
# Восстановление базы данных PostgreSQL в контейнере postgres-1c

BACKUP_FILE=$1

# Проверка аргумента
if [ -z "$BACKUP_FILE" ]; then
    echo "Использование: ./restore.sh <файл_дампа>"
    echo "Пример: ./restore.sh ~/pg-backup/backup_2026-05-16.dump"
    exit 1
fi

# Проверка существования файла
if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Ошибка: файл $BACKUP_FILE не найден!"
    exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
    echo "❌ Ошибка: файл $BACKUP_FILE пуст!"
    exit 1
fi

# Подтверждение действия
echo "ВНИМАНИЕ! Это удалит текущую базу testdb и восстановит её из $BACKUP_FILE"
read -p "Продолжить? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Операция отменена."
    exit 0
fi

# Создаём резервную копию текущей базы (на случай ошибки)
BACKUP_DIR="$HOME/pg-backup/pre_restore"
mkdir -p "$BACKUP_DIR"
PRE_RESTORE_BACKUP="$BACKUP_DIR/testdb_before_$(date +%Y%m%d_%H%M%S).dump"
echo "📁 Создаю резервную копию текущей базы..."
docker exec -i postgres-1c pg_dump -U postgres -Fc -d testdb > "$PRE_RESTORE_BACKUP"
if [ $? -ne 0 ]; then
    echo "❌ Не удалось создать резервную копию! Операция прервана."
    exit 1
fi
echo "✅ Резервная копия: $PRE_RESTORE_BACKUP"

# Принудительно завершаем все подключения к базе
echo "🔄 Завершаю активные подключения к testdb..."
docker exec -i postgres-1c psql -U postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'testdb' AND pid <> pg_backend_pid();" > /dev/null 2>&1

# Удаляем старую базу и создаём новую (чистая структура)
echo "🗑️ Удаляю старую базу testdb..."
docker exec -i postgres-1c psql -U postgres -c "DROP DATABASE IF EXISTS testdb;"

echo "🏗️ Создаю новую базу testdb..."
docker exec -i postgres-1c psql -U postgres -c "CREATE DATABASE testdb;"

# Восстанавливаем данные из дампа
echo "📀 Восстанавливаю данные из $BACKUP_FILE..."
docker exec -i postgres-1c pg_restore -U postgres -d testdb < "$BACKUP_FILE"

# Проверяем успешность
if [ $? -eq 0 ]; then
    echo "✅ База testdb успешно восстановлена из $BACKUP_FILE!"
    echo "📌 При необходимости отката используйте:"
    echo "   ./restore.sh $PRE_RESTORE_BACKUP"
else
    echo "❌ ОШИБКА при восстановлении базы!"
    echo "Попробуйте восстановить предыдущую версию:"
    echo "   ./restore.sh $PRE_RESTORE_BACKUP"
    exit 1
fi
