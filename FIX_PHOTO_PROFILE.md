# 🔧 Correction du problème des photos de profil

## Problème identifié
Les URLs des photos de profil contiennent des espaces à la fin, ce qui cause des erreurs 404 :
```
http://185.98.138.168/uploads/profiles/profile-2-1763977694812-954042021.jpg%20%20%20%20...
```

## Solutions appliquées

### 1. Frontend Flutter (✅ Fait)
- Ajout de `.trim()` dans `profil_screen.dart` pour nettoyer l'URL
- Ajout de `.trim()` dans `edit_profile_screen.dart` 
- Ajout de `.trim()` dans `user_service.dart`

### 2. Backend Node.js (✅ Fait)
- Ajout de `.trim()` dans `userController.js` lors de la sauvegarde de l'URL

### 3. Base de données (À faire sur le serveur)

#### Étape 1 : Se connecter à la base de données
```bash
psql -U postgres -d mycorisdb
```

#### Étape 2 : Vérifier les URLs avec des espaces
```sql
SELECT id, nom, prenom, photo_url, LENGTH(photo_url) as url_length
FROM users 
WHERE photo_url IS NOT NULL 
  AND (photo_url LIKE '% ' OR photo_url LIKE ' %');
```

#### Étape 3 : Nettoyer les URLs
```sql
UPDATE users 
SET photo_url = TRIM(photo_url),
    updated_at = CURRENT_TIMESTAMP
WHERE photo_url IS NOT NULL 
  AND (photo_url LIKE '% ' OR photo_url LIKE ' %');
```

#### Étape 4 : Vérifier le résultat
```sql
SELECT id, nom, prenom, photo_url
FROM users 
WHERE photo_url IS NOT NULL
LIMIT 5;
```

### 4. Redémarrer le backend
```bash
# Sur le serveur
cd /path/to/mycoris-master
pm2 restart mycoris-backend
```

### 5. Redéployer l'application Flutter
```bash
# En local
cd d:\CORIS\app_coris\mycorislife-master
flutter build apk --release
```

## Test
1. Se connecter à l'application
2. Aller dans "Mon Profil"
3. Vérifier que la photo de profil s'affiche correctement
4. Essayer de changer la photo de profil
5. Vérifier que la nouvelle photo s'affiche sans erreur 404

## Fichiers modifiés
- ✅ `lib/features/client/presentation/screens/profil_screen.dart`
- ✅ `lib/features/client/presentation/screens/edit_profile_screen.dart`
- ✅ `lib/services/user_service.dart`
- ✅ `mycoris-master/controllers/userController.js`
- ✅ `mycoris-master/migrations/clean_photo_urls.sql` (nouveau fichier)
