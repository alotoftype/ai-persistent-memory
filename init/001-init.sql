CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS memory;

CREATE TABLE IF NOT EXISTS memory.memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id TEXT UNIQUE,
  source TEXT NOT NULL DEFAULT 'manual',
  kind TEXT NOT NULL DEFAULT 'note',
  title TEXT,
  summary TEXT,
  content TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  tags TEXT[] NOT NULL DEFAULT '{}'::text[],
  entities TEXT[] NOT NULL DEFAULT '{}'::text[],
  importance SMALLINT NOT NULL DEFAULT 3 CHECK (importance BETWEEN 1 AND 5),
  salience REAL NOT NULL DEFAULT 0.5 CHECK (salience BETWEEN 0 AND 1),
  embedding vector(1536),
  content_tsv tsvector,
  occurred_at TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS memory.memory_links (
  id BIGSERIAL PRIMARY KEY,
  from_memory_id UUID NOT NULL REFERENCES memory.memories(id) ON DELETE CASCADE,
  to_memory_id UUID NOT NULL REFERENCES memory.memories(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL,
  weight REAL NOT NULL DEFAULT 1.0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (from_memory_id, to_memory_id, relationship)
);

CREATE INDEX IF NOT EXISTS idx_memory_memories_kind ON memory.memories (kind);
CREATE INDEX IF NOT EXISTS idx_memory_memories_source ON memory.memories (source);
CREATE INDEX IF NOT EXISTS idx_memory_memories_importance ON memory.memories (importance DESC);
CREATE INDEX IF NOT EXISTS idx_memory_memories_occurred_at ON memory.memories (occurred_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_memory_memories_created_at ON memory.memories (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memory_memories_metadata ON memory.memories USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_memory_memories_tags ON memory.memories USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_memory_memories_entities ON memory.memories USING GIN (entities);
CREATE INDEX IF NOT EXISTS idx_memory_memories_tsv ON memory.memories USING GIN (content_tsv);
CREATE INDEX IF NOT EXISTS idx_memory_links_from ON memory.memory_links (from_memory_id);
CREATE INDEX IF NOT EXISTS idx_memory_links_to ON memory.memory_links (to_memory_id);
CREATE INDEX IF NOT EXISTS idx_memory_links_relationship ON memory.memory_links (relationship);

CREATE OR REPLACE FUNCTION memory.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION memory.set_content_tsv()
RETURNS TRIGGER AS $$
BEGIN
  NEW.content_tsv := to_tsvector(
    'english',
    concat_ws(' ', coalesce(NEW.title, ''), coalesce(NEW.summary, ''), NEW.content)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_memory_memories_updated_at ON memory.memories;
CREATE TRIGGER trg_memory_memories_updated_at
BEFORE UPDATE ON memory.memories
FOR EACH ROW
EXECUTE FUNCTION memory.set_updated_at();

DROP TRIGGER IF EXISTS trg_memory_memories_content_tsv ON memory.memories;
CREATE TRIGGER trg_memory_memories_content_tsv
BEFORE INSERT OR UPDATE ON memory.memories
FOR EACH ROW
EXECUTE FUNCTION memory.set_content_tsv();

CREATE OR REPLACE VIEW memory.notes AS
SELECT
  id,
  source,
  kind,
  content,
  metadata,
  embedding,
  created_at,
  updated_at
FROM memory.memories;
