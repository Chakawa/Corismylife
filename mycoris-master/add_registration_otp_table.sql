-- ============================================================
-- Table pour stocker les codes OTP d'inscription en base de données
-- À exécuter sur la nouvelle base de données PostgreSQL
-- ============================================================

CREATE TABLE IF NOT EXISTS public.registration_otp (
    id SERIAL PRIMARY KEY,
    telephone VARCHAR(20) NOT NULL UNIQUE,
    code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    user_data JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index pour les recherches rapides par téléphone
CREATE INDEX IF NOT EXISTS idx_registration_otp_telephone ON public.registration_otp(telephone);

-- Index pour nettoyer les OTP expirés
CREATE INDEX IF NOT EXISTS idx_registration_otp_expires_at ON public.registration_otp(expires_at);

-- Commentaire sur la table
COMMENT ON TABLE public.registration_otp IS 'Codes OTP temporaires pour la vérification lors de la création de compte';
COMMENT ON COLUMN public.registration_otp.telephone IS 'Numéro de téléphone du futur utilisateur';
COMMENT ON COLUMN public.registration_otp.code IS 'Code OTP à 5 chiffres envoyé par SMS';
COMMENT ON COLUMN public.registration_otp.expires_at IS 'Date/heure d''expiration du code (5 minutes après envoi)';
COMMENT ON COLUMN public.registration_otp.user_data IS 'Données du compte à créer après validation OTP (nom, prénom, email, etc.)';
