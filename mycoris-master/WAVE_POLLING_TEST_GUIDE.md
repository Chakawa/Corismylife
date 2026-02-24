# 🌊 TEST WAVE CHECKOUT - MODE POLLING (Sans Webhooks)

## 📋 Vue d'ensemble

Ce guide vous explique comment tester l'intégration Wave Checkout **SANS webhooks**, en mode **polling uniquement**.

### ✅ Pourquoi sans webhooks ?

Wave Checkout API fonctionne parfaitement en mode polling :
- **Pas besoin de webhook** : Les webhooks sont **optionnels** selon la doc Wave
- **Plus simple** : Pas de configuration serveur public/tunnel
- **Fiable** : Polling actif via `GET /v1/checkout/sessions/{id}`
- **Testé** : Configuration validée pour environnement local

---

## 🚀 Démarrage Rapide

### Option 1 : Script Interactif (RECOMMANDÉ)

```powershell
# Lancer le script interactif
.\test-wave-interactive.ps1
```

Le script vous guide pas à pas :
1. Connexion automatique pour obtenir JWT token
2. Configuration des paramètres de test
3. Vérification serveur
4. Lancement du test

### Option 2 : Manuel

```powershell
# 1. Démarrer le serveur (si pas déjà fait)
npm start

# 2. Dans un autre terminal, lancer le test
node test-wave-polling.js
```

---

## ⚙️ Configuration

### 1. Fichier `.env`

```env
# Mode Wave (false = production avec API réelle)
WAVE_DEV_MODE=false

# API Wave
WAVE_API_BASE_URL=https://api.wave.com
WAVE_API_KEY=wave_ci_prod_AqlIPJvDjeIPjMfZzfJIwlgFM3fMMhO8dXm0ma3Y5VgcMBkD6ZGFAkJG3qwGjfOC5zOwGZrbwMqNIiBFV88xC_NlhGzS8z5DVw

# URLs de redirection
WAVE_SUCCESS_URL=http://185.98.138.168:5000/wave-success
WAVE_ERROR_URL=http://185.98.138.168:5000/wave-error

# Webhook (VIDE = mode polling uniquement)
WAVE_WEBHOOK_URL=
WAVE_WEBHOOK_SECRET=

# Devise
WAVE_DEFAULT_CURRENCY=XOF

# Token JWT pour les tests
TEST_JWT_TOKEN=votre-token-ici
```

### 2. Obtenir un JWT Token

**Méthode A : Via script interactif**
```powershell
.\test-wave-interactive.ps1
# Le script vous demandera email/mot de passe
```

**Méthode B : Connexion manuelle**
```powershell
curl -X POST http://localhost:5000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"votre@email.com","password":"votrepass"}'
```

Copiez le token et ajoutez-le dans `.env` :
```env
TEST_JWT_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🧪 Exécution du Test

### Flux du test automatisé

```
1. Créer session Wave
   ↓
2. Afficher URL de paiement
   ↓
3. Attendre confirmation utilisateur
   ↓
4. Polling du statut (10x, intervalle 3s)
   ↓
5. Afficher résultat final
```

### Résultats attendus

**✅ Succès**
```
🎉 PAIEMENT RÉUSSI !
  Le paiement Wave fonctionne correctement.
  Mode polling opérationnel (sans webhooks).
```

**⏱️ Timeout**
```
⏱️  TIMEOUT
  Le polling a expiré avant confirmation.
  Recommandations:
    - Augmentez maxAttempts dans le code
    - Vérifiez manuellement le statut plus tard
```

**❌ Échec**
```
❌ PAIEMENT ÉCHOUÉ
  Le paiement n'a pas abouti.
  Vérifiez:
    - L'API Wave est accessible
    - La clé API est valide
    - Le montant est conforme (min 100 FCFA)
```

---

## 🔍 Vérification Manuelle du Statut

Si le test expire, vérifiez manuellement :

```powershell
# Remplacez {sessionId} par l'ID affiché dans le test
curl -X GET "http://localhost:5000/api/payment/wave/status/{sessionId}?subscriptionId=1&transactionId=WAVE-xxx" `
  -H "Authorization: Bearer VOTRE_TOKEN"
```

---

## 📱 Test en Situation Réelle

### Sur Émulateur Android

1. **AppConfig déjà configuré** (10.0.2.2:5000)
2. Lancez l'app Flutter
3. Naviguez vers "Mes Propositions"
4. Sélectionnez une proposition
5. Cliquez "Payer avec Wave"
6. L'URL Wave s'ouvre
7. Complétez le paiement
8. L'app poll automatiquement le statut

### Sur Téléphone Réel

1. **Générez l'APK** :
   ```bash
   flutter build apk --release
   ```

2. **Installez** :
   ```bash
   flutter install
   ```

3. **Testez** le flux complet avec votre compte Wave

---

## 🛠️ Personnalisation

### Modifier le polling

Dans `test-wave-polling.js` :

```javascript
// Changer le nombre de tentatives (défaut: 10)
const pollResult = await pollStatus(sessionId, transactionId, 20);

// Changer l'intervalle (dans pollStatus())
await new Promise((resolve) => setTimeout(resolve, 5000)); // 5s au lieu de 3s
```

### Modifier les paramètres de test

Dans `test-wave-polling.js` :

```javascript
const SUBSCRIPTION_ID = 1;      // ID de souscription
const AMOUNT = 100;             // Montant (min 100 FCFA)
const DESCRIPTION = 'Test...';  // Description
```

---

## ❓ FAQ

**Q : Pourquoi pas de webhooks ?**  
R : Les webhooks sont optionnels. Le polling fonctionne parfaitement pour notre cas d'usage.

**Q : Le polling est-il fiable ?**  
R : Oui, l'API Wave garantit que `GET /v1/checkout/sessions/{id}` retourne le statut en temps réel.

**Q : Quelle est la fréquence de polling recommandée ?**  
R : 3-5 secondes entre chaque vérification. Wave met à jour le statut instantanément.

**Q : Combien de temps l'utilisateur a-t-il pour payer ?**  
R : Par défaut, une session Wave expire après 30 minutes.

**Q : Le statut est-il définitif ?**  
R : Oui, une fois "complete", "failed" ou "cancelled", le statut ne change plus.

**Q : Que faire si le test timeout ?**  
R : Vérifiez manuellement avec l'endpoint `/status/{sessionId}`. Le paiement peut avoir réussi après le timeout.

---

## 📊 Codes Statut Wave

| Statut Wave | Statut Interne | Signification |
|-------------|----------------|---------------|
| `complete` | `COMPLETED` | Paiement réussi ✅ |
| `failed` | `FAILED` | Paiement échoué ❌ |
| `cancelled` | `CANCELLED` | Annulé par l'utilisateur ⚠️ |
| `pending` | `PENDING` | En attente ⏳ |
| `expired` | `FAILED` | Session expirée ⏱️ |

---

## 🚨 Dépannage

### Erreur "Cannot find module"
```bash
npm install
```

### Serveur non accessible
```bash
# Vérifier si le serveur tourne
curl http://localhost:5000/test-db

# Redémarrer si nécessaire
npm start
```

### "JWT token invalide"
```bash
# Re-connectez-vous
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"votre@email.com","password":"pass"}'

# Mettez à jour .env avec le nouveau token
```

### "Session ID not found"
- Vérifiez que WAVE_API_KEY est correct dans `.env`
- Vérifiez que WAVE_DEV_MODE=false pour utiliser l'API réelle
- Testez d'abord en mode dev (WAVE_DEV_MODE=true) pour valider le flux

---

## 📞 Support

- Documentation Wave : https://docs.wave.com/checkout
- API Reference : https://docs.wave.com/checkout#checkout-api
- Status Codes : https://docs.wave.com/checkout#payment-statuses

---

✅ **PRÊT POUR LES TESTS !**
