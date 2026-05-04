CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS memory;

CREATE TABLE IF NOT EXISTS memory.notes (
  id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL DEFAULT 'manual',
  kind TEXT NOT NULL DEFAULT 'note',
  content TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  embedding vector(1536),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_memory_notes_kind ON memory.notes (kind);
CREATE INDEX IF NOT EXISTS idx_memory_notes_created_at ON memory.notes (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_memory_notes_metadata ON memory.notes USING GIN (metadata);

CREATE OR REPLACE FUNCTION memory.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_memory_notes_updated_at ON memory.notes;
CREATE TRIGGER trg_memory_notes_updated_at
BEFORE UPDATE ON memory.notes
FOR EACH ROW
EXECUTE FUNCTION memory.set_updated_at();
