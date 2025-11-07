-- ============================================
-- MIGRATION: Tables Produits et Tarifs
-- ============================================
-- Ce script crée les tables pour gérer les produits d'assurance
-- et leurs tarifs pour les simulations
-- ============================================

-- Table Produit
CREATE TABLE IF NOT EXISTS produit (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table Tarif Produit
CREATE TABLE IF NOT EXISTS tarif_produit (
    id SERIAL PRIMARY KEY,
    produit_id INTEGER NOT NULL REFERENCES produit(id) ON DELETE CASCADE,
    duree_contrat INTEGER,
    periodicite VARCHAR(20) NOT NULL CHECK (periodicite IN ('mensuel', 'trimestriel', 'semestriel', 'annuel', 'unique')),
    prime NUMERIC(15, 2) NOT NULL,
    capital NUMERIC(15, 2),
    age INTEGER, -- Peut être NULL pour certains produits
    categorie VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Contrainte d'unicité adaptée (sans age si NULL)
    CONSTRAINT uk_tarif_unique UNIQUE (produit_id, age, duree_contrat, periodicite)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_tarif_produit_id ON tarif_produit(produit_id);
CREATE INDEX IF NOT EXISTS idx_tarif_age ON tarif_produit(age);
CREATE INDEX IF NOT EXISTS idx_tarif_periodicite ON tarif_produit(periodicite);
CREATE INDEX IF NOT EXISTS idx_tarif_duree ON tarif_produit(duree_contrat);
CREATE INDEX IF NOT EXISTS idx_tarif_recherche ON tarif_produit(produit_id, age, duree_contrat, periodicite);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_produit_updated_at BEFORE UPDATE ON produit
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tarif_produit_updated_at BEFORE UPDATE ON tarif_produit
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Migration produits et tarifs terminée avec succès !';
END $$;