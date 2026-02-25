# 🌊 GUIDE COMPLET - Configuration Wave Checkout avec Webhook

## 📋 Table des Matières
1. [Configuration Wave Dashboard](#configuration-wave-dashboard)
2. [Configuration Serveur](#configuration-serveur)
3. [Flux Complet Expliqué](#flux-complet-expliqué)
4. [Test du Webhook](#test-du-webhook)
5. [Dépannage](#dépannage)
6. [Checklist de Production](#checklist-de-production)

---

## 🔧 Configuration Wave Dashboard

### Étape 1: Obtenir les Clés API

**Processus:**
1. Aller à: https://dashboard.wave.com/settings/api-keys
2. Dans la section **API Credentials**, vous trouverez:
   - **API Key (Public Key)**: `sk_live_...` ou `sk_test_...`
   - **Secret Key**: `whsk_live_...` ou `whsk_test_...`
3. Copier ces deux clés et les coller dans votre `.env`:

```bash
WAVE_API_KEY=YOUR_WAVE_API_KEY_HERE
WAVE_WEBHOOK_SECRET=YOUR_WAVE_WEBHOOK_SECRET_HERE
```

### Étape 2: Configurer les URLs de Redirect

**Où:**
Dashboard Wave → Store Settings → Payment Methods → Wave Checkout

**À remplir:**

```
✅ Success URL:    https://185.98.138.168:5000/wave-success
✅ Error URL:      https://185.98.138.168:5000/wave-error
✅ Checkout URL:   https://185.98.138.168:5000/api/payment/wave/status
```

**Remarques importantes:**
- ⚠️ HTTPS **OBLIGATOIRE** (Wave ne supporte pas HTTP)
- Le serveur doit avoir un certificat HTTPS valide
- Ces URLs sont appelées par le serveur Wave, pas par l'utilisateur directement

### Étape 3: Configurer le Webhook

**Où:**
Dashboard Wave → Settings → Webhooks → Create New Webhook

**À remplir:**

| Champ | Valeur |
|-------|--------|
| **Webhook URL** | `https://185.98.138.168:5000/api/payment/wave/webhook` |
| **Header Name** | `X-Wave-Signature` |
| **Secret** | `whsk_live_xxxxxxxxxxxxxxxxxxxxx` (obtenir de l'API Settings) |
| **Content Type** | `application/json` |

**Événements à activer:**
```
✅ checkout.session.completed
✅ checkout.session.expired
✅ payment.succeeded
✅ payment.failed
✅ payment.refunded (optionnel)
```

**Résultat attendu:**
```json
{
  "id": "wh_live_xxxxx",
  "url": "https://185.98.138.168:5000/api/payment/wave/webhook",
  "events": ["checkout.session.completed", "payment.succeeded", ...],
  "active": true,
  "created_at": "2026-02-15T10:30:00Z"
}
```

---

## 📦 Configuration Serveur

### Variables d'Environnement Requises

Créer un fichier `.env` avec:

```bash
# ===== WAVE API =====
WAVE_API_KEY=YOUR_WAVE_API_KEY_HERE
WAVE_WEBHOOK_SECRET=YOUR_WAVE_WEBHOOK_SECRET_HERE
WAVE_DEV_MODE=false

# ===== URLS WAVE (HTTPS OBLIGATOIRE) =====
WAVE_SUCCESS_URL=https://185.98.138.168:5000/wave-success
WAVE_ERROR_URL=https://185.98.138.168:5000/wave-error
WAVE_WEBHOOK_URL=https://185.98.138.168:5000/api/payment/wave/webhook

# ===== BASE DE DONNÉES =====
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=yourpassword
DB_NAME=mycorisdb

# ===== CONFIGURATION =====
TEST_MODE_FORCE_10_XOF=false
NODE_ENV=production
PORT=5000
```

### Vérifier que les Routes Existent

**Fichier:** `routes/paymentRoutes.js`

Vérifier la présence de:

```javascript
// Routes à vérifier:
✅ router.post('/wave/create-session', ...)
✅ router.get('/wave/status/:sessionId', ...)  
✅ router.post('/confirm-wave-payment/:subscriptionId', ...)
✅ router.get('/wave-success', ...)
✅ router.get('/wave-error', ...)
✅ router.post('/wave/webhook', ...)  // ← NOUVELLE
```

Redémarrer le serveur:

```bash
npm restart
# ou
pm2 restart coris-api
```

---

## 🔄 Flux Complet Expliqué

### Scénario: L'utilisateur paie avec Wave

```
┌─────────────┐
│   CLIENT    │
│  (App)      │
└──────┬──────┘
       │ 1. Initier paiement
       ↓
┌─────────────────────────────────────┐
│   SERVEUR CORIS                     │
│   POST /api/payment/wave/create     │
│   - Crée session Wave               │
│   - Retourne checkout URL           │
└──────────────┬──────────────────────┘
       │ 2. Ouvrir URL dans browser
       ↓
┌─────────────────────────────────────┐
│   WAVE CHECKOUT API                 │
│   - Affiche formulaire paiement      │
│   - Utilisateur entre données       │
│   - Traite le paiement              │
└──────────────┬──────────────────────┘
       │ 3a. Succès → Redirection
       │ 3b. Erreur → Redirection
       ↓
┌──────────────────────────────────────┐
│   SERVEUR CORIS                      │
│   GET /wave-success?session_id=xxx   │
│   - Affiche page confirmation        │
│   - Ferme le browser                 │
└──────────────┬───────────────────────┘
       │ 4. Retour à l'app
       ↓
┌────────────────────────────────────────────┐
│   SERVEUR CORIS (Webhook)                  │
│   POST /api/payment/wave/webhook           │
│   - Wave envoie l'événement paiement       │
│   - Signature vérifiée (HMAC-SHA256)       │
│   - Mise à jour DB + SMS envoyé            │
└────────────────────────────────────────────┘
       │
       ↓
SUCCÈS: Proposition → Contrat ✅
        SMS envoyé ✅
        Client notifié ✅
```

### Timeline de l'événement Webhook

```
Temps 0:    Utilisateur clique "Payer"
              ↓
Temps 0-30s:  Wave traite le paiement
              ↓
Temps 30s:    Wave envoie webhook → http://185.98.138.168:5000/api/payment/wave/webhook
              - Header X-Wave-Signature: base64(HMAC-SHA256)
              - Body: { type: "payment.succeeded", data: {...} }
              ↓
Temps 30s:    Serveur reçoit webhook
              - Vérifie signature HMAC
              - Enregistre en base (payment_transactions)
              - Envoie SMS
              - Retourne 200 OK
              ↓
Temps 30s-2m: Polling client (fallback)
              - Appelle /wave/status toutes les 3 secondes
              - Détecte SUCCESS
              - Appelle /confirm-wave-payment
              - Affiche message de succès
```

---

## 🧪 Test du Webhook

### Test 1: Vérifier que le Webhook est Configuré

**Dans le Dashboard Wave:**

1. Aller à: Settings → Webhooks
2. Chercher votre webhook (URL: `https://185.98.138.168:5000/api/payment/wave/webhook`)
3. Cliquer sur "Test"
4. Envoyer un événement de test

**Résultat attendu:**

Le serveur reçoit et traite:

```json
{
  "type": "checkout.session.completed",
  "data": {
    "id": "cs_live_xxxxx",
    "status": "completed",
    "amount": 50000,
    "currency": "XOF",
    ...
  }
}
```

Vérifier les logs serveur:

```bash
tail -f logs/payment.log | grep -i webhook

# Sortie attendue:
# [2026-02-15 10:30:45] 🔔 WEBHOOK WAVE REÇU
# [2026-02-15 10:30:45]    Event type: payment.succeeded
# [2026-02-15 10:30:45] ✅ Signature valide
# [2026-02-15 10:30:45] 💳 Paiement réussi via webhook
# [2026-02-15 10:30:45] ✅ Transaction mise à jour en base
```

### Test 2: Simuler un Paiement Complet

**En développement (TEST_MODE_FORCE_10_XOF=true):**

1. Ouvrir l'app Flutter
2. Aller à Propositions → Sélectionner une proposition
3. Cliquer sur "Payer avec Wave"
4. Remplir le formulaire avec les données de test Wave
5. Soumettre

**Vérifications:**

- [ ] Page success/error s'affiche après quelques secondes
- [ ] La page affiche le montant et l'ID de session
- [ ] Bouton "Retourner à l'application" fonctionne
- [ ] L'app reçoit la notification (SMS ou message)
- [ ] La proposition est devenue un contrat `SELECT statut FROM subscriptions WHERE id=xxx;`
- [ ] Les logs webhook montrent la création et la confirmation

**Logs à vérifier:**

```bash
# Server logs
tail -f ~/app_coris/logs/payment.log

# Rechercher:
grep -i "wave_success\|webhook\|payment.succeeded" ~/app_coris/logs/payment.log

# DB verification
psql mycorisdb -U postgres << EOF
SELECT id, statut, produit_nom, montant, date_validation 
FROM subscriptions 
WHERE id = XXX;
EOF
```

### Test 3: Vérifier la Signature du Webhook

**Créer un script de test:**

```javascript
// test_webhook_signature.js
const crypto = require('crypto');

const secret = process.env.WAVE_WEBHOOK_SECRET;
const payload = JSON.stringify({
  type: "payment.succeeded",
  data: {
    id: "cs_test_xxxxx",
    status: "completed",
    amount: 50000,
    currency: "XOF"
  }
});

const signature = crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('base64');

console.log('Signature attendue:', signature);

// Envoyer avec curl:
// curl -X POST https://185.98.138.168:5000/api/payment/wave/webhook \
//   -H "X-Wave-Signature: $signature" \
//   -H "Content-Type: application/json" \
//   -d '$payload'
```

Exécuter:

```bash
node test_webhook_signature.js
# Résultat: Signature attendue: abc123xyz...

# Tester le webhook
curl -X POST https://185.98.138.168:5000/api/payment/wave/webhook \
  -H "X-Wave-Signature: abc123xyz..." \
  -H "Content-Type: application/json" \
  -d '{"type":"payment.succeeded","data":{"id":"cs_test_xxxxx","status":"completed","amount":50000,"currency":"XOF"}}'

# Résultat attendu:
# {"success":true,"message":"Événement traité"}
```

---

## 🔍 Dépannage

### Problème 1: Webhook reçu mais signature invalide

**Symptôme:**
```
❌ Signature invalide!
   Reçue: abc123xyz...
   Attendue: def456uvw...
```

**Causes possibles:**
- [ ] `WAVE_WEBHOOK_SECRET` incorrect dans `.env`
- [ ] Le secret a changé dans Wave Dashboard
- [ ] Le payload a été modifié en transit

**Solution:**
1. Aller à Wave Dashboard → Settings → Webhooks
2. Chercher ton webhook
3. Copier le secret exact (souvent caché, cliquer sur "Show")
4. Mettre à jour `.env`: `WAVE_WEBHOOK_SECRET=whsk_live_...`
5. Redémarrer: `npm restart`

### Problème 2: Page success/error ne s'affiche pas

**Symptôme:**
L'utilisateur clique "Payer", Wave traite, mais la page success ne s'affiche pas ou affiche erreur 404.

**Causes possibles:**
- [ ] Route `GET /wave-success` non présente dans `paymentRoutes.js`
- [ ] URL Wave mal configurée
- [ ] Certificat HTTPS invalide
- [ ] Port 5000 pas accessible depuis l'extérieur

**Solution:**
1. Vérifier les routes:
```bash
grep -n "router.get\('/wave-success" routes/paymentRoutes.js
# Résultat attendu: ligne 900+ (routes ajoutées)
```

2. Tester les URLs directement:
```bash
curl https://185.98.138.168:5000/wave-success?session_id=test
# Résultat attendu: Page HTML avec "Paiement Réussi"

curl https://185.98.138.168:5000/wave-error?session_id=test
# Résultat attendu: Page HTML avec "Paiement Échoué"
```

3. Vérifier les certificats HTTPS:
```bash
openssl s_client -connect 185.98.138.168:5000 -servername 185.98.138.168
# Vérifier que le certificat est valide et non expiré
```

### Problème 3: SMS non reçu après paiement

**Symptôme:**
Le paiement réussit mais pas de SMS trouvé.

**Causes possibles:**
- [ ] `sendSMS()` n'est pas appelé dans la route
- [ ] Identifiants MTN SMS incorrects
- [ ] Numéro de téléphone client vide en base

**Solution:**
1. Vérifier dans `paymentRoutes.js` ligne ~1100:
```javascript
// Doit y avoir:
await notificationService.sendSMS(...);
```

2. Vérifier les logs SMS:
```bash
grep -i "sms\|notification" ~/app_coris/logs/payment.log | tail -20
```

3. Vérifier le numéro client en base:
```bash
psql mycorisdb -U postgres << EOF
SELECT nom_prenom, telephone, email FROM subscriptions WHERE id = XXX;
EOF
```

### Problème 4: Proposition reste "proposition" après paiement

**Symptôme:**
Le paiement réussit, SMS reçu, mais `SELECT statut FROM subscriptions` montre toujours "proposition".

**Causes possibles:**
- [ ] Le webhook n'a pas été reçu
- [ ] L'erreur dans la mise à jour DB
- [ ] La route `/confirm-wave-payment` n'a pas été appelée

**Solution:**
1. Vérifier que le webhook a été reçu:
```bash
curl -s https://185.98.138.168:5000/api/payment/wave/status/SESSION_ID
# Si statut = "SUCCESS", le webhook devrait avoir mis à jour

SELECT statut, date_validation FROM subscriptions WHERE id=XXX;
```

2. Vérifier les logs:
```bash
tail -100 ~/app_coris/logs/payment.log | grep -i "confirm-wave-payment"
```

3. Appeler manuellement la route de confirmation:
```bash
curl -X POST https://185.98.138.168:5000/api/payment/confirm-wave-payment/SUBSCRIPTION_ID \
  -H "Content-Type: application/json"

# Résultat attendu:
# {"success":true,"message":"Paiement confirmé","statut":"contrat"}
```

### Problème 5: Certificat HTTPS expiré

**Symptôme:**
```
curl: (60) SSL certificate problem: certificate has expired
```

**Solution:**
1. Renouveler le certificat Let's Encrypt:
```bash
sudo certbot renew --force-renewal
# ou
sudo certbot certonly --standalone -d 185.98.138.168
```

2. Redémarrer le serveur:
```bash
systemctl restart nginx
# ou
pm2 restart coris-api
```

---

## ✅ Checklist de Production

### Avant le Lancement

- [ ] **WAVE_API_KEY configurée** → `sk_live_...` (pas `sk_test_...`)
- [ ] **WAVE_WEBHOOK_SECRET configurée** → `whsk_live_...`
- [ ] **TEST_MODE_FORCE_10_XOF = false** (pas forcer 10 XOF)
- [ ] **NODE_ENV = production**
- [ ] **Certificat HTTPS valide** et non expiré
- [ ] **URLs HTTPS configurées** dans Wave Dashboard
- [ ] **Webhook activé** dans Wave Dashboard
- [ ] **Routes existantes** dans `paymentRoutes.js`:
  - `/wave-success` ✅
  - `/wave-error` ✅
  - `/wave/webhook` ✅
- [ ] **SMS configuré** et testé
- [ ] **Logs activés** pour monitoring

### Pendant le Lancement

- [ ] Faire un **test de paiement réel** (montant minimal)
- [ ] Vérifier que l'**app reçoit la notification**
- [ ] Vérifier que la **proposition devient contrat**
- [ ] Vérifier que le **client reçoit son SMS**
- [ ] Vérifier les **logs webhook** pour chaque paiement

### Après le Lancement

- [ ] **Surveiller les logs** quotidiennement: `grep -i webhook ~/logs/payment.log`
- [ ] **Tester les webhooks** mensuellement
- [ ] **Archiver les certificats** (renouvellement automatique)
- [ ] **Mettre en place alertes** pour les paiements échoués
- [ ] **Documenter les erreurs** pour amélioration

---

## 📞 Support

**En cas de problème:**

1. Vérifier les logs serveur:
```bash
tail -100 ~/app_coris/logs/payment.log
```

2. Tester manuellement:
```bash
curl -X GET https://185.98.138.168:5000/wave-success?session_id=test
```

3. Contacter Wave Support:
   - Email: support@wave.com
   - Doc: https://docs.wave.com/checkout

4. Contacter admin serveur:
   - SSH: `ssh root@185.98.138.168`
   - Vérifier PM2: `pm2 logs coris-api`

---

**Dernière mise à jour:** 15 février 2026  
**Version:** 2.0 (Webhook complet)
