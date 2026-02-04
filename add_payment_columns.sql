-- Script pour vérifier et ajouter les colonnes manquantes à la table subscriptions

-- 1. Vérifier les colonnes existantes
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'subscriptions' 
ORDER BY ordinal_position;

-- 2. Ajouter les colonnes pour CorisMoney si elles n'existent pas
ALTER TABLE subscriptions 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50),
ADD COLUMN IF NOT EXISTS payment_transaction_id VARCHAR(255);

-- 3. Vérifier que les colonnes ont été ajoutées
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'subscriptions' 
AND column_name IN ('payment_method', 'payment_transaction_id');
