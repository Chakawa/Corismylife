# 📋 Instructions pour Charger les Données de Simulation

## 🎯 Objectif

Charger toutes les données de simulation depuis le code vers la base de données PostgreSQL, afin que l'application puisse :
- ✅ Utiliser les données de la DB quand l'utilisateur est **en ligne**
- ✅ Utiliser les données du code quand l'utilisateur est **hors ligne**

## 🚀 Étape 1 : Exécuter le Script de Migration

Le script va charger automatiquement toutes les données de **CORIS SÉRÉNITÉ** :

```powershell
cd D:\app_coris\mycoris-master
node scripts/migrate_produits_data.js
```

Tu devrais voir :
```
🚀 Démarrage de la migration des données produits...
✅ Produit CORIS SÉRÉNITÉ créé avec l'id: 1
✅ 832 tarifs CORIS SÉRÉNITÉ insérés avec succès
✅ Migration terminée avec succès !
```

## 📊 Étape 2 : Vérifier les Données

Depuis pgAdmin ou psql :

```sql
-- Vérifier les produits
SELECT * FROM produit;

-- Vérifier les tarifs CORIS SÉRÉNITÉ
SELECT COUNT(*) FROM tarif_produit WHERE produit_id = (SELECT id FROM produit WHERE libelle = 'CORIS SÉRÉNITÉ');

-- Voir quelques exemples
SELECT age, duree_contrat, prime FROM tarif_produit 
WHERE produit_id = (SELECT id FROM produit WHERE libelle = 'CORIS SÉRÉNITÉ')
ORDER BY age, duree_contrat
LIMIT 10;
```

## 🔄 Étape 3 : Synchronisation Automatique

Quand l'application Flutter démarre :
1. Si **connecté à Internet** → Synchronise avec PostgreSQL
2. Si **hors ligne** → Utilise les données SQLite locale ou le code

## ⚠️ Charger les Autres Produits

Pour charger les données des autres produits (FAMILIS, RETRAITE, SOLIDARITÉ, ÉTUDE), tu as 2 options :

### Option A : Via l'API (recommandé)

Tu peux créer des scripts similaires pour chaque produit, ou utiliser l'API directement.

### Option B : Depuis les Fichiers Excel

Si tu as les fichiers Excel, je peux créer un script pour les lire et charger les données automatiquement.

## 🧪 Tester le Système

1. **Démarrer le backend** : `npm start` dans `mycoris-master`
2. **Lancer l'app Flutter**
3. **Tester avec Internet** :
   - Faire une simulation → utilise les données de PostgreSQL
4. **Tester sans Internet** (mode avion) :
   - Faire une simulation → utilise les données du code (fallback)
   - L'app fonctionne toujours !

## 📝 Structure des Données

### CORIS SÉRÉNITÉ
- Structure : `Map<age, Map<duree_mois, prime>>`
- Exemple : Age 25, Durée 60 mois → Prime 54.802

### CORIS FAMILIS
- Taux unique : `Map<age, Map<duree_annees, taux>>`
- Taux annuel : `Map<age, Map<duree_annees, taux>>`
- Périodicité : 'unique' ou 'annuel'

### CORIS RETRAITE
- Structure : `Map<duree_annees, Map<periodicite, prime>>`
- Périodicité : 'mensuel', 'trimestriel', 'semestriel', 'annuel'

### CORIS SOLIDARITÉ
- Structure : `Map<capital, Map<periodicite, prime>>`
- Capital : 500000, 1000000, 1500000, 2000000

### CORIS ÉTUDE
- Structure : `Map<age_parent, Map<duree_mois, prime>>`
- Périodicité : 'mensuel'

## 🔧 Dépannage

### Les données ne sont pas chargées
```sql
-- Vider et recharger
DELETE FROM tarif_produit;
DELETE FROM produit;
-- Puis relancer le script
```

### Erreur de connexion
- Vérifie que PostgreSQL est démarré
- Vérifie les credentials dans `.env`

### L'app ne trouve pas les données
- Vérifie que la migration SQL a été exécutée
- Vérifie que le script de chargement a fonctionné
- Vérifie les logs de l'application



