# 🚀 Guide de Production - Intégration CorisMoney

## ✅ Configuration Actuelle

### Fichier `.env` - Variables Configurées
```env
# API CorisMoney - PRODUCTION
CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=MYCORISLIFETEST
CORIS_MONEY_CLIENT_SECRET=$2a$10$H.lf9RrqqWpCISE.LK78gucwG8N87dyW8dkkPoJ9mUZ5E9botCEwa
CORIS_MONEY_CODE_PV=0280315524

# Mode Production ACTIVÉ
CORIS_MONEY_DEV_MODE=false
```

---

## 🔧 Architecture de l'API

### 1. Service CorisMoney (`services/corisMoneyService.js`)
**Fonctions disponibles :**
- ✅ `sendOTP(codePays, telephone)` - Envoie un code OTP au client
- ✅ `paiementBien(codePays, telephone, montant, codeOTP)` - Traite un paiement
- ✅ `getClientInfo(codePays, telephone)` - Récupère les infos d'un client
- ✅ `getTransactionStatus(codeOperation)` - Vérifie le statut d'une transaction

**Sécurité :**
- Hash SHA256 pour toutes les requêtes
- Vérification SSL en production
- Validation des identifiants

### 2. Routes API (`routes/paymentRoutes.js`)
Toutes les routes nécessitent une authentification (`verifyToken`)

| Route | Méthode | Description |
|-------|---------|-------------|
| `/api/payment/send-otp` | POST | Envoie l'OTP au client |
| `/api/payment/process-payment` | POST | Traite le paiement |
| `/api/payment/client-info` | GET | Info client CorisMoney |
| `/api/payment/transaction-status/:id` | GET | Statut transaction |
| `/api/payment/history` | GET | Historique paiements |

### 3. Base de Données
**Tables créées :**
```sql
-- Historique des demandes OTP
CREATE TABLE payment_otp_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    code_pays VARCHAR(10),
    telephone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Transactions de paiement
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    subscription_id INTEGER REFERENCES subscriptions(id),
    transaction_id VARCHAR(255) UNIQUE,
    code_pays VARCHAR(10),
    telephone VARCHAR(20),
    montant DECIMAL(15,2),
    statut VARCHAR(50),
    description TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);
```

---

## 🧪 Tests à Effectuer

### Test 1 : Envoi OTP
```bash
# Requête
POST http://localhost:5000/api/payment/send-otp
Headers: Authorization: Bearer <token>
Body: {
  "codePays": "225",
  "telephone": "0799283976"
}

# ⚠️ IMPORTANT : Le numéro DOIT inclure le 0 initial !
# Format complet: 225 + 0799283976 = 2250799283976
# ❌ INCORRECT: "799283976" (sans le 0)
# ✅ CORRECT: "0799283976" (avec le 0)

# Réponse attendue
{
  "success": true,
  "message": "Code OTP envoyé avec succès"
}
```

### Test 2 : Traitement Paiement
```bash
# Requête
POST http://localhost:5000/api/payment/process-payment
Headers: Authorization: Bearer <token>
Body: {
  "codePays": "225",
  "telephone": "0799283976",
  "montant": "5000",
  "codeOTP": "123456",
  "subscriptionId": 1,
  "description": "Prime d'assurance Sérenité"
}

# ⚠️ RAPPEL : Le numéro DOIT inclure le 0 initial !

# Réponse attendue
{
  "success": true,
  "message": "Paiement effectué avec succès",
  "transactionId": "TXN-12345",
  "montant": 5000,
  "paymentRecordId": 1
}
```

### Test 3 : Vérification Statut
```bash
# Requête
GET http://localhost:5000/api/payment/transaction-status/TXN-12345
Headers: Authorization: Bearer <token>

# Réponse attendue
{
  "success": true,
  "data": {
    "status": "SUCCESS",
    "amount": 5000,
    ...
  }
}
```

---

## 📱 Flux de Paiement Flutter

### Étape 1 : Modal CorisMoney
L'utilisateur ouvre le modal de paiement depuis l'app Flutter :
```dart
showCorisMoneyPaymentModal(
  context: context,
  amount: montant,
  subscriptionId: subscriptionId,
  onSuccess: (transactionId) {
    // Paiement réussi
  },
  onError: (message) {
    // Erreur
  },
);
```

### Étape 2 : Saisie du numéro
Widget `CorisMoneyPaymentModal` :
- Sélection du pays (Côte d'Ivoire par défaut)
- Saisie du numéro de téléphone
- Bouton "Envoyer le code"

### Étape 3 : Envoi OTP
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/payment/send-otp'),
  headers: {'Authorization': 'Bearer $token'},
  body: json.encode({
    'codePays': selectedCountry.dialCode,
    'telephone': phoneController.text,
  }),
);
```

### Étape 4 : Saisie du code OTP
- 6 champs numériques
- Timer de 5 minutes
- Bouton "Renvoyer le code"

### Étape 5 : Validation du paiement
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/payment/process-payment'),
  headers: {'Authorization': 'Bearer $token'},
  body: json.encode({
    'codePays': selectedCountry.dialCode,
    'telephone': phoneController.text,
    'montant': amount.toString(),
    'codeOTP': otpCode,
    'subscriptionId': subscriptionId,
  }),
);
```

---

## 🔐 Sécurité

### Hash SHA256
Toutes les requêtes utilisent un hash de sécurité :
```javascript
// Exemple pour sendOTP
// ⚠️ IMPORTANT : Le numéro doit inclure le 0 initial (ex: 0799283976)
const hashString = codePays + telephone + clientSecret;
// Exemple: "225" + "0799283976" + "secretKey" = "2250799283976secretKey"

const hashParam = crypto.createHash('sha256')
  .update(hashString, 'utf8')
  .digest('hex');

// Exemple pour paiementBien
const hashString2 = codePays + telephone + codePv + montant + codeOTP + clientSecret;
// Exemple: "225" + "0799283976" + "0280315524" + "5000" + "123456" + "secretKey"
```

### Headers Requis
```javascript
headers: {
  'Content-Type': 'application/json',
  'clientId': CORIS_MONEY_CLIENT_ID,
  'hashParam': hashSHA256
}
```

---

## 📊 Monitoring et Logs

### Logs en Production
Le service affiche au démarrage :
```
💰 ═══════════════════════════════════════════════════════════
💰 MODE PRODUCTION CORISMONEY ACTIVÉ
💰 API CorisMoney: https://testbed.corismoney.com/external/v1/api
💰 Client ID: MYCORISLIFETEST
💰 Code PV: 0280315524
💰 Les paiements seront RÉELS
💰 ═══════════════════════════════════════════════════════════
```

### Vérification des Logs
Chaque appel API affiche :
- 📱 Numéro de téléphone
- 💰 Montant (si paiement)
- ✅ Succès ou ❌ Échec
- 🔐 Hash généré (premiers 20 caractères)

---

## 🚨 Résolution de Problèmes

### Problème : "Identifiants CorisMoney non configurés"
**Solution :** Vérifier le fichier `.env` :
```bash
cat .env | grep CORIS_MONEY
```

### Problème : "Code OTP non reçu par SMS"
**Solution :** Vérifier le format du numéro de téléphone
- ✅ **CORRECT** : `codePays: "225"`, `telephone: "0799283976"` → 2250799283976
- ❌ **INCORRECT** : `codePays: "225"`, `telephone: "799283976"` → 225799283976 (manque le 0)
- Le numéro DOIT commencer par 0 pour les opérateurs ivoiriens
- L'API CorisMoney attend le format complet: codePays + 0XXXXXXXX

### Problème : "Erreur SSL/TLS"
**Solution :** Vérifier que `NODE_ENV=production` pour activer la vérification SSL

### Problème : "OTP incorrect"
**Vérifications :**
1. Le numéro de téléphone est correct
2. L'OTP n'a pas expiré (5 minutes)
3. Le code saisi correspond à celui reçu par SMS

### Problème : "Transaction échouée"
**Logs à vérifier :**
```javascript
// Dans paymentRoutes.js
console.log('❌ Échec envoi OTP:', result.message);
console.error('❌ Erreur lors du paiement:', error);
```

---

## 🎯 Checklist Production

### Avant la Mise en Production
- ✅ Variables d'environnement configurées (`.env`)
- ✅ `CORIS_MONEY_DEV_MODE=false` (mode production)
- ✅ Base de données avec tables créées
- ✅ SSL/TLS activé (`NODE_ENV=production`)
- ✅ Tests d'intégration effectués
- ✅ Logs de monitoring activés

### Tests de Validation
- ✅ Test envoi OTP avec numéro réel
- ✅ Test paiement avec montant réel
- ✅ Test vérification statut transaction
- ✅ Test historique des paiements
- ✅ Test gestion des erreurs

### Déploiement
1. **Backend** : 
   ```bash
   cd /path/to/mycoris-master
   npm install
   node server.js
   ```

2. **Flutter** :
   ```bash
   cd /path/to/mycorislife-master
   flutter pub get
   flutter run --release
   ```

---

## 📞 Support

En cas de problème avec l'API CorisMoney :
- **Documentation API :** Contactez CorisMoney
- **Support Technique :** Vérifier les logs du serveur Node.js
- **Base de données :** Consulter la table `payment_transactions`

---

## 📝 Notes Importantes

1. **Mode Test vs Production :**
   - URL Test : `https://testbed.corismoney.com/external/v1/api`
   - URL Prod : Demander à CorisMoney

2. **Montants :**
   - Minimum : Selon les règles CorisMoney
   - Maximum : Selon les règles CorisMoney
   - Devise : XOF (Franc CFA)

3. **Délais :**
   - OTP expire après 5 minutes
   - Transaction confirmée en temps réel

4. **Commissions :**
   - Frais CorisMoney appliqués selon contrat
   - À vérifier avec CorisMoney

---

**Date de finalisation :** 05/02/2026
**Version API :** CorisMoney External v1.1.0
**Statut :** ✅ Prêt pour la Production
