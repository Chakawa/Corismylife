# 🌊 WAVE PAYMENT - GUIDE DE DÉPLOIEMENT COMPLET

Date: 24 Février 2026  
Statut: ✅ 95% PRÊT - Dernière configuration requise

---

## 🎯 RÉSUMÉ EXECUTIF

Votre intégration Wave Payment est **COMPLÈTE** sauf pour une dernière étape : **configurer les URLs et le Webhook Secret**.

### Ce qui est FAIT ✅
- ✅ Intégration Flutter complète (toutes les pages de souscription)
- ✅ Backend Wave Checkout Service
- ✅ Routes API Wave (`/wave/create-session`, `/wave/status`, `/wave/webhook`)
- ✅ Gestion des transactions en base de données
- ✅ Tables notifications corrigées (user_id, updated_at)
- ✅ Pages de réponse Wave (success/error)
- ✅ Wave API Key configurée en production

### Ce qui faut ENCORE FAIRE ⏳
1. ✏️ Remplacer les URLs placeholder dans `.env`
2. 🔐 Ajouter le Webhook Secret depuis Wave Dashboard
3. 🚀 Redémarrer le serveur (une fois que le port se libère)
4. 🧪 Test paiement Wave de bout en bout

---

## 📋 INFORMATIONS REQUISES DE CORIS ASSURANCE

Pour que Wave fonctionne, il faut fournir à Wave :

### 1️⃣ Données d'Entreprise (à Wave)
```
Nom: CORIS Assurance Vie
Pays: Côte d'Ivoire (CI)
Devise: XOF (Franc CFA)
Email: [À REMPLIR: contact@coris-assurance.ci]
Téléphone: [À REMPLIR: +225 XXXXXXXXX]
```

### 2️⃣ Compte Merchant Wave (À Wave)
Une fois créé, Wave vous fournira :
- ✅ `WAVE_API_KEY` (vous l'avez déjà)
- ⏳ `WAVE_WEBHOOK_SECRET` (À RÉCUPÉRER)

### 3️⃣ Domaine de Votre Application (À VOUS DE DÉCIDER)
C'est **VOTRE domaine** où l'appli tourne :

#### Option A: Développement Local (ngrok)
Si vous travaillez en local avec un tunnel :
```
Base URL: https://abc123.ngrok-free.app
```

#### Option B: Serveur de Staging
```
Base URL: https://staging-api.corisassurance.com
```

#### Option C: Serveur de Production
```
Base URL: https://api.corisassurance.com
```

---

## 🔧 CONFIGURATION FINALE REQUISE

### ÉTAPE 1: Déterminez Votre Domaine

**Posez-vous cette question :** 
> "Où est hébergé mon serveur backend Node.js en ce moment ?"

Réponse possible :
- **Local** : `http://localhost:5000` (ou avec ngrok)
- **Domaine custom** : `https://xyz.com`
- **Instance cloud** : `https://instance.region.cloud`

### ÉTAPE 2: Mettez à Jour `.env`

Ouvrez `d:\CORIS\app_coris\mycoris-master\.env` et remplacez :

```env
# AVANT (MAUVAIS) ❌
WAVE_SUCCESS_URL=https://votre-domaine.com/wave-success
WAVE_ERROR_URL=https://votre-domaine.com/wave-error
WAVE_WEBHOOK_URL=https://votre-domaine.com/api/payment/wave/webhook
WAVE_WEBHOOK_SECRET=VOTRE_WEBHOOK_SECRET_WAVE_ICI

# APRÈS (VOTRE DOMAINE) ✅
# Exemple avec ngrok:
WAVE_SUCCESS_URL=https://abc123.ngrok-free.app/wave-success
WAVE_ERROR_URL=https://abc123.ngrok-free.app/wave-error
WAVE_WEBHOOK_URL=https://abc123.ngrok-free.app/api/payment/wave/webhook
WAVE_WEBHOOK_SECRET=[À OBTENIR DEPUIS WAVE DASHBOARD]

# OU Exemple avec domaine:
WAVE_SUCCESS_URL=https://api.corisassurance.com/wave-success
WAVE_ERROR_URL=https://api.corisassurance.com/wave-error
WAVE_WEBHOOK_URL=https://api.corisassurance.com/api/payment/wave/webhook
WAVE_WEBHOOK_SECRET=[À OBTENIR DEPUIS WAVE DASHBOARD]
```

### ÉTAPE 3: Configurez Wave Dashboard

1. Accédez à https://dashboard.wave.com
2. Allez dans **Settings → Webhooks**
3. Copiez le **Webhook Secret**
4. Collez-le dans `.env`

### ÉTAPE 4: Redémarrez le Serveur

```powershell
# Arrêtez le serveur en cours (Ctrl+C dans le terminal)
# Attendez quelques secondes...
# Relancez
npm start
```

---

## 🧪 TEST COMPLET DU PAIEMENT WAVE

### Prérequis
- ✅ Backend redémarré avec nouvelles URLs
- ✅ App Flutter compilée (pour tester)
- ✅ Compte Wave actif

### Procédure de Test

1. **Lancer l'app Flutter**
   ```
   flutter run
   ```

2. **Créer une souscription test**
   - Ouvrir un produit (Serenite, Familis, etc.)
   - Remplir le formulaire
   - **Important:** Remplir les infos du téléphone pour Wave

3. **Paiement Wave**
   - Sélectionner **Wave** comme méthode
   - Cliquer sur **Payer**

4. **Vérifications**
   
   **✅ Devrait se passer :**
   - [ ] SnackBar "Initialisation du paiement Wave..."
   - [ ] URL Wave s'ouvre (navigateur ou app Wave)
   - [ ] Page Wave Checkout affichée
   - [ ] Simulation ou vrai paiement selon mode
   
   **✅ Après paiement réussi :**
   - [ ] Redirection vers `/wave-success`
   - [ ] Page HTML affichée "✅ Paiement Réussi"
   - [ ] Notification reçue dans l'app
   - [ ] Contrat généré en base

   **✅ En cas d'erreur :**
   - [ ] Redirection vers `/wave-error`
   - [ ] Message d'erreur affiché
   - [ ] Possibilité de réessayer

5. **Vérifications Logs Backend**

   Dans la console Node.js, cherchez :
   ```
   ✅ Token valide
   🌊 CREATE WAVE CHECKOUT SESSION
   📊 Session Wave créée
   ✅ Paiement confirmé
   ```

6. **Vérifications Base de Données**

   ```sql
   -- Vérifier la transaction
   SELECT * FROM payment_transactions 
   WHERE provider = 'Wave' 
   ORDER BY created_at DESC 
   LIMIT 1;
   
   -- Vérifier la notification
   SELECT * FROM notifications 
   WHERE user_id = YOUR_USER_ID 
   ORDER BY created_at DESC;
   ```

---

## 📊 CHECKLIST DE DÉPLOIEMENT

### Configuration
- [ ] Domaine de base déterminé (local/staging/prod)
- [ ] `WAVE_SUCCESS_URL` mis à jour dans `.env`
- [ ] `WAVE_ERROR_URL` mis à jour dans `.env`
- [ ] `WAVE_WEBHOOK_URL` mis à jour dans `.env`
- [ ] `WAVE_WEBHOOK_SECRET` récupéré et mis à jour
- [ ] ✅ `WAVE_API_KEY` OK
- [ ] ✅ `WAVE_DEV_MODE=false` OK

### Serveur
- [ ] Port 5000 libéré (ou nouveau port configuré)
- [ ] Serveur backend redémarré (`npm start`)
- [ ] Logs montrent pas d'erreur de démarrage
- [ ] `/wave-success` retourne HTML OK
- [ ] `/wave-error` retourne HTML OK

### Base de Données
- [ ] Table `notifications` contient `user_id` ✅
- [ ] Table `notifications` contient `updated_at` ✅
- [ ] Table `notifications_admin` créée ✅
- [ ] Table `payment_transactions` contient `provider` ✅
- [ ] Table `payment_transactions` contient `session_id` ✅
- [ ] Table `subscriptions` contient `payment_method` ✅
- [ ] Table `subscriptions` contient `payment_transaction_id` ✅

### Application Flutter
- [ ] App compilée avec derniers changements
- [ ] Service `wave_service.dart` importé ✅
- [ ] Handler `wave_payment_handler.dart` importé ✅
- [ ] Toutes pages de souscription intégrées ✅

### Test
- [ ] Souscription + Wave payment testée
- [ ] URL Wave s'ouvre correctement
- [ ] Page success/error s'affiche
- [ ] Transaction enregistrée en base
- [ ] Notification créée
- [ ] Contrat généré

---

## 🆘 DÉPANNAGE

### ❌ "Erreur: Le port 5000 est déjà utilisé"
```
Causes: Autre processus Node utilise le port
Fix 1: Attendre que le processus existe se termine
Fix 2: Relancer le terminal
Fix 3: Changer le port: PORT=3001 npm start
```

### ❌ "Impossible d'ouvrir Wave"
```
Cause: Backend ne retourne pas launchUrl
Symptôme: Erreur "Impossible d'ouvrir Wave" dans l'app

Vérification:
1. WAVE_API_KEY est correct dans .env? 
2. WAVE_DEV_MODE=false?
3. Backend a redémarré?
4. Logs montrent "Session Wave créée"?

Fix:
- Vérifier WAVE_API_KEY production: wave_ci_prod_...
- Redémarrer backend
- Vérifier logs pendant le paiement
```

### ❌ "Erreur création notification"
```
Symptôme: "colonne user_id n'existe pas"
Fix: Migrations SQL non exécutées

Vérification:
1. Connectez-vous à la base:
   psql -h 185.98.138.168 -U db_admin -d mycorisdb
   
2. Vérifiez la colonne:
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'notifications' AND column_name = 'user_id';
   
3. Si manquante, réexécutez:
   psql -h 185.98.138.168 -U db_admin -d mycorisdb \
     -f migrations/fix_notifications_user_id.sql
```

### ❌ "Webhook non reçu de Wave"
```
Symptôme: Webhook endpoint ne reçoit rien

Causes:
1. WAVE_WEBHOOK_SECRET absent ou incorrect
2. WAVE_WEBHOOK_URL incorrecte
3. Domaine non whitelisté sur Wave Dashboard

Fix:
1. Vérifier WAVE_WEBHOOK_SECRET dans .env
2. Vérifier WAVE_WEBHOOK_URL est accessible publiquement
3. Sur Wave Dashboard: ajouter le domaine dans Approved Domains
```

---

## 📞 INTERLOCUTEURS

### Wave Support
- **Site** : https://wave.com
- **Dashboard** : https://dashboard.wave.com
- **Documentation** : https://developers.wave.com
- **Support** : support@wave.com

### CORIS Interne
**À contacter pour :**
- Données d'entreprise à fournir à Wave
- Validation du domaine production
- Clés d'API additionnelles

---

## 💡 RAPPELS IMPORTANTS

### ✅ Points Clés
1. **Les URLs DOIVENT être publiquement accessibles** (Wave doit pouvoir les atteindre)
2. **Le Webhook Secret est sensible** (ne pas partager)
3. **Tester d'abord en mode DEV** (si possible)
4. **Logs sont votre ami** (vérifier lors de problème)

### ⚠️ Pièges Communs
- ❌ URLs restent en "votre-domaine.com" (placeholder)
- ❌ Webhook Secret manquant ou mauvais
- ❌ Port 5000 occupé
- ❌ Migrations SQL non exécutées
- ❌ Certificat SSL manquant (pour HTTPS)

### 📈 Performance
- Timeouts: 15-20 secondes pour la création de session
- Polling: 8 tentatives × 3 secondes = 24 secondes max
- Webhook: Doit répondre en <30 secondes

---

## ✅ PROCHAINE ACTION

**👉 À FAIRE MAINTENANT :**

1. **Déterminez le domaine** (local/staging/prod)
2. **Mettez à jour `.env`** avec les URLs réelles
3. **Récupérez le Webhook Secret** depuis Wave Dashboard
4. **Ajoutez-le à `.env`**
5. **Redémarrez le serveur**
6. **Testez un paiement Wave**

Une fois ces étapes faites, Wave Payment sera **100% OPÉRATIONNEL** ! 🎉

---

**Document créé : 24/02/2026**  
**Version : 1.0**  
**Statut : À Action Suite**
