#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="./backups"
DATE="$(date +%Y%m%d_%H%M%S)"

DB_BACKUP="${BACKUP_DIR}/db_${DATE}.sql.gz"
MEDIA_BACKUP="${BACKUP_DIR}/media_${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Backing up PostgreSQL database..."

docker compose exec -T db sh -c \
  'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip > "$DB_BACKUP"

echo "✅ DB backup created: $DB_BACKUP"

echo "🖼️ Backing up media files..."

if [ -d "./html/public/media" ]; then
  tar -czf "$MEDIA_BACKUP" -C ./html/public media
  echo "✅ Media backup created: $MEDIA_BACKUP"
else
  echo "⚠️ ./html/public/media not found. Skipping media backup."
fi

echo "🧹 Removing backups older than 7 days..."
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +7 -delete

echo "🎉 Backup completed."