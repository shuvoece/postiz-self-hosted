#!/usr/bin/env bash
# Creates .env from .env.example and fills every "change-me" value with a random secret.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  echo "❌ .env already exists – refusing to overwrite it."
  exit 1
fi

cp .env.example .env

while grep -q '=change-me$' .env; do
  secret="$(openssl rand -hex 32)"
  # replace only the first remaining placeholder each loop
  sed -i "0,/=change-me$/s//=${secret}/" .env
done

chmod 600 .env
echo "✅ .env created with random secrets (permissions 600)."
echo "   Now edit POSTIZ_URL and any provider keys: nano .env"
