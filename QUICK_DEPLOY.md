# ⚡ DÉPLOIEMENT RAPIDE - SYSTÈME PAIEMENTS

## 🎯 ÉTAPES À SUIVRE

### 1️⃣ BASE DE DONNÉES (5 min)

```bash
# Se connecter à PostgreSQL
psql -U postgres -d mycoris

# Exécuter la migration
\i d:/CORIS/app_coris/update_contrats_table.sql

# Initialiser les dates pour contrats existants
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(COALESCE(dateeffet, NOW()), periodicite)
WHERE etat IN ('actif', 'en cours', 'EN COURS') AND periodicite IS NOT NULL;

# Vérifier
SELECT numepoli, next_payment_date, payment_status, (next_payment_date::date - CURRENT_DATE) as jours 
FROM contrats WHERE next_payment_date IS NOT NULL LIMIT 10;

\q
```

---

### 2️⃣ BACKEND (3 min)

```bash
cd d:\CORIS\app_coris\mycoris-master

# Installer node-cron
npm install node-cron

# Ajouter dans server.js (après les autres require):
# require('./cron/paymentReminders');

# Redémarrer
node server.js
```

**Vérifier dans les logs:**
```
✅ Cron job "Rappels de paiement" démarré
   Prochaine exécution: [date à 9h00]
```

---

### 3️⃣ FLUTTER (2 min)

```bash
cd d:\CORIS\app_coris\mycorislife-master

# Clean & rebuild
flutter clean
flutter pub get
flutter run
```

**Dans l'app:**
- Ouvrir "Mes Contrats"
- Vérifier bannière d'alerte (si paiements à venir)
- Vérifier badges de statut sur les cartes

---

### 4️⃣ CONFIGURATION SMS/EMAIL (10 min)

**Éditer:** `services/notificationService.js`

**Ligne 12-40 - Remplacer la fonction sendSMS:**

```javascript
// OPTION A: Orange SMS API
async function sendSMS(phoneNumber, message) {
  const axios = require('axios');
  
  // Authentification
  const authResponse = await axios.post(
    'https://api.orange.com/oauth/v3/token',
    'grant_type=client_credentials',
    {
      headers: {
        'Authorization': 'Basic ' + Buffer.from(
          'VOTRE_CLIENT_ID:VOTRE_CLIENT_SECRET'
        ).toString('base64'),
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );
  
  // Envoi SMS
  const smsResponse = await axios.post(
    'https://api.orange.com/smsmessaging/v1/outbound/tel%3A%2BVOTRE_NUMERO/requests',
    {
      outboundSMSMessageRequest: {
        address: `tel:+${phoneNumber}`,
        senderAddress: 'tel:+VOTRE_NUMERO',
        outboundSMSTextMessage: { message }
      }
    },
    {
      headers: {
        'Authorization': `Bearer ${authResponse.data.access_token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  return smsResponse.data;
}

// OPTION B: Twilio
async function sendSMS(phoneNumber, message) {
  const twilio = require('twilio');
  const client = twilio('ACCOUNT_SID', 'AUTH_TOKEN');
  
  return await client.messages.create({
    body: message,
    from: '+15017122661',
    to: `+${phoneNumber}`
  });
}
```

**Ligne 42-60 - Configuration Email:**

```javascript
const nodemailer = require('nodemailer');

async function sendEmail(email, subject, html) {
  const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
      user: 'notifications@coris.ci',
      pass: 'VOTRE_MOT_DE_PASSE_APP'
    }
  });
  
  return await transporter.sendMail({
    from: '"CORIS Assurances" <notifications@coris.ci>',
    to: email,
    subject: subject,
    html: html
  });
}
```

---

### 5️⃣ TEST MANUEL (2 min)

```bash
cd d:\CORIS\app_coris\mycoris-master

# Exécuter le job de notifications manuellement
node -e "require('./cron/paymentReminders').runManual()"
```

**Résultat attendu:**
```
🔧 Exécution manuelle du job de rappels...
Résultats: { 
  total: 15, 
  sent: 12, 
  failed: 3, 
  errors: [...] 
}
```

---

## ✅ VÉRIFICATION RAPIDE

### Base de données
```sql
SELECT COUNT(*) FROM contrats WHERE next_payment_date IS NOT NULL;
-- Doit retourner le nombre de contrats actifs

SELECT * FROM contrats_notification_needed;
-- Liste des contrats nécessitant une notification
```

### Backend
```bash
# Vérifier que le cron tourne
curl -X GET http://localhost:5000/api/notifications/pending-payment-reminders \
  -H "Authorization: Bearer VOTRE_TOKEN_ADMIN"
```

### Flutter
- Ouvrir l'app
- Aller dans "Mes Contrats"
- **Doit afficher:**
  - Bannière rouge/orange si paiements en retard/à venir
  - Badges colorés sur chaque carte
  - Prochaine date de paiement
  - Jours restants

---

## 🔥 COMMANDES UTILES

### Tester une notification pour un contrat spécifique

```bash
curl -X POST http://localhost:5000/api/notifications/send/123 \
  -H "Authorization: Bearer TOKEN_ADMIN"
```

### Voir les contrats en attente de paiement

```sql
SELECT numepoli, nom, telephone1, prime, payment_status, 
       next_payment_date::date - CURRENT_DATE as jours_restants
FROM contrats 
WHERE payment_status IN ('echeance_proche', 'en_retard')
ORDER BY next_payment_date;
```

### Réinitialiser les notifications (si spam)

```sql
UPDATE contrats 
SET notification_sent = false, 
    last_notification_date = NULL
WHERE payment_status = 'echeance_proche';
```

### Recalculer les dates de paiement

```sql
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(dateeffet, periodicite)
WHERE periodicite IS NOT NULL;
```

---

## 🚨 TROUBLESHOOTING

### ❌ Bannière ne s'affiche pas dans l'app

```bash
# Rebuild complet
cd d:\CORIS\app_coris\mycorislife-master
flutter clean
flutter pub get
flutter run
```

### ❌ Cron job ne démarre pas

Vérifier dans `server.js` :
```javascript
// Cette ligne doit être présente
require('./cron/paymentReminders');
```

Puis redémarrer:
```bash
node server.js
```

### ❌ SMS non envoyés

1. Vérifier credentials dans `services/notificationService.js`
2. Tester manuellement:
```bash
node -e "require('./services/notificationService').sendPaymentReminder({
  numepoli: 'TEST',
  telephone1: '0799283976',
  prime: 50000,
  jours_restants: 3
})"
```

### ❌ Dates de paiement NULL

```sql
-- Recalculer pour tous les contrats
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(
  COALESCE(dateeffet, NOW()), 
  periodicite
)
WHERE etat IN ('actif', 'en cours') AND periodicite IS NOT NULL;
```

---

## 📋 CHECKLIST FINALE

- [ ] Migration SQL exécutée
- [ ] Dates initialisées pour contrats existants
- [ ] `npm install node-cron` fait
- [ ] Cron job ajouté dans server.js
- [ ] Backend redémarré
- [ ] Flutter rebuild fait
- [ ] Alertes visibles dans l'app
- [ ] Credentials SMS/Email configurés
- [ ] Test manuel du job réussi
- [ ] Logs du cron vérifiés

---

## 📊 RÉSULTAT ATTENDU

### Dans l'application Flutter
- **Bannière rouge** si paiements en retard
- **Bannière orange** si paiements dans 5 jours
- **Badge 🔴** sur cartes en retard
- **Badge 🟠** sur cartes échéance proche
- **Badge 🟢** sur cartes à jour

### Dans la base de données
```
payment_status | count
---------------+-------
a_jour         |   250
echeance_proche|    15
en_retard      |     3
```

### Logs serveur (chaque matin à 9h00)
```
🔔 CRON: Démarrage envoi rappels de paiement
✅ Traitement terminé: 12/15 envoyées
```

---

## ⏰ PLANIFICATION AUTOMATIQUE

Le cron job s'exécute automatiquement **tous les jours à 9h00**.

Pour modifier l'horaire, éditer `cron/paymentReminders.js` ligne 21:

```javascript
// Chaque jour à 9h00
const paymentReminderJob = cron.schedule('0 9 * * *', async () => {

// Exemples d'autres horaires:
// '0 8 * * *'  => 8h00 tous les jours
// '0 */6 * * *' => Toutes les 6 heures
// '0 9 * * 1-5' => 9h00 du lundi au vendredi
```

---

**Temps total:** ~20 minutes  
**Complexité:** Moyenne  
**Impact:** Zéro perte de données ✅
