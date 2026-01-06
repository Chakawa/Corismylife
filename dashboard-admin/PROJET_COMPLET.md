# 📊 CORIS - Tableau de Bord Administrateur

## 🎉 Projet Créé avec Succès !

Vous disposez maintenant d'un **tableau de bord administrateur professionnel** pour gérer votre plateforme CORIS.

---

## 📁 Structure Complète du Projet

```
dashboard-admin/
├── 📄 Configuration
│   ├── package.json              # Dépendances et scripts
│   ├── vite.config.js            # Configuration Vite
│   ├── tailwind.config.js        # Configuration Tailwind CSS
│   ├── postcss.config.js         # Configuration PostCSS
│   ├── .env                      # Variables d'environnement
│   └── .env.example              # Template des variables
│
├── 🌐 Frontend (React)
│   ├── index.html                # Template HTML principal
│   └── src/
│       ├── main.jsx              # Point d'entrée React
│       ├── App.jsx               # Routeur principal
│       ├── index.css             # Styles globaux + Tailwind
│       │
│       ├── 📦 components/
│       │   └── layout/
│       │       ├── DashboardLayout.jsx   # Layout principal
│       │       ├── Sidebar.jsx           # Menu latéral
│       │       └── Header.jsx            # En-tête avec recherche
│       │
│       ├── 📄 pages/
│       │   ├── LoginPage.jsx             # ✅ Connexion admin
│       │   ├── DashboardPage.jsx         # ✅ Vue d'ensemble avec graphiques
│       │   ├── UsersPage.jsx             # ✅ Gestion utilisateurs
│       │   ├── ContractsPage.jsx         # ⏳ Gestion contrats
│       │   ├── SubscriptionsPage.jsx     # ⏳ Gestion souscriptions
│       │   ├── CommissionsPage.jsx       # ⏳ Gestion commissions
│       │   ├── ProductsPage.jsx          # ⏳ Gestion produits
│       │   └── SettingsPage.jsx          # ⏳ Paramètres
│       │
│       ├── 🔧 services/
│       │   └── api.service.js            # Services API
│       │
│       └── 🛠️ utils/
│           └── api.js                    # Configuration Axios
│
└── 📚 Documentation
    ├── README.md                 # Documentation principale
    └── GUIDE_DEMARRAGE.md        # Guide de démarrage complet
```

---

## 🎨 Design & Couleurs

### Palette CORIS (identique à l'app mobile)
- **Bleu Principal:** `#002B6B` (coris-blue)
- **Rouge CORIS:** `#E30613` (coris-red)
- **Bleu Clair:** `#003A85` (coris-blue-light)
- **Gris Fond:** `#F0F4F8` (coris-gray)
- **Vert Succès:** `#10B981` (coris-green)
- **Orange Alerte:** `#F59E0B` (coris-orange)

### Police
- **Famille:** Inter (Google Fonts)
- **Poids:** 300 à 800
- **Usage:** Moderne, professionnel, excellent pour les dashboards

---

## 🚀 Technologies Utilisées

### Frontend
- ⚛️ **React 18** - Library UI moderne
- ⚡ **Vite** - Build tool ultra-rapide
- 🎨 **Tailwind CSS 3** - Framework CSS utilitaire
- 🧭 **React Router 6** - Navigation SPA
- 📊 **Recharts** - Bibliothèque de graphiques
- 🔌 **Axios** - Client HTTP
- 🎯 **Lucide React** - Icônes modernes

### Backend (Déjà existant)
- 🟢 **Node.js + Express**
- 🐘 **PostgreSQL**
- 🔐 **JWT** pour l'authentification
- 📡 **CORS** configuré pour le web

---

## ✨ Fonctionnalités Implémentées

### ✅ Complètes

#### 1. **Authentification Sécurisée**
- Page de connexion moderne
- Vérification du rôle admin
- Gestion des tokens JWT
- Redirection automatique si non authentifié

#### 2. **Dashboard Principal**
- 📈 **4 cartes statistiques** (Utilisateurs, Contrats, Souscriptions, Revenus)
- 📊 **Graphique évolution mensuelle** (Area Chart - Contrats & Souscriptions)
- 🥧 **Distribution par produit** (Pie Chart)
- 💰 **Revenus mensuels** (Bar Chart)
- 🎯 **Statut des contrats** (Donut Chart)
- 📋 **Activités récentes** (Liste en temps réel)

#### 3. **Gestion des Utilisateurs**
- 📋 **Liste complète** avec pagination
- 🔍 **Recherche avancée** (nom, email, téléphone)
- 🎛️ **Filtres par rôle** (Client, Commercial, Admin)
- 📊 **Statistiques** (Total clients, Commerciaux actifs, Comptes suspendus)
- 👁️ **Actions** (Voir, Modifier, Supprimer)
- 🎨 **Interface moderne** avec badges de rôle colorés

#### 4. **Layout Professionnel**
- 📱 **Sidebar** avec navigation intuitive
- 🔝 **Header** avec barre de recherche et menu utilisateur
- 🔔 **Icône notifications** avec badge
- 🎨 **Design responsive** (mobile, tablette, desktop)
- 🌈 **Thème cohérent** avec l'app mobile

### ⏳ En Développement (Pages créées, à compléter)
- Gestion des Contrats
- Gestion des Souscriptions
- Gestion des Commissions
- Gestion des Produits
- Paramètres Système

---

## 🔧 Routes Backend Créées

### Authentification
- `POST /api/auth/login` - Connexion admin

### Dashboard
- `GET /api/admin/stats` - Statistiques globales

### Utilisateurs
- `GET /api/admin/users` - Liste avec filtres
- `GET /api/admin/users/:id` - Détails d'un utilisateur
- `DELETE /api/admin/users/:id` - Supprimer un utilisateur

### Contrats
- `GET /api/admin/contracts` - Liste des contrats

### Souscriptions
- `GET /api/admin/subscriptions` - Liste des souscriptions

### Commissions
- `GET /api/admin/commissions` - Liste des commissions
- `GET /api/admin/commissions/stats` - Statistiques

### Activités
- `GET /api/admin/activities` - Activités récentes

---

## 🚦 Comment Démarrer

### Option 1: Démarrage Rapide (2 terminaux)

**Terminal 1 - Backend:**
```bash
cd d:\CORIS\app_coris\mycoris-master
npm start
```
> Backend sur http://localhost:5000

**Terminal 2 - Dashboard:**
```bash
cd d:\CORIS\app_coris\dashboard-admin
npm run dev
```
> Dashboard sur http://localhost:3000

### Option 2: Script PowerShell (à créer)
Créer `start-dashboard.ps1` :
```powershell
# Démarrer le backend
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd d:\CORIS\app_coris\mycoris-master; npm start"

# Attendre 5 secondes
Start-Sleep -Seconds 5

# Démarrer le dashboard
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd d:\CORIS\app_coris\dashboard-admin; npm run dev"
```

---

## 🔐 Accès Admin

Pour accéder au dashboard, vous devez avoir un compte avec `role = 'admin'`.

### Créer un compte admin (si nécessaire)

Exécuter dans PostgreSQL :
```sql
-- Mettre à jour un utilisateur existant
UPDATE users 
SET role = 'admin' 
WHERE email = 'votre-email@example.com';

-- OU créer un nouvel admin
INSERT INTO users (civilite, nom, prenom, email, telephone, password_hash, role)
VALUES (
  'M',
  'Admin',
  'Système',
  'admin@coris.ci',
  '+2250700000000',
  '$2b$10$hashDuMotDePasse', -- Hasher avec bcrypt
  'admin'
);
```

---

## 📊 Graphiques Disponibles

### Dashboard Principal

1. **Évolution Mensuelle (Area Chart)**
   - Nombre de contrats par mois
   - Nombre de souscriptions par mois
   - 6 derniers mois affichés

2. **Distribution par Produit (Pie Chart)**
   - CORIS SÉRÉNITÉ
   - ÉPARGNE BONUS
   - CORIS ÉTUDE
   - CORIS FAMILIS
   - Autres

3. **Revenus Mensuels (Bar Chart)**
   - Revenus en FCFA par mois
   - Barres colorées avec bordures arrondies

4. **Statut des Contrats (Donut Chart)**
   - Actifs (vert)
   - En attente (orange)
   - Suspendus (rouge)

---

## 🎯 Avantages du Dashboard

### Pour l'Administrateur
- ✅ Vue d'ensemble instantanée de toute l'activité
- ✅ Surveillance des performances en temps réel
- ✅ Gestion centralisée des utilisateurs
- ✅ Accès rapide aux données critiques
- ✅ Interface intuitive et moderne

### Technique
- ⚡ **Performance optimale** (Vite + React)
- 📱 **Responsive** (fonctionne sur tous les écrans)
- 🎨 **Design cohérent** avec l'app mobile
- 🔒 **Sécurisé** (JWT + vérification rôle admin)
- 🔌 **Modulaire** (facile à étendre)

---

## 📈 Métriques Suivies

### Utilisateurs
- Total par rôle (Client, Commercial, Admin)
- Comptes actifs vs suspendus
- Nouvelles inscriptions

### Contrats
- Total actifs
- Par statut (Actif, Inactif, Suspendu)
- Évolution mensuelle

### Souscriptions
- En attente d'approbation
- Approuvées
- Rejetées
- Taux de conversion

### Revenus
- Revenus mensuels
- Tendances
- Comparaison période à période

---

## 🔜 Prochaines Étapes Recommandées

### Phase 1: Compléter les Pages Existantes
1. **Page Contrats**
   - Table avec recherche et filtres
   - Actions: Voir détails, Modifier statut, Exporter PDF
   - Graphiques: Distribution par produit, par commercial

2. **Page Souscriptions**
   - Workflow d'approbation/rejet
   - Détails complets avec documents
   - Historique des actions

3. **Page Commissions**
   - Calculs automatiques
   - Validation et paiement
   - Export pour comptabilité

### Phase 2: Fonctionnalités Avancées
1. **Notifications en Temps Réel**
   - WebSocket pour les mises à jour live
   - Alertes pour actions critiques

2. **Rapports et Exports**
   - Export PDF des rapports
   - Export Excel des données
   - Rapports personnalisables

3. **Logs et Audit**
   - Traçabilité de toutes les actions admin
   - Journal des modifications
   - Sécurité renforcée

### Phase 3: Optimisations
1. **Performance**
   - Lazy loading des composants
   - Pagination server-side
   - Cache des données fréquentes

2. **UX/UI**
   - Dark mode
   - Personnalisation du dashboard
   - Raccourcis clavier

---

## 📞 Support & Documentation

### Fichiers de Référence
- `README.md` - Documentation générale
- `GUIDE_DEMARRAGE.md` - Guide de démarrage détaillé
- `PROJET_COMPLET.md` - Ce fichier (vue d'ensemble complète)

### Structure des Services
- `src/services/api.service.js` - Tous les appels API
- `src/utils/api.js` - Configuration Axios

---

## 🎊 Félicitations !

Vous disposez maintenant d'un **dashboard administrateur professionnel** avec :

✅ Interface moderne et intuitive  
✅ Graphiques interactifs  
✅ Gestion des utilisateurs complète  
✅ Sécurité robuste (JWT + rôle admin)  
✅ Design cohérent avec l'app mobile  
✅ Backend intégré au système existant  
✅ Documentation complète  
✅ Prêt à être étendu  

**Le dashboard est opérationnel et prêt à être utilisé ! 🚀**

---

*Développé avec ❤️ pour CORIS Assurance - 2026*
