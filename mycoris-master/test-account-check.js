/**
 * Test rapide de vérification du compte CorisMoney
 * Pour le numéro: 2250799283976
 */

// ⚠️ Désactiver la vérification SSL pour l'API testbed CorisMoney
// (certificat expiré sur testbed.corismoney.com)
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// Charger les variables d'environnement
require('dotenv').config();

const corisMoneyService = require('./services/corisMoneyService');

async function testAccount() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('🔍 VÉRIFICATION DU COMPTE CORISMONEY');
  console.log('═══════════════════════════════════════════════════════\n');
  
  const codePays = '225';
  const telephone = '0799283976';
  
  console.log(`📞 Numéro testé: ${codePays}${telephone}`);
  console.log('⏳ Récupération des informations...\n');
  
  try {
    const result = await corisMoneyService.getClientInfo(codePays, telephone);
    
    if (result.success) {
      console.log('✅ COMPTE TROUVÉ!\n');
      console.log('📊 Informations du client:');
      console.log(JSON.stringify(result.data, null, 2));
      
      // Extraire le solde
      const solde = parseFloat(result.data.solde || result.data.balance || 0);
      console.log(`\n💰 Solde disponible: ${solde.toLocaleString()} FCFA`);
      
      // Tester différents montants
      console.log('\n📋 Vérifications:');
      testMontant(solde, 5000);
      testMontant(solde, 15000);
      testMontant(solde, 50000);
      testMontant(solde, 100000);
      
    } else {
      console.log('❌ COMPTE INTROUVABLE!\n');
      console.log('⚠️ Erreur CorisMoney:');
      console.log(JSON.stringify(result.error, null, 2));
      console.log('\n📝 Message utilisateur qui sera affiché:');
      console.log('   "❌ Compte CorisMoney introuvable pour ce numéro"');
      console.log('   "Veuillez vérifier que votre compte CorisMoney est bien activé"');
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error.message);
  }
  
  console.log('\n═══════════════════════════════════════════════════════');
}

function testMontant(solde, montant) {
  const suffisant = solde >= montant;
  const icon = suffisant ? '✅' : '❌';
  const status = suffisant ? 'OK' : 'INSUFFISANT';
  
  console.log(`   ${icon} ${montant.toLocaleString()} FCFA → ${status}`);
  
  if (!suffisant) {
    const manquant = montant - solde;
    console.log(`      Il manque ${manquant.toLocaleString()} FCFA`);
  }
}

// Exécuter le test
testAccount().catch(console.error);
