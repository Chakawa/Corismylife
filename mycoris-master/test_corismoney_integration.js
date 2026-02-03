const axios = require('axios');
require('dotenv').config();

const BASE_URL = 'http://localhost:5000';

// Token admin de test - À remplacer par un vrai token
let authToken = '';

// Couleurs pour la console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSection(title) {
  console.log('\n' + '═'.repeat(80));
  log(`  ${title}`, 'cyan');
  console.log('═'.repeat(80) + '\n');
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'blue');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

// Fonction pour se connecter et obtenir un token
async function login() {
  logSection('AUTHENTIFICATION');
  
  try {
    logInfo('Tentative de connexion...');
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'admin@coris.ci',
      password: 'Admin@2024'
    });

    if (response.data.token) {
      authToken = response.data.token;
      logSuccess('Connexion réussie !');
      logInfo(`Token: ${authToken.substring(0, 20)}...`);
      return true;
    }
  } catch (error) {
    logError('Erreur de connexion');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// Test 1: Vérifier la configuration
async function testConfiguration() {
  logSection('TEST 1: VÉRIFICATION DE LA CONFIGURATION');

  const requiredEnvVars = [
    'CORIS_MONEY_CLIENT_ID',
    'CORIS_MONEY_CLIENT_SECRET',
    'CORIS_MONEY_CODE_PV'
  ];

  let allConfigured = true;

  requiredEnvVars.forEach(varName => {
    if (process.env[varName] && process.env[varName] !== 'votre_client_id_ici' && process.env[varName] !== 'votre_client_secret_ici' && process.env[varName] !== 'votre_code_pv_ici') {
      logSuccess(`${varName}: Configuré`);
    } else {
      logError(`${varName}: Non configuré ou valeur par défaut`);
      allConfigured = false;
    }
  });

  if (!allConfigured) {
    logWarning('Veuillez configurer toutes les variables d\'environnement dans le fichier .env');
    logInfo('Les tests suivants utiliseront l\'environnement de test CorisMoney');
  }

  return allConfigured;
}

// Test 2: Envoyer un code OTP
async function testSendOTP() {
  logSection('TEST 2: ENVOI DU CODE OTP');

  const testData = {
    codePays: '225',
    telephone: '0102030405' // Numéro de test
  };

  try {
    logInfo(`Envoi d'OTP à +${testData.codePays} ${testData.telephone}...`);
    
    const response = await axios.post(
      `${BASE_URL}/api/payment/send-otp`,
      testData,
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (response.data.success) {
      logSuccess('Code OTP envoyé avec succès !');
      console.log('Réponse:', JSON.stringify(response.data, null, 2));
      return true;
    } else {
      logWarning('Réponse non réussie');
      console.log('Réponse:', JSON.stringify(response.data, null, 2));
      return false;
    }
  } catch (error) {
    logError('Erreur lors de l\'envoi de l\'OTP');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// Test 3: Récupérer les informations client
async function testGetClientInfo() {
  logSection('TEST 3: RÉCUPÉRATION DES INFORMATIONS CLIENT');

  const testData = {
    codePays: '225',
    telephone: '0102030405'
  };

  try {
    logInfo(`Récupération des infos pour +${testData.codePays} ${testData.telephone}...`);
    
    const response = await axios.get(
      `${BASE_URL}/api/payment/client-info`,
      {
        params: testData,
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      }
    );

    if (response.data.success) {
      logSuccess('Informations client récupérées avec succès !');
      console.log('Données:', JSON.stringify(response.data.data, null, 2));
      return true;
    } else {
      logWarning('Client non trouvé ou erreur');
      console.log('Réponse:', JSON.stringify(response.data, null, 2));
      return false;
    }
  } catch (error) {
    logError('Erreur lors de la récupération des informations');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// Test 4: Récupérer l'historique des paiements
async function testGetPaymentHistory() {
  logSection('TEST 4: HISTORIQUE DES PAIEMENTS');

  try {
    logInfo('Récupération de l\'historique...');
    
    const response = await axios.get(
      `${BASE_URL}/api/payment/history`,
      {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      }
    );

    if (response.data.success) {
      logSuccess(`Historique récupéré: ${response.data.total} transaction(s)`);
      
      if (response.data.data.length > 0) {
        console.log('\nDernières transactions:');
        response.data.data.slice(0, 5).forEach((tx, index) => {
          console.log(`\n${index + 1}. Transaction #${tx.id}`);
          console.log(`   ID: ${tx.transaction_id || 'N/A'}`);
          console.log(`   Montant: ${parseFloat(tx.montant).toLocaleString('fr-FR')} FCFA`);
          console.log(`   Statut: ${tx.statut}`);
          console.log(`   Date: ${new Date(tx.created_at).toLocaleString('fr-FR')}`);
        });
      } else {
        logInfo('Aucune transaction trouvée');
      }
      
      return true;
    }
  } catch (error) {
    logError('Erreur lors de la récupération de l\'historique');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// Test 5: Vérifier que les routes existent
async function testRoutesExist() {
  logSection('TEST 5: VÉRIFICATION DES ROUTES API');

  const routes = [
    { method: 'POST', path: '/api/payment/send-otp', name: 'Envoi OTP' },
    { method: 'POST', path: '/api/payment/process-payment', name: 'Traitement paiement' },
    { method: 'GET', path: '/api/payment/client-info', name: 'Info client' },
    { method: 'GET', path: '/api/payment/history', name: 'Historique' }
  ];

  for (const route of routes) {
    try {
      // Pour GET, on fait une requête sans paramètres (devrait renvoyer une erreur de validation, pas 404)
      // Pour POST, idem
      const config = {
        headers: {
          'Authorization': `Bearer ${authToken}`
        },
        validateStatus: (status) => status < 500 // Accepter tout sauf 500+
      };

      let response;
      if (route.method === 'GET') {
        response = await axios.get(`${BASE_URL}${route.path}`, config);
      } else {
        response = await axios.post(`${BASE_URL}${route.path}`, {}, config);
      }

      if (response.status === 404) {
        logError(`${route.name} (${route.method} ${route.path}): Route non trouvée`);
      } else {
        logSuccess(`${route.name} (${route.method} ${route.path}): Disponible`);
      }
    } catch (error) {
      if (error.response?.status === 404) {
        logError(`${route.name}: Route non trouvée`);
      } else {
        logSuccess(`${route.name}: Route disponible (erreur de validation attendue)`);
      }
    }
  }
}

// Fonction principale
async function runTests() {
  console.clear();
  
  logSection('🧪 TESTS D\'INTÉGRATION CORISMONEY');
  logInfo('Base URL: ' + BASE_URL);
  logInfo('Environment: ' + (process.env.NODE_ENV || 'development'));
  
  // Se connecter
  const loginSuccess = await login();
  if (!loginSuccess) {
    logError('Impossible de continuer sans authentification');
    process.exit(1);
  }

  // Exécuter les tests
  await testConfiguration();
  await testRoutesExist();
  await testSendOTP();
  await testGetClientInfo();
  await testGetPaymentHistory();

  logSection('RÉSUMÉ DES TESTS');
  logInfo('Tous les tests sont terminés');
  logWarning('Note: Les tests avec l\'API CorisMoney réelle nécessitent des identifiants valides');
  logInfo('Assurez-vous de configurer CORIS_MONEY_CLIENT_ID, CORIS_MONEY_CLIENT_SECRET et CORIS_MONEY_CODE_PV');
  
  console.log('\n');
}

// Exécuter les tests
runTests().catch(error => {
  logError('Erreur fatale lors des tests');
  console.error(error);
  process.exit(1);
});
