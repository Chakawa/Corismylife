-- =====================================================
-- Migration: Simplifier la table commission_instance
-- Description: Garder seulement les colonnes essentielles
--              id, code_apporteur, montant_commission, date_calcul
-- =====================================================

-- Vider la table
TRUNCATE TABLE commission_instance;

-- Supprimer les colonnes non nécessaires
ALTER TABLE commission_instance DROP COLUMN IF EXISTS numepoli CASCADE;
ALTER TABLE commission_instance DROP COLUMN IF EXISTS montant_encaisse_reference CASCADE;
ALTER TABLE commission_instance DROP COLUMN IF EXISTS statut_reception CASCADE;
ALTER TABLE commission_instance DROP COLUMN IF EXISTS date_reception CASCADE;
ALTER TABLE commission_instance DROP COLUMN IF EXISTS comments CASCADE;

-- Ajouter colonne date_calcul si elle n'existe pas
ALTER TABLE commission_instance ADD COLUMN IF NOT EXISTS date_calcul TIMESTAMP DEFAULT NOW();

-- Vérifier la structure finale
-- La table doit avoir: id, code_apporteur, montant_commission, date_calcul, created_at, updated_at

-- Index pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_commission_instance_code_apporteur 
ON commission_instance(code_apporteur);

CREATE INDEX IF NOT EXISTS idx_commission_instance_date_calcul 
ON commission_instance(date_calcul DESC);

COMMIT;
