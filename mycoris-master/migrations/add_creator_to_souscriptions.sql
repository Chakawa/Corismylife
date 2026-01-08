-- Migration: Add creator info to souscriptions
ALTER TABLE souscriptions
  ADD COLUMN IF NOT EXISTS created_by_type VARCHAR(20) DEFAULT 'client',
  ADD COLUMN IF NOT EXISTS created_by_id INTEGER NULL REFERENCES users(id) ON DELETE SET NULL;

-- Backfill existing rows to explicit default
UPDATE souscriptions SET created_by_type = COALESCE(created_by_type, 'client') WHERE created_by_type IS NULL;