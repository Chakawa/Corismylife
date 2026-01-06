-- ========================================
-- Script de Création du Compte Admin
-- Dashboard CORIS Administration
-- ========================================

-- 1. Supprimer l'admin s'il existe déjà (évite les doublons)
DELETE FROM users WHERE email = 'admin@coris.ci';

-- 2. Créer le compte administrateur
INSERT INTO users (
    nom, 
    prenom, 
    email, 
    motdepasse, 
    telephone, 
    role, 
    statut,
    created_at,
    date_naissance
) VALUES (
    'Admin',
    'CORIS',
    'admin@coris.ci',
    '$2b$10$OOJFgyY7TrfEkMwzB7u8ie0GzLsHRXFxdDFsF/55YM7TSLmB/Fe8K',  -- Mot de passe: Admin@2024
    '0700000000',
    'admin',
    'actif',
    NOW(),
    '1990-01-01'
);

-- 3. Vérifier la création
SELECT 
    id, 
    nom, 
    prenom, 
    email, 
    role, 
    statut,
    created_at
FROM users 
WHERE role = 'admin';

-- ========================================
-- Informations de Connexion
-- ========================================
-- Email: admin@coris.ci
-- Mot de passe: Admin@2024
-- URL Dashboard: http://localhost:3000
-- ========================================
