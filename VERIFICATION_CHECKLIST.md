# ✅ CHECKLIST DE VÉRIFICATION - SYSTÈME DE PAIEMENTS

## 🎯 Objectif
Vérifier que toutes les modifications sont en place avant de lancer le système.

---

## 📋 FICHIERS CRÉÉS/MODIFIÉS

### ✅ Base de données
- [ ] `update_contrats_table.sql` existe dans `d:\CORIS\app_coris\`
- [ ] Contient 7 nouvelles colonnes (next_payment_date, payment_status, etc.)
- [ ] Contient 2 fonctions SQL (calculate_next_payment_date, update_payment_status)
- [ ] Contient 2 triggers (update_payment_status_trigger, update_on_payment)
- [ ] Contient 2 vues (contrats_notification_needed, contrats_payment_stats)

### ✅ Backend - Services
- [ ] `services/notificationService.js` existe
- [ ] Contient `getContratsNeedingNotification()`
- [ ] Contient `sendPaymentReminder(contrat)`
- [ ] Contient `processAllNotifications()`
- [ ] Contient `markNotificationAsSent(contratId)`
- [ ] Contient `resetNotificationAfterPayment(contratId)`

### ✅ Backend - Routes
- [ ] `routes/notificationRoutes.js` modifié
- [ ] Route `POST /api/notifications/process-payment-reminders` ajoutée
- [ ] Route `GET /api/notifications/pending-payment-reminders` ajoutée

### ✅ Backend - Controllers
- [ ] `controllers/contratController.js` modifié
- [ ] Query SELECT enrichie avec colonnes de paiement
- [ ] Tri par statut (en_retard > echeance_proche > a_jour)
- [ ] Calcul de `jours_restants` dans le query

### ✅ Backend - Cron
- [ ] `cron/paymentReminders.js` créé
- [ ] Cron schedule configuré sur `'0 9 * * *'` (9h00)
- [ ] Timezone `Africa/Abidjan` configuré
- [ ] Fonction `runManual()` exportée pour tests

### ✅ Backend - Server
- [ ] `server.js` modifié
- [ ] Ligne `require('./cron/paymentReminders');` ajoutée après les routes

### ✅ Frontend - Models
- [ ] `lib/models/contrat.dart` modifié
- [ ] Propriétés ajoutées: nextPaymentDate, lastPaymentDate, paymentStatus, paymentMethod, totalPaid, joursRestants
- [ ] Méthodes helper ajoutées: isPaymentLate, isPaymentDueSoon, paymentStatusText, paymentStatusColor
- [ ] fromJson mis à jour pour parser les nouvelles propriétés
- [ ] toJson mis à jour pour sérialiser les nouvelles propriétés

### ✅ Frontend - Pages
- [ ] `lib/screens/mes_contrats_client_page.dart` modifié
- [ ] Fonction `_buildPaymentAlert()` ajoutée
- [ ] Calcul de `paiementsEnRetard` et `paiementsProches` ajouté
- [ ] Bannière d'alerte affichée en haut de la page
- [ ] Cartes enrichies avec section paiement (badge + date + jours)

### ✅ Documentation
- [ ] `PAYMENT_TRACKING_DEPLOYMENT.md` créé (guide complet)
- [ ] `QUICK_DEPLOY.md` créé (guide rapide 20 min)
- [ ] `PAYMENT_TRACKING_SUMMARY.md` créé (récapitulatif)

---

## 🧪 TESTS AVANT DÉPLOIEMENT

### Test 1: Fichiers présents

```powershell
# Vérifier les fichiers backend
Test-Path d:\CORIS\app_coris\mycoris-master\services\notificationService.js
Test-Path d:\CORIS\app_coris\mycoris-master\cron\paymentReminders.js

# Vérifier les fichiers frontend
Test-Path d:\CORIS\app_coris\mycorislife-master\lib\models\contrat.dart
Test-Path d:\CORIS\app_coris\mycorislife-master\lib\screens\mes_contrats_client_page.dart

# Vérifier la migration SQL
Test-Path d:\CORIS\app_coris\update_contrats_table.sql

# Vérifier la documentation
Test-Path d:\CORIS\app_coris\PAYMENT_TRACKING_DEPLOYMENT.md
Test-Path d:\CORIS\app_coris\QUICK_DEPLOY.md
Test-Path d:\CORIS\app_coris\PAYMENT_TRACKING_SUMMARY.md
```

**Résultat attendu:** Tous retournent `True`

### Test 2: Structure SQL

```powershell
# Compter les lignes dans le fichier SQL
(Get-Content d:\CORIS\app_coris\update_contrats_table.sql).Count
```

**Résultat attendu:** ~250 lignes

### Test 3: Service de notifications

```powershell
# Vérifier la présence des fonctions
Select-String -Path "d:\CORIS\app_coris\mycoris-master\services\notificationService.js" -Pattern "getContratsNeedingNotification|sendPaymentReminder|processAllNotifications|markNotificationAsSent"
```

**Résultat attendu:** 4 matches trouvés

### Test 4: Cron job

```powershell
# Vérifier la présence du cron
Select-String -Path "d:\CORIS\app_coris\mycoris-master\cron\paymentReminders.js" -Pattern "cron.schedule"
```

**Résultat attendu:** 1 match trouvé

### Test 5: Server.js

```powershell
# Vérifier l'ajout du cron dans server.js
Select-String -Path "d:\CORIS\app_coris\mycoris-master\server.js" -Pattern "paymentReminders"
```

**Résultat attendu:** 1 match trouvé

### Test 6: Modèle Flutter

```powershell
# Vérifier les nouvelles propriétés dans le modèle
Select-String -Path "d:\CORIS\app_coris\mycorislife-master\lib\models\contrat.dart" -Pattern "nextPaymentDate|paymentStatus|isPaymentLate"
```

**Résultat attendu:** 3+ matches trouvés

### Test 7: Page Flutter

```powershell
# Vérifier la bannière d'alerte
Select-String -Path "d:\CORIS\app_coris\mycorislife-master\lib\screens\mes_contrats_client_page.dart" -Pattern "_buildPaymentAlert"
```

**Résultat attendu:** 2+ matches trouvés

---

## 🚀 DÉPLOIEMENT ÉTAPE PAR ÉTAPE

### ÉTAPE 1: Backup (CRITIQUE)

```powershell
# Créer un backup de la base de données
cd d:\CORIS\app_coris\mycoris-master
$date = Get-Date -Format "yyyyMMdd_HHmmss"
psql -U postgres -d mycoris -c "\! pg_dump -U postgres mycoris > backup_$date.sql"
```

**Vérification:**
```powershell
# Vérifier que le backup existe
Test-Path "d:\CORIS\app_coris\mycoris-master\backup_*.sql"
```

### ÉTAPE 2: Migration base de données

```powershell
# Se connecter et exécuter la migration
psql -U postgres -d mycoris -f d:\CORIS\app_coris\update_contrats_table.sql
```

**Vérification:**
```sql
-- Dans psql, vérifier les colonnes
\d contrats

-- Vérifier les fonctions
\df calculate_next_payment_date
\df update_payment_status

-- Vérifier les vues
\dv contrats_notification_needed
\dv contrats_payment_stats
```

**Résultat attendu:**
- 7 nouvelles colonnes visibles
- 2 fonctions listées
- 2 vues listées

### ÉTAPE 3: Initialisation des données

```sql
-- Dans psql, initialiser les dates de paiement
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(
  COALESCE(dateeffet, NOW()), 
  periodicite
)
WHERE etat IN ('actif', 'en cours', 'EN COURS') 
  AND periodicite IS NOT NULL
  AND periodicite != '';

-- Vérifier
SELECT COUNT(*) as contrats_avec_date
FROM contrats 
WHERE next_payment_date IS NOT NULL;
```

**Résultat attendu:** Nombre > 0 (tous les contrats actifs avec périodicité)

### ÉTAPE 4: Installation dépendances backend

```powershell
cd d:\CORIS\app_coris\mycoris-master

# Installer node-cron
npm install node-cron

# Vérifier installation
npm list node-cron
```

**Résultat attendu:** `node-cron@3.0.x` installé

### ÉTAPE 5: Redémarrage backend

```powershell
cd d:\CORIS\app_coris\mycoris-master

# Arrêter le serveur actuel (Ctrl+C dans le terminal où il tourne)
# Ou forcer l'arrêt:
taskkill /F /IM node.exe

# Relancer
node server.js
```

**Vérification dans les logs:**
```
✅ Cron job "Rappels de paiement" démarré
   Schedule: Tous les jours à 9h00 (Africa/Abidjan)
   Prochaine exécution: [DATE]
```

### ÉTAPE 6: Rebuild Flutter

```powershell
cd d:\CORIS\app_coris\mycorislife-master

# Clean complet
flutter clean
flutter pub get

# Build (choisir un):
flutter run                           # Pour tester sur émulateur/device
flutter build apk --release           # Pour APK de production
flutter build apk --split-per-abi     # Pour APK optimisés
```

**Vérification:**
- Aucune erreur de compilation
- App se lance correctement

### ÉTAPE 7: Test UI Flutter

**Actions:**
1. Ouvrir l'application
2. Se connecter avec un compte client
3. Naviguer vers "Mes Contrats"

**Vérifications:**
- [ ] La page se charge sans erreur
- [ ] Les contrats s'affichent
- [ ] Chaque carte montre les nouvelles informations:
  - [ ] Badge de statut (🔴 🟠 🟢)
  - [ ] Prochaine date de paiement
  - [ ] Jours restants
  - [ ] Montant + périodicité
- [ ] Bannière d'alerte visible (si contrats en retard/à venir)

### ÉTAPE 8: Test API

```powershell
# Récupérer un token admin (remplacer par vos identifiants)
$response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method POST -ContentType "application/json" -Body '{"email":"admin@coris.ci","password":"admin123"}'
$token = $response.token

# Tester l'endpoint de contrats en attente
Invoke-RestMethod -Uri "http://localhost:5000/api/notifications/pending-payment-reminders" -Headers @{"Authorization"="Bearer $token"}
```

**Résultat attendu:**
```json
{
  "success": true,
  "count": 5,
  "data": [
    {
      "numepoli": "POL12345",
      "nom": "KOUASSI",
      "telephone1": "0799283976",
      "prime": 50000,
      "jours_restants": 3
    }
  ]
}
```

### ÉTAPE 9: Test cron manuel

```powershell
cd d:\CORIS\app_coris\mycoris-master

# Exécuter le job manuellement
node -e "require('./cron/paymentReminders').runManual()"
```

**Résultat attendu:**
```
🔧 Exécution manuelle du job de rappels...
Résultats: { total: 15, sent: 12, failed: 3, errors: [...] }
```

### ÉTAPE 10: Vérification base de données

```sql
-- Vérifier que les notifications ont été marquées comme envoyées
SELECT 
  numepoli,
  payment_status,
  notification_sent,
  last_notification_date
FROM contrats
WHERE notification_sent = true
ORDER BY last_notification_date DESC
LIMIT 10;
```

**Résultat attendu:** Liste des contrats avec `notification_sent = true`

---

## ⚙️ CONFIGURATION PRODUCTION

### SMS Provider (À faire avant premier envoi)

```powershell
# Éditer le fichier de notifications
notepad d:\CORIS\app_coris\mycoris-master\services\notificationService.js
```

**Remplacer lignes 12-40:**
- Option A: Orange SMS API (voir PAYMENT_TRACKING_DEPLOYMENT.md section 4)
- Option B: Twilio (voir documentation)

### Email Provider (Optionnel)

**Remplacer lignes 42-60:**
- Gmail SMTP (voir documentation)
- Office365 SMTP

---

## 🎯 VALIDATION FINALE

### Checklist complète

- [ ] **Base de données**
  - [ ] Backup créé
  - [ ] Migration exécutée sans erreur
  - [ ] 7 colonnes ajoutées à `contrats`
  - [ ] Dates initialisées pour contrats actifs
  - [ ] Fonctions SQL testées
  - [ ] Vues créées

- [ ] **Backend**
  - [ ] `node-cron` installé
  - [ ] `notificationService.js` présent et fonctionnel
  - [ ] `paymentReminders.js` présent
  - [ ] Cron job ajouté dans `server.js`
  - [ ] Serveur redémarré
  - [ ] Cron job démarre automatiquement (voir logs)
  - [ ] Routes API testées

- [ ] **Frontend**
  - [ ] Modèle `contrat.dart` enrichi
  - [ ] Page `mes_contrats_client_page.dart` modifiée
  - [ ] `flutter clean` + `flutter pub get` exécuté
  - [ ] App rebuilded
  - [ ] UI testée (bannière + badges)

- [ ] **Tests**
  - [ ] Test manuel du cron réussi
  - [ ] Endpoint API `/pending-payment-reminders` testé
  - [ ] Notifications marquées dans la base
  - [ ] Affichage correct dans l'app

- [ ] **Configuration**
  - [ ] SMS provider configuré (Orange/Twilio)
  - [ ] Email SMTP configuré (optionnel)
  - [ ] Credentials testés

- [ ] **Documentation**
  - [ ] `PAYMENT_TRACKING_DEPLOYMENT.md` lu
  - [ ] `QUICK_DEPLOY.md` consulté
  - [ ] `PAYMENT_TRACKING_SUMMARY.md` archivé

---

## 🚨 EN CAS DE PROBLÈME

### Problème: Migration SQL échoue

```powershell
# Restaurer le backup
psql -U postgres -d mycoris -f backup_[DATE].sql

# Vérifier les erreurs
cat d:\CORIS\app_coris\update_contrats_table.sql | psql -U postgres -d mycoris 2>&1 | Select-String "ERROR"
```

### Problème: Cron job ne démarre pas

```powershell
# Vérifier la présence dans server.js
Select-String -Path "d:\CORIS\app_coris\mycoris-master\server.js" -Pattern "paymentReminders"

# Si absent, ajouter manuellement:
# require('./cron/paymentReminders');
```

### Problème: UI ne montre pas les nouvelles données

```powershell
# Rebuild complet
cd d:\CORIS\app_coris\mycorislife-master
flutter clean
Remove-Item -Recurse -Force build
flutter pub get
flutter run
```

### Problème: API ne retourne pas les colonnes

```sql
-- Vérifier dans psql
\d contrats
-- Si colonnes absentes, refaire la migration
```

### Rollback complet

```powershell
# 1. Restaurer la base de données
psql -U postgres -d mycoris -c "DROP TABLE IF EXISTS contrats CASCADE"
psql -U postgres -d mycoris -f backup_[DATE].sql

# 2. Supprimer les fichiers créés
Remove-Item d:\CORIS\app_coris\mycoris-master\services\notificationService.js
Remove-Item d:\CORIS\app_coris\mycoris-master\cron\paymentReminders.js

# 3. Restaurer server.js (supprimer la ligne require paymentReminders)

# 4. Restaurer les fichiers Flutter originaux via Git
cd d:\CORIS\app_coris\mycorislife-master
git checkout lib/models/contrat.dart
git checkout lib/screens/mes_contrats_client_page.dart
```

---

## 📊 MÉTRIQUES DE SUCCÈS

### Immédiatement après déploiement

```sql
-- Vérifier le nombre de contrats avec date de paiement
SELECT 
  COUNT(*) FILTER (WHERE next_payment_date IS NOT NULL) as avec_date,
  COUNT(*) as total,
  (COUNT(*) FILTER (WHERE next_payment_date IS NOT NULL) * 100.0 / COUNT(*)) as pourcentage
FROM contrats
WHERE etat IN ('actif', 'en cours');
```

**Cible:** > 95% des contrats actifs ont une date

### Après 1 jour

```sql
-- Vérifier les notifications envoyées
SELECT 
  COUNT(*) FILTER (WHERE notification_sent = true) as notifs_envoyees,
  COUNT(*) as total_echeances_proches
FROM contrats
WHERE payment_status = 'echeance_proche';
```

**Cible:** > 90% des contrats à échéance proche ont reçu une notification

### Après 1 semaine

```sql
-- Statistiques globales
SELECT * FROM contrats_payment_stats;
```

**Vérifier:**
- Répartition correcte des statuts
- Notifications envoyées régulièrement
- Pas de spam (cooldown respecté)

---

## ✅ SYSTÈME OPÉRATIONNEL

Une fois toutes les étapes validées, le système est prêt.

**Résultat attendu:**
- ✅ Chaque matin à 9h00, le cron job s'exécute automatiquement
- ✅ Les clients avec paiement à venir (5 jours) reçoivent un SMS/Email
- ✅ L'application affiche les alertes visuelles
- ✅ Les contrats en retard sont mis en évidence
- ✅ Aucune perte de données existantes

**Monitoring continu:**
```powershell
# Vérifier les logs du serveur
Get-Content d:\CORIS\app_coris\mycoris-master\server.log -Tail 50 -Wait

# Rechercher les exécutions du cron
Select-String -Path "d:\CORIS\app_coris\mycoris-master\server.log" -Pattern "CRON: Démarrage"
```

---

**Date:** 12 Janvier 2026  
**Version:** 1.0.0  
**Status:** ✅ Prêt pour validation finale
