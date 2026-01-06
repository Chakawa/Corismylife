# 🔑 Identifiants de Test - Dashboard Admin CORIS

## Compte Administrateur

Pour vous connecter au dashboard admin, vous devez utiliser un compte avec le rôle `admin` dans la base de données.

### Comment créer un compte admin ?

1. **Ouvrir votre client PostgreSQL** (pgAdmin ou ligne de commande)

2. **Connectez-vous à la base de données `mycorisdb`**

3. **Créer un compte administrateur** :

```sql
-- Insérer un utilisateur admin
INSERT INTO users (
    nom, 
    prenom, 
    email, 
    motdepasse, 
    telephone, 
    role, 
    statut
) VALUES (
    'Admin',
    'CORIS',
    'admin@coris.ci',
    '$2b$10$YourHashedPasswordHere',  -- Voir ci-dessous pour générer le hash
    '0700000000',
    'admin',
    'actif'
);
```

### Générer le mot de passe hashé

Le mot de passe doit être hashé avec bcrypt. Vous pouvez le faire de deux manières :

#### Option 1 : Utiliser Node.js (Recommandé)

```javascript
// Créer un fichier hash_password.js dans mycoris-master
const bcrypt = require('bcrypt');

async function hashPassword() {
    const password = 'Admin@2024';  // Changez ce mot de passe
    const hash = await bcrypt.hash(password, 10);
    console.log('Mot de passe hashé:', hash);
}

hashPassword();
```

Exécutez :
```bash
cd d:\CORIS\app_coris\mycoris-master
node hash_password.js
```

#### Option 2 : Modifier directement dans la BDD

Si vous avez déjà un compte client, vous pouvez simplement changer son rôle :

```sql
-- Trouver un utilisateur existant
SELECT id, email, nom, prenom, role FROM users LIMIT 5;

-- Changer son rôle en admin
UPDATE users 
SET role = 'admin' 
WHERE email = 'votre.email@exemple.com';
```

## Test de Connexion

Une fois votre compte admin créé :

1. Ouvrez http://localhost:3000
2. Entrez votre email et mot de passe
3. Vous serez redirigé vers le dashboard

## Identifiants Suggérés

```
Email: admin@coris.ci
Mot de passe: Admin@2024
```

**⚠️ IMPORTANT** : Changez ces identifiants en production !

## Vérification dans la Base de Données

Pour vérifier qu'un compte admin existe :

```sql
SELECT id, nom, prenom, email, role, statut 
FROM users 
WHERE role = 'admin';
```

## Problèmes de Connexion ?

### Erreur "Identifiants invalides"
- Vérifiez que l'email existe dans la BDD
- Vérifiez que le mot de passe est correctement hashé
- Vérifiez que le statut est 'actif'

### Erreur "Accès refusé"
- Vérifiez que le rôle est bien 'admin' (et non 'client' ou 'commercial')
- Vérifiez dans la console du backend les logs d'erreur

### Le backend ne répond pas
- Assurez-vous que le backend tourne sur http://localhost:5000
- Vérifiez les logs du serveur Node.js
- Testez manuellement : `curl http://localhost:5000/api/auth/login`

## Script SQL Complet

Voici un script complet pour créer un admin :

```sql
-- 1. Supprimer l'admin si il existe déjà
DELETE FROM users WHERE email = 'admin@coris.ci';

-- 2. Créer le nouvel admin
INSERT INTO users (
    nom, 
    prenom, 
    email, 
    motdepasse, 
    telephone, 
    role, 
    statut,
    created_at
) VALUES (
    'Admin',
    'CORIS',
    'admin@coris.ci',
    '$2b$10$K5x.5z5Z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5z5',  -- Remplacez par votre hash
    '0700000000',
    'admin',
    'actif',
    NOW()
);

-- 3. Vérifier la création
SELECT * FROM users WHERE role = 'admin';
```

## Support

Si vous rencontrez des problèmes, vérifiez :
1. Le backend est lancé (`npm start` dans mycoris-master)
2. Le dashboard est lancé (`npm run dev` dans dashboard-admin)
3. La base de données PostgreSQL est accessible
4. Les tables existent (users, contrats, souscriptions, etc.)
