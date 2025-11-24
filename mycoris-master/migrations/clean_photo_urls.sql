-- Script pour nettoyer les URLs de photos de profil
-- Supprime les espaces en début et fin d'URL

-- Vérifier les URLs avec des espaces
SELECT id, nom, prenom, photo_url, LENGTH(photo_url) as url_length
FROM users 
WHERE photo_url IS NOT NULL 
  AND (photo_url LIKE '% ' OR photo_url LIKE ' %');

-- Nettoyer les URLs en supprimant les espaces
UPDATE users 
SET photo_url = TRIM(photo_url),
    updated_at = CURRENT_TIMESTAMP
WHERE photo_url IS NOT NULL 
  AND (photo_url LIKE '% ' OR photo_url LIKE ' %');

-- Vérifier le résultat
SELECT COUNT(*) as urls_nettoyees
FROM users 
WHERE photo_url IS NOT NULL;
