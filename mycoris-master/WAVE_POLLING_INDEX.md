# 🌊 WAVE CHECKOUT - MODE POLLING (Sans Webhooks)

## 📑 INDEX DES FICHIERS

### 📘 Documentation
- **[WAVE_POLLING_TEST_GUIDE.md](WAVE_POLLING_TEST_GUIDE.md)** - Guide complet avec FAQ et dépannage

### 🧪 Scripts de Test

#### 1. Test Complet Automatisé
**Fichier:** `test-wave-polling.js`  
**Usage:**
```bash
node test-wave-polling.js
```
**Fonctionnalités:**
- Crée une session Wave
- Affiche l'URL de paiement
- Polling automatique du statut (10 tentatives)
- Résumé détaillé des résultats

#### 2. Test Interactif PowerShell
**Fichier:** `test-wave-interactive.ps1`  
**Usage:**
```powershell
.\test-wave-interactive.ps1
```
**Fonctionnalités:**
- Connexion automatique (demande email/password)
- Configuration interactive des paramètres
- Sauvegarde auto du JWT token
- Vérification serveur
- Lancement guidé du test

#### 3. Test Rapide PowerShell
**Fichier:** `test-wave-quick.ps1`  
**Usage:**
```powershell
.\test-wave-quick.ps1 -Email "votre@email.com" -Password "pass" -Amount 100
```
**Fonctionnalités:**
- Test en une seule commande
- Idéal pour automatisation
- Résultats concis

---

## ⚡ DÉMARRAGE RAPIDE

### Option 1 : Script Interactif (RECOMMANDÉ pour débutants)
```powershell
.\test-wave-interactive.ps1
```

### Option 2 : Test Rapide (RECOMMANDÉ pour experts)
```powershell
.\test-wave-quick.ps1 -Email "test@coris.ci" -Password "votrepass"
```

### Option 3 : Manuel
```powershell
# Terminal 1 : Serveur
npm start

# Terminal 2 : Test
node test-wave-polling.js
```

---

## 🔧 Configuration Requise

### 1. Fichier `.env`
```env
WAVE_DEV_MODE=false
WAVE_API_BASE_URL=https://api.wave.com
WAVE_API_KEY=wave_ci_prod_AqlIPJvDjeIPjMfZzfJIwlgFM3fMMhO8dXm0ma3Y5VgcMBkD6ZGFAkJG3qwGjfOC5zOwGZrbwMqNIiBFV88xC_NlhGzS8z5DVw
WAVE_SUCCESS_URL=http://185.98.138.168:5000/wave-success
WAVE_ERROR_URL=http://185.98.138.168:5000/wave-error
WAVE_WEBHOOK_URL=
WAVE_DEFAULT_CURRENCY=XOF
TEST_JWT_TOKEN=votre-token-ici
```

### 2. Serveur démarré
```bash
npm start
```

### 3. JWT Token valide
Obtenu via :
- Script interactif (automatique)
- Connexion manuelle : `POST /api/auth/login`

---

## 📊 Flux de Test

```
┌─────────────────────────────────────┐
│  1. Créer Session Wave              │
│     POST /api/payment/wave/         │
│          create-session             │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. Obtenir URL de Paiement         │
│     → launchUrl                     │
│     → sessionId                     │
│     → transactionId                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  3. Utilisateur Paie via Wave       │
│     (ouvre launchUrl sur mobile)    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. Polling du Statut               │
│     GET /api/payment/wave/          │
│         status/{sessionId}          │
│     (toutes les 3s, 10x)            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  5. Résultat                        │
│     ✅ COMPLETED                    │
│     ❌ FAILED                       │
│     ⏱️  TIMEOUT                     │
└─────────────────────────────────────┘
```

---

## 🎯 Résultats Attendus

### ✅ Succès
```
🎉 PAIEMENT RÉUSSI !
  Le paiement Wave fonctionne correctement.
  Mode polling opérationnel (sans webhooks).
```

### ⏱️ Timeout
```
⏱️  TIMEOUT
  Le polling a expiré avant confirmation.
  Session ID: WAVE-xxx (pour vérif manuelle)
```

### ❌ Échec
```
❌ PAIEMENT ÉCHOUÉ
  Vérifiez:
    - API Wave accessible
    - Clé API valide
    - Montant ≥ 100 FCFA
```

---

## 📱 Test sur Application Mobile

### Émulateur Android
1. AppConfig déjà configuré : `10.0.2.2:5000`
2. Lancez l'app Flutter
3. Test le paiement Wave via l'interface

### Téléphone Réel
1. Générez APK : `flutter build apk --release`
2. Installez : `flutter install`
3. Testez avec compte Wave réel

---

## 🔍 Vérification Manuelle

Si timeout, vérifiez manuellement :

```powershell
curl -X GET "http://localhost:5000/api/payment/wave/status/{sessionId}?subscriptionId=1&transactionId=WAVE-xxx" `
  -H "Authorization: Bearer VOTRE_TOKEN"
```

---

## ❓ POURQUOI PAS DE WEBHOOKS ?

### ✅ Avantages Mode Polling

1. **Plus simple** : Pas de serveur public/tunnel requis
2. **Fiable** : API Wave garantit statut temps réel via GET
3. **Conforme** : Webhooks sont **optionnels** selon doc Wave
4. **Testable** : Fonctionne en local sans configuration complexe

### 📖 Documentation Wave

> "Webhooks are optional. You can poll the checkout session status endpoint to get real-time updates."
> — [Wave Checkout API Docs](https://docs.wave.com/checkout#checkout-api)

---

## 🛠️ Dépannage Express

| Problème | Solution |
|----------|----------|
| "Cannot find module" | `npm install` |
| "Server not running" | `npm start` |
| "Invalid JWT" | Re-login ou script interactif |
| "Session not found" | Vérifiez WAVE_API_KEY dans .env |
| "Timeout" | Augmentez maxAttempts ou vérifiez manuellement |

---

## 📞 Support

- **Guide détaillé** : [WAVE_POLLING_TEST_GUIDE.md](WAVE_POLLING_TEST_GUIDE.md)
- **Doc Wave** : https://docs.wave.com/checkout
- **API Reference** : https://docs.wave.com/checkout#checkout-api

---

## ✅ CHECKLIST PRÉ-TEST

- [ ] Serveur démarré (`npm start`)
- [ ] `.env` configuré (WAVE_API_KEY, etc.)
- [ ] JWT token valide (via script ou manuel)
- [ ] Compte Wave actif (pour test réel)
- [ ] Montant ≥ 100 FCFA

---

**🚀 PRÊT À TESTER !**

Choisissez votre méthode et lancez le test.
