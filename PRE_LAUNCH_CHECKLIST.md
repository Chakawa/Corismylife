# ✅ VÉRIFICATION FINALE - Avant de Démarrer

## 📋 Avant de Lancer le Système

### Dossiers
```
☐ mycoris-master/        → Existe et contient server.js
☐ dashboard-admin/       → Existe et contient package.json
☐ mycoris-master/migrations/
  ☐ create_notifications_admin_table.sql
☐ mycoris-master/
  ☐ run_notifications_migration.js
```

### Base de Données
```
☐ PostgreSQL lancé
☐ Database "mycoris" existe
☐ Peut se connecter: psql -U postgres -d mycoris
```

### Environment Variables
**mycoris-master/.env**
```
DATABASE_URL=postgres://user:password@localhost:5432/mycoris
NODE_ENV=development
PORT=5000
JWT_SECRET=your-secret-key
```

**dashboard-admin/.env** (optionnel, défaut OK)
```
VITE_API_URL=http://localhost:5000
```

### Dépendances
```
☐ npm install dans mycoris-master/ → aucune erreur
☐ npm install dans dashboard-admin/ → aucune erreur
```

---

## 🚀 Démarrage Complet (Checklist)

### ÉTAPE 1: Migration BD
```bash
cd mycoris-master
node run_notifications_migration.js
```

**Attendez le message:**
```
✅ Migration notifications executée avec succès
```

**Vérifier:**
```bash
psql -U postgres -d mycoris
SELECT COUNT(*) FROM notifications;
# Résultat: 1 row (table existe)
\dt notifications  # Voir la table
```

☐ Migration exécutée avec succès

---

### ÉTAPE 2: Démarrer Backend

**Terminal 1:**
```bash
cd mycoris-master
npm start
```

**Attendez:**
```
✅ Connexion PostgreSQL établie avec succès
📅 Test DB - Date serveur PostgreSQL : ...
🚀 Serveur CORIS lancé sur http://localhost:5000
```

**Vérifier dans navigateur:**
```
http://localhost:5000
# Doit afficher quelque chose (ou erreur 404, c'est OK)
```

☐ Backend démarré sur :5000

---

### ÉTAPE 3: Démarrer Frontend

**Terminal 2:**
```bash
cd dashboard-admin
npm run dev
```

**Attendez:**
```
➜ Local: http://localhost:3000/
```

**Vérifier dans navigateur:**
```
http://localhost:3000
# Doit afficher page de login
```

☐ Frontend démarré sur :3000

---

## 🧪 Tests Rapides

### Test 1: Login
```
☐ Ouvrir http://localhost:3000
☐ Voir page de login
☐ Entrer email/password admin
☐ Cliquer "Se connecter"
☐ Dashboard apparaît
```

### Test 2: Créer Utilisateur
```
☐ Menu gauche → Utilisateurs
☐ Cliquer "Nouvel utilisateur"
☐ Remplir formulaire:
  ☐ Prénom: Marie
  ☐ Nom: Dupont
  ☐ Email: marie@test.com
  ☐ Téléphone: +225...
  ☐ MOT DE PASSE: SecurePass123! (IMPORTANT)
  ☐ Rôle: Commercial
☐ Cliquer "Créer"
☐ Message "Utilisateur créé" apparaît
```

### Test 3: Vérifier Notification
```
☐ Chercher cloche (🔔) en haut à droite
☐ Cloche montre badge ROUGE avec "1"
☐ Cliquer cloche
☐ Dropdown s'ouvre
☐ Voir notification:
  ☐ Type: 🔵 Nouvel utilisateur
  ☐ Title: "Nouvel utilisateur Commercial"
  ☐ Message: "Nouvel utilisateur Commercial enregistré: Marie Dupont"
  ☐ Timestamp: Date/heure actuelle
```

### Test 4: Marquer Notification Lue
```
☐ Notification visible dans dropdown
☐ Cliquer sur notification
☐ Badge disparaît de la cloche
☐ Notification n'apparaît plus non lue
```

### Test 5: Voir Utilisateur
```
☐ Utilisateurs → Trouver Marie Dupont
☐ Cliquer icône 👁️ (Voir)
☐ Modal s'ouvre avec:
  ☐ Tous les champs affichés
  ☐ Valeurs correctes
  ☐ Pas de champ password
  ☐ Bouton "Fermer" fonctionne
```

### Test 6: Modifier Utilisateur
```
☐ Cliquer icône ✏️ (Modifier)
☐ Modal avec formulaire s'ouvre
☐ Changer: Téléphone: +225 07 98 76 54 32
☐ Cliquer "Sauvegarder"
☐ Message "modifié avec succès"
☐ Nouvelle valeur affichée dans liste
```

### Test 7: Supprimer Utilisateur
```
☐ Cliquer icône 🗑️ (Supprimer)
☐ Dialog "Êtes-vous sûr?" apparaît
☐ Cliquer "Oui"
☐ Message "Utilisateur supprimé"
☐ Utilisateur retiré de la liste
```

### Test 8: Auto-refresh Notifications
```
☐ Dropdown notifications ouvert
☐ Attendre 30+ secondes
☐ Données se mettent à jour automatiquement
☐ Pas besoin de cliquer refresh
```

---

## 🔍 Vérifications Détaillées

### Console Navigateur (F12)
```
☐ Pas d'erreurs rouges
☐ Voir des fetch vers /api/admin/...
☐ Réponses 200 OK
☐ Pas de CORS errors
```

### Terminal Backend
```
☐ Voir des logs:
  ☐ Connexions DB: "Connexion PostgreSQL établie"
  ☐ Requêtes: Log des POST/PUT/DELETE
  ☐ Pas d'erreurs 500
```

### Terminal Frontend
```
☐ Pas d'erreurs de build
☐ Voir "HMR Client connected"
☐ Pas de warnings rouges
```

### PostgreSQL
```
☐ Table users existe et a 20 rows
☐ Table notifications existe et est vide (0 rows)
☐ Peut faire: SELECT * FROM users;
```

---

## ❌ Si Quelque Chose ne Fonctionne Pas

### Problème: "notifications table does not exist"
```bash
cd mycoris-master
node run_notifications_migration.js
# Puis redémarrer backend
```

### Problème: Cloche ne montre pas de badge
```
1. Redémarrer frontend: Ctrl+C puis npm run dev
2. F5 pour recharger page
3. Vérifier que nouvel utilisateur a été créé
4. Vérifier console (F12) pour erreurs
```

### Problème: Boutons Voir/Modifier/Supprimer ne fonctionnent pas
```
1. Vérifier que UsersPage.jsx est bien à jour
2. Redémarrer frontend
3. Vérifier console (F12) pour erreurs
```

### Problème: Port 3000 ou 5000 déjà utilisé
```bash
# Windows PowerShell
Get-NetTCPConnection -LocalPort 3000 | Stop-Process -Force
Get-NetTCPConnection -LocalPort 5000 | Stop-Process -Force

# Linux/Mac
lsof -ti:3000 | xargs kill -9
lsof -ti:5000 | xargs kill -9
```

### Problème: Mot de passe non accepté
```
☐ Vérifier que password field n'est pas vide
☐ Vérifier que mot de passe a min 8 caractères
☐ Vérifier console pour validation errors
```

---

## ✨ Résumé Final

**Avant de commencer:**
- ☐ PostgreSQL en marche
- ☐ Base de données "mycoris" existe
- ☐ .env files configurés
- ☐ npm install exécuté

**Pour démarrer:**
- ☐ Migration: `node run_notifications_migration.js`
- ☐ Backend: `npm start` (Terminal 1)
- ☐ Frontend: `npm run dev` (Terminal 2)

**Pour tester:**
- ☐ Login: http://localhost:3000
- ☐ Créer utilisateur
- ☐ Vérifier notifications
- ☐ Tester Voir/Modifier/Supprimer

**Si erreur:**
- ☐ Vérifier logs (Terminal + F12)
- ☐ Vérifier migration
- ☐ Redémarrer backend/frontend
- ☐ Chercher dans QUICK_REFERENCE.md

---

**Status de Déploiement:**
- Backend: ✅ Prêt
- Frontend: ✅ Prêt
- Base de Données: ✅ Prêt
- Notifications: ✅ Prêt
- Tests: ✅ Procédure disponible

**VOUS ÊTES PRÊT À DÉMARRER!** 🚀
