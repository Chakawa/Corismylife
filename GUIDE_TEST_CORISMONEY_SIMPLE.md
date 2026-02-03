# 🧪 COMMENT TESTER L'INTÉGRATION CORISMONEY

## ⚠️ PROBLÈME ACTUEL : Serveur non démarré

Lorsque vous essayez de lancer le script de test, vous obtenez l'erreur :
```
connect ECONNREFUSED ::1:5000
```

**Cause** : Le serveur backend Node.js n'est pas démarré.

---

## ✅ SOLUTION : Démarrer le serveur backend

### 1️⃣ Ouvrir un nouveau terminal PowerShell

Dans VS Code :
- Cliquez sur **Terminal** → **New Terminal**
- Ou utilisez le raccourci : `Ctrl + Shift + ù`

### 2️⃣ Naviguer vers le dossier backend

```powershell
cd d:\CORIS\app_coris\mycoris-master
```

### 3️⃣ Démarrer le serveur

```powershell
npm start
```

**Résultat attendu** :
```
Server ready at http://0.0.0.0:5000
Database connected successfully
```

**Important** : Laissez ce terminal ouvert ! Le serveur doit continuer à tourner en arrière-plan.

---

## 🧪 TESTER L'API CORISMONEY

### Option 1 : Test avec script automatique (RECOMMANDÉ)

#### Créer un script de test simple

Créez le fichier `mycoris-master/scripts/test_corismoney_simple.js` :

```javascript
/**
 * TEST SIMPLE DE L'API CORISMONEY
 * 
 * Ce script teste l'envoi d'OTP et le paiement CorisMoney
 * en utilisant les routes de votre backend.
 * 
 * PRÉREQUIS:
 * 1. Le serveur backend doit être démarré (npm start)
 * 2. Les identifiants CorisMoney doivent être configurés dans .env
 * 3. Vous devez avoir un compte CorisMoney pour tester
 */

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:5000/api/payment';

// IMPORTANT: Remplacez par vos vraies informations de test
const TEST_PHONE = '0576093737'; // Votre numéro CorisMoney
const TEST_AMOUNT = 1000;        // Montant de test (1000 FCFA)
const TEST_CODE_PAYS = '225';    // Côte d'Ivoire

// Token JWT de test (utilisez un vrai token d'un utilisateur connecté)
let AUTH_TOKEN = '';

/**
 * Étape 1 : Se connecter pour obtenir un token JWT
 */
async function login() {
  console.log('\n📱 ÉTAPE 1 : Connexion pour obtenir le token JWT');
  console.log('='.repeat(60));
  
  try {
    const response = await axios.post('http://localhost:5000/api/auth/login', {
      email: 'admin@coris.ci',  // Utilisez un email de test valide
      password: 'Admin@123'      // Utilisez le mot de passe correspondant
    });

    if (response.data.token) {
      AUTH_TOKEN = response.data.token;
      console.log('✅ Connexion réussie !');
      console.log(`Token: ${AUTH_TOKEN.substring(0, 20)}...`);
      return true;
    } else {
      console.log('❌ Pas de token reçu');
      return false;
    }
  } catch (error) {
    console.log('❌ Erreur de connexion:', error.message);
    console.log('⚠️  Vérifiez que le serveur est démarré (npm start)');
    return false;
  }
}

/**
 * Étape 2 : Envoyer le code OTP
 */
async function sendOTP() {
  console.log('\n📨 ÉTAPE 2 : Envoi du code OTP');
  console.log('='.repeat(60));
  console.log(`Numéro : +${TEST_CODE_PAYS} ${TEST_PHONE}`);

  try {
    const response = await axios.post(
      `${BASE_URL}/send-otp`,
      {
        codePays: TEST_CODE_PAYS,
        telephone: TEST_PHONE
      },
      {
        headers: {
          'Authorization': `Bearer ${AUTH_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Code OTP envoyé !');
    console.log('Réponse:', JSON.stringify(response.data, null, 2));
    console.log('\n📱 Vérifiez votre téléphone pour le code OTP');
    return true;
  } catch (error) {
    console.log('❌ Erreur lors de l\'envoi de l\'OTP');
    if (error.response) {
      console.log('Statut:', error.response.status);
      console.log('Erreur:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.log('Erreur:', error.message);
    }
    return false;
  }
}

/**
 * Étape 3 : Traiter le paiement avec le code OTP
 */
async function processPayment(otp) {
  console.log('\n💰 ÉTAPE 3 : Traitement du paiement');
  console.log('='.repeat(60));
  console.log(`Montant : ${TEST_AMOUNT} FCFA`);
  console.log(`Code OTP : ${otp}`);

  try {
    const response = await axios.post(
      `${BASE_URL}/process-payment`,
      {
        subscriptionId: 1,  // ID de test
        codePays: TEST_CODE_PAYS,
        telephone: TEST_PHONE,
        montant: TEST_AMOUNT,
        codeOTP: otp,
        description: 'Test paiement CorisMoney'
      },
      {
        headers: {
          'Authorization': `Bearer ${AUTH_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Paiement effectué avec succès !');
    console.log('Réponse:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.log('❌ Erreur lors du paiement');
    if (error.response) {
      console.log('Statut:', error.response.status);
      console.log('Erreur:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.log('Erreur:', error.message);
    }
    return false;
  }
}

/**
 * Fonction principale
 */
async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║         TEST DE L\'INTÉGRATION CORISMONEY                  ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  // Étape 1 : Connexion
  const loginSuccess = await login();
  if (!loginSuccess) {
    console.log('\n⚠️  Impossible de continuer sans connexion');
    return;
  }

  // Étape 2 : Envoi OTP
  const otpSent = await sendOTP();
  if (!otpSent) {
    console.log('\n⚠️  Impossible de continuer sans OTP');
    return;
  }

  // Attendre que l'utilisateur saisisse le code OTP
  console.log('\n⏳ En attente du code OTP...');
  console.log('📝 Saisissez le code OTP reçu par SMS et appuyez sur Entrée :');

  // Lire le code OTP depuis le terminal
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question('Code OTP : ', async (otp) => {
    rl.close();

    if (!otp || otp.trim().length === 0) {
      console.log('❌ Code OTP vide');
      return;
    }

    // Étape 3 : Traiter le paiement
    await processPayment(otp.trim());

    console.log('\n✅ Test terminé !');
  });
}

// Lancer le test
main();
```

### Lancer le test :

```powershell
cd d:\CORIS\app_coris\mycoris-master
node scripts/test_corismoney_simple.js
```

**Ce qui va se passer** :
1. Le script se connecte au backend
2. Il envoie un code OTP à votre numéro CorisMoney
3. Vous recevez un SMS avec le code
4. Vous saisissez le code dans le terminal
5. Le script traite le paiement

---

## 🔧 Vérifier que le serveur tourne

### Méthode 1 : Vérifier dans le terminal

Si le serveur tourne, vous verrez dans le terminal :
```
Server ready at http://0.0.0.0:5000
Database connected successfully
```

### Méthode 2 : Tester avec curl ou Postman

```powershell
# Test rapide de l'API
curl http://localhost:5000/api/health
```

Si le serveur répond, c'est qu'il tourne correctement.

---

## ⚠️ IMPORTANT AVANT DE TESTER

### 1. Vérifier que les identifiants CorisMoney sont configurés

Ouvrez `mycoris-master/.env` et vérifiez :

```dotenv
CORIS_MONEY_CLIENT_ID=votre_client_id_ici    # ❌ À REMPLACER
CORIS_MONEY_CLIENT_SECRET=votre_client_secret_ici  # ❌ À REMPLACER
CORIS_MONEY_CODE_PV=votre_code_pv_ici        # ❌ À REMPLACER
```

**SI CES VALEURS NE SONT PAS CONFIGURÉES** :
- Voir le fichier [GUIDE_DEMANDE_CORISMONEY.md](GUIDE_DEMANDE_CORISMONEY.md)
- Contactez l'administrateur CorisMoney pour obtenir ces identifiants

### 2. Utiliser un vrai compte CorisMoney

Dans le script de test, remplacez :
```javascript
const TEST_PHONE = '0576093737'; // ← Votre numéro CorisMoney
```

Par votre vrai numéro de téléphone CorisMoney (celui de Fofana Chaka : `0576093737`)

---

## 📱 Tester avec l'application Flutter

### 1. S'assurer que le serveur backend tourne

```powershell
# Terminal 1 : Serveur backend
cd d:\CORIS\app_coris\mycoris-master
npm start
```

### 2. Lancer l'application Flutter

```powershell
# Terminal 2 : Application Flutter
cd d:\CORIS\app_coris\mycorislife-master
flutter run
```

### 3. Tester le paiement CorisMoney

Dans l'application :
1. **Créer une souscription** (CORIS SÉRÉNITÉ par exemple)
2. À l'étape **Paiement**, choisir **CORIS Money**
3. Le modal CorisMoney s'ouvre
4. Saisir le numéro : `0576093737`
5. Cliquer sur **Envoyer le code OTP**
6. Recevoir le SMS avec le code
7. Saisir le code OTP
8. Cliquer sur **Confirmer le paiement**
9. ✅ Paiement validé !

---

## 🐛 Problèmes courants et solutions

### Erreur : `ECONNREFUSED ::1:5000`

**Cause** : Le serveur n'est pas démarré
**Solution** : Lancer `npm start` dans le dossier `mycoris-master`

### Erreur : `Identifiants CorisMoney non configurés`

**Cause** : Les variables `.env` ne sont pas remplies
**Solution** : Obtenir les identifiants de CorisMoney (voir GUIDE_DEMANDE_CORISMONEY.md)

### Erreur : `COMPTE INEXISTANT`

**Cause** : Le numéro de téléphone n'a pas de compte CorisMoney
**Solution** : Utiliser un numéro avec un compte CorisMoney actif

### Erreur : `CODE OTP INVALIDE`

**Cause** : Le code OTP saisi est incorrect ou expiré
**Solution** : Renvoyer un nouveau code OTP et réessayer

### Erreur : `RenderFlex overflowing` (Flutter)

**Cause** : Le modal CorisMoney déborde de l'écran
**Solution** : Cette erreur a été corrigée avec `SingleChildScrollView`. Relancer l'app.

---

## ✅ Checklist de test

Avant de déployer en production, vérifiez :

- [ ] Le serveur backend démarre sans erreur
- [ ] Les tables `payment_otp_requests` et `payment_transactions` existent
- [ ] Les identifiants CorisMoney sont configurés dans `.env`
- [ ] L'envoi d'OTP fonctionne (SMS reçu)
- [ ] Le paiement avec OTP fonctionne (transaction réussie)
- [ ] Le modal Flutter s'affiche correctement (pas d'overflow)
- [ ] Les transactions sont enregistrées dans la base de données
- [ ] L'application redirige correctement après paiement réussi

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifier les logs du serveur** (terminal où `npm start` tourne)
2. **Vérifier les logs de l'app Flutter** (terminal où `flutter run` tourne)
3. **Consulter les fichiers de documentation** :
   - [INTEGRATION_CORISMONEY.md](INTEGRATION_CORISMONEY.md)
   - [GUIDE_DEMANDE_CORISMONEY.md](GUIDE_DEMANDE_CORISMONEY.md)
   - [GUIDE_SERVICE_CORISMONEY_COMMENTE.md](GUIDE_SERVICE_CORISMONEY_COMMENTE.md)

---

**Bon test ! 🚀**
