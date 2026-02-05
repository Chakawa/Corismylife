# 🔔 NOTIFICATIONS DE RAPPEL DE PAIEMENT - MISE À JOUR

## Date de mise à jour
**5 Février 2026**

---

## 🎯 FONCTIONNEMENT DES NOTIFICATIONS

### Pour le CLIENT (pas l'admin)

Le client reçoit **deux types de notifications** 5 jours avant l'échéance de paiement:

#### 1. 📱 SMS (via API SMS CI)
- Envoyé au numéro de téléphone enregistré sur le contrat
- API utilisée: https://apis.letexto.com/v1/messages/send
- Même configuration que pour les OTP et autres SMS du système
- Expéditeur: **CORIS ASSUR**

**Exemple de message SMS:**
```
CORIS: Rappel de paiement - 50 000 FCFA à régler dans 5 jour(s) pour votre contrat POL12345. Payez via CorisMoney.
```

#### 2. 📲 Notification in-app
- Enregistrée dans la table `notifications` de la base de données
- Le client verra la notification quand il ouvrira l'application
- Affichée dans la section **"Notifications"** de l'app
- Badge de notification visible

**Structure de la notification:**
- **Titre:** 💰 Rappel de paiement
- **Message:** Votre paiement de 50 000 FCFA pour le contrat POL12345 est dû dans 5 jour(s). Échéance: 10/02/2026.
- **Type:** payment_reminder
- **État:** Non lu par défaut

---

## 🔧 IMPLÉMENTATION TECHNIQUE

### Service de notification (notificationService.js)

**Configuration SMS:**
```javascript
const SMS_API_URL = 'https://apis.letexto.com/v1/messages/send';
const SMS_API_TOKEN = 'fa09e6cef91f77c4b7d8e2c067f1b22c'; // Production
const SMS_SENDER = 'CORIS ASSUR';
```

**Fonction sendSMS:**
- Utilise la même API que authRoutes.js (OTP, password reset, etc.)
- Format du numéro: avec indicatif complet (ex: 2250799283976)
- Logs détaillés pour débogage

**Fonction createInAppNotification:**
- Insère dans la table `notifications`
- Colonnes: user_id, type, title, message, is_read, created_at
- Type: 'payment_reminder'

### Processus complet

```javascript
async sendPaymentReminder(contrat) {
  // 1. Envoyer SMS au téléphone du contrat
  const smsResult = await sendSMS(contrat.telephone1, message);
  
  // 2. Créer notification in-app (si user trouvé)
  if (contrat.user_id) {
    await createInAppNotification(contrat.user_id, contrat);
  }
  
  // 3. Retourner résultat (succès si au moins un canal fonctionne)
  return { success: smsSuccess || notifSuccess };
}
```

---

## 📊 REQUÊTE SQL

La requête pour récupérer les contrats à notifier fait un **JOIN avec la table users**:

```sql
SELECT 
  c.id,
  c.numepoli,
  c.nom_prenom,
  c.telephone1,
  c.prime,
  c.next_payment_date,
  c.jours_restants,
  u.id as user_id,  -- IMPORTANT: pour créer la notification in-app
  u.email
FROM contrats c
LEFT JOIN users u ON (u.telephone = c.telephone1 OR u.telephone = c.telephone2)
WHERE c.payment_status IN ('echeance_proche', 'en_retard')
  AND c.notification_sent = false
```

**Points clés:**
- Le JOIN permet de récupérer le `user_id`
- Le `user_id` est nécessaire pour créer la notification in-app
- Si le client n'a pas de compte user, il reçoit quand même le SMS

---

## 🔄 FLUX COMPLET

### 1. Cron job s'exécute (9h00 chaque matin)
```
Exécution cron: paymentReminders.js
↓
Appel: notificationService.processAllNotifications()
```

### 2. Récupération des contrats
```
Query SQL avec JOIN users
↓
Liste des contrats avec payment_status = 'echeance_proche' ou 'en_retard'
↓
Filtrage: notification_sent = false OU last_notification_date > 2 jours
```

### 3. Pour chaque contrat
```
Envoi SMS via API SMS CI
  ↓
  ✅ SMS envoyé au client (ex: 0799283976)
  
Création notification in-app
  ↓
  ✅ INSERT dans table notifications (user_id = ID du client)
  
Marquage notification_sent = true
  ↓
  ✅ UPDATE contrat: notification_sent = true, last_notification_date = NOW()
```

### 4. Client se connecte à l'application
```
Ouverture de l'app
↓
Badge de notification visible (1 non lue)
↓
Client clique sur "Notifications"
↓
Affichage: "💰 Rappel de paiement - Votre paiement de 50 000 FCFA..."
↓
Client clique → notification marquée comme lue
```

---

## 📱 AFFICHAGE DANS L'APPLICATION

### Page "Mes Contrats"
- Bannière d'alerte en haut (si paiements à venir)
- Badge rouge/orange sur les cartes de contrats
- Prochaine date de paiement visible

### Page "Notifications"
- Liste de toutes les notifications
- Badge sur l'icône de notification (nombre de non lues)
- Notification de rappel de paiement avec type `payment_reminder`
- Clic sur notification → marque comme lue

---

## 🧪 TESTS

### Test 1: Vérifier la configuration SMS

```powershell
# Dans notificationService.js, vérifier:
Select-String -Path "d:\CORIS\app_coris\mycoris-master\services\notificationService.js" -Pattern "SMS_API_URL|SMS_API_TOKEN"
```

**Résultat attendu:**
```
const SMS_API_URL = 'https://apis.letexto.com/v1/messages/send';
const SMS_API_TOKEN = 'fa09e6cef91f77c4b7d8e2c067f1b22c';
```

### Test 2: Tester l'envoi manuel

```bash
cd d:\CORIS\app_coris\mycoris-master

# Exécuter le cron manuellement
node -e "require('./cron/paymentReminders').runManual()"
```

**Résultat attendu:**
```
=== 📱 ENVOI SMS RAPPEL PAIEMENT ===
📞 Destinataire: 2250799283976
📝 Message: CORIS: Rappel de paiement...
✅ SMS envoyé avec succès

📲 Création notification in-app pour user 123...
✅ Notification in-app créée
```

### Test 3: Vérifier la notification in-app

```sql
-- Vérifier les notifications créées
SELECT 
  n.id,
  n.user_id,
  n.type,
  n.title,
  n.message,
  n.is_read,
  n.created_at,
  u.nom,
  u.telephone
FROM notifications n
JOIN users u ON u.id = n.user_id
WHERE n.type = 'payment_reminder'
ORDER BY n.created_at DESC
LIMIT 10;
```

**Résultat attendu:**
```
| id  | user_id | type             | title                | is_read | created_at           |
|-----|---------|------------------|----------------------|---------|----------------------|
| 245 | 123     | payment_reminder | 💰 Rappel de paiement| false   | 2026-02-05 09:00:15  |
| 244 | 456     | payment_reminder | 💰 Rappel de paiement| false   | 2026-02-05 09:00:12  |
```

### Test 4: Vérifier dans l'application mobile

1. Ouvrir l'application
2. Se connecter avec un compte client ayant un contrat avec échéance proche
3. **Vérifier:**
   - Badge de notification visible (nombre)
   - Cliquer sur "Notifications"
   - Notification de rappel de paiement affichée
   - Cliquer dessus → marquée comme lue

---

## 📋 DIFFÉRENCES AVEC LA VERSION PRÉCÉDENTE

| Aspect | Avant (12 Jan) | Maintenant (5 Fév) |
|--------|----------------|---------------------|
| **Destinataire** | Admin | **Client** |
| **SMS API** | À configurer (Orange API) | **API SMS CI existante** |
| **Notification in-app** | ❌ Non | **✅ Oui** (table notifications) |
| **Configuration** | Manuelle nécessaire | **Déjà configurée** |
| **Code SMS** | Commenté (TODO) | **Implémenté** avec API réelle |

---

## ✅ AVANTAGES

1. **Réutilisation du code existant**
   - Même API SMS que pour les OTP
   - Pas de nouvelle configuration à faire
   - Token déjà validé en production

2. **Double canal de notification**
   - SMS: Le client reçoit même sans connexion internet
   - In-app: Historique consultable dans l'application
   - Redondance: Si un canal échoue, l'autre fonctionne

3. **Expérience utilisateur optimale**
   - Client informé à temps (5 jours avant)
   - Notification persistante dans l'app
   - Badge visuel pour attirer l'attention

4. **Monitoring facile**
   - Logs détaillés dans la console serveur
   - Statistiques dans la table notifications
   - Traçabilité complète (SMS + in-app)

---

## 🔧 MAINTENANCE

### Logs à surveiller

```bash
# Logs du cron job
[9h00:00] 🔔 CRON: Démarrage envoi rappels de paiement
[9h00:02] === 📱 ENVOI SMS RAPPEL PAIEMENT ===
[9h00:03] ✅ SMS envoyé avec succès
[9h00:04] 📲 Création notification in-app pour user 123
[9h00:04] ✅ Notification in-app créée
[9h00:10] ✅ Traitement terminé: 12/15 envoyées
```

### Statistiques

```sql
-- Taux de succès des notifications
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_notifications,
  COUNT(*) FILTER (WHERE is_read = true) as lues,
  (COUNT(*) FILTER (WHERE is_read = true) * 100.0 / COUNT(*)) as taux_lecture
FROM notifications
WHERE type = 'payment_reminder'
  AND created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## 🚀 DÉPLOIEMENT

### Aucune modification nécessaire !

Le système utilise déjà:
- ✅ API SMS CI configurée (token en production)
- ✅ Table `notifications` existante
- ✅ Routes de notifications existantes

**Il suffit de:**
1. Redémarrer le serveur backend
2. Le cron job utilisera automatiquement la bonne API

```bash
cd d:\CORIS\app_coris\mycoris-master
node server.js
```

**Vérification:**
```
✅ Cron job "Rappels de paiement" démarré
   Schedule: Tous les jours à 9h00 (Africa/Abidjan)
```

---

## 📞 EXEMPLES DE MESSAGES

### SMS pour échéance proche (J-5)
```
CORIS: Rappel de paiement - 50 000 FCFA à régler dans 5 jour(s) pour votre contrat POL12345. Payez via CorisMoney.
```

### SMS pour retard (J-2 de retard)
```
CORIS: Votre paiement de 50 000 FCFA pour le contrat POL12345 est en retard de 2 jours. Veuillez régulariser via CorisMoney.
```

### Notification in-app
**Titre:** 💰 Rappel de paiement  
**Message:** Votre paiement de 50 000 FCFA pour le contrat POL12345 est dû dans 5 jour(s). Échéance: 10/02/2026.

---

## ✅ RÉSUMÉ

**Ce qui a été modifié:**
1. `services/notificationService.js` - Utilise API SMS CI existante + crée notifications in-app
2. Requête SQL - JOIN avec users pour récupérer user_id
3. Double canal: SMS + in-app pour le client

**Ce qui n'a PAS changé:**
- Structure de la base de données
- Interface Flutter (déjà prête)
- Cron job (même fonctionnement)
- Routes API

**Prêt pour production:** ✅  
**Configuration supplémentaire:** ❌ Aucune

---

**Date de finalisation:** 5 Février 2026  
**Status:** ✅ Production Ready avec API SMS réelle
