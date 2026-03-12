-- Ajouter le champ profession pour la création client par commercial
ALTER TABLE users
ADD COLUMN IF NOT EXISTS profession VARCHAR(150);
