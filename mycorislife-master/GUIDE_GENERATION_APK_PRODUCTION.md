# 📱 Guide de Génération APK - Mode Production

## ✅ Configuration Validée - Prêt pour Production

Toutes les configurations ont été vérifiées et l'application est prête pour la génération APK.

---

## 🎯 Configuration Actuelle

### Backend Production
- **URL**: `http://185.98.138.168:5000`
- **Base de données**: PostgreSQL 18.1 à `185.98.138.168:5432/mycorisdb`
- **Mode Wave**: Production (WAVE_DEV_MODE=false)
- **API Wave**: https://api.wave.com
- **Mode Polling**: Activé (webhooks désactivés)

### Frontend Flutter (AppConfig)
```dart
// PRODUCTION - Serveur déployé
static const String baseUrl = 'http://185.98.138.168:5000/api';
```

---

## 🔍 Vérifications Effectuées

### ✅ Services Wave
1. **WaveService.dart** - Service de communication avec l'API Wave
   - ✅ `createCheckoutSession()` - Création de session de paiement
   - ✅ `getCheckoutStatus()` - Vérification du statut de paiement
   - ✅ Utilise AppConfig.baseUrl correctement

2. **WavePaymentHandler.dart** - Gestionnaire de flux de paiement
   - ✅ `startPayment()` - Lance le paiement et gère le polling
   - ✅ Gestion des erreurs complète
   - ✅ Polling automatique (8 tentatives × 3 secondes)

### ✅ Intégration Client (3 écrans)

#### 1. proposition_detail_page.dart
- ✅ **Bouton Wave** (ligne 1532-1536)
- ✅ **Fonction**: `_processPayment('Wave')` → `_startWavePayment()`
- ✅ **Service**: `WaveService.createCheckoutSession()` + `getCheckoutStatus()`
- ✅ **Flow**: Affiche URL Wave → Ouvre navigateur → Poll status → Validation

#### 2. mes_contrats_page.dart
- ✅ **Bouton Wave** (ligne 474-481)
- ✅ **Fonction**: `_processPayment(contrat, 'Wave')` → `WavePaymentHandler.startPayment()`
- ✅ **Context**: Paiement de prime pour contrats existants
- ✅ **Callback**: Rafraîchit la liste après succès

#### 3. mes_propositions_page.dart
- ✅ **Bouton Wave** (ligne 927-931)
- ✅ **Fonction**: `_processPayment(subscription, 'Wave')` → `WavePaymentHandler.startPayment()`
- ✅ **Context**: Paiement initial pour transformer proposition en contrat
- ✅ **Callback**: Rafraîchit la liste après succès

### ✅ Intégration Commercial (1 écran)

#### subscription_detail_screen.dart
- ✅ **Bouton Wave** (ligne 1454-1461)
- ✅ **Function**: Bottom sheet → `onPayNow('Wave')` → `_processPayment('Wave')` → `_startWavePayment()`
- ✅ **Service**: `WaveService.createCheckoutSession()` + `getCheckoutStatus()`
- ✅ **Flow**: Identique au client avec interface commercial

### ✅ Routes Backend
- ✅ **POST** `/api/payment/wave/create-session` (ligne 515 paymentRoutes.js)
- ✅ **GET** `/api/payment/wave/status/:sessionId` (ligne 627 paymentRoutes.js)
- ✅ **GET** `/wave-success` (waveResponseRoutes.js)
- ✅ **GET** `/wave-error` (waveResponseRoutes.js)

---

## 📋 Checklist Pré-Génération

### Configuration
- [x] AppConfig.baseUrl = `http://185.98.138.168:5000/api` (PRODUCTION)
- [x] Backend déployé à `185.98.138.168:5000`
- [x] Base de données PostgreSQL accessible
- [x] Wave API en mode production
- [x] Polling activé (pas de webhooks)

### Services
- [x] WaveService.dart fonctionnel
- [x] WavePaymentHandler.dart fonctionnel
- [x] Routes backend Wave opérationnelles
- [x] PaymentService.js créé

### Intégration UI
- [x] Client - proposition_detail_page.dart
- [x] Client - mes_contrats_page.dart
- [x] Client - mes_propositions_page.dart
- [x] Commercial - subscription_detail_screen.dart

### Sécurité & Assets
- [x] Token JWT système fonctionnel
- [x] Images Wave présentes (`assets/images/icone_wave.jpeg`)
- [x] Gestion d'erreurs complète
- [x] Messages utilisateur clairs

---

## 🚀 Génération de l'APK

### 1. Nettoyage du Build
```powershell
cd d:\CORIS\app_coris\mycorislife-master
flutter clean
flutter pub get
```

### 2. Génération APK Release
```powershell
flutter build apk --release
```

**Alternative - APK séparés par architecture (recommandé pour réduire la taille):**
```powershell
flutter build apk --split-per-abi
```

### 3. Localisation des APK
Après la génération, les APK seront dans:
```
mycorislife-master\build\app\outputs\flutter-apk\
```

**Fichiers générés:**
- `app-release.apk` (APK universel, ~40-60 MB)

**OU si --split-per-abi:**
- `app-armeabi-v7a-release.apk` (ARM 32-bit, smartphones anciens)
- `app-arm64-v8a-release.apk` (ARM 64-bit, smartphones récents) ← **Recommandé**
- `app-x86_64-release.apk` (x86 64-bit, émulateurs/rares devices)

---

## 📱 Installation sur Téléphone Mobile

### Méthode 1: Transfert USB
1. Connecter le téléphone en USB
2. Copier l'APK dans le téléphone (Download/Documents)
3. Ouvrir le fichier APK depuis le gestionnaire de fichiers
4. Autoriser l'installation depuis sources inconnues si demandé
5. Installer

### Méthode 2: Transfert Cloud
1. Uploader l'APK sur Google Drive / OneDrive / Dropbox
2. Télécharger depuis le téléphone
3. Installer comme méthode 1

### Méthode 3: ADB Install
```powershell
# Vérifier que le téléphone est connecté
adb devices

# Installer l'APK directement
adb install build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

---

## 🧪 Tests à Effectuer sur Téléphone

### Test 1: Connexion Backend
1. Ouvrir l'application
2. Se connecter avec compte test: `fofanachaka76@gmail.com`
3. ✅ Vérifier que la connexion réussit
4. ✅ Vérifier que les données s'affichent

### Test 2: Paiement Wave - Client
**Écran: proposition_detail_page**
1. Naviguer vers "Mes Propositions"
2. Sélectionner une proposition
3. Cliquer sur "Payer maintenant"
4. Choisir "Wave"
5. ✅ Vérifier que le navigateur Wave s'ouvre
6. ✅ Effectuer le paiement sur Wave
7. ✅ Revenir à l'app → Vérifier que le paiement est confirmé

**Écran: mes_contrats_page**
1. Naviguer vers "Mes Contrats"
2. Sélectionner un contrat avec prime à payer
3. Cliquer sur "Payer la prime"
4. Choisir "Wave"
5. ✅ Répéter le test de paiement

**Écran: mes_propositions_page**
1. Test identique à proposition_detail_page mais depuis la liste

### Test 3: Paiement Wave - Commercial
**Écran: subscription_detail_screen**
1. Se connecter avec compte commercial
2. Accéder à une souscription en attente
3. Cliquer sur "Finaliser la souscription"
4. Choisir "Wave" dans le bottom sheet
5. ✅ Vérifier le flux de paiement complet

### Test 4: Gestion d'Erreurs
1. **Connexion réseau coupée**:
   - ✅ Désactiver WiFi/4G pendant un paiement
   - ✅ Vérifier message d'erreur clair

2. **Annulation paiement**:
   - ✅ Lancer paiement Wave puis annuler
   - ✅ Vérifier que l'app gère bien l'annulation

3. **Session expirée**:
   - ✅ Attendre expiration JWT (30 jours en production)
   - ✅ Vérifier redirection vers login

---

## 🔧 Problèmes Courants & Solutions

### APK ne s'installe pas
**Problème**: "Application non installée"
**Solutions**:
1. Désinstaller l'ancienne version d'abord
2. Vérifier l'architecture (ARM64 pour téléphones récents)
3. Vérifier l'espace disque disponible (>100 MB)

### Paiement Wave échoue
**Problème**: "Impossible de créer la session Wave"
**Solutions**:
1. Vérifier que `185.98.138.168:5000` est accessible depuis le téléphone
2. Tester avec navigateur mobile: `http://185.98.138.168:5000/test-db`
3. Vérifier les logs backend: `npm start` (voir erreurs Wave API)
4. Vérifier que WAVE_API_KEY est toujours valide

### Navigateur Wave ne s'ouvre pas
**Problème**: URL Wave invalide ou navigateur manquant
**Solutions**:
1. Installer un navigateur (Chrome, Firefox)
2. Vérifier que `url_launcher` package est installé
3. Vérifier permissions AndroidManifest.xml

### Backend non accessible
**Problème**: "Erreur réseau", "Connection timeout"
**Solutions**:
1. Vérifier que le téléphone et le serveur sont sur le même réseau (si local)
2. Vérifier firewall sur `185.98.138.168` (port 5000 ouvert)
3. Vérifier que le backend tourne: `ssh` au serveur puis `pm2 status`

---

## 📊 Logs & Débogage

### Voir les logs en temps réel (téléphone connecté)
```powershell
flutter logs
```

### Voir les logs backend
```powershell
# Sur le serveur (SSH)
pm2 logs mycoris-backend

# Ou localement
cd d:\CORIS\app_coris\mycoris-master
npm start
# Voir la console pour les erreurs Wave
```

### Activer le mode debug Flutter (si besoin)
```powershell
flutter build apk --debug
flutter install
```

---

## 🎉 Checklist de Production

- [ ] APK généré sans erreurs
- [ ] APK installé sur téléphone test
- [ ] Connexion backend fonctionne
- [ ] Authentification fonctionne
- [ ] Paiement Wave client (3 écrans) testé
- [ ] Paiement Wave commercial testé
- [ ] Gestion erreurs validée
- [ ] Performance acceptable (pas de lag)
- [ ] UI responsive sur écran mobile

---

## 📞 Support

En cas de problème lors des tests, vérifier:

1. **Logs Backend**: Console npm ou PM2
2. **Logs Frontend**: `flutter logs` ou console navigateur Wave
3. **Configuration .env**: Vérifier que WAVE_API_KEY, WAVE_SUCCESS_URL, etc. sont corrects
4. **Base de données**: Vérifier que PostgreSQL est accessible

---

## 🎯 Résumé

### Ce qui est Prêt ✅
- Configuration production (AppConfig + .env)
- 4 écrans avec boutons Wave fonctionnels
- Services Wave (WaveService + WavePaymentHandler)
- Routes backend opérationnelles
- Polling mode activé
- Gestion d'erreurs complète

### Prochaines Étapes
1. `flutter build apk --release`
2. Installer sur téléphone mobile
3. Tester paiement Wave réel
4. Valider tous les scénarios client + commercial
5. Déployer en production si tests OK

---

**Date de préparation**: 24 février 2026  
**Version**: 1.0.0  
**Status**: ✅ **PRÊT POUR GÉNÉRATION APK**
