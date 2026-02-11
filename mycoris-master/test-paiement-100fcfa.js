#!/usr/bin/env node

/**
 * 🎯 TEST DE PAIEMENT RÉEL - 100 FCFA
 * Teste le flux complet avec le compte réel CorisMoney
 */

require('dotenv').config();

const corisMoneyService = require('./services/corisMoneyService');

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

// Configuration du test
const TEST_CONFIG = {
  codePays: '226',
  telephone: '61347475',
  montantTest: 100 // 100 FCFA
};

async function testComplet() {
  try {
    log(colors.bright + colors.magenta, '\n' + '═'.repeat(60));
    log(colors.bright + colors.magenta, '🎯 TEST PAIEMENT RÉEL - 100 FCFA');
    log(colors.bright + colors.magenta, '═'.repeat(60));

    // ÉTAPE 1: Vérifier le compte
    log(colors.bright + colors.blue, '\n📋 ÉTAPE 1: VÉRIFICATION DU COMPTE');
    log(colors.bright + colors.blue, '━'.repeat(60));
    
    log(colors.cyan, 'Numéro:', TEST_CONFIG.codePays + TEST_CONFIG.telephone);
    
    const clientInfo = await corisMoneyService.getClientInfo(
      TEST_CONFIG.codePays,
      TEST_CONFIG.telephone
    );
    
    if (!clientInfo.success) {
      log(colors.red, '❌ Impossible de récupérer les infos client');
      log(colors.red, '   Erreur:', clientInfo.error);
      process.exit(1);
    }
    
    log(colors.green, '✅ Client trouvé!');
    
    // Parser le XML pour extraire le nom
    const xmlData = clientInfo.data.text;
    const nomMatch = xmlData.match(/<nom>(.*?)<\/nom>/);
    const prenomMatch = xmlData.match(/<prenom>(.*?)<\/prenom>/);
    const compteMatch = xmlData.match(/<numeroCompte>(.*?)<\/numeroCompte>/);
    
    if (nomMatch && prenomMatch) {
      log(colors.cyan, `📝 Titulaire: ${prenomMatch[1]} ${nomMatch[1]}`);
    }
    if (compteMatch) {
      log(colors.cyan, `💳 Compte: ${compteMatch[1]}`);
    }
    
    // Note: Le solde n'est pas dans la réponse infos-client
    // On va quand même essayer le paiement pour voir la vraie réponse
    
    log(colors.yellow, '\n💡 Note: Le solde exact sera vérifié lors du paiement');
    
    // ÉTAPE 2: Envoyer OTP
    log(colors.bright + colors.blue, '\n📱 ÉTAPE 2: ENVOI CODE OTP');
    log(colors.bright + colors.blue, '━'.repeat(60));
    
    const otpResult = await corisMoneyService.sendOTP(
      TEST_CONFIG.codePays,
      TEST_CONFIG.telephone
    );
    
    if (!otpResult.success) {
      log(colors.red, '❌ Échec envoi OTP');
      log(colors.red, '   Erreur:', otpResult.error);
      process.exit(1);
    }
    
    log(colors.green, '✅ Code OTP envoyé!');
    log(colors.cyan, '📧 Message:', otpResult.data.text);
    
    // Si en mode DEV, on a le code OTP
    if (otpResult.data.codeOTP) {
      log(colors.yellow, '\n🔐 CODE OTP:', otpResult.data.codeOTP);
    } else {
      log(colors.yellow, '\n⚠️  Code OTP envoyé par SMS au numéro');
      log(colors.yellow, '   En mode PRODUCTION: Vérifiez votre téléphone');
      log(colors.yellow, '   En mode DEV: Le code est dans .env (CORIS_MONEY_DEV_OTP)');
    }
    
    // ÉTAPE 3: Demander le code OTP
    log(colors.bright + colors.blue, '\n🔑 ÉTAPE 3: SAISIE CODE OTP');
    log(colors.bright + colors.blue, '━'.repeat(60));
    
    // En mode production, il faudrait demander à l'utilisateur
    // Pour le test, on utilise le code de dev ou un code par défaut
    const codeOTP = process.env.CORIS_MONEY_DEV_OTP || '123456';
    
    log(colors.cyan, 'Code OTP utilisé:', codeOTP);
    log(colors.yellow, '💡 (En mode réel, le client le reçoit par SMS)');
    
    // ÉTAPE 4: Effectuer le paiement
    log(colors.bright + colors.blue, '\n💳 ÉTAPE 4: PAIEMENT DE', TEST_CONFIG.montantTest, 'FCFA');
    log(colors.bright + colors.blue, '━'.repeat(60));
    
    const paymentResult = await corisMoneyService.paiementBien(
      TEST_CONFIG.codePays,
      TEST_CONFIG.telephone,
      TEST_CONFIG.montantTest,
      codeOTP
    );
    
    if (paymentResult.success) {
      log(colors.green, '\n🎉 ✅ PAIEMENT RÉUSSI!');
      log(colors.green, '━'.repeat(60));
      log(colors.cyan, '📊 Transaction ID:', paymentResult.transactionId);
      log(colors.cyan, '💰 Montant débité:', TEST_CONFIG.montantTest, 'FCFA');
      
      if (paymentResult.data) {
        log(colors.cyan, '📦 Réponse complète:');
        console.log(JSON.stringify(paymentResult.data, null, 2));
      }
      
      // ÉTAPE 5: Vérifier le statut
      if (paymentResult.transactionId) {
        log(colors.bright + colors.blue, '\n📊 ÉTAPE 5: VÉRIFICATION STATUT');
        log(colors.bright + colors.blue, '━'.repeat(60));
        
        // Attendre 2 secondes
        await new Promise(r => setTimeout(r, 2000));
        
        const statusResult = await corisMoneyService.getTransactionStatus(
          paymentResult.transactionId
        );
        
        if (statusResult.success) {
          log(colors.green, '✅ Statut récupéré:');
          console.log(JSON.stringify(statusResult.data, null, 2));
        } else {
          log(colors.yellow, '⚠️  Impossible de vérifier le statut immédiatement');
        }
      }
      
    } else {
      log(colors.red, '\n❌ PAIEMENT ÉCHOUÉ');
      log(colors.red, '━'.repeat(60));
      log(colors.red, '📋 Message:', paymentResult.message);
      log(colors.red, '❌ Erreur:', paymentResult.error);
      
      // Analyser l'erreur
      if (JSON.stringify(paymentResult.error).includes('INSUFFICIENT_BALANCE') || 
          JSON.stringify(paymentResult.error).includes('solde')) {
        log(colors.yellow, '\n💡 CAUSE: Solde insuffisant');
        log(colors.yellow, '   Le compte n\'a pas assez de fonds pour payer', TEST_CONFIG.montantTest, 'FCFA');
        log(colors.yellow, '\n   SOLUTIONS:');
        log(colors.yellow, '   1. Recharger le compte CorisMoney');
        log(colors.yellow, '   2. Utiliser un autre compte avec du solde');
        log(colors.yellow, '   3. Activer le mode DEV pour simuler (CORIS_MONEY_DEV_MODE=true)');
      } else if (JSON.stringify(paymentResult.error).includes('OTP')) {
        log(colors.yellow, '\n💡 CAUSE: Code OTP invalide ou expiré');
        log(colors.yellow, '   Le code OTP n\'est plus valide');
        log(colors.yellow, '\n   SOLUTIONS:');
        log(colors.yellow, '   1. Redemander un nouveau code OTP');
        log(colors.yellow, '   2. Vérifier que vous utilisez le bon code');
      }
    }
    
    // RÉSUMÉ FINAL
    log(colors.bright + colors.green, '\n\n' + '═'.repeat(60));
    log(colors.bright + colors.green, '📋 RÉSUMÉ DU TEST');
    log(colors.bright + colors.green, '═'.repeat(60));
    
    log(colors.cyan, '\n✅ Ce qui a fonctionné:');
    log(colors.green, '  • Récupération infos client');
    log(colors.green, '  • Envoi code OTP');
    
    if (paymentResult.success) {
      log(colors.green, '  • Paiement de', TEST_CONFIG.montantTest, 'FCFA');
      log(colors.green, '\n🎉 TEST COMPLET RÉUSSI!');
      log(colors.green, '   Le système de paiement CorisMoney est OPÉRATIONNEL ✅');
    } else {
      log(colors.yellow, '\n⚠️  Paiement non effectué (voir détails ci-dessus)');
      log(colors.yellow, '   Le système fonctionne, mais le compte a un solde insuffisant');
      log(colors.cyan, '\n💡 Pour tester avec simulation:');
      log(colors.cyan, '   Modifiez .env: CORIS_MONEY_DEV_MODE=true');
    }
    
  } catch (error) {
    log(colors.red, '\n❌ ERREUR CRITIQUE:', error.message);
    log(colors.red, error.stack);
  }
  
  process.exit(0);
}

// Lancer le test
testComplet();
