# 🔧 Correction de la Base de Données pour Wave Payment

## 📋 Problèmes Identifiés

Lors du test du paiement Wave, cette erreur s'est affichée :
```
❌ Erreur getUnreadCount: error: la colonne « user_id » n'existe pas
code: '42703' (column does not exist)
```

### Analyse Complète

Après inspection de la base de données et du code, **3 tables** ont des colonnes manquantes :

#### 1. ❌ Table `notifications`
**Colonne manquante :** `user_id`
- **Impact :** Erreur immédiate qui bloque toute l'application
- **Cause :** La table existe mais sans la colonne `user_id`
- **Solution :** Ajouter `user_id INTEGER NOT NULL REFERENCES users(id)`

#### 2. ❌ Table `payment_transactions`
**Colonnes manquantes :**
- `provider` : Pour distinguer Wave/CorisMoney/OrangeMoney
- `session_id` : Pour stocker l'ID de session Wave checkout
- `api_response` : Pour stocker les réponses brutes de l'API (peut exister sur certaines installations)

**Impact :** Le code Wave renvoie ces champs mais la table ne peut pas les stocker

#### 3. ❌ Table `subscriptions`
**Colonnes manquantes :**
- `payment_method` : Méthode de paiement utilisée
- `payment_transaction_id` : Référence vers la transaction

**Impact :** Impossible de lier une souscription à son paiement Wave

---

## 🚀 Solution : Migration Automatique

### Fichiers Créés

1. **`migrations/fix_wave_database_schema.sql`**
   - Script SQL qui ajoute toutes les colonnes manquantes
   - Vérifie l'existence avant d'ajouter (idempotent)
   - Crée les index nécessaires
   - Ajoute les commentaires de documentation

2. **`run_wave_migration.ps1`**
   - Script PowerShell pour exécuter la migration
   - Charge automatiquement les variables depuis `.env`
   - Demande confirmation avant exécution
   - Affiche des messages clairs sur le résultat

---

## 📝 Instructions d'Exécution

### Option 1 : Script PowerShell (Recommandé)

```powershell
# Depuis le dossier mycoris-master
cd d:\CORIS\app_coris\mycoris-master

# Exécuter le script
.\run_wave_migration.ps1
```

Le script va :
1. ✅ Charger votre configuration `.env`
2. ✅ Vérifier la connexion à la base de données
3. ✅ Demander confirmation
4. ✅ Exécuter la migration
5. ✅ Afficher le résultat

### Option 2 : Exécution Manuelle avec psql

```powershell
# Charger les variables d'environnement
$env:PGPASSWORD = "votre_mot_de_passe"

# Exécuter la migration
psql -h localhost -p 5432 -U postgres -d mycorisdb -f migrations\fix_wave_database_schema.sql

# Nettoyer
Remove-Item Env:PGPASSWORD
```

### Option 3 : Depuis pgAdmin ou autre client SQL

1. Ouvrir `migrations/fix_wave_database_schema.sql` dans votre éditeur SQL
2. Se connecter à votre base de données `mycorisdb`
3. Exécuter le script complet
4. Vérifier que tous les messages sont ✅

---

## ✅ Vérification Post-Migration

### 1. Vérifier les colonnes ajoutées

```sql
-- Vérifier notifications
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
  AND column_name = 'user_id';

-- Vérifier payment_transactions
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'payment_transactions' 
  AND column_name IN ('provider', 'session_id', 'api_response');

-- Vérifier subscriptions
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'subscriptions' 
  AND column_name IN ('payment_method', 'payment_transaction_id');
```

### 2. Redémarrer le serveur backend

```powershell
# Arrêter le serveur (Ctrl+C dans le terminal)
# Puis redémarrer
npm start
```

### 3. Tester un paiement Wave

1. Ouvrir l'application mobile
2. Aller dans une page de souscription (ex: Serenite)
3. Remplir le formulaire
4. Sélectionner **Wave** comme méthode de paiement
5. Cliquer sur **Payer**
6. Vérifier qu'aucune erreur ne s'affiche

---

## 📊 Récapitulatif des Changements

| Table | Colonne | Type | Description |
|-------|---------|------|-------------|
| `notifications` | `user_id` | INTEGER NOT NULL | Référence vers users(id) |
| `payment_transactions` | `provider` | VARCHAR(50) | Wave/CorisMoney/OrangeMoney |
| `payment_transactions` | `session_id` | VARCHAR(255) | ID session Wave checkout |
| `payment_transactions` | `api_response` | JSONB | Réponse API complète |
| `subscriptions` | `payment_method` | VARCHAR(50) | Méthode de paiement |
| `subscriptions` | `payment_transaction_id` | VARCHAR(100) | Référence transaction |

**Total : 6 colonnes ajoutées**

---

## 🔍 Diagnostic en Cas de Problème

### Erreur : "column user_id does not exist"
➡️ **Cause :** Migration non exécutée  
➡️ **Solution :** Exécuter `run_wave_migration.ps1`

### Erreur : "relation does not exist"
➡️ **Cause :** Table manquante complètement  
➡️ **Solution :** Vérifier que les tables existent avec :
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public';
```

### Erreur : "permission denied"
➡️ **Cause :** Droits insuffisants sur PostgreSQL  
➡️ **Solution :** Se connecter avec un utilisateur ayant des droits ALTER TABLE

### Migration déjà exécutée
➡️ Le script est **idempotent** : il vérifie l'existence avant d'ajouter  
➡️ Vous pouvez le ré-exécuter sans risque

---

## 📚 Fichiers de Référence

- **Migration SQL :** `migrations/fix_wave_database_schema.sql`
- **Script PowerShell :** `run_wave_migration.ps1`
- **Schéma attendu :** `Table_notifications.txt` (à la racine)
- **Documentation Wave :** `WAVE_QUICK_SETUP.md`

---

## 🎯 Prochaines Étapes

Après la migration :

1. ✅ **Tester Wave Payment** sur toutes les pages de souscription
2. ✅ **Configurer les URLs manquantes** dans `.env` :
   - `WAVE_WEBHOOK_SECRET` (depuis Wave Dashboard)
   - `WAVE_WEBHOOK_URL` (votre domaine + `/api/payment/wave/webhook`)
   - `WAVE_SUCCESS_URL` (page de succès après paiement)
   - `WAVE_ERROR_URL` (page d'erreur après échec)
3. ✅ **Tester le webhook** Wave en simulant un paiement réel
4. ✅ **Vérifier les logs** backend pour détecter toute erreur

---

## 🆘 Support

En cas de problème persistant :

1. Vérifier les logs du serveur backend (console Node.js)
2. Vérifier les logs PostgreSQL (`/var/log/postgresql/`)
3. Exécuter les requêtes de vérification ci-dessus
4. Vérifier que `.env` contient bien `WAVE_API_KEY` et `WAVE_DEV_MODE=false`

---

**Date de création :** $(Get-Date -Format "dd/MM/yyyy HH:mm")  
**Version :** 1.0
