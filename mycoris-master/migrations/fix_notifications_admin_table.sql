-- ============================================
-- FIX: Notifications Admin Table
-- ============================================
-- Creer une vraie table notifications_admin
-- moderne avec la bonne structure

-- Supprimer l'ancienne table si elle existe (pour nettoyer)
DROP TABLE IF EXISTS notifications_notifications_admin CASCADE;

-- Creer la vraie table notifications_admin
CREATE TABLE IF NOT EXISTS notifications_admin (
    id SERIAL PRIMARY KEY,
    admin_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    reference_id INTEGER,
    reference_type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_url VARCHAR(255)
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_notifications_admin_admin_id ON notifications_admin(admin_id);
CREATE INDEX IF NOT EXISTS idx_notifications_admin_is_read ON notifications_admin(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_admin_admin_read ON notifications_admin(admin_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_admin_type ON notifications_admin(type);
CREATE INDEX IF NOT EXISTS idx_notifications_admin_created_at ON notifications_admin(created_at DESC);

-- Trigger pour mise a jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_notifications_admin_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_notifications_admin_updated_at ON notifications_admin;
CREATE TRIGGER trigger_update_notifications_admin_updated_at
BEFORE UPDATE ON notifications_admin
FOR EACH ROW
EXECUTE FUNCTION update_notifications_admin_updated_at();

-- Commentaires
COMMENT ON TABLE notifications_admin IS 'Notifications destinees aux administrateurs';
COMMENT ON COLUMN notifications_admin.admin_id IS 'Reference vers admin destinataire';
COMMENT ON COLUMN notifications_admin.type IS 'Type de notification : subscription_alert, payment_alert, document_review, etc.';

DO $$
BEGIN
    RAISE NOTICE 'Table notifications_admin creee avec succes';
END $$;
