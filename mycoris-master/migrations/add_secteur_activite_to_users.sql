-- Migration : ajouter secteur_activite à la table users
ALTER TABLE users
ADD COLUMN IF NOT EXISTS secteur_activite VARCHAR(150);
