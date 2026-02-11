-- Migration: Ajouter la colonne api_response pour sauvegarder la réponse complète de l'API CorisMoney
-- Date: 2026-02-11
-- Description: Stocke la réponse JSON complète pour un audit complet des transactions

ALTER TABLE payment_transactions 
ADD COLUMN IF NOT EXISTS api_response JSONB;

-- Ajouter un index pour requêtes JSON
CREATE INDEX IF NOT EXISTS idx_payment_transactions_api_response 
ON payment_transactions USING gin (api_response);

-- Commentaire explicatif
COMMENT ON COLUMN payment_transactions.api_response IS 
'Réponse JSON complète de l''API CorisMoney pour traçabilité et audit';
