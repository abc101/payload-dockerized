#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ .env file not found. Please create one with your database credentials."
  exit 1
fi

BACKUP_DIR="./backups"

if [ $# -lt 1 ]; then
  echo "Usage:"
  echo "  ./restore.sh YYYYMMDD_HHMMSS"
  echo ""
  echo "Available backups:"
  ls -lh "$BACKUP_DIR" || true
  exit 1
fi

DATE="$1"

DB_BACKUP="${BACKUP_DIR}/db_${DATE}.sql.gz"
MEDIA_BACKUP="${BACKUP_DIR}/media_${DATE}.tar.gz"
PUBLIC_BACKUP="${BACKUP_DIR}/public_${DATE}.tar.gz"

if [ ! -f "$DB_BACKUP" ]; then
  echo "❌ DB backup not found: $DB_BACKUP"
  exit 1
fi

echo "🔍 Checking Docker..."

if ! docker compose ps db >/dev/null 2>&1; then
  echo "❌ Docker Compose service 'db' not found."
  exit 1
fi

if ! docker compose exec -T db pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
  echo "❌ PostgreSQL container is not running or not ready."
  echo "Try:"
  echo "   docker compose up -d db"
  exit 1
fi

echo "✅ PostgreSQL is ready."

echo "⚠️ This will restore the database from:"
echo "   $DB_BACKUP"
echo ""
echo "It will DROP the current public schema."
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Cancelled."
  exit 0
fi

echo "📦 Creating safety backup before restore..."
./backup.sh

echo "🧹 Resetting database schema..."
docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

echo "♻️ Restoring database..."
gunzip -c "$DB_BACKUP" | docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

if [ -f "$MEDIA_BACKUP" ]; then
  echo "🖼️ Restoring media files..."
  rm -rf ./html/media
  tar -xzf "$MEDIA_BACKUP" -C ./html
else
  echo "⚠️ Media backup not found. Skipping media restore:"
  echo "   $MEDIA_BACKUP"
fi

if [ -f "$PUBLIC_BACKUP" ]; then
  echo "🖼️ Restoring public files..."
  rm -rf ./html/public
  tar -xzf "$PUBLIC_BACKUP" -C ./html
else
  echo "⚠️ Public backup not found. Skipping public restore:"
  echo "   $PUBLIC_BACKUP"
fi

echo "🔄 Restarting app..."
docker compose restart app

echo "✅ Restore completed."