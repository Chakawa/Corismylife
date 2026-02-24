-- ============================================
-- FIX: Ajouter updated_at à notifications
-- ============================================

-- Ajouter la colonne updated_at
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE notifications 
        ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        
        RAISE NOTICE 'Colonne updated_at ajoutee a notifications';
    ELSE
        RAISE NOTICE 'Colonne updated_at existe deja';
    END IF;
END $$;

-- Creer le trigger pour mise a jour automatique
CREATE OR REPLACE FUNCTION update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_notifications_updated_at ON notifications;
CREATE TRIGGER trigger_update_notifications_updated_at
BEFORE UPDATE ON notifications
FOR EACH ROW
EXECUTE FUNCTION update_notifications_updated_at();

DO $$
BEGIN
    RAISE NOTICE 'Trigger de mise a jour cree pour notifications';
END $$;
