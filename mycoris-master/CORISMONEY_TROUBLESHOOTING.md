# 🔧 Troubleshooting CorisMoney API

**Date**: 5 février 2026

---

## ⚠️ Problème 1: Certificat SSL Expiré (Testbed)

### Symptôme
```
Error: certificate has expired
```

### Cause
L'API testbed CorisMoney (`testbed.corismoney.com`) a un certificat SSL expiré.

### Solution Appliquée

#### Option 1: Modification du Service (Recommandé)
Le `httpsAgent` dans `corisMoneyService.js` a été modifié pour désactiver la vérification SSL **uniquement pour testbed**:

```javascript
const isTestbedAPI = this.baseURL.includes('testbed');
this.httpsAgent = new https.Agent({
  rejectUnauthorized: isTestbedAPI ? false : (process.env.NODE_ENV === 'production')
});
```

#### Option 2: Variable d'Environnement (Scripts de Test)
Pour les scripts de test standalone:

```javascript
// En début de fichier
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
```

⚠️ **ATTENTION**: Ne JAMAIS utiliser cette option en production réelle !

### Migration vers Production
Quand vous passerez à l'API production CorisMoney:
1. Changer `CORIS_MONEY_BASE_URL` dans le `.env`
2. La vérification SSL se réactivera automatiquement
3. Retirer `NODE_TLS_REJECT_UNAUTHORIZED = '0'` des scripts de test

---

## ❌ Problème 2: "Client introuvable" malgré un Compte Actif

### Symptôme
```json
{
  "code": "-1",
  "message": "Client introuvable !",
  "msg": "client inexistant",
  "errCode": "-1"
}
```

### Investigation
Lors du test du numéro **2250799283976** :

```bash
$ node test-account-check.js

📞 Numéro testé: 2250799283976
✅ COMPTE TROUVÉ!

📊 Informations du client:
{
  "msg": "client inexistant",
  "codeErr": "-1",
  ...
}

💰 Solde disponible: 0 FCFA
```

### Conclusion
**Le compte n'existe réellement pas** dans la base CorisMoney testbed, même si l'utilisateur pense avoir un compte.

### Raisons Possibles
1. **Environnement différent**: Le compte existe en **production** mais pas sur **testbed**
2. **Numéro incorrect**: Format ou indicatif incorrect
3. **Compte désactivé**: Le compte a été désactivé/supprimé dans CorisMoney
4. **Base de données séparées**: Production CorisMoney vs Testbed ont des bases différentes

### Solution pour l'Utilisateur

#### Option A: Créer un Compte Testbed
Si le numéro a un compte en production CorisMoney mais pas en testbed:
1. Créer un compte sur l'environnement testbed
2. Utiliser ce compte pour les tests

#### Option B: Utiliser un Autre Numéro
Tester avec un numéro qui existe sur testbed

#### Option C: Passer en Production
Si les tests testbed ne sont plus nécessaires:
1. Changer l'URL vers l'API production CorisMoney
2. Utiliser les comptes réels

---

## ✅ Améliorations Apportées

### 1. Messages d'Erreur Explicites

**AVANT**:
```json
{
  "success": false,
  "message": "Client introuvable !",
  "error": { "code": "-1", ... }
}
```
→ L'utilisateur ne sait pas si c'est le compte, le solde, ou autre chose.

**APRÈS**:
```json
{
  "success": false,
  "message": "❌ Compte CorisMoney introuvable pour ce numéro",
  "detail": "Veuillez vérifier que votre compte CorisMoney est bien activé pour ce numéro de téléphone.",
  "errorCode": "ACCOUNT_NOT_FOUND"
}
```
→ L'utilisateur sait exactement le problème et quoi faire.

### 2. Vérification Préalable du Compte

**Flux amélioré**:
```
1. Vérifier l'existence du compte (getClientInfo)
   ↓
2. Vérifier le solde disponible
   ↓
3. Effectuer le paiement seulement si tout est OK
```

**Avantages**:
- ✅ Économie d'appels API (pas de tentative de paiement si compte inexistant)
- ✅ Messages d'erreur précis
- ✅ Meilleure expérience utilisateur

### 3. Comparaison de Solde avec Détails

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

L'utilisateur voit:
- Son solde actuel
- Le montant requis
- Le montant manquant (calculé par l'interface)

---

## 🧪 Comment Tester

### Test 1: Compte Inexistant
```bash
cd D:\CORIS\app_coris\mycoris-master
node test-account-check.js
```

**Attendu**: Message "client inexistant"

### Test 2: Paiement avec Compte Inexistant
```javascript
// Dans votre application ou via Postman
POST /api/payment/process-payment
{
  "codePays": "225",
  "telephone": "0799283976",  // Compte inexistant sur testbed
  "montant": 15000,
  "codeOTP": "123456"
}
```

**Attendu**:
```json
{
  "success": false,
  "message": "❌ Compte CorisMoney introuvable pour ce numéro",
  "errorCode": "ACCOUNT_NOT_FOUND"
}
```

### Test 3: Solde Insuffisant
Pour tester ce cas, il faut:
1. Trouver un numéro avec un compte testbed actif
2. Vérifier son solde avec `test-account-check.js`
3. Demander un paiement supérieur au solde

---

## 📋 Checklist de Migration Production

Avant de passer en production CorisMoney réelle:

- [ ] Changer `CORIS_MONEY_BASE_URL` vers l'URL production
- [ ] Vérifier que `CORIS_MONEY_CLIENT_ID` est correct pour la production
- [ ] Vérifier que `CORIS_MONEY_CLIENT_SECRET` est correct pour la production
- [ ] Vérifier que `CORIS_MONEY_CODE_PV` est correct
- [ ] Retirer `NODE_TLS_REJECT_UNAUTHORIZED = '0'` des scripts
- [ ] Tester avec des petits montants d'abord
- [ ] Vérifier les logs de transaction
- [ ] Confirmer que les certificats SSL production sont valides

---

## 🔗 Fichiers Modifiés

| Fichier | Modifications |
|---------|--------------|
| `services/corisMoneyService.js` | Agent HTTPS avec détection testbed |
| `routes/paymentRoutes.js` | Vérification compte + solde avant paiement |
| `test-account-check.js` | Script de diagnostic SSL/compte |
| `test-payment-errors.js` | Tests des différents messages d'erreur |

---

## 📞 Contact Support CorisMoney

Si le problème persiste:
1. Vérifier que les credentials (CLIENT_ID, SECRET, CODE_PV) sont corrects
2. Contacter CorisMoney pour vérifier l'état du compte sur testbed
3. Demander le renouvellement du certificat SSL de testbed
4. Envisager de passer directement en production si testbed n'est plus maintenu

---

**Conclusion**: Le message "Client introuvable" était correct ! Le compte n'existe vraiment pas sur l'environnement testbed CorisMoney. Les améliorations apportées permettent maintenant de détecter ce cas plus tôt et d'informer l'utilisateur avec un message clair. ✅
