-- ========================================
-- Migration: Ajout de la colonne admin_type
-- Date: 2026-01-07
-- Description: Ajoute le type d'administrateur pour gérer les niveaux d'accès
-- ========================================

-- Ajouter la colonne admin_type si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'admin_type'
    ) THEN
        ALTER TABLE users 
        ADD COLUMN admin_type VARCHAR(50) DEFAULT NULL;
        
        COMMENT ON COLUMN users.admin_type IS 'Type d''administrateur: super_admin, admin, moderation';
    END IF;
END $$;

-- Mettre à jour les admins existants avec un type par défaut
UPDATE users 
SET admin_type = 'super_admin' 
WHERE role = 'admin' AND admin_type IS NULL;

-- Vérifier la création
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'admin_type';

-- ========================================
-- Types d'administrateurs disponibles:
-- - super_admin: Accès complet à tout le système
-- - admin: Accès standard aux fonctions d'administration
-- - moderation: Accès limité à la modération de contenu
-- ========================================
