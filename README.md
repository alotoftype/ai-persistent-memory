# ai-persistent-memory

A small, repeatable local Postgres + pgvector template for persistent AI memory workloads.

## What it gives you
- Postgres 16 in Docker
- `pgvector` for embeddings
- A richer memory schema with metadata, tags, entities, importance, timestamps, and links
- Full-text search support
- Localhost-only exposure by default
- Tiny Node and Python client examples
- A GitHub-safe setup (`.env.example`, `.gitignore`, MIT license)

## Quick start
```bash
cp .env.example .env
# edit .env and set a strong POSTGRES_PASSWORD

docker compose up -d
```

Or use the bootstrap helper:
```bash
./bootstrap.sh
```

## Verify
```bash
docker compose ps
docker compose exec postgres pg_isready -U ${POSTGRES_USER:-memory_admin} -d ${POSTGRES_DB:-memory}
```

## Default connection URL
```text
postgresql://memory_admin:<PASSWORD>@127.0.0.1:5432/memory
```

## Schema
### `memory.memories`
Core memory records with:
- `id` (UUID)
- `external_id`
- `source`
- `kind`
- `title`
- `summary`
- `content`
- `metadata` (jsonb)
- `tags` (text[])
- `entities` (text[])
- `importance` (1-5)
- `salience` (0-1)
- `embedding` (vector(1536))
- `content_tsv` (generated full-text search column)
- `occurred_at`
- `last_accessed_at`
- `created_at`
- `updated_at`

### `memory.memory_links`
Simple graph edges between memories:
- `from_memory_id`
- `to_memory_id`
- `relationship`
- `weight`
- `metadata`

### Compatibility view
- `memory.notes` maps the old simple shape onto `memory.memories`

## Examples
### Node
```bash
cd examples/node
npm install
DATABASE_URL='postgresql://memory_admin:YOUR_PASSWORD@127.0.0.1:5432/memory' node index.mjs
```

### Python
```bash
cd examples/python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
DATABASE_URL='postgresql://memory_admin:YOUR_PASSWORD@127.0.0.1:5432/memory' python client.py
```

## Suggested repo structure
```text
ai-persistent-memory/
├── compose.yml
├── .env.example
├── .gitignore
├── LICENSE
├── README.md
├── bootstrap.sh
├── init/
│   └── 001-init.sql
└── examples/
    ├── node/
    │   ├── index.mjs
    │   └── package.json
    └── python/
        ├── client.py
        └── requirements.txt
```

## Tests
Run the end-to-end smoke test locally:
```bash
bash tests/smoke.sh
```

It validates:
- container startup
- schema creation
- compatibility view creation
- Node example insert/query
- Python example insert/query

A GitHub Actions workflow is included at `.github/workflows/validate.yml`.

## Notes
- `.env` is intentionally ignored; do not commit real secrets.
- Host binding defaults to `127.0.0.1` so the database stays local to the machine.
- For production-ish use, add backups, migrations, and auth rotation.
- For semantic search at scale, add embedding writes plus an HNSW/IVFFlat strategy tuned to your data size.
