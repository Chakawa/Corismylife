# Système de Tracking des Simulations - Documentation Complète

## 🎯 Résumé des Modifications

### 1. **Signature dans le PDF** ✅
- **Largeur**: 270px
- **Hauteur**: 75px  
- **Padding**: 3px (minimal pour masquer la bordure de capture)
- **Zone effective**: 264×69px
- La signature remplit maintenant parfaitement le cadre tout en cachant les bordures de la zone de capture

---

## 📊 Système de Tracking des Simulations

### 2. **Base de Données** ✅

#### Table créée: `simulations`
```sql
CREATE TABLE simulations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  produit_nom VARCHAR(100) NOT NULL,
  type_simulation VARCHAR(50) NOT NULL,
  age INT NULL,
  date_naissance DATE NULL,
  capital DECIMAL(15, 2) NULL,
  prime DECIMAL(15, 2) NULL,
  duree_mois INT NULL,
  periodicite VARCHAR(20) NULL,
  resultat_prime DECIMAL(15, 2) NULL,
  resultat_capital DECIMAL(15, 2) NULL,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Pour créer la table:**
```powershell
cd mycoris-master
.\create_simulations_table.ps1
```

Ou manuellement:
```bash
mysql -u root -p mycorisdb < migrations/create_simulations_table.sql
```

---

### 3. **API Backend** ✅

#### Nouveau Controller: `simulationController.js`

**Endpoints créés:**

1. **POST /api/simulations** - Enregistrer une simulation
   - Accessible avec ou sans authentification
   - Enregistre automatiquement l'IP et le user agent
   
2. **GET /api/simulations** - Récupérer toutes les simulations (Admin)
   - Filtres: produit, type_simulation, date_debut, date_fin
   - Pagination intégrée
   
3. **GET /api/simulations/stats** - Statistiques pour le dashboard
   - Total des simulations
   - Répartition par produit
   - Répartition par type
   - Évolution mensuelle et quotidienne
   - Statistiques des montants (capital moyen, max, min, etc.)
   
4. **GET /api/simulations/user** - Simulations de l'utilisateur connecté

#### Nouveau fichier: `routes/simulationRoutes.js`
Route ajoutée dans `server.js`

---

### 4. **Application Flutter** ✅

#### Nouveau Service: `SimulationService`
Fichier: `lib/features/simulation/domain/simulation_service.dart`

**Méthodes:**
- `saveSimulation()` - Enregistre une simulation (avec ou sans authentification)
- `getUserSimulations()` - Récupère les simulations de l'utilisateur

#### Écran modifié: `simulation_serenite_screen.dart`
- Import du `SimulationService`
- Ajout de la méthode `_saveSimulation()`
- Enregistrement automatique après chaque calcul (Par Capital ou Par Prime)

**Données enregistrées:**
- Produit (CORIS SERENITE, etc.)
- Type de simulation (Par Capital / Par Prime)
- Âge et date de naissance
- Capital ou Prime saisie
- Résultat calculé
- Durée et périodicité

---

### 5. **Dashboard Admin** ✅

#### Nouvelle Page: `SimulationsPage.jsx`

**Fonctionnalités:**

📈 **Statistiques principales:**
- Total des simulations
- Capital moyen
- Prime moyenne
- Capital maximum

🎨 **Graphiques interactifs:**
1. **Évolution mensuelle** (Ligne) - Simulations sur 12 mois
2. **Répartition par produit** (Camembert) - Distribution des produits
3. **Simulations par type** (Barres) - Par Capital vs Par Prime
4. **Évolution quotidienne** (Barres) - Activité des 30 derniers jours

🔍 **Filtres disponibles:**
- Date début / Date fin
- Produit (CORIS SERENITE, FAMILIS, ETUDE, etc.)
- Type de simulation

📋 **Liste détaillée:**
- Date de la simulation
- Produit
- Type
- Capital
- Prime
- Durée
- Nom du client (si connecté)

**Route ajoutée:** `/simulations`
**Navigation:** Ajoutée dans le menu latéral avec l'icône Calculator

---

## 🚀 Installation et Utilisation

### Étape 1: Créer la table dans la base de données

```powershell
cd D:\CORIS\app_coris\mycoris-master
.\create_simulations_table.ps1
```

### Étape 2: Redémarrer le serveur backend

```powershell
cd D:\CORIS\app_coris\mycoris-master
node server.js
```

### Étape 3: Redémarrer le dashboard admin

```powershell
cd D:\CORIS\app_coris\dashboard-admin
npm run dev
```

### Étape 4: Tester dans l'application Flutter

1. Lancez l'application Flutter
2. Allez dans une page de simulation (ex: CORIS SERENITE)
3. Remplissez les champs et cliquez sur "Calculer"
4. ✅ La simulation est automatiquement enregistrée en base de données

### Étape 5: Visualiser dans le dashboard admin

1. Connectez-vous au dashboard admin
2. Cliquez sur "Simulations" dans le menu
3. 📊 Visualisez les graphiques et les statistiques

---

## 📂 Fichiers Créés/Modifiés

### Backend
- ✨ `controllers/simulationController.js` (NOUVEAU)
- ✨ `routes/simulationRoutes.js` (NOUVEAU)
- ✨ `migrations/create_simulations_table.sql` (NOUVEAU)
- ✨ `create_simulations_table.ps1` (NOUVEAU)
- ✏️ `server.js` (Ajout route simulations)

### Frontend Flutter
- ✏️ `lib/features/simulation/domain/simulation_service.dart` (Service complet)
- ✏️ `lib/features/simulation/presentation/screens/simulation_serenite_screen.dart` (Ajout tracking)

### Dashboard Admin
- ✨ `src/pages/SimulationsPage.jsx` (NOUVEAU - Page complète avec graphiques)
- ✏️ `src/App.jsx` (Ajout route /simulations)
- ✏️ `src/components/layout/SidebarNav.jsx` (Ajout menu)

### PDF
- ✏️ `controllers/subscriptionController.js` (Optimisation signature)

---

## 🎨 Captures d'écran Attendues

### Dashboard Admin - Page Simulations
- 4 cartes de statistiques en haut
- 4 graphiques interactifs (Recharts)
- Filtres pour personnaliser la vue
- Tableau avec liste détaillée des simulations

### Application Flutter
- Aucun changement visible pour l'utilisateur
- Enregistrement silencieux en arrière-plan après chaque calcul

---

## 📝 Notes Importantes

1. **Authentification optionnelle**: Les simulations sont enregistrées même si l'utilisateur n'est pas connecté (champ `user_id` NULL)

2. **Tracking IP**: L'adresse IP est enregistrée pour analyser la provenance des simulations

3. **Tous les produits**: Le même système peut être appliqué aux autres produits:
   - CORIS FAMILIS
   - CORIS ETUDE
   - CORIS RETRAITE
   - CORIS SOLIDARITE
   - FLEX EMPRUNTEUR

4. **Performance**: L'enregistrement se fait de manière asynchrone et ne bloque pas l'UI

5. **Permissions**: Seuls les utilisateurs avec accès "stats" peuvent voir la page Simulations dans le dashboard

---

## 🔧 Prochaines Étapes (Optionnel)

- [ ] Appliquer le tracking aux autres écrans de simulation
- [ ] Ajouter un export Excel/PDF des statistiques
- [ ] Créer des alertes pour les simulations avec gros montants
- [ ] Intégrer un système de recommandations basé sur les simulations

---

## ✅ Résultat Final

Vous disposez maintenant d'un système complet de tracking des simulations avec:
- ✅ Enregistrement automatique dans la base de données
- ✅ API backend robuste avec statistiques
- ✅ Dashboard admin avec graphiques interactifs
- ✅ Signature optimisée dans les PDF (264×69px, bordure masquée)

**Tout est prêt et opérationnel !** 🚀
