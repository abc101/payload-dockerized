#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ .env file not found. Please create one with your database credentials."
  exit 1
fi

BACKUP_DIR="./backups"
DATE="$(date +%Y%m%d_%H%M%S)"

DB_BACKUP="${BACKUP_DIR}/db_${DATE}.sql.gz"
MEDIA_BACKUP="${BACKUP_DIR}/media_${DATE}.tar.gz"
PUBLIC_BACKUP="${BACKUP_DIR}/public_${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "🔍 Checking Docker..."

if ! docker compose ps --services | grep -q "^db$"; then
  echo "❌ db service not found"
  exit 1
fi

if ! docker compose exec -T db pg_isready \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" >/dev/null 2>&1; then

  echo "❌ Database is unavailable"
  echo "Try:"
  echo "docker compose up -d db"
  exit 1
fi

echo "✅ Database connection OK"


echo "📦 Backing up PostgreSQL database..."

docker compose exec -T db sh -c \
  'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip > "$DB_BACKUP"

echo "✅ DB backup created: $DB_BACKUP"

echo "🖼️ Backing up media files..."

if [ -d "./html/public" ]; then
  tar -czf "$PUBLIC_BACKUP" -C ./html/public public
  echo "✅ Media backup created: $PUBLIC_BACKUP"
else
  echo "⚠️ ./html/public not found. Skipping media backup."
fi

if [ -d "./html/media" ]; then
  tar -czf "$MEDIA_BACKUP" -C ./html/media media
  echo "✅ Media backup created: $MEDIA_BACKUP"
else
  echo "⚠️ ./html/media not found. Skipping media backup."
fi

echo "🧹 Removing backups older than 7 days..."
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +7 -delete

echo "🎉 Backup completed."