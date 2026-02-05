/**
 * Script de test des messages d'erreur CorisMoney améliorés
 * 
 * Ce script teste les différents scénarios d'erreur:
 * 1. Compte CorisMoney introuvable
 * 2. Solde insuffisant
 * 3. Code OTP invalide
 * 4. Paiement réussi
 */

const fetch = require('node-fetch');

const API_BASE = 'http://localhost:5000/api';

// Simule une connexion utilisateur (vous devez adapter le token)
const AUTH_TOKEN = 'YOUR_JWT_TOKEN_HERE';

/**
 * Test 1: Vérifier les informations d'un client CorisMoney
 */
async function testClientInfo(codePays, telephone) {
  console.log('\n🔍 TEST: Vérification des informations client');
  console.log(`📞 Numéro: ${codePays}${telephone}`);
  
  const corisMoneyService = require('./services/corisMoneyService');
  const result = await corisMoneyService.getClientInfo(codePays, telephone);
  
  if (result.success) {
    console.log('✅ Client trouvé!');
    console.log('📊 Données:', JSON.stringify(result.data, null, 2));
    return result.data;
  } else {
    console.log('❌ Client introuvable!');
    console.log('⚠️ Erreur:', result.error);
    return null;
  }
}

/**
 * Test 2: Tenter un paiement et observer les messages d'erreur
 */
async function testPayment(codePays, telephone, montant, codeOTP) {
  console.log('\n💳 TEST: Tentative de paiement');
  console.log(`📞 Numéro: ${codePays}${telephone}`);
  console.log(`💰 Montant: ${montant} FCFA`);
  console.log(`🔑 OTP: ${codeOTP}`);
  
  try {
    const response = await fetch(`${API_BASE}/payment/process-payment`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_TOKEN}`
      },
      body: JSON.stringify({
        codePays,
        telephone,
        montant,
        codeOTP,
        description: 'Test paiement - Messages erreur améliorés'
      })
    });
    
    const result = await response.json();
    
    console.log('\n📨 RÉPONSE SERVEUR:');
    console.log(`   Status HTTP: ${response.status}`);
    console.log(`   Success: ${result.success}`);
    console.log(`   Message: ${result.message}`);
    
    if (result.errorCode) {
      console.log(`   Code erreur: ${result.errorCode}`);
    }
    
    if (result.detail) {
      console.log(`   Détails: ${result.detail}`);
    }
    
    if (result.soldeDisponible !== undefined) {
      console.log(`   Solde disponible: ${result.soldeDisponible.toLocaleString()} FCFA`);
      console.log(`   Montant requis: ${result.montantRequis.toLocaleString()} FCFA`);
    }
    
    return result;
    
  } catch (error) {
    console.error('❌ Erreur réseau:', error.message);
    return null;
  }
}

/**
 * Scénarios de test
 */
async function runTests() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('🧪 TESTS DES MESSAGES D\'ERREUR CORISMONEY AMÉLIORÉS');
  console.log('═══════════════════════════════════════════════════════');
  
  // Test 1: Vérifier les infos du client
  console.log('\n📋 ÉTAPE 1: Vérification du compte CorisMoney');
  const clientData = await testClientInfo('225', '0799283976');
  
  if (!clientData) {
    console.log('\n⚠️ Le test s\'arrête ici car le compte n\'existe pas.');
    console.log('📝 Message attendu: "❌ Compte CorisMoney introuvable pour ce numéro"');
    return;
  }
  
  // Test 2: Vérifier le solde
  console.log('\n📋 ÉTAPE 2: Vérification du solde');
  const solde = parseFloat(clientData.solde || clientData.balance || 0);
  console.log(`💰 Solde disponible: ${solde.toLocaleString()} FCFA`);
  
  // Test 3: Tenter un paiement avec montant supérieur au solde
  if (solde < 100000) {
    console.log('\n📋 ÉTAPE 3: Test avec montant supérieur au solde');
    await testPayment('225', '0799283976', 100000, '12345');
    console.log('📝 Message attendu: "💰 Solde insuffisant"');
  }
  
  // Test 4: Tenter un paiement avec OTP invalide
  console.log('\n📋 ÉTAPE 4: Test avec OTP invalide');
  await testPayment('225', '0799283976', 1000, '00000');
  console.log('📝 Message attendu: "🔑 Code OTP invalide ou expiré"');
  
  console.log('\n═══════════════════════════════════════════════════════');
  console.log('✅ TESTS TERMINÉS');
  console.log('═══════════════════════════════════════════════════════');
  console.log('\n📌 RÉSUMÉ DES AMÉLIORATIONS:');
  console.log('   1. Vérification du compte AVANT le paiement');
  console.log('   2. Vérification du solde AVANT le paiement');
  console.log('   3. Messages d\'erreur explicites:');
  console.log('      - ACCOUNT_NOT_FOUND: Compte CorisMoney introuvable');
  console.log('      - INSUFFICIENT_BALANCE: Solde insuffisant (avec montants)');
  console.log('      - INVALID_OTP: Code OTP invalide ou expiré');
  console.log('      - PAYMENT_FAILED: Erreur générique');
}

// Lancer les tests
runTests().catch(console.error);
