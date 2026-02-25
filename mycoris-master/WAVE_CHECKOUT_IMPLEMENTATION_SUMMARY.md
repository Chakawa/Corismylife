# 🚀 WAVE CHECKOUT - IMPLÉMENTATION COMPLÈTE

## 📊 Résumé de l'Implémentation

Vous avez demandé une implémentation **complète du Wave Checkout** comme documenté par Wave.  
Voici exactement ce qui a été fait:

---

## ✅ Composants Implémentés

### 1. 📄 Pages de Redirection (Success/Error)

**Fichier:** `routes/paymentRoutes.js`

**Routes créées:**

#### GET `/wave-success` 
Affichée quand Wave redirige après un paiement réussi.

**Caractéristiques:**
```
✅ Page HTML moderne avec animation
✅ Affiche le montant payé
✅ Affiche l'ID de session Wave
✅ Compte à rebours: 5 secondes avant fermeture
✅ Bouton: "Retourner à l'application"
✅ Message: "SMS de confirmation a été envoyé"
✅ Support du protocole custom: coris://payment-success
```

**Exemple d'appel by Wave:**
```
GET https://185.98.138.168:5000/wave-success?session_id=cs_live_xxxxx&amount=50000&currency=XOF
```

#### GET `/wave-error`
Affichée quand Wave redirige après un paiement échoué.

**Caractéristiques:**
```
✅ Page HTML avec style d'erreur
✅ Affiche la raison de l'erreur
✅ Affiche le code d'erreur
✅ Bouton: "Retour à l'application"
✅ Support du protocole custom: coris://payment-error
```

**Exemple d'appel by Wave:**
```
GET https://185.98.138.168:5000/wave-error?session_id=cs_live_xxxxx&reason=insufficient_funds&error_code=INSUFFICIENT_FUNDS
```

### 2. 🔔 Webhook Handler

**Fichier:** `routes/paymentRoutes.js`

**Route créée:**

#### POST `/api/payment/wave/webhook`

Appelée par Wave **automatiquement** après chaque événement de paiement.

**Sécurité:**
```
✅ Signature HMAC-SHA256 obligatoire
✅ Vérification Header: X-Wave-Signature
✅ Secret: WAVE_WEBHOOK_SECRET
✅ Rejet si signature invalide (HTTP 403)
```

**Événements gérés:**

| Événement | Action |
|-----------|--------|
| `checkout.session.completed` | ✅ Marquer transaction SUCCESS, mettre à jour DB |
| `payment.succeeded` | ✅ Marquer transaction SUCCESS, mettre à jour DB |
| `checkout.session.expired` | ❌ Marquer transaction FAILED |
| `payment.failed` | ❌ Marquer transaction FAILED |

**Exemple de webhook reçu de Wave:**
```json
POST /api/payment/wave/webhook HTTP/1.1
Host: 185.98.138.168:5000
X-Wave-Signature: base64_encoded_hmac_signature
Content-Type: application/json

{
  "type": "payment.succeeded",
  "data": {
    "id": "cs_live_xxxxx",
    "status": "completed",
    "amount": 50000,
    "currency": "XOF",
    "client_reference": "SUB_123456"
  }
}
```

**Actions du serveur:**
```
1. Recevoir l'événement
2. Vérifier la signature HMAC
3. Mettre à jour payment_transactions en base
4. Envoyer SMS de confirmation
5. Retourner HTTP 200 OK
```

### 3. 🔄 Flux Complet

```
┌─ UTILISATEUR ────────────────────────────────────────────────────┐
│                                                                   │
│  1. Lance l'app Flutter → Navigue vers Proposition                │
│  2. Clique "Payer avec Wave"                                      │
│  ↓                                                                 │
├─ FRONTEND FLUTTER ───────────────────────────────────────────────┤
│                                                                   │
│  3. Lance WavePaymentHandler.startPayment()                        │
│     ├─ Appelle /api/payment/wave/create-session                   │
│     ├─ Récupère l'URL de paiement de Wave                         │
│     └─ Ouvre l'URL dans le browser: https://checkout.wave.com    │
│  ↓                                                                 │
├─ WAVE CHECKOUT ──────────────────────────────────────────────────┤
│                                                                   │
│  4. Affiche le formulaire de paiement                             │
│  5. L'utilisateur rentre ses données                              │
│  6. Traite le paiement (débit bancaire)                           │
│  ↓ (Succès ou Erreur)                                             │
├─ REDIRECTION ─────────────────────────────────────────────────────┤
│                                                                   │
│  7. Wave redirige vers:                                           │
│     - Succès → https://185.98.138.168:5000/wave-success?...       │
│     - Erreur → https://185.98.138.168:5000/wave-error?...         │
│  ↓                                                                 │
├─ SERVEUR CORIS (GET /wave-success ou /wave-error) ────────────────┤
│                                                                   │
│  8. Affiche la page HTML moderne de confirmation                  │
│  9. Page compte à rebours: 5 secondes                             │
│  10. Bouton "Retourner à l'application"                           │
│  ↓                                                                 │
├─ WEBHOOK (Asynchrone - en parallèle) ────────────────────────────┤
│                                                                   │
│  11. Wave envoie POST /api/payment/wave/webhook                   │
│      ├─ Signature vérifiée ✓                                      │
│      ├─ Mise à jour DB: payment_transactions                      │
│      ├─ Envoi SMS de confirmation                                │
│      └─ Retour: HTTP 200 OK                                       │
│  ↓                                                                 │
├─ FALLBACK POLLING (Flutter) ────────────────────────────────────┤
│                                                                   │
│  12. En parallèle, l'app tente:                                   │
│      ├─ Appel /api/payment/wave/status toutes les 3 sec           │
│      ├─ Max 40 tentatives (2 minutes)                             │
│      ├─ Si SUCCESS → Appelle /confirm-wave-payment                │
│      └─ Affiche message de succès                                 │
│  ↓                                                                 │
├─ FERMETURE ───────────────────────────────────────────────────────┤
│                                                                   │
│  13. Utilisateur clique "Retourner à l'application"               │
│  14. Browser ferme (ou utilise protocole custom coris://)         │
│  15. Retour à l'app Flutter                                       │
│  16. Proposition → Contrat (mise à jour en base)                  │
│  17. Client reçoit SMS de confirmation                            │
│  ↓                                                                 │
│  ✅ SUCCÈS COMPLET                                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Configuration Requise

### Variables d'Environnement

Ajouter à votre `.env`:

```bash
# ===== WAVE API CREDENTIALS =====
# Obtenir de: https://dashboard.wave.com/settings/api-keys
WAVE_API_KEY=YOUR_WAVE_API_KEY_HERE

# Obtenir de: https://dashboard.wave.com/settings/webhooks (Secret tab)
WAVE_WEBHOOK_SECRET=YOUR_WAVE_WEBHOOK_SECRET_HERE

# ===== URLs WAVE CONFIGURATION =====
# À remplir dans Wave Dashboard → Store Settings → Payment Methods

# URL où Wave redirige après succès
WAVE_SUCCESS_URL=https://185.98.138.168:5000/wave-success

# URL où Wave redirige après erreur
WAVE_ERROR_URL=https://185.98.138.168:5000/wave-error

# URL du webhook (où Wave envoie les confirmations)
WAVE_WEBHOOK_URL=https://185.98.138.168:5000/api/payment/wave/webhook

# ===== MODE =====
WAVE_DEV_MODE=false
NODE_ENV=production
```

### Configuration dans Wave Dashboard

**1. Ajouter les URLs de Redirection**

```
Dashboard Wave → Store Settings → Payment Methods → Wave Checkout
┌─────────────────────────────────────────────────────┐
│ Success URL:   https://185.98.138.168:5000/wave-success
│ Error URL:     https://185.98.138.168:5000/wave-error
│ [Save]                                              │
└─────────────────────────────────────────────────────┘
```

**2. Créer le Webhook**

```
Dashboard Wave → Settings → Webhooks → Create New Webhook
┌──────────────────────────────────────────────────────────┐
│ Webhook URL:      https://185.98.138.168:5000/api/payment/wave/webhook
│ Header Name:      X-Wave-Signature
│ Secret:           whsk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
│ Content Type:     application/json
│                                                           │
│ Events to Enable:                                        │
│ ☑ checkout.session.completed                            │
│ ☑ checkout.session.expired                              │
│ ☑ payment.succeeded                                     │
│ ☑ payment.failed                                        │
│ [Create]                                                │
└──────────────────────────────────────────────────────────┘
```

**3. Test du Webhook**

```
Dans la section Webhooks, cliquer sur "Test":
- Envoyer un événement de test
- Vérifier les logs du serveur:
  tail -f ~/logs/payment.log | grep -i webhook
- Résultat attendu: ✅ Signature valide
```

---

## 🧪 Tests

### Test 1: Vérifier les Routes Sont Présentes

```bash
curl -s https://185.98.138.168:5000/wave-success \
  -I | head -5

# Résultat attendu:
# HTTP/1.1 200 OK
# Content-Type: text/html
```

### Test 2: Simuler un Webhook

```bash
#!/bin/bash

# Générer la signature HMAC
SECRET="whsk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
PAYLOAD='{"type":"payment.succeeded","data":{"id":"cs_test_123","status":"completed","amount":50000,"currency":"XOF"}}'

SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)

# Envoyer le webhook
curl -X POST https://185.98.138.168:5000/api/payment/wave/webhook \
  -H "X-Wave-Signature: $SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

# Résultat attendu:
# {"success":true,"message":"Événement traité","sessionId":"cs_test_123"}
```

### Test 3: Simuler un Paiement Complet

**En dev (TEST_MODE_FORCE_10_XOF=true):**

1. Ouvrir l'app Flutter
2. Aller à Propositions
3. Cliquer "Payer avec Wave"
4. Page success/error apparaît après quelques secondes ✓
5. Vérifier DB: `SELECT statut FROM subscriptions WHERE id=XXX;` → "contrat" ✓
6. Vérifier SMS reçu ✓

---

## 📈 Architecture Finale

```
┌────────────────────────────────────────────────────────────┐
│                     WAVE CHECKOUT FLOW                      │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  Frontend (Flutter)           Backend (Node.js)             │
│  ═══════════════════════════════════════════════════════   │
│                                                              │
│  1. initiate payment    ──→  POST /create-session          │
│                         ←──  { checkoutUrl: "..." }        │
│                                                              │
│  2. open URL                                                │
│     (Wave Checkout)     ←──  Wave API processes payment    │
│                                                              │
│  3. Wave redirects      ──→  GET /wave-success (or error)  │
│                         ←──  HTML page with countdown      │
│                                                              │
│  4. click return        ──→  Close browser                  │
│                                                              │
│  5. [parallel] poll     ──→  GET /wave/status              │
│     status (fallback)   ←──  { status: "SUCCESS" }         │
│                         ──→  POST /confirm-wave-payment    │
│                         ←──  { statut: "contrat" }          │
│                                                              │
│  ========== WEBHOOK (Async) ===============                │
│  Wave → POST /wave/webhook                                 │
│         + X-Wave-Signature header                          │
│         + Verify HMAC-SHA256                               │
│         + Update DB + Send SMS                             │
│         ← HTTP 200 OK                                       │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

---

## 📋 Checklist Avant Production

### Step 1: Configuration
- [ ] Les variables `.env` sont définies (WAVE_API_KEY, WAVE_WEBHOOK_SECRET)
- [ ] TEST_MODE_FORCE_10_XOF = false (en production)
- [ ] NODE_ENV = production

### Step 2: Wave Dashboard
- [ ] URLs HTTPS configurées dans Wave Settings
- [ ] Webhook créé et activé
- [ ] Secret du webhook copié dans `.env`

### Step 3: Code
- [ ] Routes `/wave-success`, `/wave-error`, `/api/payment/wave/webhook` présentes
- [ ] Redémarrage du serveur: `npm restart`

### Step 4: Tests
- [ ] Test avec paiement réel (montant minimum)
- [ ] Vérifier page success s'affiche ✓
- [ ] Vérifier SMS reçu ✓
- [ ] Vérifier BD: proposition → contrat ✓
- [ ] Vérifier logs webhook: `grep "webhook" logs/payment.log` ✓

---

## 🎯 Résultats Attendus

Après implémentation complète:

```
Client paie                 ↓
Page success s'affiche      ✓ (3-5 secondes)
Compte à rebours            ✓ (5 secondes)
Bouton retour fonctionne    ✓ (ferme browser)
App reprend                 ✓ (polling ou webhook)
Proposition → Contrat       ✓ (DB mise à jour)
SMS reçu                    ✓ (confirmation envoyée)
Webhook reçu                ✓ (logs montrent succès)
```

---

## 📚 Fichiers Créés/Modifiés

| Fichier | Action | Contenu |
|---------|--------|---------|
| `routes/paymentRoutes.js` | Modifié | +3 routes (success, error, webhook) |
| `.env.wave.example` | Créé | Variables de config commentées |
| `GUIDE_WAVE_WEBHOOK_CONFIG.md` | Créé | Guide détaillé de configuration |
| Ce fichier | Créé | Résumé de l'implémentation |

---

## 🚀 Prochaines Étapes

1. **Mettre à jour le `.env`:**
   ```bash
   cp .env.wave.example variables_values.txt
   # Remplir avec vos vraies valeurs Wave
   cat variables_values.txt >> .env
   ```

2. **Redémarrer le serveur:**
   ```bash
   npm restart
   # ou pm2 restart coris-api
   ```

3. **Tester le flux complet:**
   ```bash
   # Ouvrir l'app, naviguer à Proposition, payer avec Wave
   # Vérifier: page success → SMS → BD
   ```

4. **Surveiller les logs:**
   ```bash
   tail -f logs/payment.log | grep -i "webhook\|wave\|payment"
   ```

---

## 🔗 Ressources

- Wave Checkout Docs: https://docs.wave.com/checkout
- Wave Dashboard: https://dashboard.wave.com
- API Reference: https://docs.wave.com/api-reference
- Webhook Safe: https://docs.wave.com/webhooks-security

---

**Documentation créée:** 15 février 2026  
**Version mise à jour:** 2.0 (Webhook complet + Pages success/error)  
**Support:** Contacter admin@corisassurance.ci pour aide
