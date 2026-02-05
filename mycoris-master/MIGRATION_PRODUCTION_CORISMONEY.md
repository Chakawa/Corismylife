# 🔄 Guide de Migration CorisMoney: Testbed → Production

**Date**: 5 février 2026  
**Objectif**: Passer de l'API testbed CorisMoney à l'API production pour tester avec de vrais comptes

---

## ⚠️ IMPORTANT - À LIRE AVANT DE CONTINUER

### Ce qui est DÉJÀ en Production ✅
- **API SMS**: `https://apis.letexto.com/v1/messages/send` → RÉELLE
- Les codes OTP que vous recevez sont réels
- Les SMS sont vraiment envoyés

### Ce qui est en Testbed 🧪
- **API CorisMoney**: `https://testbed.corismoney.com/external/v1/api` → TEST
- Base de données séparée (vos comptes production n'existent pas sur testbed)
- Certificat SSL expiré
- Paiements en mode test

---

## 📝 Étapes pour Passer en PRODUCTION

### ⚠️ PRÉCAUTIONS

1. **Vérifier vos credentials production CorisMoney**
   - Avez-vous les vrais identifiants production ?
   - Client ID production (peut être différent de `MYCORISLIFETEST`)
   - Client Secret production (peut être différent)
   - Code PV production (peut être différent de `0280315524`)

2. **Tester d'abord avec de PETITS montants**
   - Les paiements seront RÉELS
   - L'argent sera vraiment débité
   - Commencez par 100 FCFA ou 500 FCFA

3. **Sauvegarder la configuration actuelle**
   - Faites une copie du fichier `.env` avant modification

---

## 🔧 Modification du Fichier .env

### Option A: Vous Connaissez l'URL Production CorisMoney

Ouvrez le fichier `.env` et modifiez ces lignes:

```bash
# AVANT (Testbed)
CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=MYCORISLIFETEST
CORIS_MONEY_CLIENT_SECRET=$2a$10$H.lf9RrqqWpCISE.LK78gucwG8N87dyW8dkkPoJ9mUZ5E9botCEwa
CORIS_MONEY_CODE_PV=0280315524

# APRÈS (Production) - EXEMPLE, vérifiez vos vraies valeurs !
CORIS_MONEY_BASE_URL=https://api.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=MYCORISLIFEPROD
CORIS_MONEY_CLIENT_SECRET=VOTRE_SECRET_PRODUCTION
CORIS_MONEY_CODE_PV=VOTRE_CODE_PV_PRODUCTION
```

**URLs possibles pour la production**:
- `https://api.corismoney.com/external/v1/api`
- `https://prod.corismoney.com/external/v1/api`
- `https://corismoney.com/external/v1/api`
- **→ VÉRIFIEZ avec votre contact CorisMoney !**

---

### Option B: Vous N'Avez Pas les Informations Production

**Contactez CorisMoney** pour obtenir:
1. ✅ URL de l'API production
2. ✅ Client ID production
3. ✅ Client Secret production
4. ✅ Code PV production
5. ✅ Documentation de l'API production

**Contact CorisMoney**:
- Support technique CorisMoney
- Documentation: Demander le guide d'intégration API production
- Vérifier que votre compte est bien activé pour la production

---

## 🧪 Scénario de Test Recommandé

### Étape 1: Sauvegarder la Configuration Actuelle

```powershell
# Dans PowerShell
cd D:\CORIS\app_coris\mycoris-master
Copy-Item .env .env.testbed.backup
```

### Étape 2: Créer une Configuration Production

```powershell
# Créer un fichier .env.production avec vos credentials production
notepad .env.production
```

Contenu de `.env.production`:
```bash
PORT=5000
NODE_ENV=production
DATABASE_URL=postgresql://db_admin:Corisvie2025@185.98.138.168:5432/mycorisdb
JWT_SECRET=ton_secret_jwt_tres_securise
JWT_EXPIRES_IN=30d
SESSION_SECRET=une_autre_cle_secrete

# ⚠️ PRODUCTION CORISMONEY - PAIEMENTS RÉELS !
CORIS_MONEY_BASE_URL=https://api.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=VOTRE_CLIENT_ID_PRODUCTION
CORIS_MONEY_CLIENT_SECRET=VOTRE_SECRET_PRODUCTION
CORIS_MONEY_CODE_PV=VOTRE_CODE_PV_PRODUCTION

CORIS_MONEY_DEV_MODE=false
CORIS_MONEY_DEV_OTP=123456
```

### Étape 3: Basculer en Production

```powershell
# Copier la config production
Copy-Item .env.production .env -Force

# Redémarrer le serveur
if (Get-Process -Name node -ErrorAction SilentlyContinue) { 
    Stop-Process -Name node -Force
    Start-Sleep -Seconds 2
}
npm start
```

### Étape 4: Vérifier la Configuration

Quand le serveur démarre, vous devriez voir:

```
💰 ═══════════════════════════════════════════════════════════
💰 MODE PRODUCTION CORISMONEY ACTIVÉ
💰 API CorisMoney: https://api.corismoney.com/external/v1/api  ← Production !
💰 Client ID: VOTRE_CLIENT_ID_PRODUCTION
💰 Code PV: VOTRE_CODE_PV_PRODUCTION
💰 Les paiements seront RÉELS  ← ATTENTION !
💰 ═══════════════════════════════════════════════════════════
```

### Étape 5: Test de Vérification de Compte

```powershell
# Modifier le script de test pour votre numéro réel
notepad test-account-check.js
```

Dans le fichier, changez:
```javascript
const codePays = '225';
const telephone = '0799283976';  // ← Votre vrai numéro avec compte CorisMoney
```

Puis exécutez:
```powershell
node test-account-check.js
```

**Résultat attendu si tout est OK**:
```
✅ COMPTE TROUVÉ!
📊 Informations du client:
{
  "nom": "...",
  "prenom": "...",
  "solde": 50000,  ← Votre vrai solde
  ...
}

💰 Solde disponible: 50 000 FCFA
```

### Étape 6: Test de Paiement Réel (PETIT MONTANT!)

⚠️ **ATTENTION**: L'argent sera VRAIMENT débité !

```javascript
// Test avec 100 FCFA d'abord !
POST /api/payment/process-payment
{
  "codePays": "225",
  "telephone": "0799283976",  // Votre numéro
  "montant": 100,              // Petit montant pour tester !
  "codeOTP": "87634"           // Code OTP reçu par SMS
}
```

**Résultats possibles**:

✅ **Succès**:
```json
{
  "success": true,
  "message": "Paiement effectué avec succès",
  "transactionId": "TRANS123456",
  "montant": 100
}
```
→ Le paiement a fonctionné ! 100 FCFA débités de votre compte.

❌ **Solde insuffisant**:
```json
{
  "success": false,
  "message": "💰 Solde insuffisant",
  "detail": "Votre solde actuel (50 FCFA) est insuffisant pour ce paiement (100 FCFA).",
  "errorCode": "INSUFFICIENT_BALANCE"
}
```
→ Rechargez votre compte CorisMoney.

🔑 **OTP invalide**:
```json
{
  "success": false,
  "message": "🔑 Code OTP invalide ou expiré",
  "errorCode": "INVALID_OTP"
}
```
→ Redemandez un code OTP.

---

## 🔙 Revenir en Testbed

Si vous voulez revenir au mode test:

```powershell
# Restaurer la configuration testbed
Copy-Item .env.testbed.backup .env -Force

# Redémarrer
if (Get-Process -Name node -ErrorAction SilentlyContinue) { 
    Stop-Process -Name node -Force
}
npm start
```

---

## 📋 Checklist Avant Production

- [ ] **Credentials production CorisMoney obtenus**
  - [ ] URL API production
  - [ ] Client ID production
  - [ ] Client Secret production
  - [ ] Code PV production

- [ ] **Sauvegarde effectuée**
  - [ ] Copie de `.env` → `.env.testbed.backup`
  - [ ] Configuration testbed documentée

- [ ] **Tests préliminaires**
  - [ ] `test-account-check.js` retourne un compte valide
  - [ ] Le solde est affiché correctement
  - [ ] Le certificat SSL fonctionne (pas d'erreur)

- [ ] **Préparation au test de paiement**
  - [ ] Compte CorisMoney rechargé avec au moins 1000 FCFA
  - [ ] Numéro de téléphone confirmé
  - [ ] Prêt à recevoir un code OTP par SMS

- [ ] **Sécurité**
  - [ ] Premiers tests avec des petits montants (100-500 FCFA)
  - [ ] Logs activés pour surveiller les transactions
  - [ ] Base de données sauvegardée

---

## ⚠️ Problèmes Potentiels

### Problème 1: "Client introuvable" en Production

**Cause**: Le numéro n'a pas de compte CorisMoney en production non plus.

**Solution**: 
1. Vérifier que le compte existe vraiment sur CorisMoney production
2. Contacter CorisMoney pour activer le compte
3. Tester avec un autre numéro qui a un compte confirmé

---

### Problème 2: Erreur d'Authentification

```
"Paramètres erronés" ou "Authentication failed"
```

**Cause**: Credentials production incorrects.

**Solution**:
1. Vérifier CLIENT_ID, CLIENT_SECRET, CODE_PV
2. Vérifier le calcul du hash (peut être différent en production)
3. Contacter CorisMoney pour confirmer les credentials

---

### Problème 3: Certificat SSL Invalide

```
Error: certificate has expired
```

**Cause**: Certificat SSL de l'API production expiré (peu probable).

**Solution**:
1. Contacter CorisMoney immédiatement
2. Temporairement (⚠️ non recommandé en prod):
   ```javascript
   // services/corisMoneyService.js
   // Le code détecte automatiquement "testbed", pour production:
   rejectUnauthorized: false  // ⚠️ À éviter !
   ```

---

## 📊 Comparaison Testbed vs Production

| Aspect | Testbed 🧪 | Production 💰 |
|--------|-----------|--------------|
| **URL** | `testbed.corismoney.com` | `api.corismoney.com` (à confirmer) |
| **Paiements** | Simulés (aucun débit réel) | RÉELS (argent débité) |
| **Base de données** | Séparée (comptes de test) | Comptes réels clients |
| **Certificat SSL** | ❌ Expiré | ✅ Valide (normalement) |
| **Credentials** | `MYCORISLIFETEST` | À obtenir de CorisMoney |
| **OTP** | Fonctionne (SMS réel via API SMS CI) | Fonctionne (SMS réel) |

---

## 💡 Recommandation

### Pour Tester Rapidement

Si vous voulez juste **vérifier que le code fonctionne** avec un vrai compte:

1. **Gardez testbed pour le développement**
2. **Passez en production uniquement pour valider**
3. **Revenez en testbed pour le développement quotidien**

### Pour la Mise en Production Finale

Quand vous serez prêt à lancer l'application:

1. **Modifier `.env` définitivement vers production**
2. **Configurer NODE_ENV=production**
3. **Activer toutes les sécurités SSL**
4. **Monitorer les transactions en temps réel**

---

## 🚀 Commandes Rapides

### Basculer en Production
```powershell
# 1. Sauvegarder testbed
Copy-Item D:\CORIS\app_coris\mycoris-master\.env D:\CORIS\app_coris\mycoris-master\.env.testbed

# 2. Éditer .env avec vos credentials production
notepad D:\CORIS\app_coris\mycoris-master\.env

# 3. Redémarrer
cd D:\CORIS\app_coris\mycoris-master
npm start
```

### Tester un Compte
```powershell
cd D:\CORIS\app_coris\mycoris-master
node test-account-check.js
```

### Revenir en Testbed
```powershell
Copy-Item D:\CORIS\app_coris\mycoris-master\.env.testbed D:\CORIS\app_coris\mycoris-master\.env -Force
cd D:\CORIS\app_coris\mycoris-master
npm start
```

---

## 📞 Support

**Questions à poser à CorisMoney**:

1. ❓ "Quelle est l'URL de l'API production ?"
2. ❓ "Quels sont mes credentials production (Client ID, Secret, Code PV) ?"
3. ❓ "Le compte `2250799283976` existe-t-il en production ?"
4. ❓ "Comment puis-je créer des comptes de test en production ?"
5. ❓ "Y a-t-il des limites de montant pour les premiers tests ?"

---

**Résumé**: Vous avez raison ! L'API SMS est RÉELLE (vous recevez les OTP), mais CorisMoney est en TESTBED. Pour tester avec de vrais comptes, modifiez `CORIS_MONEY_BASE_URL` dans `.env` vers l'URL production CorisMoney (à obtenir de leur support) et utilisez vos credentials production. Commencez par de PETITS montants car les paiements seront RÉELS ! 💰
