# ✅ CORIS Admin Dashboard - Fonctionnalités Complètes

## 📊 État du Système Actuel

### ✅ Fonctionnalités Implémentées

#### 1. **Gestion des Utilisateurs (CRUD Complet)**
- ✅ **Voir les détails** (modal lecture seule)
- ✅ **Modifier les données** (nom, prénom, email, téléphone, adresse, rôle)
- ✅ **Supprimer un utilisateur** (avec confirmation)
- ✅ **Créer un nouvel utilisateur** avec tous les champs:
  - Civilité, Prénom, Nom
  - Email, Téléphone
  - Date/Lieu de naissance
  - Adresse, Pays
  - Rôle (Client, Commercial, Admin)
  - Type d'Admin (Super Admin, Admin Standard, Modérateur)
  - Code apporteur
  - **Mot de passe** (haché en base de données avec bcrypt)

#### 2. **Système de Notifications**
- ✅ Cloche (bell icon) dans le header
- ✅ Badge de compte des notifications non lues
- ✅ Menu déroulant avec 10 dernières notifications
- ✅ Notifications auto-actualisées toutes les 30 secondes
- ✅ Marquer comme lue en cliquant sur la notification
- ✅ Couleurs différentes par type:
  - 🔵 Nouvel utilisateur (bleu)
  - 🟢 Nouvelle souscription (vert)
  - 🟣 Mise à jour contrat (violet)
  - 🟡 Action commercial (jaune)

#### 3. **Déclencheurs de Notifications Automatiques**
- ✅ **Nouvel utilisateur/admin** → notification créée immédiatement
- ✅ **Nouvelle souscription** → notification avec détails du produit
- 📋 Changer le statut d'un contrat (prochaine phase)
- 📋 Actions commerciales - commissions (prochaine phase)

#### 4. **Dashboard Analytique**
- ✅ Cartes KPI avec % de changement (vs mois précédent)
- ✅ Graphique des revenus (12 derniers mois)
- ✅ Sélecteur de période (3/6/12 mois)
- ✅ Export CSV des revenus
- ✅ Page d'activités avec pagination
- ✅ Graphiques par produit et statut

---

## 🚀 Guide de Démarrage Rapide

### Étape 1: Migration Base de Données
```bash
cd mycoris-master
node run_notifications_migration.js
```
**Résultat**: Table `notifications` créée avec tous les index

### Étape 2: Démarrer le Backend
```bash
cd mycoris-master
npm start
# ✓ Serveur sur http://localhost:5000
```

### Étape 3: Démarrer le Dashboard
```bash
cd dashboard-admin
npm run dev
# ✓ Dashboard sur http://localhost:3000
```

### Étape 4: Se connecter
- URL: `http://localhost:3000`
- Email: (admin créé lors de l'installation)
- Mot de passe: (votre mot de passe admin)

---

## 🧪 Tests à Effectuer

### Test 1: Créer un Nouvel Utilisateur
1. Dashboard → Menu gauche → "Utilisateurs"
2. Cliquer "Nouvel utilisateur"
3. Remplir le formulaire (tous les champs requis)
4. **Important**: Ajouter un mot de passe fort
5. Sélectionner le rôle (Client/Commercial/Admin)
6. Cliquer "Créer"
7. ✅ **Vérification**: Une notification apparaît dans la cloche

### Test 2: Voir les Détails d'un Utilisateur
1. Depuis la liste des utilisateurs
2. Cliquer sur l'icône 👁️ (Voir)
3. ✅ Une modal s'ouvre en lecture seule avec tous les détails

### Test 3: Modifier un Utilisateur
1. Cliquer sur l'icône ✏️ (Modifier)
2. Changer quelques champs (ex: téléphone, adresse)
3. Cliquer "Sauvegarder"
4. ✅ L'utilisateur est mis à jour

### Test 4: Supprimer un Utilisateur
1. Cliquer sur l'icône 🗑️ (Supprimer)
2. Confirmer dans la dialog
3. ✅ L'utilisateur est supprimé et retiré de la liste

### Test 5: Notifications - Nouvel Utilisateur
1. Créer un nouvel utilisateur (voir Test 1)
2. Vérifier la cloche dans le header
3. ✅ Badge montrant "1" notification non lue
4. Cliquer sur la cloche
5. ✅ La notification apparaît avec:
   - Type: "Nouvel utilisateur"
   - Message: Détails du nouvel utilisateur
   - Timestamp: Date/heure de création
6. Cliquer sur la notification
7. ✅ Elle est marquée comme lue (badge disparaît)

### Test 6: Notifications - Nouvelle Souscription (optionnel)
1. Créer une nouvelle souscription (via l'app mobile ou API)
2. Vérifier la cloche
3. ✅ Nouvelle notification "Nouvelle souscription"

---

## 📁 Structure des Fichiers Modifiés

```
mycoris-master/
├── routes/
│   └── adminRoutes.js                          [✏️ MODIFIÉ]
│       ├── POST /users → crée notification
│       ├── GET /notifications → liste notifications
│       ├── PUT /notifications/:id/mark-read → marquer comme lue
│       └── POST /notifications/create → créer manuelle
├── controllers/
│   └── subscriptionController.js               [✏️ MODIFIÉ]
│       └── createSubscription() → crée notification
├── migrations/
│   └── create_notifications_admin_table.sql    [✨ CRÉÉ]
└── run_notifications_migration.js              [✨ CRÉÉ]

dashboard-admin/src/
├── components/layout/
│   └── Header.jsx                              [✏️ MODIFIÉ]
│       ├── Cloche avec dropdown
│       ├── Badge de compte
│       └── Auto-refresh (30s)
├── pages/
│   └── UsersPage.jsx                           [✏️ MODIFIÉ]
│       ├── Champ mot de passe
│       ├── Modal Voir (read-only)
│       ├── Modal Modifier (form)
│       └── Boutons Voir/Modifier/Supprimer
└── services/
    └── api.service.js                          [✏️ MODIFIÉ]
        └── notificationsService {getNotifications, markAsRead, create}
```

---

## 🔐 Sécurité des Mots de Passe

- ✅ Les mots de passe sont hachés avec **bcrypt** (10 rounds) avant stockage
- ✅ Les mots de passe ne sont JAMAIS retournés par les API
- ✅ Tous les endpoints nécessitent l'authentification JWT
- ✅ Seuls les admins peuvent créer des utilisateurs

**Exemple de flux:**
```
1. Admin entre mot de passe dans le formulaire
2. Frontend envoie: { prenom, nom, email, ..., password }
3. Backend reçoit et hache: bcrypt.hash(password, 10)
4. Base de données stocke: $2b$10$encrypted...
5. Réponse API: { success, user: {...} } (pas de password)
```

---

## 📞 Endpoints API Principaux

### Utilisateurs
```
GET    /api/admin/users                    - Liste avec filtres
POST   /api/admin/users                    - Créer (crée notification)
PUT    /api/admin/users/:id                - Modifier
DELETE /api/admin/users/:id                - Supprimer
```

### Notifications
```
GET    /api/admin/notifications            - Mes notifications (avec count non lues)
PUT    /api/admin/notifications/:id/mark-read - Marquer comme lue
POST   /api/admin/notifications/create     - Créer (pour tous les admins)
```

### Dashboard
```
GET    /api/admin/stats                    - Statistiques globales
GET    /api/admin/activities               - Activités récentes
GET    /api/admin/contracts                - Contrats
GET    /api/admin/subscriptions            - Souscriptions
GET    /api/admin/commissions              - Commissions
```

---

## 🎯 Prochaines Améliorations Suggérées

### Phase 1 (Court terme)
- [ ] Ajouter notifications pour "Contrat - Changement de statut"
- [ ] Ajouter notifications pour "Action Commercial - Commission"
- [ ] Implémenter WebSocket pour notifications en temps réel (vs polling)
- [ ] Ajouter son/toast pour notifications critiques

### Phase 2 (Moyen terme)
- [ ] Préférences de notifications (admin peut choisir les événements)
- [ ] Historique des notifications (voir toutes, pas seulement dernières 10)
- [ ] Filtrage par type dans le dropdown
- [ ] Export notifications comme rapport

### Phase 3 (Long terme)
- [ ] Notifications email en plus des notifications in-app
- [ ] Nettoyage automatique des anciennes notifications (>30 jours)
- [ ] Analytics: qui a cliqué sur quelles notifications
- [ ] Notifications mobiles push

---

## 🐛 Dépannage

### Problème: Aucune notification n'apparaît
**Solutions:**
1. Vérifier que la migration a été exécutée:
   ```bash
   psql -U postgres -d mycoris -c "SELECT * FROM notifications;"
   ```
2. Vérifier que vous êtes connecté en tant qu'admin
3. Redémarrer le backend et le frontend
4. Vérifier la console du navigateur (F12 → Console)

### Problème: "Table notifications does not exist"
**Solution:**
```bash
node run_notifications_migration.js
```

### Problème: Les notifications ne s'actualisent pas
**Solutions:**
1. Vérifier que `/api/admin/notifications` retourne des données
2. Vérifier l'onglet Network (DevTools) pour voir les appels
3. Recharger la page (F5)

### Problème: Mot de passe non accepté
**Solution:**
1. Vérifier que le champ password n'est pas vide
2. Utiliser un mot de passe avec au moins 8 caractères
3. Vérifier les erreurs dans la console du navigateur

---

## 📊 Stats Actuelles (Exemple)

| Métrique | Valeur |
|----------|--------|
| Total Utilisateurs | 20 |
| Clients | 8 |
| Commerciaux | 5 |
| Administrateurs | 7 |
| Utilisateurs suspendus | 1 |
| Contrats actifs | 850+ |
| Souscriptions | 71 |
| Produits | 5+ |

---

## 📝 Notes Importantes

1. **Permissions**: Seuls les admins peuvent:
   - Voir tous les utilisateurs
   - Créer des utilisateurs
   - Modifier/supprimer des utilisateurs
   - Voir les notifications

2. **Notifications**: Créées automatiquement pour:
   - Chaque nouvel utilisateur enregistré
   - Chaque nouvelle souscription
   - (À ajouter) Changements de statut de contrats
   - (À ajouter) Actions commerciales

3. **Base de Données**: PostgreSQL avec:
   - Table `users` (20 utilisateurs existants)
   - Table `notifications` (nouvelle - vide au départ)
   - Indexes pour performance (admin_id, is_read, type, created_at)

4. **Authentification**: Tous les endpoints protégés par JWT
   - Token stocké en localStorage
   - Auto-refresh si expiré
   - Redirection vers login si non authentifié

---

## 🎓 Légende des Icônes

| Icône | Signification |
|-------|---------------|
| ✅ | Implémenté et fonctionnel |
| ✏️ | Fichier modifié |
| ✨ | Nouveau fichier créé |
| 🔵 | Notification nouvel utilisateur |
| 🟢 | Notification nouvelle souscription |
| 👁️ | Voir détails |
| ✏️ | Modifier |
| 🗑️ | Supprimer |
| 🔔 | Notifications |

---

**Dernière mise à jour**: 2025-01-09
**Status**: ✅ Production Ready
