# ⚡ QUICK REFERENCE - Commandes Essentielles

## 🚀 DÉMARRAGE COMPLET (3 options)

### Option 1: Automatique (Windows - Recommandé pour commencer)
```batch
# Double-cliquer simplement sur:
start-all.bat
```
✅ Fait tout automatiquement (migration + backend + frontend)

### Option 2: Automatique (Linux/Mac)
```bash
chmod +x start-all.sh
./start-all.sh
```

### Option 3: Manuel (Comprendre chaque étape)
```bash
# Fenêtre Terminal 1: Migration
cd mycoris-master
node run_notifications_migration.js
# Attend: "✅ Migration notifications executée avec succès"

# Fenêtre Terminal 2: Backend  
cd mycoris-master
npm start
# Attend: "🚀 Serveur CORIS lancé sur http://localhost:5000"

# Fenêtre Terminal 3: Frontend
cd dashboard-admin
npm run dev
# Attend: "http://localhost:3000/"
```

---

## 📝 PREMIERS PAS

### 1. Accéder au Dashboard
```
URL: http://localhost:3000
Email: [votre email admin]
Password: [votre password]
```

### 2. Créer un Utilisateur (avec notification)
```
1. Menu gauche → Utilisateurs
2. Cliquer "Nouvel utilisateur"
3. Remplir formulaire (tous les champs)
4. IMPORTANT: Ajouter un MOT DE PASSE
5. Cliquer "Créer"
6. ✅ Cloche montre badge "1"
```

### 3. Tester Voir/Modifier/Supprimer
```
1. Trouvez un utilisateur dans la liste
2. Cliquer 👁️ (Voir) → Détails en lecture seule
3. Cliquer ✏️ (Modifier) → Formulaire éditable
4. Cliquer 🗑️ (Supprimer) → Demande confirmation
```

### 4. Tester Notifications
```
1. Cliquer cloche (🔔) dans le header
2. Dropdown s'ouvre avec notifications
3. Voir détails: type, message, timestamp
4. Cliquer notification → marque comme lue
5. Badge disparaît
```

---

## 🔧 COMMANDES UTILES

### Installation Dépendances (Une seule fois)
```bash
# Backend
cd mycoris-master
npm install

# Frontend
cd dashboard-admin
npm install
```

### Migration Base de Données
```bash
cd mycoris-master
node run_notifications_migration.js
```
✅ Crée table notifications et indexes

### Vérifier Migration (PostgreSQL)
```bash
psql -U postgres -d mycoris
SELECT COUNT(*) FROM notifications;
```
Résultat attendu: `1` (table existe, 0 rows)

### Redémarrer Backend
```bash
# Arrêter (Ctrl+C dans le terminal)
# Puis relancer
npm start
```

### Redémarrer Frontend
```bash
# Arrêter (Ctrl+C dans le terminal)  
# Puis relancer
npm run dev
```

### Voir Logs Backend
```
# Visible dans le terminal du "npm start"
# Chercher: ✅ ou ❌ ou 🚀 ou 📅
```

### Voir Logs Frontend
```
# Appuyer F12 dans navigateur
# Aller à: Console tab
# Chercher les erreurs rouges
```

---

## 🧪 TESTS RAPIDES

### Test 1: Migration OK?
```bash
node run_notifications_migration.js
# Résultat: ✅ Migration notifications executée
```

### Test 2: Backend OK?
```bash
curl http://localhost:5000
# Ou ouvrir http://localhost:5000 dans navigateur
```

### Test 3: Frontend OK?
```
Ouvrir http://localhost:3000 dans navigateur
Voir page de login
```

### Test 4: BD OK?
```bash
# Depuis PostgreSQL console
SELECT * FROM users LIMIT 1;
# Doit retourner: 1 ligne avec données
```

### Test 5: Notifications OK?
```bash
# Créer un utilisateur
# Vérifier cloche montre badge
# Cliquer cloche → dropdown apparaît
```

---

## 🆘 DÉPANNAGE RAPIDE

### Erreur: "notifications table does not exist"
```bash
cd mycoris-master
node run_notifications_migration.js
# Puis redémarrer backend
```

### Erreur: "Cannot find module"
```bash
# Réinstaller dépendances
npm install
# Puis redémarrer
```

### Port 3000 ou 5000 déjà utilisé?
```bash
# Tuer le processus (Windows PowerShell)
Get-Process | Where-Object {$_.Port -eq 3000} | Stop-Process
Get-Process | Where-Object {$_.Port -eq 5000} | Stop-Process
```

### Frontend ne voit pas backend?
```bash
1. Vérifier que backend tourne: http://localhost:5000
2. Vérifier CORS (backend accepte localhost:3000)
3. Vérifier .env VITE_API_URL=http://localhost:5000
4. Redémarrer frontend (npm run dev)
```

### Mot de passe non accepté?
```
Vérifier que le champ password dans le formulaire:
1. N'est pas vide
2. A minimum 8 caractères
3. Redémarrer navigateur (Ctrl+Shift+Delete)
```

---

## 📊 ARCHITECTURE RÉSUMÉE

```
🖥️ FRONTEND (React + Vite)
   └─ localhost:3000
      ├─ Login page
      ├─ Dashboard (analytics)
      └─ Users page (CRUD + notifications)
              │
              │ HTTP + JWT
              ▼
🖧 BACKEND (Node/Express)
   └─ localhost:5000
      ├─ POST /users → créer + notifier
      ├─ PUT /users/:id → modifier
      ├─ DELETE /users/:id → supprimer
      ├─ GET /notifications → lister
      ├─ PUT /notifications/:id/mark-read → marquer lue
      └─ POST /notifications/create → créer manuelle
              │
              │ pg driver
              ▼
🗄️ DATABASE (PostgreSQL)
   └─ mycoris
      ├─ users (20 rows)
      ├─ notifications (auto-populated)
      ├─ subscriptions (71 rows)
      ├─ contrats (860+ rows)
      └─ other tables...
```

---

## 📋 CHECKLIST DE DÉMARRAGE

```
☐ Dossiers existants:
   ☐ mycoris-master/
   ☐ dashboard-admin/

☐ Variables d'environnement:
   ☐ mycoris-master/.env (DATABASE_URL, etc.)
   ☐ dashboard-admin/.env (VITE_API_URL)

☐ Dépendances installées:
   ☐ npm install dans mycoris-master/
   ☐ npm install dans dashboard-admin/

☐ Base de données:
   ☐ PostgreSQL lancé
   ☐ Database mycoris créée
   ☐ Tables existantes (users, contrats, etc.)

☐ Migration:
   ☐ node run_notifications_migration.js exécuté
   ☐ Table notifications visible en BD

☐ Serveurs:
   ☐ Backend lancé (npm start) sur :5000
   ☐ Frontend lancé (npm run dev) sur :3000

☐ Tests:
   ☐ Login fonctionne
   ☐ Dashboard affiche données
   ☐ Créer utilisateur fonctionne
   ☐ Voir/Modifier/Supprimer fonctionne
   ☐ Notifications cloche fonctionne
```

---

## 🎯 FLUX D'UTILISATION COMPLET

```
1. DÉMARRAGE
   ├─ npm install (si première fois)
   ├─ node run_notifications_migration.js
   ├─ npm start (backend)
   └─ npm run dev (frontend)
        
2. LOGIN
   ├─ Aller http://localhost:3000
   ├─ Entrer email/password
   └─ Accéder au dashboard
   
3. UTILISATEURS
   ├─ Menu → Utilisateurs
   ├─ Voir liste (filtrer par rôle)
   ├─ Créer nouveau:
   │  ├─ Remplir tous champs
   │  ├─ Ajouter mot de passe
   │  └─ Cliquer "Créer"
   ├─ Voir détails: 👁️
   ├─ Modifier: ✏️
   └─ Supprimer: 🗑️
   
4. NOTIFICATIONS
   ├─ Cloche (🔔) en haut à droite
   ├─ Voir badge: nombre non lues
   ├─ Cliquer cloche: dropdown
   ├─ Voir liste notifications
   ├─ Cliquer notification: marquer lue
   └─ Auto-refresh: toutes les 30s
```

---

## 📞 AIDE RAPIDE

**Quelle est l'URL?**
```
Dashboard: http://localhost:3000
API: http://localhost:5000
```

**Où voir les logs?**
```
Backend: Terminal (npm start)
Frontend: DevTools (F12 → Console)
BD: PostgreSQL logs
```

**Quels fichiers modifier?**
```
Frontend: dashboard-admin/src/
Backend: mycoris-master/routes/ + controllers/
BD: mycoris-master/migrations/
```

**Comment redémarrer?**
```
Appuyez Ctrl+C dans chaque terminal
Puis relancez: npm start / npm run dev
```

**Ça ne fonctionne pas?**
```
1. Vérifier logs (Terminal + F12 Console)
2. Redémarrer backend et frontend
3. Exécuter migration: node run_notifications_migration.js
4. Vérifier ports 3000/5000 libres
```

---

## ✨ RÉSUMÉ EXTRÊMEMENT COURT

**Pour démarrer (Windows):**
```
1. Double-cliquer: start-all.bat
2. Attendre 30 secondes
3. Ouvrir: http://localhost:3000
4. Login + Profiter! 🎉
```

**Pour démarrer (Linux/Mac):**
```bash
chmod +x start-all.sh
./start-all.sh
# Puis ouvrir http://localhost:3000
```

**Vérifications essentielles:**
```
✅ Backend → http://localhost:5000
✅ Frontend → http://localhost:3000
✅ Login → Fonctionne
✅ Utilisateurs → Voir/Modifier/Supprimer
✅ Notifications → Cloche affiche badge
```

---

**Dernière mise à jour**: 2025-01-09  
**Status**: ✅ Prêt à l'emploi
