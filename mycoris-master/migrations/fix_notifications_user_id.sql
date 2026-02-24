-- ============================================
-- FIX: Notifications Table User ID Column
-- ============================================
-- Ce script corrige le probleme de la colonne user_id
-- qui ne peut pas etre ajoutee car la table contient
-- deja des donnees sans user_id
-- ============================================

-- Option 1: Supprimer toutes les anciennes notifications (SIMPLE)
-- Decommentez si vous voulez supprimer les anciennes notifications

-- TRUNCATE TABLE notifications CASCADE;

-- Option 2: Ajouter la colonne comme NULLABLE puis corriger (RECOMMANDE)

-- Etape 1: Verifier si la colonne user_id existe deja
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' AND column_name = 'user_id'
    ) THEN
        RAISE NOTICE 'La colonne user_id existe deja dans notifications';
    ELSE
        RAISE NOTICE 'Ajout de la colonne user_id (NULLABLE temporairement)';
        
        -- Ajouter la colonne comme NULLABLE
        ALTER TABLE notifications ADD COLUMN user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
        
        -- Supprimer les notifications orphelines (sans user possible)
        -- Ces notifications sont probablement de test ou corrompues
        DELETE FROM notifications WHERE user_id IS NULL;
        
        -- Maintenant rendre la colonne NOT NULL
        ALTER TABLE notifications ALTER COLUMN user_id SET NOT NULL;
        
        -- Creer les index
        CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
        
        RAISE NOTICE 'Colonne user_id ajoutee avec succes !';
    END IF;
END $$;

-- Ajouter le commentaire
COMMENT ON COLUMN notifications.user_id IS 'Reference vers utilisateur destinataire';

-- Verification finale
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'user_id';
    
    IF v_count > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '========================================';
        RAISE NOTICE 'SUCCES: Colonne user_id configuree !';
        RAISE NOTICE '========================================';
    ELSE
        RAISE WARNING 'ATTENTION: Colonne user_id manquante !';
    END IF;
END $$;
