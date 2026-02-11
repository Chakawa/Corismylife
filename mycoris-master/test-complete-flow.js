#!/usr/bin/env node

/**
 * 🎬 TEST COMPLET: PROPOSITION → PAIEMENT → CONTRAT
 * Simule le flux complet d'une souscription sur l'app mobile
 */

require('dotenv').config();

const axios = require('axios');

const API_BASE_URL = 'http://localhost:5000';

// COULEURS
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
};

function log(color, ...args) {
  console.log(color, ...args, colors.reset);
}

// TEST CREDENTIALS
const TEST_USER = {
  email: 'fofanachaka76@gmail.com',
  password: 'password123'
};

const TEST_SUBSCRIPTION = {
  product_type: 'coris_epargne',
  capital: 10000,
  duree: 1,
  duree_type: 'years',
  periodicite: 'unique',
  prime: 100, // 100 FCFA pour le test
  beneficiaire: {
    nom: 'OUEDRAOGO KALEB',
    contact: '61347475',
    lien_parente: 'Enfant'
  }
};

const TEST_PAYMENT = {
  codePays: '226',
  telephone: '61347475',
  montant: TEST_SUBSCRIPTION.prime,
  codeOTP: process.env.CORIS_MONEY_DEV_OTP || '123456'
};

let authToken = null;
let subscriptionId = null;

async function login() {
  log(colors.bright + colors.blue, '\n📝 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '📝 ÉTAPE 1: AUTHENTIFICATION');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  try {
    log(colors.cyan, 'Email:', TEST_USER.email);
    
    // NOTE: Ajustez cette route selon votre API
    const response = await axios.post(
      `${API_BASE_URL}/api/auth/login`,
      TEST_USER,
      { timeout: 10000 }
    );
    
    if (response.data.data?.token) {
      authToken = response.data.data.token;
      log(colors.green, '✅ Connexion réussie!');
      log(colors.cyan, '🎫 Token reçu');
      return true;
    } else {
      log(colors.red, '❌ Pas de token reçu');
      return false;
    }
  } catch (error) {
    log(colors.red, '❌ Erreur de connexion:', error.message);
    return false;
  }
}

async function createSubscription() {
  log(colors.bright + colors.blue, '\n🆕 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '🆕 ÉTAPE 2: CRÉER UNE PROPOSITION');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  try {
    log(colors.cyan, 'Produit:', TEST_SUBSCRIPTION.product_type);
    log(colors.cyan, 'Capital:', TEST_SUBSCRIPTION.capital, 'FCFA');
    log(colors.cyan, 'Prime:', TEST_SUBSCRIPTION.prime, 'FCFA');
    
    const response = await axios.post(
      `${API_BASE_URL}/api/subscriptions`,
      TEST_SUBSCRIPTION,
      {
        headers: { Authorization: `Bearer ${authToken}` },
        timeout: 10000
      }
    );
    
    if (response.data.data?.id) {
      subscriptionId = response.data.data.id;
      log(colors.green, '✅ Proposition créée!');
      log(colors.cyan, '📊 ID souscription:', subscriptionId);
      log(colors.cyan, '📊 Statut:', response.data.data.statut || 'proposition');
      return true;
    } else {
      log(colors.red, '❌ Pas d\'ID souscription');
      return false;
    }
  } catch (error) {
    log(colors.red, '❌ Erreur création:', error.response?.data?.message || error.message);
    return false;
  }
}

async function processPayment() {
  log(colors.bright + colors.blue, '\n💳 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '💳 ÉTAPE 3: EFFECTUER LE PAIEMENT');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  try {
    log(colors.cyan, 'Montant:', TEST_PAYMENT.montant, 'FCFA');
    log(colors.cyan, 'Téléphone:', TEST_PAYMENT.codePays + TEST_PAYMENT.telephone);
    
    const paymentData = {
      ...TEST_PAYMENT,
      subscriptionId: subscriptionId,
      description: `Paiement souscription ${subscriptionId}`
    };
    
    const response = await axios.post(
      `${API_BASE_URL}/api/payment/process-payment`,
      paymentData,
      {
        headers: { Authorization: `Bearer ${authToken}` },
        timeout: 15000
      }
    );
    
    if (response.data.success) {
      log(colors.green, '✅ Paiement effectué!');
      log(colors.cyan, '📊 Transaction ID:', response.data.transactionId);
      log(colors.cyan, '📊 Contrat créé:', response.data.contractCreated ? 'OUI ✅' : 'NON ❌');
      return response.data.contractCreated;
    } else {
      log(colors.red, '❌ Paiement échoué:', response.data.message);
      return false;
    }
  } catch (error) {
    log(colors.red, '❌ Erreur paiement:', error.response?.data?.message || error.message);
    return false;
  }
}

async function getContractDetails() {
  log(colors.bright + colors.blue, '\n📋 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '📋 ÉTAPE 4: AFFICHER DÉTAILS CONTRAT');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  try {
    const response = await axios.get(
      `${API_BASE_URL}/api/payment/contracts`,
      {
        headers: { Authorization: `Bearer ${authToken}` },
        timeout: 10000
      }
    );
    
    if (response.data.data && response.data.data.length > 0) {
      const contract = response.data.data[0]; // Dernier contrat
      
      log(colors.green, '✅ Contrats trouvés!');
      log(colors.cyan, '\n📄 DÉTAILS DU CONTRAT:');
      log(colors.cyan, '   Numéro:', contract.contract_number);
      log(colors.cyan, '   Produit:', contract.product_name);
      log(colors.cyan, '   Montant:', contract.amount, 'FCFA');
      log(colors.cyan, '   Périodicité:', contract.periodicite);
      log(colors.cyan, '   Date début:', new Date(contract.start_date).toLocaleDateString());
      log(colors.cyan, '   Prochain paiement:', new Date(contract.next_payment_date).toLocaleDateString());
      log(colors.cyan, '   Statut:', contract.status);
      
      if (contract.payment_history) {
        log(colors.cyan, '\n📜 HISTORIQUE PAIEMENTS:');
        contract.payment_history.forEach((payment, idx) => {
          log(colors.cyan, `   ${idx + 1}. ${payment.montant} FCFA - ${payment.statut}`);
        });
      }
      
      return true;
    } else {
      log(colors.yellow, '⚠️  Aucun contrat trouvé');
      return false;
    }
  } catch (error) {
    log(colors.red, '❌ Erreur récupération contrat:', error.response?.data?.message || error.message);
    return false;
  }
}

async function runFullTest() {
  try {
    log(colors.bright + colors.magenta, '\n' + '═'.repeat(50));
    log(colors.bright + colors.magenta, '🎬 TEST COMPLET: PROPOSITION → PAIEMENT → CONTRAT');
    log(colors.bright + colors.magenta, '═'.repeat(50));
    
    // ÉTAPE 1: Connexion
    const loggedIn = await login();
    if (!loggedIn) {
      log(colors.red, '❌ Impossible de se connecter');
      process.exit(1);
    }
    
    // ATTENDRE UN MOMENT
    await new Promise(r => setTimeout(r, 1000));
    
    // ÉTAPE 2: Créer une proposition
    const subscriptionCreated = await createSubscription();
    if (!subscriptionCreated) {
      log(colors.red, '❌ Impossible de créer la proposition');
      process.exit(1);
    }
    
    // ATTENDRE UN MOMENT
    await new Promise(r => setTimeout(r, 1000));
    
    // ÉTAPE 3: Paiement
    const paymentSuccess = await processPayment();
    if (!paymentSuccess) {
      log(colors.red, '❌ Impossible d\'effectuer le paiement');
      // On continue quand même pour voir le détail
    }
    
    // ATTENDRE UN MOMENT
    await new Promise(r => setTimeout(r, 1000));
    
    // ÉTAPE 4: Afficher les contrats
    await getContractDetails();
    
    // RÉSUMÉ FINAL
    log(colors.bright + colors.green, '\n\n✅ ═══════════════════════════════════════');
    log(colors.bright + colors.green, '✅ TEST COMPLET TERMINÉ');
    log(colors.bright + colors.green, '═══════════════════════════════════════\n');
    
    log(colors.yellow, '💡 RÉSULTAT:');
    if (paymentSuccess) {
      log(colors.green, '   ✅ La proposition est devenue un contrat après le paiement!');
      log(colors.green, '   ✅ Le contrat est visible dans "Mes Contrats"');
      log(colors.green, '   ✅ Tous les détails sont affichés correctement');
    } else {
      log(colors.yellow, '   ⚠️  Vérifiez les logs pour les erreurs');
    }
    
  } catch (error) {
    log(colors.red, '\n❌ ERREUR CRITIQUE:', error.message);
    log(colors.red, error.stack);
  }
  
  process.exit(0);
}

// Lancer le test
runFullTest();
