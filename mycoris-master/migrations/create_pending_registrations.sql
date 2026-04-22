-- Migration : table pour sauvegarder les inscriptions incomplètes
-- Les données sont sauvegardées dès l'envoi de l'OTP
-- Supprimées si l'inscription est finalisée avec succès
CREATE TABLE IF NOT EXISTS pending_registrations (
  id SERIAL PRIMARY KEY,
  telephone VARCHAR(20) UNIQUE NOT NULL,
  user_data JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pending_registrations_telephone 
  ON pending_registrations(telephone);
