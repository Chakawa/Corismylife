# 🔧 Amélioration des Messages d'Erreur CorisMoney

**Date**: 5 février 2026  
**Objectif**: Fournir des messages d'erreur précis pour distinguer les différents types de problèmes lors des paiements CorisMoney

---

## 🎯 Problème Initial

Lorsqu'un paiement CorisMoney échouait, l'API retournait systématiquement le message générique:
```json
{
  "code": "-1",
  "message": "Client introuvable !",
  "transactionId": null
}
```

**Ce message ne permettait pas de distinguer**:
- ❌ Le compte CorisMoney n'existe pas
- 💰 Le solde est insuffisant  
- 🔑 Le code OTP est invalide
- ⚠️ Autres erreurs techniques

---

## ✅ Solution Implémentée

### 1. Vérification Préalable du Compte

**Avant** de tenter le paiement, on vérifie maintenant:

```javascript
// ✅ ÉTAPE 1: Vérifier l'existence du client
const clientInfo = await corisMoneyService.getClientInfo(codePays, telephone);

if (!clientInfo.success) {
  return res.status(404).json({
    success: false,
    message: '❌ Compte CorisMoney introuvable pour ce numéro',
    detail: 'Veuillez vérifier que votre compte CorisMoney est bien activé pour ce numéro de téléphone.',
    errorCode: 'ACCOUNT_NOT_FOUND'
  });
}
```

**Avantage**: L'utilisateur sait immédiatement si le problème vient de l'absence de compte.

---

### 2. Vérification du Solde

**Avant** de lancer le paiement, on compare le solde disponible au montant requis:

```javascript
const soldeDisponible = parseFloat(clientInfo.data.solde || clientInfo.data.balance || 0);
const montantRequis = parseFloat(montant);

if (soldeDisponible < montantRequis) {
  return res.status(400).json({
    success: false,
    message: '💰 Solde insuffisant',
    detail: `Votre solde actuel (${soldeDisponible.toLocaleString()} FCFA) est insuffisant pour effectuer ce paiement (${montantRequis.toLocaleString()} FCFA).`,
    soldeDisponible: soldeDisponible,
    montantRequis: montantRequis,
    errorCode: 'INSUFFICIENT_BALANCE'
  });
}
```

**Avantage**: L'utilisateur voit exactement combien il lui manque.

---

### 3. Messages d'Erreur Détaillés

Si malgré les vérifications le paiement échoue, on analyse le code d'erreur CorisMoney:

```javascript
// Analyser le code d'erreur CorisMoney
if (result.error && result.error.code) {
  const code = result.error.code.toString();
  
  if (code === '-1') {
    errorMessage = '❌ Erreur lors du paiement CorisMoney';
    errorCode = 'CORISMONEY_ERROR';
  } else if (code.includes('OTP') || code.includes('otp')) {
    errorMessage = '🔑 Code OTP invalide ou expiré';
    errorCode = 'INVALID_OTP';
  } else if (code.includes('BALANCE') || code.includes('INSUFFICIENT')) {
    errorMessage = '💰 Solde insuffisant';
    errorCode = 'INSUFFICIENT_BALANCE';
  }
}
```

---

## 📊 Types de Réponses Possibles

### ✅ Succès
```json
{
  "success": true,
  "message": "Paiement effectué avec succès",
  "transactionId": "TRANS123456",
  "montant": 15000,
  "contractCreated": true
}
```

---

### ❌ Compte Introuvable
**Status HTTP**: `404 Not Found`

```json
{
  "success": false,
  "message": "❌ Compte CorisMoney introuvable pour ce numéro",
  "detail": "Veuillez vérifier que votre compte CorisMoney est bien activé pour ce numéro de téléphone.",
  "errorCode": "ACCOUNT_NOT_FOUND"
}
```

**Cause possible**:
- Le numéro n'a jamais été enregistré dans CorisMoney
- Le compte CorisMoney a été désactivé
- Le numéro de téléphone est incorrect

**Action utilisateur**: Créer/activer un compte CorisMoney pour ce numéro

---

### 💰 Solde Insuffisant
**Status HTTP**: `400 Bad Request`

```json
{
  "success": false,
  "message": "💰 Solde insuffisant",
  "detail": "Votre solde actuel (5 000 FCFA) est insuffisant pour effectuer ce paiement (15 000 FCFA).",
  "soldeDisponible": 5000,
  "montantRequis": 15000,
  "errorCode": "INSUFFICIENT_BALANCE"
}
```

**Cause**: Le compte existe mais n'a pas assez de fonds

**Action utilisateur**: Recharger le compte CorisMoney

---

### 🔑 OTP Invalide
**Status HTTP**: `400 Bad Request`

```json
{
  "success": false,
  "message": "🔑 Code OTP invalide ou expiré",
  "errorCode": "INVALID_OTP",
  "detail": {...}
}
```

**Cause possible**:
- Le code OTP a expiré (durée de validité: 5 minutes)
- Le code saisi est incorrect
- L'utilisateur a demandé un nouveau code entre-temps

**Action utilisateur**: Redemander un nouveau code OTP

---

### ⏳ Transaction en Attente
**Status HTTP**: `202 Accepted`

```json
{
  "success": true,
  "message": "Transaction en cours de traitement. Vérifiez le statut dans quelques instants.",
  "transactionId": "TRANS123456",
  "status": "PENDING"
}
```

**Cause**: CorisMoney traite la transaction

**Action utilisateur**: Attendre quelques secondes puis vérifier le statut

---

### ⚠️ Erreur Générique
**Status HTTP**: `400 Bad Request`

```json
{
  "success": false,
  "message": "❌ Erreur lors du paiement CorisMoney",
  "errorCode": "PAYMENT_FAILED",
  "detail": {...}
}
```

**Cause**: Erreur technique non identifiée

**Action utilisateur**: Réessayer ou contacter le support

---

## 🔄 Flux de Paiement Amélioré

```
1. Utilisateur initie le paiement
   ↓
2. ✅ Vérification du compte CorisMoney
   ├─ ❌ Compte introuvable → Retour erreur ACCOUNT_NOT_FOUND
   └─ ✅ Compte trouvé
      ↓
3. ✅ Vérification du solde
   ├─ ❌ Solde insuffisant → Retour erreur INSUFFICIENT_BALANCE (avec montants)
   └─ ✅ Solde suffisant
      ↓
4. 💳 Exécution du paiement CorisMoney
   ├─ ❌ OTP invalide → Retour erreur INVALID_OTP
   ├─ ⏳ En cours → Retour status PENDING
   └─ ✅ Succès
      ↓
5. 🔍 Vérification du statut final (après 2s)
   ├─ SUCCESS → Création du contrat
   ├─ FAILED → Enregistrement de l'échec
   └─ PENDING → Statut en attente
```

---

## 🧪 Comment Tester

### Option 1: Script de Test Automatisé

```bash
# Exécuter le script de test
node test-payment-errors.js
```

Ce script teste:
1. Vérification d'un compte existant
2. Détection de solde insuffisant
3. Gestion d'OTP invalide

### Option 2: Test Manuel via API

#### Test 1: Compte Introuvable
```bash
curl -X POST http://localhost:5000/api/payment/process-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "codePays": "225",
    "telephone": "0000000000",
    "montant": 15000,
    "codeOTP": "12345"
  }'
```

**Résultat attendu**: `ACCOUNT_NOT_FOUND`

#### Test 2: Solde Insuffisant
```bash
# Utiliser un numéro valide avec peu de solde
curl -X POST http://localhost:5000/api/payment/process-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "codePays": "225",
    "telephone": "0799283976",
    "montant": 1000000,
    "codeOTP": "12345"
  }'
```

**Résultat attendu**: `INSUFFICIENT_BALANCE` avec détails du solde

#### Test 3: OTP Invalide
```bash
# Utiliser un OTP expiré ou incorrect
curl -X POST http://localhost:5000/api/payment/process-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "codePays": "225",
    "telephone": "0799283976",
    "montant": 5000,
    "codeOTP": "00000"
  }'
```

**Résultat attendu**: `INVALID_OTP`

---

## 📁 Fichiers Modifiés

### `routes/paymentRoutes.js`
**Modifications**:
- Ajout de `getClientInfo()` avant le paiement
- Vérification du solde avec comparaison montants
- Messages d'erreur détaillés par type
- Codes d'erreur explicites (`ACCOUNT_NOT_FOUND`, `INSUFFICIENT_BALANCE`, etc.)

**Lignes modifiées**: ~120-170, ~330-365

---

## 💡 Avantages pour l'Utilisateur Final

### Avant (Problématique)
```
❌ "Client introuvable !"
→ Qu'est-ce qui ne va pas ? Compte inexistant ou solde insuffisant ?
```

### Après (Solution)
```
✅ "Solde insuffisant"
   Votre solde actuel (5 000 FCFA) est insuffisant 
   pour effectuer ce paiement (15 000 FCFA).
→ L'utilisateur sait exactement quoi faire: recharger son compte
```

---

## 🔐 Sécurité

Les vérifications préalables n'exposent pas de données sensibles:
- Le solde est affiché **uniquement** au propriétaire du compte (authentifié)
- Les messages d'erreur sont génériques en cas de problème technique
- Le hash de sécurité CorisMoney est toujours vérifié

---

## 📈 Prochaines Étapes

1. ✅ Tester avec de vrais comptes CorisMoney
2. ✅ Monitorer les logs pour identifier d'autres codes d'erreur CorisMoney
3. ⏳ Ajouter une interface utilisateur montrant le solde disponible
4. ⏳ Implémenter un système de retry automatique pour les OTP expirés
5. ⏳ Notification SMS si le solde est insuffisant avec un lien de recharge

---

## 📞 Support

En cas de problème:
1. Vérifier les logs du serveur Node.js
2. Tester avec le script `test-payment-errors.js`
3. Consulter la documentation CorisMoney API
4. Contacter l'équipe technique CORIS

---

**Résumé**: Maintenant, chaque type d'erreur de paiement CorisMoney a son propre message explicite, permettant à l'utilisateur de comprendre et résoudre le problème rapidement. ✅
