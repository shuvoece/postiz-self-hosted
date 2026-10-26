#!/usr/bin/env bash
# Restores a backup created by backup.sh
# Usage: ./scripts/restore.sh backups/2026-10-26_03-00
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source .env

SRC="${1:?Usage: $0 backups/<timestamp>}"
[[ -f "${SRC}/postiz-db.sql.gz" ]] || { echo "❌ ${SRC}/postiz-db.sql.gz not found"; exit 1; }

read -rp "⚠️  This overwrites the current database and uploads. Continue? (yes/no) " ok
[[ "${ok}" == "yes" ]] || exit 1

docker compose stop postiz

echo "Restoring database..."
docker exec postiz-postgres psql -U "${POSTGRES_USER}" -d postgres \
  -c "DROP DATABASE IF EXISTS \"${POSTGRES_DB}\";" \
  -c "CREATE DATABASE \"${POSTGRES_DB}\" OWNER \"${POSTGRES_USER}\";"
gunzip -c "${SRC}/postiz-db.sql.gz" | docker exec -i postiz-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"

if [[ -f "${SRC}/uploads.tar.gz" ]]; then
  echo "Restoring uploads..."
  docker run --rm --volumes-from postiz -v "$(pwd)/${SRC}:/backup" \
    alpine sh -c "rm -rf /uploads/* && tar xzf /backup/uploads.tar.gz -C /"
fi

docker compose start postiz
echo "✅ Restore finished."
