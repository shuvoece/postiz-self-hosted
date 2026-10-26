#!/usr/bin/env bash
# Backs up the Postiz database and uploaded media.
# Usage:  ./scripts/backup.sh            (keeps the last 7 backups)
# Cron:   0 3 * * * /opt/postiz-self-hosted/scripts/backup.sh >> /var/log/postiz-backup.log 2>&1
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source .env

KEEP="${KEEP:-7}"
STAMP="$(date +%Y-%m-%d_%H-%M)"
DEST="backups/${STAMP}"
mkdir -p "${DEST}"

echo "[$(date)] Dumping database ${POSTGRES_DB}..."
docker exec postiz-postgres pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  | gzip > "${DEST}/postiz-db.sql.gz"

echo "[$(date)] Archiving uploads..."
docker run --rm \
  --volumes-from postiz \
  -v "$(pwd)/${DEST}:/backup" \
  alpine tar czf /backup/uploads.tar.gz -C / uploads

echo "[$(date)] Removing old backups (keeping ${KEEP})..."
ls -1dt backups/*/ | tail -n +"$((KEEP + 1))" | xargs -r rm -rf

echo "[$(date)] ✅ Backup done: ${DEST}"
