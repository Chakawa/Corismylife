# CORIS - Tableau de Bord Admin

Dashboard d'administration pour la plateforme CORIS Assurance.

## 🚀 Technologies

- **React 18** - Library UI
- **Vite** - Build tool moderne et rapide
- **Tailwind CSS** - Framework CSS utilitaire
- **React Router** - Navigation
- **Recharts** - Graphiques et visualisations
- **Axios** - Requêtes HTTP
- **Lucide React** - Icônes modernes

## 📦 Installation

```bash
# Installer les dépendances
npm install

# Lancer le serveur de développement
npm run dev

# Build pour la production
npm run build
```

## 🎨 Design

Le dashboard utilise les couleurs officielles CORIS :
- **Bleu CORIS**: #002B6B
- **Rouge CORIS**: #E30613
- **Police**: Inter (Google Fonts)

## 🔧 Configuration

Créer un fichier `.env` à la racine :

```env
VITE_API_URL=http://localhost:5000/api
```

## 📁 Structure

```
src/
├── components/
│   └── layout/        # Composants de mise en page
├── pages/             # Pages de l'application
├── services/          # Services API
├── utils/             # Utilitaires
└── App.jsx            # Point d'entrée
```

## 🔐 Authentification

Seuls les utilisateurs avec le rôle `admin` peuvent accéder au dashboard.

## 📊 Fonctionnalités

- ✅ Vue d'ensemble avec statistiques et graphiques
- ✅ Gestion des utilisateurs (clients, commerciaux)
- ⏳ Gestion des contrats
- ⏳ Gestion des souscriptions
- ⏳ Gestion des commissions
- ⏳ Gestion des produits
- ⏳ Paramètres système

## 🌐 Ports

- Dashboard: http://localhost:3000
- API Backend: http://localhost:5000
