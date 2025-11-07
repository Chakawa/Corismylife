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
    duree_contrat INTEGER, -- Durée en mois ou années selon le produit
    periodicite VARCHAR(50) NOT NULL, -- 'mensuel', 'trimestriel', 'semestriel', 'annuel', 'unique'
    prime NUMERIC(15, 6), -- Prime pour 1000 ou montant selon le produit
    capital NUMERIC(15, 2), -- Capital garanti ou montant selon le produit
    age INTEGER, -- Âge de l'assuré
    categorie VARCHAR(100), -- Catégorie optionnelle pour catégoriser les tarifs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_tarif_produit_id ON tarif_produit(produit_id);
CREATE INDEX IF NOT EXISTS idx_tarif_age ON tarif_produit(age) WHERE age IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarif_periodicite ON tarif_produit(periodicite);
CREATE INDEX IF NOT EXISTS idx_tarif_duree ON tarif_produit(duree_contrat) WHERE duree_contrat IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarif_capital ON tarif_produit(capital) WHERE capital IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarif_categorie ON tarif_produit(categorie) WHERE categorie IS NOT NULL;

-- Index composites pour les produits avec age (SÉRÉNITÉ, FAMILIS, ÉTUDE)
CREATE INDEX IF NOT EXISTS idx_tarif_produit_age_duree ON tarif_produit(produit_id, age, duree_contrat) WHERE age IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tarif_composite_age ON tarif_produit(produit_id, age, duree_contrat, periodicite) WHERE age IS NOT NULL;

-- Index composites pour les produits sans age (RETRAITE, SOLIDARITÉ)
CREATE INDEX IF NOT EXISTS idx_tarif_produit_duree_perio ON tarif_produit(produit_id, duree_contrat, periodicite) WHERE age IS NULL;
CREATE INDEX IF NOT EXISTS idx_tarif_capital_perio ON tarif_produit(produit_id, capital, periodicite) WHERE capital IS NOT NULL;

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


