#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
WORK_DIR="$TMP_DIR/repo"
PROJECT_NAME="ai-persistent-memory-test-$RANDOM-$$"

cleanup() {
  if [[ -d "$WORK_DIR" ]]; then
    (
      cd "$WORK_DIR"
      docker compose -p "$PROJECT_NAME" down -v >/dev/null 2>&1 || true
    )
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cp -R "$REPO_ROOT" "$WORK_DIR"
cd "$WORK_DIR"
cp .env.example .env

PORT="$(python3 - <<'PY'
import random
print(random.randint(55000, 58999))
PY
)"
PASSWORD="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(24))
PY
)"

python3 - <<PY
from pathlib import Path
p = Path('.env')
text = p.read_text()
text = text.replace('change_me_to_a_strong_password', '$PASSWORD')
text = text.replace('POSTGRES_PORT=5432', 'POSTGRES_PORT=$PORT')
p.write_text(text)
PY

export DATABASE_URL="postgresql://memory_admin:${PASSWORD}@127.0.0.1:${PORT}/memory"

docker compose -p "$PROJECT_NAME" up -d

for _ in $(seq 1 30); do
  if docker compose -p "$PROJECT_NAME" exec -T postgres psql -U memory_admin -d memory -Atc "select 1" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker compose -p "$PROJECT_NAME" exec -T postgres psql -U memory_admin -d memory -Atc "
select count(*) from information_schema.tables where table_schema='memory' and table_name in ('memories','memory_links');
select count(*) from pg_views where schemaname='memory' and viewname='notes';
" | tee /tmp/ai-persistent-memory-schema-check.txt

if ! grep -qx '2' /tmp/ai-persistent-memory-schema-check.txt; then
  echo 'Expected 2 schema tables' >&2
  exit 1
fi

if ! grep -qx '1' /tmp/ai-persistent-memory-schema-check.txt; then
  echo 'Expected 1 compatibility view' >&2
  exit 1
fi

(
  cd examples/node
  npm install --silent
  node index.mjs
)

(
  cd examples/python
  if command -v uv >/dev/null 2>&1; then
    uv run --with 'psycopg[binary]>=3.2,<4' python client.py
  else
    python3 -m pip install -q --target "$TMP_DIR/python-deps" -r requirements.txt
    PYTHONPATH="$TMP_DIR/python-deps" python3 client.py
  fi
)

MEMORY_COUNT="$(docker compose -p "$PROJECT_NAME" exec -T postgres psql -U memory_admin -d memory -Atc 'select count(*) from memory.memories;')"
if [[ "$MEMORY_COUNT" -lt 2 ]]; then
  echo "Expected at least 2 inserted memories, got $MEMORY_COUNT" >&2
  exit 1
fi

echo "Smoke test passed with $MEMORY_COUNT memories inserted."
