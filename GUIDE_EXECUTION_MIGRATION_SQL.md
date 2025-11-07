# 📋 Guide d'Exécution - Migration SQL Notifications

## ⚠️ IMPORTANT - À FAIRE EN PREMIER

Avant de tester l'application, tu dois **exécuter le script SQL** pour créer la table notifications.

## 🚀 Comment Exécuter la Migration

### Méthode 1: Depuis pgAdmin (Recommandé)

1. Ouvre **pgAdmin**
2. Connecte-toi à ta base de données PostgreSQL
3. Clique droit sur ta base de données → **Query Tool**
4. Copie tout le contenu du fichier `mycoris-master/migrations/create_notifications_table.sql`
5. Colle-le dans Query Tool
6. Clique sur **Execute** (ou F5)
7. Tu devrais voir : ✅ Table notifications créée avec succès

### Méthode 2: Depuis la Ligne de Commande

```bash
# Navigue vers le dossier migrations
cd D:\app_coris\mycoris-master\migrations

# Exécute le script SQL
psql -U postgres -d mycoris_db -f create_notifications_table.sql
```

**Remplace** :
- `postgres` par ton nom d'utilisateur PostgreSQL
- `mycoris_db` par le nom de ta base de données

## 📊 Ce que le Script Fait

1. ✅ Crée la table `notifications` avec :
   - `id` (clé primaire)
   - `user_id` (référence vers users)
   - `type` (contract, proposition, payment, reminder, info)
   - `title` (titre de la notification)
   - `message` (message)
   - `is_read` (lu ou non)
   - `created_at` et `updated_at` (dates)

2. ✅ Ajoute la colonne `photo_url` à la table `users` (pour les photos de profil)

3. ✅ Ajoute la colonne `pays` à la table `users`

4. ✅ Crée des index pour améliorer les performances

5. ✅ Insère une notification de bienvenue pour chaque utilisateur existant

## 🧪 Vérifier que Ça a Marché

Après l'exécution, tu peux vérifier avec ces requêtes :

```sql
-- Vérifier que la table existe
SELECT * FROM notifications LIMIT 5;

-- Vérifier le nombre de notifications
SELECT COUNT(*) FROM notifications;

-- Vérifier les colonnes ajoutées
SELECT photo_url, pays FROM users LIMIT 5;
```

## ✅ Confirmation

Si tout s'est bien passé, tu devrais voir :
- ✅ Une table `notifications` créée
- ✅ Une notification "Bienvenue sur MyCorisLife" pour chaque utilisateur
- ✅ Les colonnes `photo_url` et `pays` dans la table `users`

## 📱 Après la Migration

Une fois la migration exécutée, tu peux :
1. Relancer le serveur backend: `node server.js`
2. Relancer l'app Flutter
3. Te connecter avec ton téléphone (ex: 05 76 09 75 38 avec +225)
4. Cliquer sur l'icône 🔔 en haut à droite
5. Voir tes notifications !

---

**Important**: Ce script est **idempotent**, ce qui signifie que tu peux l'exécuter plusieurs fois sans problème. Il ne créera pas de doublons.














