#!/usr/bin/env node

/**
 * 🧪 TEST SSL FIX
 * Teste que les corrections SSL sont bien appliquées
 */

require('dotenv').config();

const corisMoneyService = require('./services/corisMoneyService');

async function test() {
  console.log('🧪 ═══════════════════════════════════════');
  console.log('🧪 TEST CORRECTIONS SSL');
  console.log('🧪 ═══════════════════════════════════════');
  console.log();

  const codePays = '226';
  const telephone = '61347475';

  console.log('📋 Configuration:');
  console.log('   Code Pays:', codePays);
  console.log('   Téléphone:', telephone);
  console.log('   API URL:', process.env.CORIS_MONEY_BASE_URL);
  console.log('   Certificat:', 'SSL désactivé (testbed)');
  console.log();

  console.log('🔍 Test 1: Récupérer infos client (getClientInfo)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  try {
    const result = await corisMoneyService.getClientInfo(codePays, telephone);
    
    if (result.success) {
      console.log('✅ SUCCÈS!');
      console.log('📦 Données reçues:');
      console.log(JSON.stringify(result.data, null, 2));
    } else {
      console.log('❌ ÉCHEC');
      console.log('📦 Erreur:');
      console.log(JSON.stringify(result.error, null, 2));
      console.log('   Message:', result.message);
      if (result.errorCode) {
        console.log('   Code d\'erreur:', result.errorCode);
      }
    }
  } catch (error) {
    console.log('❌ EXCEPTION');
    console.log('   Erreur:', error.message);
    console.log('   Stack:', error.stack);
  }

  console.log();
  console.log('✅ Test terminé');
  process.exit(0);
}

test().catch(error => {
  console.error('❌ Erreur:', error);
  process.exit(1);
});
