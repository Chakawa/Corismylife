# 📱 GUIDE: GÉNÉRATION D'APK POUR TESTING

## 🎯 OBJECTIF
Générer un fichier APK de l'application Flutter MyCorisLife
pour tester sur des appareils Android réels ou virtuels.

---

## 📋 PRÉREQUIS

### 1. ✅ Flutter SDK (dernière version)
```bash
flutter --version
# Doit afficher Flutter version 3.x.x ou plus
```

### 2. ✅ Android Studio + SDK Android
```bash
# Vérifier le SDK Android
flutter doctor

# Si des dépendances manquent:
flutter doctor --android-licenses
# Accepter toutes les licences (tapez 'y')
```

### 3. ✅ Java JDK 11 ou 17
```bash
java -version
# Doit afficher Java 11 ou 17+
```

---

## 🔧 CONFIGURATION AVANT BUILD

### Étape 1: Vérifier le fichier pubspec.yaml

```yaml
name: mycorislife
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  url_launcher: ^6.0.0
  # ... autres dépendances
```

### Étape 2: Mettre à jour les dépendances

```bash
cd /d/CORIS/app_coris/mycorislife-master
flutter pub get
flutter pub upgrade
```

### Étape 3: Vérifier les permissions Android

Fichier: `android/app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.corisassurance.mycorislife">

    <!-- Permissions requises -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application
        android:allowBackup="false"
        android:icon="@mipmap/launcher_icon"
        android:label="@string/app_name"
        android:usesCleartextTraffic="true">
        <!-- usesCleartextTraffic=true pour http://185.98.138.168 -->
        
        <activity ... />
    </application>
</manifest>
```

### Étape 4: Configurer build.gradle

Fichier: `android/app/build.gradle`

```gradle
android {
    compileSdk 34  // Dernière version Android SDK
    ndkVersion "25.1.8937393"

    defaultConfig {
        applicationId "com.corisassurance.mycorislife"
        minSdkVersion 23  // Android 6.0+
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    buildTypes {
        debug {
            debuggable true
        }
        release {
            signingConfig signingConfigs.release
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Étape 5: Configurer la signature APK (pour Release)

📌 **Important pour le Play Store uniquement**

Créer `android/key.properties`:

```properties
storePassword=VotreMotDePasseMagasin
keyPassword=VotreMotDePasseCle
keyAlias=my_key_alias
storeFile=key.jks
```

Générer la clé:

```bash
cd android/app
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my_key_alias
# Remplissez les informations demandées
```

---

## 🚀 GÉNÉRER L'APK

### Pour Testing (Debug APK)

```bash
cd /d/CORIS/app_coris/mycorislife-master

# Nettoyer
flutter clean

# Obtenir les dépendances
flutter pub get

# Générer APK en debug
flutter build apk --debug
```

**Sortie:** `build/app/outputs/apk/debug/app-debug.apk`

### Pour Production (Release APK)

```bash
# Générer APK en release (optimisé)
flutter build apk --release
```

**Sortie:** `build/app/outputs/apk/release/app-release.apk`

### Générer un Bundle App (pour Play Store)

```bash
flutter build appbundle --release
```

**Sortie:** `build/app/outputs/bundle/release/app-release.aab`

---

## 📱 INSTALLER SUR APPAREIL/ÉMULATEUR

### Option 1: Installer via ADB

```bash
# Lister les appareils connectés
adb devices

# Installer l'APK
adb install build/app/outputs/apk/debug/app-debug.apk

# Désinstaller
adb uninstall com.corisassurance.mycorislife

# Réinstaller (ignorer l'ancienne version)
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

### Option 2: Via Android Studio

1. Connecter l'appareil USB
2. **Device Manager** > Sélectionner l'appareil
3. **Run** > Sélectionner l'appareil cible
4. Flutter générera et installera l'APK automatiquement

### Option 3: Via Émulateur Android

```bash
# Lancer l'émulateur
emulator -avd Pixel_6_API_34

# Générer et installer
flutter run --release
```

---

## ✅ VÉRIFICATION APRÈS INSTALLATION

### 1. Vérifier la connectivité API

Ouvrir l'app et tester une requête:

```bash
# Afficher les logs
flutter logs

# Ou via Android Studio
# Logcat > Filter > mycorislife
```

###2. Tester les principales fonctionnalités

- ✅ **Login:** Connexion avec identifiants
- ✅ **Souscriptions:** Affichage liste produits
- ✅ **Propositions:** Visualisation propositions
- ✅ **Contrats:** Affichage contrats actifs
- ✅ **Paiement Wave:** Tester paiement (utiliser n° de test Wave)
- ✅ **Notifications:** Recevoir une notification test

### 3. Vérifier les logs réseau

```bash
# Dans les logs Flutter, chercher:
# ✅ "Creating checkout session"
# ✅ "Wave API response: success"
# ✅ "Payment transaction recorded"

# ❌ Les erreurs courantes:
# ❌ "Connection refused"  = Backend non accessible
# ❌ "Invalid credentials" = Identifiants Wave incorrects
# ❌ "Network timeout"     = Problème réseau
```

---

## 🐛 DÉPANNAGE COURANT

### Problème: "Connection refused"

```
Cause: Backend non accessible depuis l'appareil
Solution: Vérifier AppConfig.dart

# ❌ MAUVAIS (localhost)
static const String baseUrl = 'http://10.0.2.2:5000/api';

# ✅ BON (serveur distant)
static const String baseUrl = 'http://185.98.138.168:5000/api';
```

### Problème: "Certificate validation failed"

```
Cause: HTTP non sécurisé avec HTTPS forcé
Solution: Ajouter usesCleartextTraffic=true dans AndroidManifest.xml
```

### Problème: "Insufficient permissions"

```
Cause: Permissions non accordées
Solution: Autoriser les permissions dans les paramètres Android
```

### Problème: "App freeze on payment"

```
Cause: Wave URL invalide ou redirection manquante
Solution: Vérifier .env WAVE_SUCCESS_URL et WAVE_ERROR_URL pointent vers
          http://185.98.138.168:5000/wave-success
          et
          http://185.98.138.168:5000/wave-error
```

---

## 📊 OPTIMISATION POUR PRODUCTION

### 1. Minification & Obfuscation

```bash
flutter build apk --release
# Automatiquement réduit le fichier APK
```

### 2. Réduction de taille

- Supprimer les images non utilisées
- Utiliser WebP au lieu de PNG
- Minifier les JSON

### 3. Performance

- Profiler l'app avec DevTools
- Corriger les frame drops
- Optimiser les requêtes API

---

## 📤 DÉPLOYER SUR GOOGLE PLAY STORE

### Prérequis

1. ✅ Créer un compte Google Play Developer ($25)
2. ✅ Générer APK/Bundle signé
3. ✅ Remplir les détails de l'application
4. ✅ Passer la révision de Google

### Processus

```bash
# 1. Générer APK signé
flutter build appbundle --release

# 2. Télécharger sur Google Play Console
# Play Console > Votre app > Release > Production

# 3. Soumettre pour révision
# Google révise en 24-48h généralement
```

---

## 📝 CHECKLIST AVANT PRODUCTION

- [ ] AppConfig.dart pointe vers le bon backend (185.98.138.168)
- [ ] .env du backend contient WAVE_SUCCESS_URL et WAVE_ERROR_URL correctes
- [ ] AndroidManifest.xml a tous les permissions requises
- [ ] App a été testée sur l'émulateur Android
- [ ] App a été testée sur un appareil réel
- [ ] Paiement Wave fonctionne du début à la fin
- [ ] Notifications fonctionnent
- [ ] Pas d'erreurs dans les logs
- [ ] Taille APK < 100 MB
- [ ] Version code incrémenté (pubspec.yaml)

---

## 🔗 RESSOURCES

- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [Android Manifest Documentation](https://developer.android.com/guide/topics/manifest/manifest-intro)
- [Wave API Documentation](https://docs.wave.com)

---

**Generated:** $(date)
**Environment:** Production
**Status:** Ready for APK generation
