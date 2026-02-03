# 🎯 GUIDE COMPLET - PAIEMENT CORISMONEY INTÉGRÉ

## 📋 RÉCAPITULATIF DE TOUT CE QUI A ÉTÉ FAIT

### ✅ **PHASE 1 : BACKEND (Terminé)**
J'ai créé l'infrastructure backend complète pour gérer les paiements CorisMoney:

**1. Service Backend Node.js** ([mycoris-master/services/corisMoneyService.js](mycoris-master/services/corisMoneyService.js))
- ✅ Fonction `getHash256()` pour sécuriser toutes les requêtes avec SHA256
- ✅ Fonction `sendOTP()` pour envoyer le code de validation par SMS
- ✅ Fonction `paiementBien()` pour traiter le paiement avec OTP
- ✅ Fonction `getTransactionStatus()` pour vérifier le statut d'une transaction
- ✅ Fonction `getClientInfo()` pour récupérer les infos du compte marchand

**2. Routes API Backend** ([mycoris-master/routes/paymentRoutes.js](mycoris-master/routes/paymentRoutes.js))
- ✅ `POST /api/payment/send-otp` - Envoie le code OTP au client
- ✅ `POST /api/payment/process-payment` - Traite le paiement avec OTP
- ✅ `GET /api/payment/transaction-status/:id` - Statut d'une transaction
- ✅ `GET /api/payment/history` - Historique des paiements de l'utilisateur
- ✅ `GET /api/payment/client-info` - Informations du compte marchand
- ✅ Toutes les routes sécurisées avec JWT token (`verifyToken`)

**3. Base de Données PostgreSQL** (Tables créées)
```sql
-- Table pour les requêtes OTP
CREATE TABLE payment_otp_requests (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  code_pays VARCHAR(5) NOT NULL,
  telephone VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table pour les transactions
CREATE TABLE payment_transactions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  subscription_id INTEGER REFERENCES souscriptions(id),
  transaction_id VARCHAR(100) UNIQUE,
  code_pays VARCHAR(5) NOT NULL,
  telephone VARCHAR(20) NOT NULL,
  montant NUMERIC(12,2) NOT NULL,
  statut VARCHAR(50) NOT NULL,
  description TEXT,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**4. Configuration Backend** ([mycoris-master/.env](mycoris-master/.env))
```env
# Variables CorisMoney à configurer
CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=votre_client_id
CORIS_MONEY_CLIENT_SECRET=votre_secret
CORIS_MONEY_CODE_PV=votre_code_pv
```

---

### ✅ **PHASE 2 : FRONTEND FLUTTER (Terminé)**

**1. Service CorisMoney Flutter** ([mycorislife-master/lib/services/corismoney_service.dart](mycorislife-master/lib/services/corismoney_service.dart))
Communique avec l'API backend pour:
- ✅ `sendOTP()` - Demander l'envoi d'un code OTP
- ✅ `processPayment()` - Confirmer le paiement avec le code OTP
- ✅ `getTransactionStatus()` - Vérifier le statut d'un paiement
- ✅ `getPaymentHistory()` - Récupérer l'historique
- ✅ `getClientInfo()` - Informations du compte

**2. Widget Modal de Paiement** ([mycorislife-master/lib/core/widgets/corismoney_payment_modal.dart](mycorislife-master/lib/core/widgets/corismoney_payment_modal.dart))
Interface utilisateur en 3 étapes:
- **Étape 1**: Saisie du numéro de téléphone (+225...)
- **Étape 2**: Saisie du code OTP reçu par SMS
- **Étape 3**: Traitement et confirmation du paiement

Design moderne avec:
- ✅ Gradient bleu CORIS dans l'en-tête
- ✅ Icônes pour chaque étape
- ✅ Messages d'erreur clairs en rouge
- ✅ Bouton de confirmation en vert
- ✅ Loading spinner pendant le traitement
- ✅ Formatage automatique du montant (espaces tous les 3 chiffres)

---

### ✅ **PHASE 3 : INTÉGRATION DANS LES PAGES (Terminé)**

**1. Page "Mes Propositions" - Client** ([mes_propositions_page.dart](mycorislife-master/lib/features/client/presentation/screens/mes_propositions_page.dart))
- ✅ Bouton vert "**Payer maintenant**" sur chaque proposition
- ✅ Bottom sheet avec 3 options: Wave, Orange Money, **CORIS Money**
- ✅ Quand le client sélectionne CORIS Money → Modal CorisMoney s'affiche
- ✅ Extraction automatique du montant depuis la souscription
- ✅ Après paiement réussi → Rafraîchissement automatique de la liste

**2. Page "Détail Souscription" - Commercial** ([subscription_detail_screen.dart](mycorislife-master/lib/features/commercial/presentation/screens/subscription_detail_screen.dart))
- ✅ Bouton "**Marquer comme payé**" en bas de l'écran
- ✅ Options de paiement incluant CORIS Money
- ✅ Le commercial saisit le numéro du client
- ✅ Reçoit le code OTP du client et valide
- ✅ La proposition devient automatiquement un contrat

**3. Page "Souscription Sérénité" - Pendant la souscription** ([souscription_serenite.dart](mycorislife-master/lib/features/souscription/presentation/screens/souscription_serenite.dart))
- ✅ Option "**CORIS Money**" ajoutée dans la liste des modes de paiement
- ✅ Champ de saisie du numéro de téléphone CorisMoney
- ✅ Validation du numéro (minimum 8 chiffres)
- ✅ À la finalisation → Modal CorisMoney s'affiche
- ✅ Flux complet : Création souscription → Paiement CorisMoney → Transformation en contrat

**Flux détaillé de la souscription avec CorisMoney:**
1. Client remplit le formulaire de souscription (toutes les étapes)
2. À l'étape "Mode de paiement", sélectionne "CORIS Money"
3. Saisit son numéro de téléphone CorisMoney
4. Clique sur "Finaliser" → La souscription est créée avec statut "proposition"
5. Le modal CorisMoney s'affiche automatiquement
6. Client saisit son numéro → Reçoit OTP par SMS → Valide
7. Paiement traité → Statut passe automatiquement à "contrat"
8. Message de succès affiché ✅

---

## 🧪 COMMENT TESTER AVEC VOTRE COMPTE CORISMONEY

### 📱 **VOS INFORMATIONS DE TEST**
D'après l'image que vous avez fournie:
```
Nom: Fofana Chaka
Téléphone: +225 05 76 09 75 37
Compte CorisMoney: 0033000148306
```

### 🔧 **ÉTAPE 1: Configurer les identifiants CorisMoney**

1. **Ouvrir le fichier `.env`** dans `mycoris-master/`
2. **Remplacer les valeurs par vos vrais identifiants**:

```env
# CorisMoney Configuration
CORIS_MONEY_BASE_URL=https://testbed.corismoney.com/external/v1/api
CORIS_MONEY_CLIENT_ID=VOTRE_VRAI_CLIENT_ID
CORIS_MONEY_CLIENT_SECRET=VOTRE_VRAI_SECRET
CORIS_MONEY_CODE_PV=VOTRE_VRAI_CODE_PV
```

⚠️ **IMPORTANT**: Vous devez obtenir ces 3 valeurs auprès de CorisMoney:
- **CLIENT_ID** : Identifiant de votre compte marchand
- **CLIENT_SECRET** : Clé secrète de votre compte
- **CODE_PV** : Code point de vente

**Comment les obtenir?**
- Contactez le support CorisMoney ou votre gestionnaire de compte
- Demandez les accès API testbed pour votre compte marchand
- Ils vous fourniront ces 3 valeurs

---

### 🚀 **ÉTAPE 2: Démarrer le serveur backend**

```powershell
cd D:\CORIS\app_coris\mycoris-master
npm start
```

Vous devriez voir:
```
🚀 Server ready at http://0.0.0.0:5000
✅ Connexion PostgreSQL établie avec succès
```

---

### 📱 **ÉTAPE 3: Tester dans l'application Flutter**

#### **TEST 1: Payer une proposition existante (Client)**

1. **Lancer l'app Flutter client**
2. **Se connecter** avec votre compte client (Fofana Chaka)
3. **Aller dans "Mes Propositions"**
4. **Sélectionner une proposition** (ou créer une nouvelle souscription d'abord)
5. **Cliquer sur le bouton vert "Payer maintenant"**
6. **Sélectionner "CORIS Money"** dans le bottom sheet
7. **Le modal CorisMoney s'affiche**:
   - Saisir votre numéro: **+225 05 76 09 75 37**
   - Cliquer "Envoyer le code OTP"
   - Vérifier votre téléphone pour le SMS avec le code OTP
   - Saisir le code OTP reçu (6 chiffres)
   - Cliquer "Confirmer le paiement"
8. **Vérifier le résultat**:
   - Message de succès ✅
   - La proposition disparaît de la liste (devient un contrat)
   - Aller dans "Mes Contrats" pour la voir

#### **TEST 2: Paiement pendant une nouvelle souscription (Client)**

1. **Dans l'app Flutter client**
2. **Aller dans "Produits" → Choisir "CORIS SÉRÉNITÉ"**
3. **Faire une simulation** (ex: Capital 1 000 000 FCFA)
4. **Cliquer "Souscrire maintenant"**
5. **Remplir toutes les étapes**:
   - Informations personnelles
   - Bénéficiaires
   - **Mode de paiement**: Sélectionner "**CORIS Money**"
   - Saisir le numéro: **05 76 09 75 37**
   - Questionnaire médical (si applicable)
   - Récapitulatif
6. **Cliquer "Finaliser la souscription"**
7. **Le modal CorisMoney s'affiche automatiquement**:
   - Le numéro est déjà pré-rempli
   - Cliquer "Envoyer le code OTP"
   - Saisir le code OTP reçu par SMS
   - Confirmer le paiement
8. **Résultat**:
   - Message "✅ Souscription créée et payée avec succès !"
   - Redirection vers la page d'accueil ou contrats

#### **TEST 3: Commercial paie pour un client**

1. **Lancer l'app Flutter commercial**
2. **Se connecter avec un compte commercial**
3. **Aller dans "Mes Clients" → Sélectionner un client**
4. **Voir ses souscriptions → Ouvrir une proposition**
5. **Cliquer "Marquer comme payé"**
6. **Sélectionner "CORIS Money"**
7. **Saisir le numéro du client**: **+225 05 76 09 75 37**
8. **Demander au client le code OTP** (il le reçoit par SMS)
9. **Saisir le code OTP**
10. **Confirmer** → La proposition devient un contrat

---

### 🔍 **ÉTAPE 4: Vérifier dans la base de données**

Après un paiement réussi, vérifiez les enregistrements:

```sql
-- Voir les dernières requêtes OTP
SELECT * FROM payment_otp_requests 
ORDER BY created_at DESC 
LIMIT 5;

-- Voir les dernières transactions
SELECT 
  id, 
  subscription_id, 
  transaction_id, 
  telephone, 
  montant, 
  statut, 
  created_at 
FROM payment_transactions 
ORDER BY created_at DESC 
LIMIT 5;

-- Vérifier le changement de statut de la souscription
SELECT 
  id, 
  numero_souscription, 
  statut, 
  montant,
  date_souscription,
  updated_at 
FROM souscriptions 
WHERE statut = 'contrat' 
ORDER BY updated_at DESC 
LIMIT 5;
```

---

## 🎨 **APERÇU VISUEL DU MODAL CORISMONEY**

```
┌────────────────────────────────────┐
│  💳 Paiement CorisMoney            │  ← Gradient bleu CORIS
│     Paiement sécurisé         [X]  │
├────────────────────────────────────┤
│                                    │
│  ┌──────────────────────────────┐ │
│  │    Montant à payer           │ │
│  │    250 000 FCFA              │ │  ← Montant formaté
│  └──────────────────────────────┘ │
│                                    │
│  Numéro de téléphone               │
│  ┌──────────────────────────────┐ │
│  │ 📱 +225 07 00 00 00 00       │ │  ← Input téléphone
│  └──────────────────────────────┘ │
│                                    │
│  ┌──────────────────────────────┐ │
│  │   Envoyer le code OTP        │ │  ← Bouton bleu CORIS
│  └──────────────────────────────┘ │
│                                    │
└────────────────────────────────────┘

        ↓ Après envoi OTP ↓

┌────────────────────────────────────┐
│  💳 Paiement CorisMoney            │
│     Paiement sécurisé         [X]  │
├────────────────────────────────────┤
│                                    │
│  Code OTP                          │
│  Saisissez le code reçu par SMS    │
│                                    │
│  ┌──────────────────────────────┐ │
│  │ 🔒 [  0  0  0  0  0  0  ]    │ │  ← Input OTP (6 chiffres)
│  └──────────────────────────────┘ │
│                                    │
│  ← Modifier le numéro  Renvoyer → │
│                                    │
│  ┌──────────────────────────────┐ │
│  │   Confirmer le paiement ✅   │ │  ← Bouton vert
│  └──────────────────────────────┘ │
│                                    │
└────────────────────────────────────┘
```

---

## 📊 **FLUX TECHNIQUE COMPLET**

### **Diagramme du flux de paiement:**

```
┌─────────────────┐
│  App Flutter    │
│   (Client)      │
└────────┬────────┘
         │
         │ 1. Saisit téléphone et clique "Envoyer OTP"
         ↓
┌─────────────────────────────────────────────┐
│  Service Flutter (corismoney_service.dart)  │
│  → sendOTP(codePays, telephone)             │
└────────┬────────────────────────────────────┘
         │
         │ 2. HTTP POST /api/payment/send-otp
         ↓
┌─────────────────────────────────────────────┐
│  Backend Node.js (paymentRoutes.js)         │
│  → Valide le token JWT                      │
│  → Appelle corisMoneyService.sendOTP()      │
└────────┬────────────────────────────────────┘
         │
         │ 3. Calcule le hash SHA256
         │    hash = SHA256(clientId + telephone + clientSecret)
         ↓
┌─────────────────────────────────────────────┐
│  API CorisMoney Externe                     │
│  POST /otp/phone                            │
│  Headers:                                   │
│    - clientId: VOTRE_CLIENT_ID              │
│    - hashParam: hash_calculé                │
│  Body: { codePays: "CI", telephone: "..." } │
└────────┬────────────────────────────────────┘
         │
         │ 4. CorisMoney envoie SMS avec code OTP au client
         ↓
┌─────────────────┐
│   Téléphone     │
│   du client     │  ← SMS reçu: "Votre code OTP est: 123456"
│  +225 05 76...  │
└────────┬────────┘
         │
         │ 5. Client saisit le code OTP dans le modal
         ↓
┌─────────────────────────────────────────────┐
│  Service Flutter                            │
│  → processPayment(subscriptionId, ...)      │
└────────┬────────────────────────────────────┘
         │
         │ 6. HTTP POST /api/payment/process-payment
         ↓
┌─────────────────────────────────────────────┐
│  Backend Node.js                            │
│  → Valide le token JWT                      │
│  → Appelle corisMoneyService.paiementBien() │
└────────┬────────────────────────────────────┘
         │
         │ 7. Calcule le hash SHA256
         │    hash = SHA256(clientId + codePays + telephone + montant + codeOTP + clientSecret)
         ↓
┌─────────────────────────────────────────────┐
│  API CorisMoney                             │
│  POST /payment/goods                        │
│  Vérifie le code OTP et débite le compte    │
└────────┬────────────────────────────────────┘
         │
         │ 8. Retourne le statut du paiement
         ↓
┌─────────────────────────────────────────────┐
│  Backend Node.js                            │
│  → Enregistre dans payment_transactions     │
│  → Met à jour souscriptions.statut → 'payé' │
│  → Retourne le succès à Flutter             │
└────────┬────────────────────────────────────┘
         │
         │ 9. Succès retourné au client
         ↓
┌─────────────────┐
│  App Flutter    │
│  → Modal affiche │
│     "✅ Paiement │
│      effectué!"  │
└─────────────────┘
```

---

## ⚠️ **POINTS IMPORTANTS**

### **Sécurité**
- ✅ Toutes les requêtes utilisent le token JWT de l'utilisateur connecté
- ✅ Hash SHA256 pour chaque appel à l'API CorisMoney
- ✅ Code OTP à 6 chiffres envoyé par SMS
- ✅ Les secrets ne sont jamais exposés au frontend
- ✅ Enregistrement de toutes les transactions dans la base

### **Codes pays supportés**
```dart
CI = Côte d'Ivoire (+225)
BF = Burkina Faso (+226)
CM = Cameroun (+237)
TG = Togo (+228)
BJ = Bénin (+229)
NG = Nigeria (+234)
```

### **Format du numéro de téléphone**
- **Avec indicatif**: `+225 05 76 09 75 37`
- **Sans indicatif**: `05 76 09 75 37` (le code pays CI est ajouté automatiquement)
- **Minimum**: 8 chiffres
- **Maximum**: 15 chiffres

### **Gestion des erreurs**
Le modal affiche automatiquement:
- ❌ "Numéro de téléphone invalide"
- ❌ "Code OTP incorrect"
- ❌ "Erreur de connexion"
- ❌ "Solde insuffisant"
- ❌ "Transaction échouée"

---

## 🐛 **RÉSOLUTION DES PROBLÈMES**

### ❌ **"Erreur de connexion" dans l'app**
**Solutions:**
1. Vérifier que le serveur backend tourne:
   ```powershell
   # Dans un terminal
   cd D:\CORIS\app_coris\mycoris-master
   npm start
   ```
2. Vérifier que l'URL dans `AppConfig.baseUrl` est correcte:
   ```dart
   // Pour émulateur Android
   static String baseUrl = 'http://10.0.2.2:5000';
   
   // Pour appareil physique (remplacer par votre IP)
   static String baseUrl = 'http://192.168.1.XX:5000';
   ```

### ❌ **"Code OTP invalide"**
**Solutions:**
1. Vérifier que les identifiants CorisMoney sont corrects dans `.env`
2. Demander un nouveau code (cliquer "Renvoyer le code")
3. Vérifier que le numéro de téléphone est correct
4. S'assurer que vous avez bien reçu le SMS

### ❌ **"Impossible de récupérer le montant"**
**Solution:** Le montant est extrait automatiquement depuis la souscription. Si vide, vérifier que la prime a bien été calculée lors de la simulation.

### ❌ **Le modal ne s'affiche pas**
**Solutions:**
1. Vérifier l'import:
   ```dart
   import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
   ```
2. Faire un hot restart (R majuscule) ou redémarrer l'app

### ❌ **"401 Unauthorized"**
**Solution:** Le token JWT a expiré. Se déconnecter puis se reconnecter.

---

## 📝 **CHECKLIST AVANT LE TEST**

- [ ] Serveur backend démarré (`npm start`)
- [ ] Base de données PostgreSQL active
- [ ] Tables `payment_otp_requests` et `payment_transactions` créées
- [ ] Fichier `.env` configuré avec les vrais identifiants CorisMoney
- [ ] Application Flutter compilée et installée
- [ ] Compte client créé dans l'app (Fofana Chaka)
- [ ] Téléphone du client prêt à recevoir des SMS (+225 05 76 09 75 37)
- [ ] Solde suffisant sur le compte CorisMoney pour le test

---

## 🎉 **CE QUE VOUS POUVEZ FAIRE MAINTENANT**

1. ✅ **Créer une souscription** en choisissant CORIS Money comme mode de paiement
2. ✅ **Payer une proposition existante** directement depuis "Mes Propositions"
3. ✅ **En tant que commercial**, payer pour un client
4. ✅ **Voir les transactions** dans la base de données
5. ✅ **Vérifier le changement de statut** (proposition → contrat)

---

## 📞 **SUPPORT**

Si vous rencontrez des problèmes:
1. Vérifier les logs du serveur backend (terminal où `npm start` tourne)
2. Vérifier les logs Flutter (terminal où l'app Flutter tourne)
3. Consulter la table `payment_transactions` pour voir les erreurs enregistrées

---

**Date de création**: 3 février 2026  
**Serveur backend**: http://localhost:5000 (actif ✅)  
**Environnement**: Testbed CorisMoney  
**Statut**: 🟢 Prêt pour les tests
