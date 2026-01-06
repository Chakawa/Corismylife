-- ============================================
-- MIGRATION: Création de la table souscriptions
-- ============================================

CREATE TABLE IF NOT EXISTS souscriptions (
    id SERIAL PRIMARY KEY,
    statut VARCHAR(50) DEFAULT 'en_attente',
    nom_client VARCHAR(150),
    prenom_client VARCHAR(150),
    email VARCHAR(200),
    telephone VARCHAR(50),
    produit VARCHAR(150),
    montant NUMERIC(15,2),
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour les filtres fréquents
CREATE INDEX IF NOT EXISTS idx_souscriptions_statut ON souscriptions(statut);
CREATE INDEX IF NOT EXISTS idx_souscriptions_created_at ON souscriptions(created_at);

-- Trigger de mise à jour du updated_at
CREATE OR REPLACE FUNCTION update_souscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_souscriptions_updated_at ON souscriptions;
CREATE TRIGGER trigger_update_souscriptions_updated_at
BEFORE UPDATE ON souscriptions
FOR EACH ROW
EXECUTE FUNCTION update_souscriptions_updated_at();

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Table souscriptions créée/mise à jour';
END $$;
