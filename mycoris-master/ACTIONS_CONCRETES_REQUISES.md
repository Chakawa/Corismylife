# ⚡ ACTIONS CONCRÈTES REQUISES

**Vous avez demandé:** Une implémentation complète du Wave Checkout avec success/error pages et webhook.

**C'est fait!** Voici exactement ce que vous devez faire maintenant:

---

## 🎯 ACTION 1: Configurer le .env

**Fichier:** `.env` (à la racine du projet)

**Ajouter ces variables:**

```bash
# ========== WAVE API CREDENTIALS ==========
# Obtenir de: https://dashboard.wave.com/settings/api-keys
WAVE_API_KEY=YOUR_WAVE_API_KEY_HERE

# Obtenir de: https://dashboard.wave.com/settings/webhooks 
# Cliquer sur "Show Secret"
WAVE_WEBHOOK_SECRET=YOUR_WAVE_WEBHOOK_SECRET_HERE

# ========== URLS DE REDIRECTION ==========
# Où Wave redirige après paiement réussi
WAVE_SUCCESS_URL=https://185.98.138.168:5000/wave-success

# Où Wave redirige après paiement échoué
WAVE_ERROR_URL=https://185.98.138.168:5000/wave-error

# ========== WEBHOOK ==========
# Où Wave envoie la confirmation du paiement
WAVE_WEBHOOK_URL=https://185.98.138.168:5000/api/payment/wave/webhook

# ========== MODE ==========
WAVE_DEV_MODE=false
TEST_MODE_FORCE_10_XOF=false
```

**✅ Après avoir ajouté:**
```bash
npm restart
# ou
pm2 restart coris-api
```

---

## 🌊 ACTION 2: Configuration dans Wave Dashboard

**Accéder à:** https://dashboard.wave.com

### Étape 2.1: Ajouter les URLs de Redirection

**Où:** Store Settings → Payment Methods → Wave Checkout

```
Remplir:
┌────────────────────────────────────────────────┐
│ Success URL:  https://185.98.138.168:5000/wave-success
│ Error URL:    https://185.98.138.168:5000/wave-error
│ [SAVE]                                         │
└────────────────────────────────────────────────┘
```

### Étape 2.2: Créer le Webhook

**Où:** Settings → Webhooks → Create New Webhook

**Remplir avec:**

```
Webhook URL:      https://185.98.138.168:5000/api/payment/wave/webhook
Header Name:      X-Wave-Signature
Secret:           whsk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx (de l'API Settings)
Content Type:     application/json

Événements à activer:
☑ checkout.session.completed
☑ checkout.session.expired
☑ payment.succeeded
☑ payment.failed
```

**Cliquer:** [CREATE WEBHOOK]

**Résultat attendu:**
```
Webhook successfully created!
ID: wh_live_xxxxx
Status: Active
```

### Étape 2.3: Tester le Webhook (Optionnel)

**Dans la section Webhooks:**
1. Trouver votre webhook
2. Cliquer sur "Test"
3. Envoyer un événement de test
4. Vérifier dans les logs serveur:
```bash
tail -f logs/payment.log | grep -i "webhook"
# Doit afficher: ✅ Signature valide
```

---

## 🧪 ACTION 3: Redémarrer le Serveur

```bash
# Option A: npm
npm restart

# Option B: pm2
pm2 restart coris-api

# Option C: Vérifier l'état
pm2 status
```

**Vérifier que les routes sont chargées:**
```bash
curl -I https://185.98.138.168:5000/wave-success
# Résultat attendu: HTTP/1.1 200 OK
```

---

## ✅ ACTION 4: Tester le Flux Complet

### Test en Mode Développement

**Prérequis:**
- TEST_MODE_FORCE_10_XOF=true dans `.env`
- Serveur redémarré

**Processus de test:**

```
1. Ouvrir l'app Flutter
   ↓
2. Naviguer: Propositions → Sélectionner une proposition
   ↓
3. Cliquer: "Payer avec Wave"
   ↓
4. Attendre que le formulaire Wave s'ouvre (~3-5 sec)
   ↓
5. Remplir les données (utiliser cartes de test Wave)
   - Numéro: 4111 1111 1111 1111
   - Expiration: 12/25
   - CVV: 123
   ↓
6. Soumettre le formulaire
   ↓
7. [SUCCÈS] Page "Paiement Réussi!" s'affiche
   - Montre le montant (10 XOF en test)
   - Montre l'ID de session
   - Compte à rebours: 5 secondes
   ↓
8. [Attendre 5 sec OU] Cliquer "Retourner à l'application"
   ↓
9. Browser ferme, retour à l'app
```

**Vérifications après test:**

```bash
# 1. Vérifier que la proposition est devenue contrat
psql mycorisdb -U postgres << EOF
SELECT id, statut, produit_nom, montant, date_validation 
FROM subscriptions 
WHERE produit_nom LIKE '%RETRAITE%' 
ORDER BY created_at DESC LIMIT 1;
EOF
# Résultat attendu: statut = "contrat" (au lieu de "proposition")

# 2. Vérifier les logs webhook
tail -100 logs/payment.log | grep -i "webhook\|wave_success"
# Résultat attendu lignes comme:
# [10:30:45] 🔔 WEBHOOK WAVE REÇU
# [10:30:45]    Event type: payment.succeeded
# [10:30:45] ✅ Signature valide
# [10:30:45] ✅ Transaction mise à jour en base

# 3. Vérifier que la transaction est enregistrée
psql mycorisdb -U postgres << EOF
SELECT id, statut, montant, api_response 
FROM payment_transactions 
ORDER BY created_at DESC LIMIT 1;
EOF
# Résultat attendu: statut = "SUCCESS"

# 4. Vérifier que le SMS a été envoyé
tail -50 logs/notification.log | grep -i "sms\|wave"
```

---

## 🔍 Vérification Rapide

**Lancer le script de vérification:**

```bash
bash verify_wave_setup.sh
```

**Résultat attendu:**
```
✅ WAVE_API_KEY
✅ WAVE_WEBHOOK_SECRET
✅ WAVE_SUCCESS_URL
✅ WAVE_ERROR_URL
✅ WAVE_WEBHOOK_URL
✅ /wave-success route trouvée
✅ /wave-error route trouvée
✅ /wave/webhook route trouvée
✅ Certificat HTTPS valide
✅ Serveur écoute sur port 5000
✅ HTTPS accessible

════════════════════════════════════════
✅ Réussi: 12
❌ Échoué: 0
════════════════════════════════════════
🎉 TOUT EST CONFIGURÉ CORRECTEMENT!
```

---

## 📊 Résumé de ce qui a été Fait

### ✅ Code Modifié

**Fichier:** `routes/paymentRoutes.js`

**3 Routes ajoutées:**

1. **GET /wave-success**
   - Appelée par Wave après paiement réussi
   - Affiche page HTML moderne avec:
     - Message "Paiement Réussi! 🎉"
     - Montant payé et ID de session
     - Compte à rebours 5 secondes
     - Bouton "Retourner à l'application"
     - Support protocole custom `coris://payment-success`

2. **GET /wave-error**
   - Appelée par Wave après paiement échoué
   - Affiche page HTML avec:
     - Message "Paiement Échoué ❌"
     - Raison et code erreur
     - Bouton "Retour à l'application"
     - Support protocole custom `coris://payment-error`

3. **POST /api/payment/wave/webhook**
   - Appelée par Wave après chaque paiement
   - Sécurité:
     - Vérifie signature HMAC-SHA256
     - Rejette si signature invalide
   - Actions:
     - Enregistre en base (payment_transactions)
     - Envoie SMS de confirmation
     - Retourne HTTP 200 OK

### ✅ Points Clés de l'Implémentation

```
Sécurité:
✅ HMAC-SHA256 pour vérification webhook
✅ Rejet des requêtes sans signature valide
✅ HTTPS obligatoire pour Wave

Fluxassurance:
✅ Webhook asynchrone (real-time)
✅ Polling synchrone pour fallback (40 tentatives)
✅ Confirmation automatique après paiement

UX:
✅ Pages success/error attrayantes et responsives
✅ Animations et visuels modernes
✅ Compte à rebours automatique
✅ Protocole custom pour retour à l'app

Notification:
✅ SMS automatique après confirmation
✅ Message détaillé avec montant et produit
✅ Versements toutes les données de transaction

Monitoring:
✅ Logs détaillés pour chaque événement
✅ Traçabilité complète du paiement
✅ Erreurs claires et actionnables
```

---

## 🚀 Ordre d'Exécution

```
1. ✅ Ajouter variables .env
   │
2. ✅ Redémarrer serveur
   │
3. ✅ Configurer URLs dans Wave Dashboard
   │
4. ✅ Créer le Webhook dans Wave Dashboard
   │
5. ✅ Attendre confirmation webhook
   │
6. ✅ Tester avec l'app Flutter
   │
7. ✅ Vérifier DB et logs
   │
8. ✅ En production: mettre TEST_MODE_FORCE_10_XOF=false
```

---

## ⚠️ Checklist de Sécurité

Avant de passer en production:

- [ ] TEST_MODE_FORCE_10_XOF = **false**
- [ ] WAVE_DEV_MODE = **false**
- [ ] NODE_ENV = **production**
- [ ] Certificat HTTPS valide et non expiré
- [ ] Variables Wave pointent vers clés **LIVE** (sk_live_, whsk_live_)
- [ ] Webhook testé et confirmé actif
- [ ] URLs HTTPS correctes dans Wave Dashboard
- [ ] Logs configurés et surveillés
- [ ] Backup de la DB avant le lancement

---

## 🆘 Dépannage Rapide

**Le webhook ne reçoit pas les événements?**
```bash
# 1. Vérifier le URL est accessible
curl -I https://185.98.138.168:5000/api/payment/wave/webhook

# 2. Vérifier le secret dans .env
grep "WAVE_WEBHOOK_SECRET" .env

# 3. Vérifier dans Wave Dashboard que le webhook est "Active"
# Dashboard → Settings → Webhooks → [chercher ton webhook]

# 4. Tester manuellement
bash test_webhook.sh
```

**La page success ne s'affiche pas?**
```bash
# 1. Vérifier la route existe
grep -n "router.get\('/wave-success" routes/paymentRoutes.js

# 2. Tester directement
curl -I https://185.98.138.168:5000/wave-success

# 3. Vérifier les certificats
openssl s_client -connect 185.98.138.168:5000
```

**La proposition reste "proposition" après paiement?**
```bash
# 1. Vérifier le webhooket a reçu l'événement
tail -50 logs/payment.log | grep -i "webhook"

# 2. Vérifier la transaction en base
psql mycorisdb -U postgres -c "SELECT * FROM payment_transactions ORDER BY created_at DESC LIMIT 1;"

# 3. Appeler manuellement confirm-wave-payment
curl -X POST https://185.98.138.168:5000/api/payment/confirm-wave-payment/SUBSCRIPTION_ID
```

---

## 📞 Support

- **Logs serveur:** `tail -f logs/payment.log`
- **Docs Wave:** https://docs.wave.com/checkout
- **Dashboard:** https://dashboard.wave.com

---

**Fait le:** 15 février 2026  
**Version:** 2.0 (Wave Checkout Complet)  
**Status:** ✅ Prêt pour configuration
