# 🧪 MODE DÉVELOPPEMENT CORISMONEY - GUIDE RAPIDE

## ✅ Problème résolu !

Le message "Paramètres erronés !" venait du fait que vous n'avez pas encore les **vrais identifiants CorisMoney** pour le testbed.

## 🎯 Solution : Mode Développement

J'ai ajouté un **mode développement** qui simule complètement le paiement CorisMoney **sans appeler l'API réelle**.

### Configuration actuelle (.env)

```env
# Mode de développement pour CorisMoney
CORIS_MONEY_DEV_MODE=true          # ✅ Active le mode simulation
CORIS_MONEY_DEV_OTP=123456         # Code OTP de test à utiliser
```

## 🚀 Comment tester maintenant

### Étape 1: Redémarrer le serveur
```powershell
cd D:\CORIS\app_coris\mycoris-master
npm start
```

**Vous verrez au démarrage :**
```
🧪 ═══════════════════════════════════════════════════════════
🧪 MODE DÉVELOPPEMENT CORISMONEY ACTIVÉ
🧪 Les paiements seront SIMULÉS (aucun appel API réel)
🧪 Code OTP de test: 123456
🧪 Pour activer l'API réelle: CORIS_MONEY_DEV_MODE=false dans .env
🧪 ═══════════════════════════════════════════════════════════
```

### Étape 2: Tester le flux complet

1. **Ouvrir l'app** et aller sur une souscription
2. **Sélectionner "CORIS Money"** comme mode de paiement
3. **Saisir un numéro** : `0576097537` ou n'importe quel numéro
4. **Cliquer sur "Envoyer le code"**

**Dans la console du serveur, vous verrez :**
```
📨 ===== REQUÊTE ENVOI OTP =====
User ID: 2
Code Pays: 225
Téléphone: 576097537
📱 ===== ENVOI CODE OTP CORISMONEY =====
Code Pays: 225
Téléphone: 576097537
🧪 MODE DEV: Simulation d'envoi OTP
🔐 ═══════════════════════════════════════
🔐 CODE OTP DE TEST: 123456
🔐 ═══════════════════════════════════════
✅ Simulation réussie
```

5. **Saisir le code OTP** : `123456`
6. **Confirmer le paiement**

**Dans la console :**
```
💳 ===== PAIEMENT CORISMONEY =====
Montant: 30000 FCFA
Code OTP fourni: 123456
🧪 MODE DEV: Simulation de paiement
✅ Code OTP validé
💰 Paiement simulé de 30000 FCFA
🎉 Simulation de paiement réussie !
```

## 📊 Avantages du mode développement

✅ **Pas besoin des identifiants réels** pour tester
✅ **Paiements instantanés** - pas d'attente serveur
✅ **Code OTP visible** dans la console (123456)
✅ **Aucun risque** - aucun appel API externe
✅ **Base de données mise à jour** - toutes les transactions sont enregistrées
✅ **Workflow complet testé** - même flux qu'en production

## 🔄 Basculer en mode production

Quand vous aurez les **vrais identifiants CorisMoney** :

### 1. Obtenir les identifiants de CORIS
Demandez à CORIS de vous fournir :
- `CLIENT_ID` (Identifiant marchand)
- `CLIENT_SECRET` (Clé secrète)
- `CODE_PV` (Code point de vente)

### 2. Modifier le .env
```env
# Configuration CorisMoney (Paiement)
CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=votre_vrai_client_id
CORIS_MONEY_CLIENT_SECRET=votre_vraie_secret
CORIS_MONEY_CODE_PV=votre_code_pv

# Désactiver le mode dev
CORIS_MONEY_DEV_MODE=false
```

### 3. Redémarrer le serveur
Le système utilisera alors l'API CorisMoney réelle.

## 🎯 Tests recommandés en mode DEV

Testez tous les scénarios :

### ✅ Scénario 1: Paiement réussi
- Code OTP : `123456`
- Résultat : ✅ Paiement accepté

### ❌ Scénario 2: Code OTP incorrect
- Code OTP : `000000` ou autre
- Résultat : ❌ "Code OTP incorrect"

### ✅ Scénario 3: Tous les produits
Testez le paiement CorisMoney sur :
- SÉRÉNITÉ ✅
- ÉTUDE ✅
- FAMILIS ✅
- RETRAITE ✅
- MON BON PLAN ✅
- ÉPARGNE ✅
- ASSURE PRESTIGE ✅
- FLEX ✅

## 📝 Notes importantes

1. **Base de données** : Toutes les transactions (même simulées) sont enregistrées dans `payment_transactions`
2. **Logs complets** : Chaque étape est loggée pour faciliter le débogage
3. **Code OTP modifiable** : Changez `CORIS_MONEY_DEV_OTP` dans .env pour un autre code
4. **Production** : N'oubliez pas de mettre `CORIS_MONEY_DEV_MODE=false` en production !

## 🚀 Prêt pour les tests !

Vous pouvez maintenant tester **tout le flux de paiement CorisMoney** sans avoir besoin des identifiants réels ! 🎉

Le code OTP à utiliser est : **123456**
