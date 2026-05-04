# postgres-memory-template

A small, repeatable local Postgres + pgvector template for memory workloads.

## What it gives you
- Postgres 16 in Docker
- `pgvector` enabled for embeddings
- A starter `memory.notes` table
- Localhost-only exposure by default
- A GitHub-safe setup (`.env.example`, `.gitignore`)

## Quick start
```bash
cp .env.example .env
# edit .env and set a strong POSTGRES_PASSWORD

docker compose up -d
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

## Starter schema
- Extension: `vector`
- Schema: `memory`
- Table: `memory.notes`

Columns:
- `id`
- `source`
- `kind`
- `content`
- `metadata` (jsonb)
- `embedding` (vector(1536))
- `created_at`
- `updated_at`

## Suggested repo structure
```text
postgres-memory-template/
├── compose.yml
├── .env.example
├── .gitignore
├── README.md
└── init/
    └── 001-init.sql
```

## Notes
- `.env` is intentionally ignored; do not commit real secrets.
- Host binding defaults to `127.0.0.1` so the database stays local to the machine.
- If you want semantic search later, you can add an IVFFlat or HNSW index once embedding writes are live.
