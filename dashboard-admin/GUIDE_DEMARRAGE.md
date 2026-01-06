# 🚀 Guide de Démarrage - Dashboard Admin CORIS

Ce guide vous aidera à démarrer le tableau de bord administrateur.

## 📋 Prérequis

- Node.js (v18 ou supérieur)
- npm ou yarn
- Backend MyCoris en cours d'exécution (port 5000)

## 🛠️ Installation

### 1. Naviguer vers le dossier du dashboard

```bash
cd d:\CORIS\app_coris\dashboard-admin
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer les variables d'environnement

Copier `.env.example` vers `.env` :

```bash
copy .env.example .env
```

Vérifier que l'URL de l'API est correcte dans `.env` :

```env
VITE_API_URL=http://localhost:5000/api
```

### 4. Démarrer le serveur backend

Dans un autre terminal, démarrer le backend :

```bash
cd d:\CORIS\app_coris\mycoris-master
npm start
```

Le backend devrait démarrer sur http://localhost:5000

### 5. Démarrer le dashboard

Dans le terminal du dashboard :

```bash
npm run dev
```

Le dashboard devrait s'ouvrir sur http://localhost:3000

## 🔐 Connexion

Pour se connecter au dashboard, utilisez un compte administrateur :

**Email:** admin@coris.ci  
**Mot de passe:** [votre mot de passe admin]

> **Note:** Seuls les utilisateurs avec le rôle `admin` peuvent accéder au dashboard.

## 📁 Structure du Projet

```
dashboard-admin/
├── public/              # Fichiers statiques
├── src/
│   ├── components/      # Composants réutilisables
│   │   └── layout/      # Layout (Sidebar, Header)
│   ├── pages/           # Pages de l'application
│   │   ├── LoginPage.jsx
│   │   ├── DashboardPage.jsx
│   │   ├── UsersPage.jsx
│   │   └── ...
│   ├── services/        # Services API
│   │   └── api.service.js
│   ├── utils/           # Utilitaires
│   │   └── api.js
│   ├── App.jsx          # Composant principal
│   ├── main.jsx         # Point d'entrée
│   └── index.css        # Styles globaux
├── index.html           # Template HTML
├── package.json         # Dépendances
├── vite.config.js       # Configuration Vite
└── tailwind.config.js   # Configuration Tailwind
```

## 🎨 Fonctionnalités Disponibles

### ✅ Déjà Implémentées

- **Dashboard Principal**
  - Statistiques globales (utilisateurs, contrats, revenus)
  - Graphiques interactifs (Recharts)
  - Évolution mensuelle
  - Distribution par produit
  - Activités récentes

- **Gestion des Utilisateurs**
  - Liste complète avec recherche et filtres
  - Détails utilisateur
  - Actions (voir, modifier, supprimer)
  - Statistiques par rôle

- **Authentification**
  - Connexion sécurisée (JWT)
  - Vérification du rôle admin
  - Déconnexion

### ⏳ En Développement

- Gestion des Contrats
- Gestion des Souscriptions
- Gestion des Commissions
- Gestion des Produits
- Paramètres Système

## 🔧 Scripts Disponibles

```bash
# Démarrer en mode développement
npm run dev

# Build pour la production
npm run build

# Prévisualiser le build de production
npm run preview
```

## 🐛 Dépannage

### Le dashboard ne se connecte pas à l'API

1. Vérifier que le backend est en cours d'exécution :
   ```bash
   curl http://localhost:5000/health
   ```

2. Vérifier les logs du backend pour voir si les requêtes arrivent

3. Vérifier la configuration CORS dans `mycoris-master/server.js` :
   ```javascript
   origin: ['http://localhost:3000']
   ```

### Erreur CORS

Si vous voyez des erreurs CORS dans la console :

1. Vérifier que `http://localhost:3000` est dans la liste `origin` du backend
2. Redémarrer le backend après modification

### Erreur "401 Unauthorized"

1. Vérifier que vous êtes connecté avec un compte admin
2. Vérifier que le token JWT n'a pas expiré
3. Se déconnecter et se reconnecter

## 📊 API Endpoints Utilisés

- `POST /api/auth/login` - Connexion
- `GET /api/auth/profile` - Profil utilisateur
- `GET /api/admin/stats` - Statistiques dashboard
- `GET /api/admin/users` - Liste utilisateurs
- `GET /api/admin/contracts` - Liste contrats
- `GET /api/admin/subscriptions` - Liste souscriptions
- `GET /api/admin/commissions` - Liste commissions

## 🎯 Prochaines Étapes

1. ✅ Tester le dashboard avec des vraies données
2. ⏳ Implémenter les pages manquantes
3. ⏳ Ajouter des graphiques plus avancés
4. ⏳ Implémenter les actions CRUD complètes
5. ⏳ Ajouter des notifications en temps réel

## 📞 Support

Pour toute question ou problème, contactez l'équipe de développement.

## 📝 Notes Importantes

- Le dashboard utilise les **mêmes couleurs** que l'application mobile
- La **police Inter** est utilisée pour une meilleure lisibilité
- Les **graphiques sont interactifs** (Recharts)
- Le dashboard est **responsive** et s'adapte à toutes les tailles d'écran
- Les données sensibles ne sont **jamais exposées** dans le code frontend
