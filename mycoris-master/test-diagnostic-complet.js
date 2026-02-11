#!/usr/bin/env node

/**
 * 🔍 TEST DIAGNOSTIC COMPLET - PAIEMENT CORISMONEY
 * Vérifie:
 * 1. Horloge système
 * 2. Certificats SSL
 * 3. Connexion CorisMoney
 * 4. Flux complet: OTP → Payment → Contract
 */

require('dotenv').config();

const https = require('https');
const axios = require('axios');
const corisMoneyService = require('./services/corisMoneyService');

// COULEURS POUR AFFICHAGE
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(color, ...args) {
  console.log(color, ...args, colors.reset);
}

async function checkSystemTime() {
  log(colors.bright + colors.blue, '\n📅 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '📅 VÉRIFICATION HORLOGE SYSTÈME');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  const now = new Date();
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
  
  log(colors.cyan, '🕐 Heure système:', now.toISOString());
  log(colors.cyan, '🌍 Fuseau horaire:', timezone);
  log(colors.cyan, '📍 ISO String:', now.toISOString());
  log(colors.cyan, '⏱️  Timestamp:', now.getTime());
  
  // Info Côte d'Ivoire
  log(colors.yellow, '\n💡 Côte d\'Ivoire (Abidjan):');
  log(colors.yellow, '   Fuseau: UTC+0 (GMT)');
  log(colors.yellow, '   Pas d\'heure d\'été');
  
  return now;
}

async function checkSSLCertificates() {
  log(colors.bright + colors.blue, '\n🔒 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '🔒 VÉRIFICATION CERTIFICATS SSL');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  const host = 'testbed.corismoney.com';
  const port = 443;
  
  return new Promise((resolve) => {
    const options = {
      host: host,
      port: port,
      method: 'HEAD'
    };
    
    const req = https.request(options, (res) => {
      const cert = res.socket.getPeerCertificate();
      
      log(colors.cyan, '\n📜 Certificat reçu:');
      log(colors.cyan, '   Sujet:', cert.subject?.CN || 'N/A');
      log(colors.cyan, '   Émetteur:', cert.issuer?.CN || 'N/A');
      log(colors.cyan, '   Valide du:', new Date(cert.valid_from).toISOString());
      log(colors.cyan, '   Valide jusqu\'au:', new Date(cert.valid_to).toISOString());
      
      const validFrom = new Date(cert.valid_from);
      const validTo = new Date(cert.valid_to);
      const now = new Date();
      
      if (now >= validFrom && now <= validTo) {
        log(colors.green, '✅ Certificat VALIDE');
      } else if (now > validTo) {
        log(colors.red, '❌ Certificat EXPIRÉ');
      } else if (now < validFrom) {
        log(colors.red, '❌ Certificat pas encore valide');
        log(colors.yellow, '💡 PROBLÈME PROBABLE: Horloge système trop en retard');
      }
      
      resolve(cert);
    });
    
    req.on('error', (err) => {
      log(colors.red, '❌ Erreur certificat:', err.message);
      resolve(null);
    });
    
    req.end();
  });
}

async function testOTPSending() {
  log(colors.bright + colors.blue, '\n📱 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '📱 TEST 1: ENVOI OTP');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  const codePays = '226';
  const telephone = '61347475';
  
  log(colors.cyan, 'Paramètres:');
  log(colors.cyan, '   Code Pays:', codePays);
  log(colors.cyan, '   Téléphone:', telephone);
  
  try {
    const result = await corisMoneyService.sendOTP(codePays, telephone);
    
    if (result.success) {
      log(colors.green, '✅ OTP envoyé avec succès!');
      log(colors.cyan, '📦 Réponse:', JSON.stringify(result.data, null, 2));
      return result.data;
    } else {
      log(colors.red, '❌ Échec envoi OTP');
      log(colors.red, '❌ Erreur:', JSON.stringify(result.error, null, 2));
      return null;
    }
  } catch (error) {
    log(colors.red, '❌ Exception:', error.message);
    return null;
  }
}

async function testGetClientInfo() {
  log(colors.bright + colors.blue, '\n👤 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '👤 TEST 2: RÉCUPÉRER INFOS CLIENT');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  const codePays = '226';
  const telephone = '61347475';
  
  log(colors.cyan, 'Paramètres:');
  log(colors.cyan, '   Code Pays:', codePays);
  log(colors.cyan, '   Téléphone:', telephone);
  
  try {
    const result = await corisMoneyService.getClientInfo(codePays, telephone);
    
    if (result.success) {
      log(colors.green, '✅ Infos client récupérées!');
      log(colors.cyan, '📦 Données:');
      const firstLine = result.data.text?.split('\n')[0] || result.data;
      log(colors.cyan, firstLine);
      return result.data;
    } else {
      log(colors.red, '❌ Impossible de récupérer infos client');
      log(colors.red, '❌ Erreur:', result.error);
      return null;
    }
  } catch (error) {
    log(colors.red, '❌ Exception:', error.message);
    return null;
  }
}

async function testPayment() {
  log(colors.bright + colors.blue, '\n💳 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '💳 TEST 3: EFFECTUER UN PAIEMENT');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  const codePays = '226';
  const telephone = '61347475';
  const montant = 100; // Test avec 100 FCFA
  const codeOTP = process.env.CORIS_MONEY_DEV_OTP || '123456';
  
  log(colors.cyan, 'Paramètres:');
  log(colors.cyan, '   Code Pays:', codePays);
  log(colors.cyan, '   Téléphone:', telephone);
  log(colors.cyan, '   Montant:', montant, 'FCFA');
  log(colors.cyan, '   Code OTP:', codeOTP);
  log(colors.yellow, '   Mode:', process.env.CORIS_MONEY_DEV_MODE === 'true' ? 'DÉVELOPPEMENT' : 'PRODUCTION');
  
  try {
    const result = await corisMoneyService.paiementBien(
      codePays,
      telephone,
      montant,
      codeOTP
    );
    
    if (result.success) {
      log(colors.green, '✅ Paiement effectué!');
      log(colors.cyan, '📦 Transaction ID:', result.transactionId);
      return result.data;
    } else {
      log(colors.red, '❌ Paiement échoué');
      log(colors.red, '❌ Erreur:', result.error);
      return null;
    }
  } catch (error) {
    log(colors.red, '❌ Exception:', error.message);
    return null;
  }
}

async function testTransactionStatus() {
  log(colors.bright + colors.blue, '\n📊 ═══════════════════════════════════════');
  log(colors.bright + colors.blue, '📊 TEST 4: VÉRIFIER STATUT TRANSACTION');
  log(colors.bright + colors.blue, '═══════════════════════════════════════');
  
  // Pour ce test, on utilise un ID de test
  const transactionId = 'TEST-' + Date.now();
  
  log(colors.cyan, 'Paramètres:');
  log(colors.cyan, '   Transaction ID:', transactionId);
  
  try {
    const result = await corisMoneyService.getTransactionStatus(transactionId);
    
    if (result.success) {
      log(colors.green, '✅ Statut récupéré!');
      log(colors.cyan, '📦 Statut:', result.data);
      return result.data;
    } else {
      log(colors.yellow, '⚠️  Impossible de vérifier le statut (peut être normal pour ID test)');
      return null;
    }
  } catch (error) {
    log(colors.yellow, '⚠️  Exception:', error.message);
    return null;
  }
}

async function runAllTests() {
  try {
    log(colors.bright + colors.green, '\n' + '═'.repeat(50));
    log(colors.bright + colors.green, '🧪 DIAGNOSTIC COMPLET - SYSTÈME PAIEMENT CORISMONEY');
    log(colors.bright + colors.green, '═'.repeat(50));
    
    // Vérifier l'heure
    await checkSystemTime();
    
    // Vérifier les certificats SSL
    await checkSSLCertificates();
    
    // Tests CorisMoney
    log(colors.bright + colors.green, '\n\n🔄 TESTS CORISMONEY');
    log(colors.bright + colors.green, '═'.repeat(50));
    
    // Test 1: OTP
    const otpResult = await testOTPSending();
    
    // Test 2: Client Info
    const clientResult = await testGetClientInfo();
    
    // Test 3: Payment
    const paymentResult = await testPayment();
    
    // Test 4: Transaction Status
    const statusResult = await testTransactionStatus();
    
    // RÉSUMÉ FINAL
    log(colors.bright + colors.green, '\n\n📋 ═══════════════════════════════════════');
    log(colors.bright + colors.green, '📋 RÉSUMÉ DES RÉSULTATS');
    log(colors.bright + colors.green, '═══════════════════════════════════════\n');
    
    const results = {
      'OTP envoyé': otpResult ? '✅' : '❌',
      'Infos client': clientResult ? '✅' : '❌',
      'Paiement': paymentResult ? '✅' : '❌',
      'Statut transaction': statusResult ? '✅' : '❌'
    };
    
    Object.entries(results).forEach(([test, status]) => {
      const color = status === '✅' ? colors.green : colors.red;
      log(color, `  ${status} ${test}`);
    });
    
    log(colors.bright + colors.yellow, '\n💡 ACTIONS À FAIRE:');
    log(colors.yellow, '  1. Si certificat expiré: Vérifier horloge système');
    log(colors.yellow, '  2. Si horloge non synchronisée: Synchroniser avec NTP');
    log(colors.yellow, '  3. Si OTP/Payment échouent: Vérifier identifiants CorisMoney');
    log(colors.yellow, '  4. Chercher "Erreur lors de" dans les logs pour erreurs détaillées');
    
  } catch (error) {
    log(colors.red, '\n❌ ERREUR CRITICAL:', error.message);
    log(colors.red, error.stack);
  }
  
  process.exit(0);
}

// Lancer tous les tests
runAllTests();
