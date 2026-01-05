-- ===============================================
-- MIGRATION: CRÉATION TABLE 2FA
-- ===============================================
-- Créer la table pour gérer l'authentification à deux facteurs

-- Créer la table two_factor_auth si elle n'existe pas
CREATE TABLE IF NOT EXISTS two_factor_auth (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    enabled BOOLEAN DEFAULT false,
    secondary_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Créer un index sur user_id pour des recherches rapides
CREATE INDEX IF NOT EXISTS idx_2fa_user_id ON two_factor_auth(user_id);

-- Créer un index sur enabled pour filtrer rapidement les utilisateurs avec 2FA active
CREATE INDEX IF NOT EXISTS idx_2fa_enabled ON two_factor_auth(enabled);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_2fa_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement updated_at
DROP TRIGGER IF EXISTS trigger_update_2fa_updated_at ON two_factor_auth;
CREATE TRIGGER trigger_update_2fa_updated_at
    BEFORE UPDATE ON two_factor_auth
    FOR EACH ROW
    EXECUTE FUNCTION update_2fa_updated_at();

-- Afficher un message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Table two_factor_auth créée avec succès';
    RAISE NOTICE '✅ Index créés sur user_id et enabled';
    RAISE NOTICE '✅ Trigger de mise à jour automatique configuré';
END $$;
