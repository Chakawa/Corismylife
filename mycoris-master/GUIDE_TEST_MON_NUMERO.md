# 🧪 TEST AVEC VOTRE NUMÉRO - Guide Rapide

## ✅ Préparation Terminée

- ✅ Mode DEV activé (simulation)
- ✅ Test créé pour votre numéro : **2250576097537**
- ✅ Code OTP de test : **123456**

---

## 🚀 Comment Faire le Test

### Étape 1 : Démarrer le serveur

**Ouvrez un terminal PowerShell et lancez :**
```powershell
cd d:\CORIS\app_coris\mycoris-master
npm start
```

**Attendez de voir :**
```
🚀 Server ready at http://0.0.0.0:5000
```

### Étape 2 : Lancer VOTRE test

**Dans un NOUVEAU terminal PowerShell :**
```powershell
cd d:\CORIS\app_coris\mycoris-master
node test-mon-numero.js
```

### Étape 3 : Suivre le flux

Le test va :
1. ✅ Se connecter automatiquement
2. ✅ Envoyer un OTP à **2250576097537**
3. ⏳ Vous demander d'entrer le code OTP
   - **En mode DEV, le code est : 123456**
4. ✅ Traiter le paiement (simulation)
5. ✅ Vous devriez recevoir un SMS de confirmation !

---

## 📱 Ce Que Vous Allez Recevoir

**SMS sur votre téléphone (2250576097537) :**
```
Bonjour FOFANA CHAKA, votre paiement de 100 FCFA a été effectué 
avec succès ! Votre contrat CORIS-XXX-XXXXXXX est maintenant 
VALIDE. Merci de votre confiance. CORIS Assurance
```

---

## 🔄 Remettre en Mode PRODUCTION Après

```powershell
# Éditer le fichier .env
# Changer :
CORIS_MONEY_DEV_MODE=true
# En :
CORIS_MONEY_DEV_MODE=false

# Redémarrer le serveur
npm start
```

---

## 🎯 Résumé

**Commande 1 (Terminal 1) :**
```powershell
npm start
```

**Commande 2 (Terminal 2) :**
```powershell
node test-mon-numero.js
```

**Code OTP à entrer :**
```
123456
```

**Résultat attendu :**
- ✅ SMS reçu sur 2250576097537
- ✅ Flux complet testé
- ✅ Système vérifié

---

C'est tout ! Vous allez recevoir le SMS de confirmation sur votre téléphone 📱
