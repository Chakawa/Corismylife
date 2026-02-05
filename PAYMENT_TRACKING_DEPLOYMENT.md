# 🔔 SYSTÈME DE GESTION DES PAIEMENTS ET NOTIFICATIONS

## Vue d'ensemble

Ce guide documente l'intégration complète du système de suivi des paiements et de notifications pour les contrats CORIS.

### Fonctionnalités implémentées

✅ **Suivi des paiements** - Date de prochain paiement automatique  
✅ **Statuts intelligents** - Calcul automatique (à jour / échéance proche / en retard)  
✅ **Alertes visuelles** - Bannière et badges colorés dans l'interface  
✅ **Notifications automatiques** - SMS/Email 5 jours avant l'échéance  
✅ **Intégration complète** - Aucune donnée perdue, système additif  

---

## 📋 ÉTAPE 1: Migration de la base de données

### Exécution du script

```bash
# Se connecter à PostgreSQL
psql -U postgres -d mycoris

# Exécuter le script de migration
\i d:/CORIS/app_coris/update_contrats_table.sql

# Vérifier les colonnes ajoutées
\d contrats
```

### Colonnes ajoutées

| Colonne | Type | Description |
|---------|------|-------------|
| `next_payment_date` | TIMESTAMP | Prochaine date de paiement |
| `last_payment_date` | TIMESTAMP | Dernière date de paiement effectué |
| `payment_status` | VARCHAR(50) | Statut: a_jour / echeance_proche / en_retard |
| `payment_method` | VARCHAR(50) | Méthode: CorisMoney / Orange Money / Wave |
| `total_paid` | DECIMAL | Montant total payé |
| `notification_sent` | BOOLEAN | Notification envoyée (true/false) |
| `last_notification_date` | TIMESTAMP | Date du dernier rappel |

### Initialisation des données existantes

```sql
-- Calculer la prochaine date de paiement pour tous les contrats actifs
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(
  COALESCE(dateeffet, NOW()), 
  periodicite
)
WHERE etat IN ('actif', 'en cours', 'EN COURS') 
  AND periodicite IS NOT NULL
  AND periodicite != '';

-- Vérifier les résultats
SELECT 
  numepoli, 
  etat, 
  periodicite, 
  dateeffet,
  next_payment_date,
  payment_status,
  CASE 
    WHEN next_payment_date IS NOT NULL 
    THEN next_payment_date::date - CURRENT_DATE 
  END as jours_restants
FROM contrats
WHERE next_payment_date IS NOT NULL
ORDER BY next_payment_date ASC
LIMIT 20;
```

---

## 📱 ÉTAPE 2: Mise à jour de l'application Flutter

### Fichiers modifiés

1. **`lib/models/contrat.dart`** - Modèle enrichi avec propriétés de paiement
2. **`lib/screens/mes_contrats_client_page.dart`** - Interface avec alertes

### Reconstruction de l'application

```bash
cd d:\CORIS\app_coris\mycorislife-master

# Clean build
flutter clean
flutter pub get

# Rebuild
flutter build apk --release
# OU pour debug:
flutter run
```

### Nouvelles fonctionnalités UI

#### Bannière d'alerte
- **Rouge**: Contrats en retard de paiement
- **Orange**: Paiements à venir dans 5 jours

#### Cartes de contrats enrichies
- Badge de statut coloré (🔴 En retard / 🟠 Échéance proche / 🟢 À jour)
- Affichage de la prochaine date de paiement
- Compteur de jours restants
- Montant et périodicité

---

## 🔧 ÉTAPE 3: Configuration backend

### Fichiers modifiés/créés

| Fichier | Type | Description |
|---------|------|-------------|
| `controllers/contratController.js` | MODIFIÉ | Query enrichie avec données paiement |
| `services/notificationService.js` | NOUVEAU | Logique d'envoi de rappels |
| `routes/notificationRoutes.js` | MODIFIÉ | Routes pour rappels de paiement |
| `cron/paymentReminders.js` | NOUVEAU | Cron job automatique |

### Installation des dépendances

```bash
cd d:\CORIS\app_coris\mycoris-master

# Installer node-cron pour les tâches planifiées
npm install node-cron
```

### Activation du cron job

Ajouter dans `server.js` (après les autres `require`):

```javascript
// ... autres imports ...

// Démarrer le cron job des rappels de paiement
require('./cron/paymentReminders');

// ... reste du code ...
```

### Redémarrage du serveur

```bash
# Arrêter le serveur actuel (Ctrl+C)
# Relancer
node server.js
```

Vous devriez voir:
```
✅ Cron job "Rappels de paiement" démarré
   Schedule: Tous les jours à 9h00 (Africa/Abidjan)
   Prochaine exécution: [date]
```

---

## 📧 ÉTAPE 4: Configuration SMS/Email

### Provider SMS recommandés (Côte d'Ivoire)

1. **Orange SMS API** (recommandé)
   - Site: https://developer.orange.com/
   - Créer un compte développeur
   - Obtenir Client ID + Client Secret

2. **Twilio** (international)
   - Site: https://www.twilio.com/
   - Bon pour tests et production
   - Tarifs compétitifs

### Configuration dans `notificationService.js`

```javascript
// Ligne 12-15 de services/notificationService.js

// OPTION 1: Orange SMS API
async function sendSMS(phoneNumber, message) {
  const axios = require('axios');
  
  // 1. Obtenir le token d'accès
  const authResponse = await axios.post(
    'https://api.orange.com/oauth/v3/token',
    'grant_type=client_credentials',
    {
      headers: {
        'Authorization': 'Basic ' + Buffer.from(
          'YOUR_CLIENT_ID:YOUR_CLIENT_SECRET'
        ).toString('base64'),
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );
  
  const accessToken = authResponse.data.access_token;
  
  // 2. Envoyer le SMS
  const smsResponse = await axios.post(
    'https://api.orange.com/smsmessaging/v1/outbound/tel%3A%2B2250000000000/requests',
    {
      outboundSMSMessageRequest: {
        address: `tel:+${phoneNumber}`,
        senderAddress: 'tel:+2250000000000', // Votre numéro Orange
        outboundSMSTextMessage: { message }
      }
    },
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  return smsResponse.data;
}

// OPTION 2: Twilio
async function sendSMS(phoneNumber, message) {
  const twilio = require('twilio');
  const client = twilio('ACCOUNT_SID', 'AUTH_TOKEN');
  
  const result = await client.messages.create({
    body: message,
    from: '+15017122661', // Votre numéro Twilio
    to: `+${phoneNumber}`
  });
  
  return result;
}
```

### Configuration Email

```javascript
// services/notificationService.js - ligne 42-56

const nodemailer = require('nodemailer');

async function sendEmail(email, subject, html) {
  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', // OU smtp.office365.com
    port: 587,
    secure: false,
    auth: {
      user: 'notifications@coris.ci',
      pass: 'VOTRE_MOT_DE_PASSE_APP' // Mot de passe d'application
    }
  });
  
  const info = await transporter.sendMail({
    from: '"CORIS Assurances" <notifications@coris.ci>',
    to: email,
    subject: subject,
    html: html
  });
  
  return info;
}
```

---

## 🧪 ÉTAPE 5: Tests

### Test 1: Exécution manuelle du cron

```bash
cd d:\CORIS\app_coris\mycoris-master

# Exécuter le job manuellement
node -e "require('./cron/paymentReminders').runManual()"
```

**Résultat attendu:**
```
🔧 Exécution manuelle du job de rappels...
Résultats: { total: 15, sent: 12, failed: 3, errors: [...] }
```

### Test 2: API - Liste des contrats nécessitant une notification

```bash
# GET /api/notifications/pending-payment-reminders
curl -X GET http://localhost:5000/api/notifications/pending-payment-reminders \
  -H "Authorization: Bearer VOTRE_TOKEN_ADMIN"
```

**Réponse attendue:**
```json
{
  "success": true,
  "count": 8,
  "data": [
    {
      "numepoli": "POL12345",
      "nom": "KOUASSI",
      "telephone1": "0799283976",
      "prime": 50000,
      "jours_restants": 3,
      "next_payment_date": "2026-01-20"
    }
  ]
}
```

### Test 3: UI Flutter

1. Ouvrir l'application
2. Naviguer vers "Mes Contrats"
3. **Vérifier:**
   - ✅ Bannière d'alerte si paiements à venir/en retard
   - ✅ Badges de statut sur les cartes
   - ✅ Dates de paiement affichées
   - ✅ Couleurs correctes (rouge/orange/vert)

### Test 4: Vérification base de données

```sql
-- Vérifier que les triggers fonctionnent
SELECT 
  numepoli,
  payment_status,
  next_payment_date,
  (next_payment_date::date - CURRENT_DATE) as jours_calcules,
  notification_sent,
  last_notification_date
FROM contrats
WHERE next_payment_date IS NOT NULL
ORDER BY next_payment_date ASC;

-- Vérifier les vues créées
SELECT * FROM contrats_notification_needed;
SELECT * FROM contrats_payment_stats;
```

---

## 🚀 ÉTAPE 6: Mise en production

### Checklist avant déploiement

- [ ] Migration SQL exécutée avec succès
- [ ] Données existantes initialisées (next_payment_date)
- [ ] Backend redémarré avec cron job actif
- [ ] Application Flutter reconstruite
- [ ] Credentials SMS/Email configurés
- [ ] Tests manuels réussis
- [ ] Monitoring des logs activé

### Configuration du cron en production

Si vous utilisez **pm2** pour gérer Node.js:

```bash
pm2 restart server
pm2 logs server --lines 100
```

Vérifier les logs du cron:
```
[9h00:00] 🔔 CRON: Démarrage envoi rappels de paiement
[9h00:02] ✅ Traitement terminé: 12/15 envoyées
```

### Monitoring

```sql
-- Dashboard admin - Stats de notifications
SELECT 
  COUNT(*) FILTER (WHERE notification_sent = true) as notifs_envoyees,
  COUNT(*) FILTER (WHERE payment_status = 'en_retard') as retards,
  COUNT(*) FILTER (WHERE payment_status = 'echeance_proche') as echeances_proches,
  AVG(prime) FILTER (WHERE payment_status = 'echeance_proche') as montant_moyen_echeance
FROM contrats
WHERE next_payment_date IS NOT NULL;
```

---

## 🔄 FLUX COMPLET

### 1. Création de contrat (après paiement CorisMoney)

```javascript
// Dans paymentRoutes.js - après vérification du paiement
const dateEffet = new Date();
const nextPaymentDate = calculateNextPaymentDate(dateEffet, periodicite);

await pool.query(`
  INSERT INTO contrats (
    numepoli, codeprod, nom, prime, periodicite, 
    dateeffet, next_payment_date, payment_method, 
    payment_status, total_paid
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'CorisMoney', 'a_jour', $4)
`, [numepoli, codeprod, nom, prime, periodicite, dateEffet, nextPaymentDate]);
```

### 2. Mise à jour automatique du statut (trigger)

```sql
-- Exécuté automatiquement chaque nuit à minuit
-- Ou lors de l'UPDATE du contrat
UPDATE contrats 
SET payment_status = CASE
  WHEN next_payment_date::date - CURRENT_DATE < 0 THEN 'en_retard'
  WHEN next_payment_date::date - CURRENT_DATE <= 5 THEN 'echeance_proche'
  ELSE 'a_jour'
END;
```

### 3. Envoi de notification (cron job - 9h00)

```javascript
// Chaque matin à 9h00
const contrats = await getContratsNeedingNotification();
// Filtre: payment_status = 'echeance_proche' 
//         AND (notification_sent = false OR last_notification_date < NOW() - 2 jours)

for (const contrat of contrats) {
  await sendPaymentReminder(contrat);
  // SMS: "CORIS: Rappel paiement - 50000 FCFA dans 3 jours (POL12345)"
  
  await markNotificationAsSent(contrat.id);
}
```

### 4. Affichage dans l'app (temps réel)

```dart
// mes_contrats_client_page.dart
Widget build(BuildContext context) {
  final paiementsEnRetard = contrats.where((c) => c.isPaymentLate).length;
  final paiementsProches = contrats.where((c) => c.isPaymentDueSoon).length;
  
  // Afficher bannière si nécessaire
  if (paiementsEnRetard > 0 || paiementsProches > 0) {
    return _buildPaymentAlert(paiementsEnRetard, paiementsProches);
  }
}
```

### 5. Après paiement

```javascript
// Réinitialiser après réception du paiement
await pool.query(`
  UPDATE contrats
  SET 
    next_payment_date = calculate_next_payment_date($1, periodicite),
    last_payment_date = NOW(),
    payment_status = 'a_jour',
    total_paid = total_paid + $2,
    notification_sent = false,
    last_notification_date = NULL
  WHERE numepoli = $3
`, [new Date(), montant, numepoli]);
```

---

## 🛠️ COMMANDES UTILES

### Base de données

```bash
# Backup avant migration
pg_dump -U postgres mycoris > backup_avant_migration.sql

# Restore si problème
psql -U postgres mycoris < backup_avant_migration.sql

# Vérifier les contrats avec paiement à venir
psql -U postgres -d mycoris -c "SELECT COUNT(*) FROM contrats WHERE payment_status = 'echeance_proche'"
```

### Backend

```bash
# Logs en temps réel
tail -f logs/server.log

# Test endpoint notification
curl -X POST http://localhost:5000/api/notifications/process-payment-reminders \
  -H "Authorization: Bearer TOKEN_ADMIN"

# Vérifier si le cron tourne
ps aux | grep node
```

### Flutter

```bash
# Hot reload en développement
flutter run

# Build release
flutter build apk --release --split-per-abi

# Installer sur device
flutter install
```

---

## ⚠️ TROUBLESHOOTING

### Problème: Notifications non envoyées

**Vérifier:**
```sql
SELECT * FROM contrats WHERE payment_status = 'echeance_proche' AND notification_sent = false;
```

**Solution:**
- Vérifier credentials SMS/Email dans `notificationService.js`
- Consulter les logs: `console.log` dans `sendPaymentReminder()`
- Tester manuellement: `node -e "require('./cron/paymentReminders').runManual()"`

### Problème: Dates de paiement incorrectes

**Vérifier la fonction:**
```sql
SELECT 
  dateeffet,
  periodicite,
  calculate_next_payment_date(dateeffet, periodicite) as calcule
FROM contrats LIMIT 5;
```

**Recalculer si nécessaire:**
```sql
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(dateeffet, periodicite)
WHERE next_payment_date IS NULL AND periodicite IS NOT NULL;
```

### Problème: UI ne montre pas les alertes

**Vérifier:**
1. Flutter rebuild: `flutter clean && flutter pub get && flutter run`
2. Vérifier que l'API retourne bien `payment_status`: 
   ```bash
   curl http://localhost:5000/api/contrats/mes-contrats -H "Authorization: Bearer TOKEN"
   ```
3. Console Flutter: Vérifier les erreurs de parsing JSON

---

## 📊 STATISTIQUES ET MONITORING

### Dashboard Admin (SQL)

```sql
-- Vue globale des paiements
SELECT 
  payment_status,
  COUNT(*) as nombre,
  SUM(prime) as montant_total,
  AVG(prime) as montant_moyen
FROM contrats
WHERE next_payment_date IS NOT NULL
GROUP BY payment_status;

-- Contrats par échéance
SELECT 
  DATE_TRUNC('day', next_payment_date) as date_echeance,
  COUNT(*) as nombre_contrats,
  SUM(prime) as montant_total
FROM contrats
WHERE payment_status IN ('echeance_proche', 'en_retard')
GROUP BY date_echeance
ORDER BY date_echeance;

-- Taux de notifications envoyées
SELECT 
  COUNT(*) FILTER (WHERE notification_sent = true) * 100.0 / COUNT(*) as taux_envoi
FROM contrats
WHERE payment_status = 'echeance_proche';
```

---

## 📝 RÉSUMÉ

### Ce qui a été ajouté

✅ **7 nouvelles colonnes** dans la table `contrats`  
✅ **2 fonctions SQL** pour calcul automatique  
✅ **2 triggers** pour mise à jour auto du statut  
✅ **2 vues** pour requêtes simplifiées  
✅ **1 service de notification** complet  
✅ **2 routes API** pour administration  
✅ **1 cron job** pour envoi automatique  
✅ **5 propriétés** ajoutées au modèle Dart  
✅ **4 méthodes helper** pour l'UI  
✅ **Bannière d'alerte** dans la page contrats  
✅ **Badges de statut** sur chaque carte  

### Ce qui est préservé

✅ **Toutes les données existantes** intactes  
✅ **Structure de table originale** inchangée  
✅ **Requêtes existantes** toujours fonctionnelles  
✅ **UI existante** améliorée (non remplacée)  
✅ **Routes API** backward compatible  

---

## 🎯 PROCHAINES ÉTAPES (OPTIONNEL)

1. **Page de détail du contrat** - Historique des paiements
2. **Statistiques Admin** - Dashboard avec graphiques
3. **Paiement in-app** - Bouton "Payer maintenant" depuis l'alerte
4. **Rappels multiples** - J-5, J-3, J-1, J+1
5. **WhatsApp Business** - Alternative au SMS
6. **Export Excel** - Liste des contrats en retard pour commercial

---

**Date de création:** 12 Janvier 2026  
**Version:** 1.0  
**Auteur:** GitHub Copilot  
**Testé sur:** PostgreSQL 13+ / Flutter 3.0+ / Node.js 16+
