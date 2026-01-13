-- ===============================================
-- Migration: Tracking connexion/déconnexion et suspension comptes
-- ===============================================
-- Cette migration ajoute:
-- 1. Table pour tracker les connexions/déconnexions
-- 2. Champ 'est_suspendu' dans la table users
-- 3. Champ pour raison de suspension
-- ===============================================

-- Ajouter les champs de suspension dans la table users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS est_suspendu BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS date_suspension TIMESTAMP,
ADD COLUMN IF NOT EXISTS raison_suspension TEXT,
ADD COLUMN IF NOT EXISTS suspendu_par INTEGER REFERENCES users(id);

-- Créer la table pour tracker les connexions/déconnexions
CREATE TABLE IF NOT EXISTS user_activity_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'login' ou 'logout'
  ip_address VARCHAR(50),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Créer les index pour améliorer les performances de recherche
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON user_activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_type ON user_activity_logs(type);
CREATE INDEX IF NOT EXISTS idx_user_activity_created_at ON user_activity_logs(created_at);

-- Commentaires pour documentation
COMMENT ON TABLE user_activity_logs IS 'Enregistre toutes les connexions et déconnexions des utilisateurs';
COMMENT ON COLUMN user_activity_logs.type IS 'Type d''activité: login ou logout';
COMMENT ON COLUMN users.est_suspendu IS 'Indique si le compte utilisateur est suspendu';
COMMENT ON COLUMN users.raison_suspension IS 'Raison de la suspension du compte';
COMMENT ON COLUMN users.suspendu_par IS 'ID de l''administrateur qui a suspendu le compte';

-- Créer une vue pour obtenir les statistiques d'utilisation
CREATE OR REPLACE VIEW user_activity_stats AS
SELECT 
  DATE(created_at) as date,
  COUNT(*) FILTER (WHERE type = 'login') as total_connexions,
  COUNT(DISTINCT user_id) FILTER (WHERE type = 'login') as utilisateurs_uniques,
  COUNT(*) FILTER (WHERE type = 'logout') as total_deconnexions
FROM user_activity_logs
GROUP BY DATE(created_at)
ORDER BY date DESC;

COMMENT ON VIEW user_activity_stats IS 'Statistiques d''utilisation quotidiennes de l''application';
