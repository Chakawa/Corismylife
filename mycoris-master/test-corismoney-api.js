/**
 * Script de test pour l'API CorisMoney
 * Utilisation: node test-corismoney-api.js
 */

const corisMoneyService = require('./services/corisMoneyService');
require('dotenv').config();

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(color, ...args) {
  console.log(color, ...args, colors.reset);
}

async function testCorisMoneyAPI() {
  console.log('\n' + '='.repeat(60));
  log(colors.cyan, '🧪 TEST DE L\'API CORISMONEY');
  console.log('='.repeat(60) + '\n');

  // Afficher la configuration
  log(colors.blue, '📋 Configuration:');
  console.log(`  Base URL: ${process.env.CORIS_MONEY_BASE_URL}`);
  console.log(`  Client ID: ${process.env.CORIS_MONEY_CLIENT_ID}`);
  console.log(`  Code PV: ${process.env.CORIS_MONEY_CODE_PV}`);
  console.log(`  Mode Dev: ${process.env.CORIS_MONEY_DEV_MODE}`);
  console.log('');

  // Vérifier que les identifiants sont configurés
  if (!process.env.CORIS_MONEY_CLIENT_ID || 
      !process.env.CORIS_MONEY_CLIENT_SECRET || 
      !process.env.CORIS_MONEY_CODE_PV) {
    log(colors.red, '❌ ERREUR: Identifiants CorisMoney non configurés dans .env');
    process.exit(1);
  }

  // Numéro de test - ⚠️ IMPORTANT: Doit commencer par 0 !
  const codePays = '225'; // Côte d'Ivoire
  const telephone = '0799283976'; // ⚠️ AVEC le 0 initial ! Format final: 2250799283976
  const montant = 1000; // 1000 FCFA pour le test

  console.log('─'.repeat(60));
  log(colors.yellow, '⚠️  IMPORTANT:');
  console.log(`  Numéro complet: ${codePays}${telephone} (DOIT inclure le 0 initial)`);
  console.log(`  Assurez-vous que ce numéro est un compte CorisMoney valide`);
  console.log(`  En mode DEV, utilisez le code OTP: ${process.env.CORIS_MONEY_DEV_OTP || '123456'}`);
  console.log('─'.repeat(60) + '\n');

  try {
    // TEST 1: Envoi OTP
    console.log('─'.repeat(60));
    log(colors.blue, '📱 TEST 1: Envoi du code OTP');
    console.log('─'.repeat(60));
    
    const otpResult = await corisMoneyService.sendOTP(codePays, telephone);
    
    if (otpResult.success) {
      log(colors.green, '✅ OTP envoyé avec succès');
      console.log('   Message:', otpResult.message);
    } else {
      log(colors.red, '❌ Échec envoi OTP');
      console.log('   Message:', otpResult.message);
      console.log('   Erreur:', JSON.stringify(otpResult.error, null, 2));
      return;
    }

    console.log('\n' + '─'.repeat(60));
    log(colors.blue, '💬 Saisissez le code OTP reçu par SMS');
    console.log('─'.repeat(60));
    
    // En mode dev, utiliser l'OTP par défaut
    let codeOTP;
    if (process.env.CORIS_MONEY_DEV_MODE === 'true') {
      codeOTP = process.env.CORIS_MONEY_DEV_OTP || '123456';
      log(colors.cyan, `🧪 Mode DEV: Utilisation du code OTP: ${codeOTP}`);
    } else {
      // En production, demander à l'utilisateur
      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });
      
      codeOTP = await new Promise(resolve => {
        readline.question('Code OTP: ', answer => {
          readline.close();
          resolve(answer);
        });
      });
    }

    console.log('');

    // TEST 2: Paiement
    console.log('─'.repeat(60));
    log(colors.blue, `💰 TEST 2: Traitement du paiement (${montant} FCFA)`);
    console.log('─'.repeat(60));
    
    const paymentResult = await corisMoneyService.paiementBien(
      codePays,
      telephone,
      montant,
      codeOTP
    );
    
    if (paymentResult.success) {
      log(colors.green, '✅ Paiement effectué avec succès');
      console.log('   Transaction ID:', paymentResult.transactionId);
      console.log('   Montant:', paymentResult.data.montant, 'FCFA');
      console.log('   Message:', paymentResult.message);
      
      // TEST 3: Vérification du statut
      if (paymentResult.transactionId && process.env.CORIS_MONEY_DEV_MODE !== 'true') {
        console.log('\n' + '─'.repeat(60));
        log(colors.blue, '🔍 TEST 3: Vérification du statut de la transaction');
        console.log('─'.repeat(60));
        
        // Attendre 2 secondes avant de vérifier
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const statusResult = await corisMoneyService.getTransactionStatus(paymentResult.transactionId);
        
        if (statusResult.success) {
          log(colors.green, '✅ Statut récupéré avec succès');
          console.log('   Statut:', statusResult.data.status);
          console.log('   Détails:', JSON.stringify(statusResult.data, null, 2));
        } else {
          log(colors.yellow, '⚠️  Impossible de vérifier le statut');
          console.log('   Message:', statusResult.message);
        }
      }
    } else {
      log(colors.red, '❌ Échec du paiement');
      console.log('   Message:', paymentResult.message);
      console.log('   Erreur:', JSON.stringify(paymentResult.error, null, 2));
    }

    // Résumé final
    console.log('\n' + '='.repeat(60));
    log(colors.cyan, '📊 RÉSUMÉ DES TESTS');
    console.log('='.repeat(60));
    console.log(`  Envoi OTP: ${otpResult.success ? '✅ Réussi' : '❌ Échoué'}`);
    console.log(`  Paiement: ${paymentResult.success ? '✅ Réussi' : '❌ Échoué'}`);
    console.log('='.repeat(60) + '\n');

  } catch (error) {
    log(colors.red, '❌ ERREUR FATALE:');
    console.error(error);
    process.exit(1);
  }
}

// TEST 4: Informations client (optionnel)
async function testClientInfo() {
  const codePays = '225';
  const telephone = '0707070707';
  
  console.log('\n' + '─'.repeat(60));
  log(colors.blue, '👤 TEST BONUS: Informations client');
  console.log('─'.repeat(60));
  
  try {
    const result = await corisMoneyService.getClientInfo(codePays, telephone);
    
    if (result.success) {
      log(colors.green, '✅ Informations récupérées');
      console.log('   Données:', JSON.stringify(result.data, null, 2));
    } else {
      log(colors.yellow, '⚠️  Informations non disponibles');
      console.log('   Message:', result.message);
    }
  } catch (error) {
    log(colors.red, '❌ Erreur:', error.message);
  }
}

// Exécution
console.log('\n');
testCorisMoneyAPI()
  .then(() => {
    log(colors.green, '\n✅ Tests terminés avec succès!\n');
    process.exit(0);
  })
  .catch(error => {
    log(colors.red, '\n❌ Tests échoués:', error.message, '\n');
    process.exit(1);
  });
