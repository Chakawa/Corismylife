# 🧪 Guide de Test - Système d'Administrateurs Multi-Types

## 📋 Administrateurs de Test

Trois administrateurs ont été créés pour tester les différents niveaux d'accès :

### 1️⃣ Super Administrateur (Accès Complet)
```
Email: super_admin@coris.ci
Mot de passe: SuperAdmin@2024
Type: super_admin
```

**Permissions:**
- ✅ Gestion des utilisateurs
- ✅ Gestion des administrateurs
- ✅ Gestion des contrats
- ✅ Gestion des produits
- ✅ Gestion des commerciaux
- ✅ Voir rapports
- ✅ Modifier paramètres système
- ✅ Supprimer données
- ✅ Voir logs d'audit

**Pages accessibles:**
- 📊 Tableau de Bord
- 👥 Utilisateurs
- 📄 Contrats
- 📦 Produits
- 💼 Commerciaux
- 📈 Rapports
- 📋 Activités
- ⚙️ Paramètres

---

### 2️⃣ Administrateur Standard
```
Email: admin@coris.ci
Mot de passe: Admin@2024
Type: admin
```

**Permissions:**
- ✅ Gestion des utilisateurs
- ❌ Gestion des administrateurs
- ✅ Gestion des contrats
- ✅ Gestion des produits
- ✅ Gestion des commerciaux
- ✅ Voir rapports
- ❌ Modifier paramètres système
- ❌ Supprimer données
- ❌ Voir logs d'audit

**Pages accessibles:**
- 📊 Tableau de Bord
- 👥 Utilisateurs
- 📄 Contrats
- 📦 Produits
- 💼 Commerciaux
- 📈 Rapports
- 📋 Activités
- ❌ Paramètres (accès refusé)

---

### 3️⃣ Modérateur (Accès Limité)
```
Email: moderation@coris.ci
Mot de passe: Moderation@2024
Type: moderation
```

**Permissions:**
- ❌ Gestion des utilisateurs
- ❌ Gestion des administrateurs
- ❌ Gestion des contrats
- ❌ Gestion des produits
- ❌ Gestion des commerciaux
- ✅ Voir rapports
- ❌ Modifier paramètres système
- ❌ Supprimer données
- ❌ Voir logs d'audit

**Pages accessibles:**
- 📊 Tableau de Bord
- 📈 Rapports
- 📋 Activités
- ❌ Toutes autres pages (accès refusé)

---

## 🧪 Scénarios de Test

### Test 1: Accès Tableau de Bord
1. Se connecter avec chaque compte
2. Vérifier que le tableau de bord affiche le type d'admin correct
3. Vérifier que les permissions affichées correspondent

### Test 2: Navigation Sidebar
1. Se connecter avec chaque compte
2. Vérifier que la sidebar affiche uniquement les pages autorisées
3. Tester que les autres liens ne sont pas cliquables

### Test 3: Protection des Routes
1. Se connecter avec `moderation@coris.ci`
2. Essayer d'accéder manuellement à `/users` (devrait afficher "Accès Refusé")
3. Essayer `/contracts` (devrait afficher "Accès Refusé")
4. Essayer `/settings` avec `admin@coris.ci` (devrait afficher "Accès Refusé")

### Test 4: Badge Admin Type
1. Dans la sidebar, vérifier que le badge affiche correctement le type d'admin
2. 👑 Super Admin pour super_admin
3. 🔧 Admin pour admin
4. 🔒 Modérateur pour moderation

### Test 5: Pages Accessibles
1. Vérifier que le tableau de bord affiche les pages accessibles
2. Les émojis correspondent au type de page
3. Cliquer sur une page pour naviguer

---

## 🔧 Commandes Utiles

### Vérifier les admins en base de données
```bash
cd mycoris-master
node create_test_admins.js
```

### Réinitialiser les admins de test
```bash
node create_test_admins.js
```

---

## 📝 Notes d'Implémentation

### Fichiers Créés/Modifiés

**Backend:**
- ✅ `routes/adminRoutes.js` - Endpoint GET /api/admin/permissions
- ✅ `middleware/adminPermissions.js` - Middleware de vérification des droits
- ✅ `controllers/authController.js` - Inclusion de admin_type dans JWT
- ✅ `create_test_admins.js` - Script de création des admins

**Frontend:**
- ✅ `pages/AdminDashboard.jsx` - Nouveau tableau de bord admin
- ✅ `pages/AccessDeniedPage.jsx` - Page d'accès refusé
- ✅ `components/ProtectedRoute.jsx` - Composant de protection de route
- ✅ `components/layout/SidebarNav.jsx` - Navigation filtrée par permissions
- ✅ `services/permissions.service.js` - Service de gestion des permissions
- ✅ `App.jsx` - Intégration des routes protégées

---

## 🚀 Prochaines Améliorations

1. **WebSocket pour les mises à jour temps réel** des permissions
2. **Logs d'audit** pour les actions des admins
3. **Historique des modifications** par admin
4. **Restriction par IP** pour les super admins
5. **Session timeout** selon le type d'admin
6. **Audit trail** des accès refusés

---

## ❓ Dépannage

### "Accès Refusé" pour tous les admins
→ Vérifier que le JWT inclut `admin_type`
→ Vérifier que la migration `admin_type` a été exécutée

### Sidebar ne met pas à jour les permissions
→ Recharger la page
→ Vérifier la console pour les erreurs
→ Vérifier que le token est valide

### Routes ne sont pas protégées
→ Vérifier que ProtectedRoute est utilisé
→ Vérifier le paramètre `requiredPage` ou `requiredAdminTypes`

---

**Date de création:** 7 janvier 2026
**Version:** 1.0
