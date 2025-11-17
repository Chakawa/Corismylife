# 🗄️ Guide - Base de Données Produits et Tarifs

## 📋 Vue d'ensemble

Ce système permet de gérer les produits d'assurance et leurs tarifs dans une base de données, avec synchronisation online/offline entre le backend PostgreSQL et l'application Flutter (SQLite).

## 🏗️ Architecture

- **Backend (PostgreSQL)** : Tables `produit` et `tarif_produit`
- **Frontend (SQLite)** : Mêmes tables pour le mode offline
- **Synchronisation** : Automatique quand connecté à Internet

## 📦 Installation

### 1. Exécuter la migration PostgreSQL

```powershell
cd D:\app_coris\mycoris-master
psql -U postgres -d mycoris_db -f migrations/create_produits_tarifs_tables.sql
```

**OU depuis pgAdmin** :
1. Ouvre pgAdmin
2. Connecte-toi à `mycoris_db`
3. Ouvre **Query Tool** (Ctrl+E)
4. Copie le contenu de `migrations/create_produits_tarifs_tables.sql`
5. Exécute (F5)

### 2. Charger les données initiales

Tu peux charger les données de deux façons :

#### Option A : Depuis l'application Flutter (recommandé)

L'application Flutter migrera automatiquement les données du code vers SQLite au premier démarrage. Si tu es connecté à Internet, elle synchronisera aussi avec PostgreSQL.

#### Option B : Via l'API (pour charger dans PostgreSQL)

```powershell
# Après avoir démarré le serveur backend
curl -X POST http://localhost:5000/api/produits \
  -H "Content-Type: application/json" \
  -d '{"libelle": "CORIS SÉRÉNITÉ"}'
```

## 📊 Structure des Tables

### Table `produit`
- `id` : Identifiant unique (auto-incrémenté)
- `libelle` : Nom du produit (ex: "CORIS SÉRÉNITÉ")
- `created_at` : Date de création
- `updated_at` : Date de dernière modification

### Table `tarif_produit`
- `id` : Identifiant unique
- `produit_id` : Référence au produit (foreign key)
- `duree_contrat` : Durée du contrat (en mois ou années selon le produit)
- `periodicite` : Périodicité ('mensuel', 'trimestriel', 'semestriel', 'annuel', 'unique')
- `prime` : Prime pour 1000 ou montant selon le produit
- `capital` : Capital garanti (optionnel)
- `age` : Âge de l'assuré
- `categorie` : Catégorie optionnelle pour classer les tarifs
- `created_at` : Date de création
- `updated_at` : Date de dernière modification

## 🔄 Utilisation dans le Code

### Dans Flutter

```dart
import 'package:mycorislife/services/produit_sync_service.dart';

final syncService = ProduitSyncService();

// Obtenir un tarif (fonctionne online et offline)
final tarif = await syncService.getTarif(
  produitLibelle: 'CORIS SÉRÉNITÉ',
  age: 25,
  dureeContrat: 60, // 60 mois = 5 ans
  periodicite: 'annuel',
);

if (tarif != null) {
  final prime = tarif.prime;
  // Utiliser la prime pour le calcul
}
```

### Synchronisation manuelle

```dart
// Synchroniser avec l'API (si connecté à Internet)
await syncService.syncProduits();
```

## 📝 Notes Importantes

1. **Mode Offline** : Les données sont stockées localement dans SQLite, donc la simulation fonctionne même sans Internet
2. **Mode Online** : Si connecté, l'app synchronise automatiquement avec PostgreSQL
3. **Migration automatique** : Au premier lancement, les données du code sont migrées vers SQLite
4. **Performance** : Les index sont créés automatiquement pour optimiser les recherches

## 🔍 Exemples de Requêtes

### Rechercher tous les tarifs d'un produit
```dart
final tarifs = await syncService.getTarifs(
  produitLibelle: 'CORIS SÉRÉNITÉ',
);
```

### Rechercher avec filtres
```dart
final tarifs = await syncService.getTarifs(
  produitLibelle: 'CORIS SÉRÉNITÉ',
  age: 30,
  dureeContrat: 120, // 10 ans en mois
  periodicite: 'annuel',
);
```

## ⚠️ Dépannage

### Les données ne s'affichent pas
1. Vérifie que la migration SQL a été exécutée
2. Vérifie que les données ont été chargées (voir dans pgAdmin)
3. Vérifie la connexion Internet pour la synchronisation

### Erreur de synchronisation
1. Vérifie que le backend est démarré
2. Vérifie l'URL dans `app_config.dart`
3. Vérifie les logs du serveur backend














