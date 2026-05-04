#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
  echo ".env already exists; leaving it untouched."
else
  password="$(openssl rand -base64 24 | tr -d '\n')"
  sed "s/change_me_to_a_strong_password/${password//\//\\/}/" .env.example > .env
  echo "Created .env with a generated password."
fi

docker compose up -d

echo
printf 'Postgres should be available on %s:%s\n' "127.0.0.1" "${POSTGRES_PORT:-5432}"
echo "Run: docker compose ps"
echo "Verify with: docker compose exec postgres pg_isready -U ${POSTGRES_USER:-memory_admin} -d ${POSTGRES_DB:-memory}"
