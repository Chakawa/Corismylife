# 🧪 Guide de Test - Envoi OTP CorisMoney

## ✅ Modifications apportées

### 1. **Correction du débordement des boutons**
- Remplacement de `TextButton` par `TextButton.icon` avec `Flexible`
- Textes raccourcis: "← Modifier le numéro" → "Modifier" avec icône
- Textes raccourcis: "Renvoyer le code" → "Renvoyer" avec icône
- Ajout de `padding` réduit pour optimiser l'espace

### 2. **Ajout de logs détaillés**
Pour vérifier si le code OTP est réellement envoyé, des logs ont été ajoutés :

#### Dans `paymentRoutes.js` :
```
📨 ===== REQUÊTE ENVOI OTP =====
User ID: [id]
Code Pays: [code]
Téléphone: [numéro]
```

#### Dans `corisMoneyService.js` :
```
📱 ===== ENVOI CODE OTP CORISMONEY =====
Code Pays: [code]
Téléphone: [numéro]
Hash généré: [hash...]
URL: https://testbed.corismoney.com/...
```

#### Si succès :
```
✅ Code OTP envoyé avec succès
Réponse API: { ... }
✅ Enregistré en BDD
```

#### Si erreur :
```
❌ Erreur lors de l'envoi du code OTP
Code statut: [status]
```

## 🔍 Comment vérifier si l'OTP est envoyé

### Étape 1: Démarrer le serveur backend
```powershell
cd D:\CORIS\app_coris\mycoris-master
node server.js
```

### Étape 2: Observer la console
Quand vous cliquez sur "Envoyer le code" ou "Renvoyer" :

1. **Vous devriez voir dans la console du serveur Node.js :**
   ```
   📨 ===== REQUÊTE ENVOI OTP =====
   User ID: 123
   Code Pays: 225
   Téléphone: 0123456789
   📱 ===== ENVOI CODE OTP CORISMONEY =====
   ...
   ```

2. **Si l'envoi réussit :**
   ```
   ✅ Code OTP envoyé avec succès
   Réponse API: { "status": "success", ... }
   ✅ Enregistré en BDD
   ```

3. **Si l'envoi échoue :**
   ```
   ❌ Erreur lors de l'envoi du code OTP
   Code statut: 400/500
   ```

### Étape 3: Vérifier en base de données
```sql
-- Voir les dernières demandes OTP
SELECT * FROM payment_otp_requests 
ORDER BY created_at DESC 
LIMIT 10;
```

## 🎯 Points de vérification

### ✅ L'OTP est envoyé SI :
1. Vous voyez `📱 ===== ENVOI CODE OTP CORISMONEY =====` dans la console
2. Vous voyez `✅ Code OTP envoyé avec succès`
3. Un enregistrement apparaît dans `payment_otp_requests`
4. L'application affiche "Code OTP envoyé par SMS" (SnackBar vert)

### ❌ L'OTP N'est PAS envoyé SI :
1. Vous voyez `❌ Erreur lors de l'envoi du code OTP`
2. Code statut 400 = Mauvais paramètres ou hash incorrect
3. Code statut 502 = Serveur CorisMoney testbed indisponible
4. Rien ne s'affiche dans les logs = Le backend ne reçoit pas la requête

## 🐛 Problèmes courants

### Problème 1: Serveur testbed CorisMoney hors ligne
**Symptôme :** 502 Bad Gateway
**Cause :** Le serveur `testbed.corismoney.com` est parfois hors ligne
**Solution :** Attendre que le serveur soit de nouveau en ligne

### Problème 2: Hash incorrect
**Symptôme :** Erreur 400 "Invalid hash"
**Cause :** Les identifiants CorisMoney (CLIENT_ID, SECRET) sont incorrects
**Solution :** Vérifier les credentials dans `.env`

### Problème 3: Certificat SSL expiré
**Symptôme :** "certificate has expired"
**Cause :** Le certificat SSL du testbed est expiré
**Solution :** Déjà contourné avec `rejectUnauthorized: false` en mode développement

## 📞 Test avec un vrai numéro

Pour tester avec un vrai numéro ivoirien :
1. Sélectionner le code pays **+225** (Côte d'Ivoire)
2. Entrer votre numéro sans le 0 initial : `0123456789` → `123456789`
3. Cliquer sur "Envoyer le code"
4. Vérifier la console pour voir les logs
5. **SI le serveur CorisMoney est en ligne**, vous devriez recevoir un SMS réel

## 🔐 Code OTP de test

En mode testbed, CorisMoney peut utiliser des codes OTP fixes pour les tests :
- Code de test courant : `000000` ou `123456`
- Vérifier la documentation CorisMoney pour les codes de test valides

## 📊 Résumé des fichiers modifiés

1. **corismoney_payment_modal.dart** - Interface utilisateur des boutons
2. **corisMoneyService.js** - Logs détaillés de l'envoi OTP
3. **paymentRoutes.js** - Logs de réception de la requête

Tous ces fichiers logguent maintenant les actions pour faciliter le débogage ! 🚀
