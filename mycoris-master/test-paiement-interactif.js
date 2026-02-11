#!/usr/bin/env node

/**
 * 💳 TEST PAIEMENT INTERACTIF - 100 FCFA
 * 1. Envoie l'OTP au téléphone
 * 2. Demande à l'utilisateur de saisir le code reçu
 * 3. Effectue le paiement
 */

require('dotenv').config();

const readline = require('readline');
const corisMoneyService = require('./services/corisMoneyService');

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

// Configuration
const CONFIG = {
  codePays: '226',
  telephone: '61347475',
  montant: 100,  // 100 FCFA
};

// Interface pour saisie utilisateur
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function runTest() {
  try {
    log(colors.bright + colors.magenta, '\n' + '═'.repeat(60));
    log(colors.bright + colors.magenta, '💳 TEST PAIEMENT INTERACTIF - 100 FCFA');
    log(colors.bright + colors.magenta, '═'.repeat(60));

    // ÉTAPE 1: Afficher les informations
    log(colors.bright + colors.blue, '\n📋 CONFIGURATION:');
    log(colors.cyan, `   Code Pays: ${CONFIG.codePays}`);
    log(colors.cyan, `   Téléphone: ${CONFIG.telephone}`);
    log(colors.cyan, `   Numéro complet: ${CONFIG.codePays}${CONFIG.telephone}`);
    log(colors.cyan, `   Montant: ${CONFIG.montant} FCFA`);
    log(colors.cyan, `   Mode: ${process.env.CORIS_MONEY_DEV_MODE === 'true' ? 'DÉVELOPPEMENT' : 'PRODUCTION'}`);

    // ÉTAPE 2: Vérifier les infos client
    log(colors.bright + colors.blue, '\n📱 ÉTAPE 1: VÉRIFICATION DU COMPTE');
    log(colors.blue, '━'.repeat(60));

    const clientInfo = await corisMoneyService.getClientInfo(CONFIG.codePays, CONFIG.telephone);
    
    if (!clientInfo.success) {
      log(colors.red, '❌ Impossible de trouver le compte CorisMoney');
      log(colors.red, '   Erreur:', clientInfo.error);
      rl.close();
      process.exit(1);
    }

    log(colors.green, '✅ Compte trouvé!');
    
    // Parser le XML pour extraire les infos
    const xmlText = clientInfo.data.text || '';
    const nomMatch = xmlText.match(/<nom>(.*?)<\/nom>/);
    const prenomMatch = xmlText.match(/<prenom>(.*?)<\/prenom>/);
    const compteMatch = xmlText.match(/<numeroCompte>(.*?)<\/numeroCompte>/);
    
    if (nomMatch && prenomMatch) {
      log(colors.cyan, `   Titulaire: ${prenomMatch[1]} ${nomMatch[1]}`);
    }
    if (compteMatch) {
      log(colors.cyan, `   Numéro compte: ${compteMatch[1]}`);
    }

    // ÉTAPE 3: Envoyer l'OTP
    log(colors.bright + colors.blue, '\n🔐 ÉTAPE 2: ENVOI DU CODE OTP');
    log(colors.blue, '━'.repeat(60));

    const otpResult = await corisMoneyService.sendOTP(CONFIG.codePays, CONFIG.telephone);
    
    if (!otpResult.success) {
      log(colors.red, '❌ Échec envoi OTP');
      log(colors.red, '   Erreur:', otpResult.error);
      rl.close();
      process.exit(1);
    }

    log(colors.green, `✅ Code OTP envoyé au ${CONFIG.codePays}${CONFIG.telephone}`);
    
    // Si en mode DEV, afficher le code
    if (process.env.CORIS_MONEY_DEV_MODE === 'true') {
      log(colors.yellow, '\n🔐 MODE DEV ACTIVÉ');
      log(colors.yellow, `   Code OTP de test: ${process.env.CORIS_MONEY_DEV_OTP || '123456'}`);
    } else {
      log(colors.yellow, '\n📱 Vérifiez votre téléphone!');
      log(colors.yellow, `   Un SMS a été envoyé au ${CONFIG.codePays}${CONFIG.telephone}`);
      
      // Si l'API retourne le code (testbed parfois le fait)
      if (otpResult.data.codeOTP) {
        log(colors.bright + colors.green, '\n🎉 CODE OTP REÇU DE L\'API:');
        log(colors.bright + colors.green, `   >>> ${otpResult.data.codeOTP} <<<`);
      }
    }

    // ÉTAPE 4: Demander le code OTP
    log(colors.bright + colors.blue, '\n⌨️  ÉTAPE 3: SAISIE DU CODE OTP');
    log(colors.blue, '━'.repeat(60));

    const codeOTP = await question(colors.yellow + '   Entrez le code OTP reçu: ' + colors.reset);
    
    if (!codeOTP || codeOTP.trim().length === 0) {
      log(colors.red, '❌ Code OTP vide');
      rl.close();
      process.exit(1);
    }

    log(colors.cyan, `   Code saisi: ${codeOTP.trim()}`);

    // ÉTAPE 5: Effectuer le paiement
    log(colors.bright + colors.blue, '\n💳 ÉTAPE 4: PAIEMENT');
    log(colors.blue, '━'.repeat(60));

    log(colors.cyan, `   Montant à débiter: ${CONFIG.montant} FCFA`);
    log(colors.yellow, '   Traitement en cours...');

    const paymentResult = await corisMoneyService.paiementBien(
      CONFIG.codePays,
      CONFIG.telephone,
      CONFIG.montant,
      codeOTP.trim()
    );

    // ÉTAPE 6: Afficher le résultat
    log(colors.bright + colors.blue, '\n📊 RÉSULTAT');
    log(colors.blue, '━'.repeat(60));

    // Vérifier le vrai statut (code -1 = échec)
    const isRealSuccess = paymentResult.success && 
                          paymentResult.data?.code !== '-1' &&
                          !paymentResult.data?.message?.toLowerCase().includes('erreur');

    if (isRealSuccess) {
      log(colors.bright + colors.green, '\n🎉 PAIEMENT RÉUSSI !');
      log(colors.green, '   Transaction ID:', paymentResult.transactionId || 'N/A');
      log(colors.green, '   Montant débité:', CONFIG.montant, 'FCFA');
      
      if (paymentResult.data) {
        log(colors.cyan, '\n📦 Détails:');
        log(colors.cyan, JSON.stringify(paymentResult.data, null, 2));
      }

      // Vérifier le statut
      if (paymentResult.transactionId) {
        log(colors.yellow, '\n🔍 Vérification du statut...');
        
        await new Promise(r => setTimeout(r, 2000));
        
        const statusResult = await corisMoneyService.getTransactionStatus(paymentResult.transactionId);
        
        if (statusResult.success) {
          log(colors.green, '✅ Statut vérifié:');
          log(colors.cyan, JSON.stringify(statusResult.data, null, 2));
        }
      }

    } else {
      log(colors.bright + colors.red, '\n❌ PAIEMENT ÉCHOUÉ');
      
      // Afficher le message d'erreur de l'API
      const errorMsg = paymentResult.data?.message || paymentResult.message || 'Erreur inconnue';
      const errorCode = paymentResult.data?.code || paymentResult.error?.code || 'N/A';
      
      log(colors.red, '   Code erreur:', errorCode);
      log(colors.red, '   Message:', errorMsg);
      
      if (paymentResult.data) {
        log(colors.cyan, '\n📦 Réponse complète de l\'API:');
        log(colors.cyan, JSON.stringify(paymentResult.data, null, 2));
      }
      
      if (paymentResult.error) {
        log(colors.cyan, '\n📦 Détails de l\'erreur:');
        log(colors.cyan, JSON.stringify(paymentResult.error, null, 2));
      }

      // Messages d'aide selon l'erreur
      const fullError = JSON.stringify(paymentResult.data) + JSON.stringify(paymentResult.error);
      
      if (fullError.includes('OTP')) {
        log(colors.yellow, '\n💡 Le code OTP est peut-être:');
        log(colors.yellow, '   - Incorrect');
        log(colors.yellow, '   - Expiré (validité ~5 minutes)');
        log(colors.yellow, '   - Déjà utilisé');
      } else if (fullError.includes('BALANCE') || fullError.includes('solde')) {
        log(colors.yellow, '\n💡 Le solde du compte est peut-être insuffisant');
      } else if (fullError.includes('type de service') || fullError.includes('ne pouvez pas')) {
        log(colors.yellow, '\n💡 CAUSE: Compte non autorisé pour ce type de transaction');
        log(colors.yellow, '   Le compte CorisMoney n\'a pas les permissions pour "paiement-bien"');
        log(colors.yellow, '\n   SOLUTIONS:');
        log(colors.yellow, '   1. Vérifier avec CorisMoney que le compte est activé pour les paiements');
        log(colors.yellow, '   2. Utiliser un autre type de transaction');
        log(colors.yellow, '   3. Contacter le support CorisMoney pour activer les paiements');
        log(colors.yellow, '   4. Utiliser le MODE DEV pour tester (CORIS_MONEY_DEV_MODE=true)');
      }
    }

    log(colors.bright + colors.green, '\n' + '═'.repeat(60));
    log(colors.bright + colors.green, '✅ TEST TERMINÉ');
    log(colors.bright + colors.green, '═'.repeat(60) + '\n');

  } catch (error) {
    log(colors.red, '\n❌ ERREUR:', error.message);
    log(colors.red, error.stack);
  } finally {
    rl.close();
    process.exit(0);
  }
}

// Lancer le test
runTest();
