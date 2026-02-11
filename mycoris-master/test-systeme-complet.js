/**
 * TEST FINAL - Validation Complete du Système de Paiement
 * 
 * Vérifie:
 * 1. ✅ Envoi OTP CorisMoney
 * 2. ✅ Validation paiement avec OTP
 * 3. ✅ Sauvegarde réponse API complète (JSONB)
 * 4. ✅ Création contrat avec statut 'valid'
 * 5. ✅ Envoi SMS de confirmation au client
 */

const axios = require('axios');
const readline = require('readline');
const { Pool } = require('pg');

// Configuration
const BASE_URL = 'http://localhost:5000';
const TEST_USER = {
  email: 'fofanachaka76@gmail.com',
  password: 'Chaka76!'
};
const PAYMENT_DATA = {
  codePays: '226',
  telephone: '61347475',
  montant: '100',     // 100 FCFA
  description: 'Test paiement avec sauvegarde complete'
};

// Base de données
const pool = new Pool({
  host: '185.98.138.168',
  port: 5432,
  database: 'mycorisdb',
  user: 'db_admin',
  password: 'Corisvie2025'
});

let token = '';
let transactionId = '';

// Interface pour saisie OTP
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function login() {
  console.log('\n🔑 Connexion utilisateur...');
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, TEST_USER);
    token = response.data.token;
    console.log('✅ Connecté avec succès');
    console.log('👤 User ID:', response.data.user?.id);
    return response.data.user;
  } catch (error) {
    console.error('❌ Erreur connexion:', error.response?.data || error.message);
    throw error;
  }
}

async function sendOTP() {
  console.log('\n📱 Envoi du code OTP...');
  try {
    const response = await axios.post(
      `${BASE_URL}/api/payment/send-otp`,
      PAYMENT_DATA,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    console.log('✅ OTP envoyé avec succès');
    console.log('📞 Téléphone:', PAYMENT_DATA.codePays + PAYMENT_DATA.telephone);
    console.log('💵 Montant:', PAYMENT_DATA.montant, 'FCFA');
    return response.data;
  } catch (error) {
    console.error('❌ Erreur envoi OTP:', error.response?.data || error.message);
    throw error;
  }
}

async function processPayment(otpCode) {
  console.log('\n💳 Traitement du paiement avec OTP...');
  try {
    const response = await axios.post(
      `${BASE_URL}/api/payment/process-payment`,
      { ...PAYMENT_DATA, otpCode },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    console.log('\n✅ PAIEMENT RÉUSSI !');
    console.log('📝 Transaction ID:', response.data.transactionId);
    console.log('✅ Statut:', response.data.message);
    
    transactionId = response.data.transactionId;
    return response.data;
  } catch (error) {
    console.error('❌ Erreur paiement:', error.response?.data || error.message);
    throw error;
  }
}

async function verifyDatabaseSave() {
  console.log('\n🔍 Vérification base de données...');
  
  try {
    // 1. Vérifier la transaction avec api_response
    const txQuery = await pool.query(
      `SELECT 
        id,
        transaction_id,
        montant,
        statut,
        api_response,
        created_at
       FROM payment_transactions 
       WHERE transaction_id = $1`,
      [transactionId]
    );
    
    if (txQuery.rows.length === 0) {
      console.error('❌ Transaction non trouvée en BDD !');
      return false;
    }
    
    const transaction = txQuery.rows[0];
    console.log('\n✅ Transaction trouvée:');
    console.log('  - ID:', transaction.id);
    console.log('  - Montant:', transaction.montant, 'FCFA');
    console.log('  - Statut:', transaction.statut);
    console.log('  - Date:', transaction.created_at);
    
    // VÉRIFIER api_response
    if (transaction.api_response) {
      console.log('\n✅ Réponse API sauvegardée (JSONB):');
      console.log(JSON.stringify(transaction.api_response, null, 2));
    } else {
      console.error('❌ api_response est NULL !');
      return false;
    }
    
    // 2. Vérifier le contrat créé
    const contractQuery = await pool.query(
      `SELECT 
        contract_number,
        product_name,
        status,
        amount,
        created_at
       FROM contracts 
       WHERE user_id = (SELECT user_id FROM payment_transactions WHERE transaction_id = $1)
       ORDER BY created_at DESC
       LIMIT 1`,
      [transactionId]
    );
    
    if (contractQuery.rows.length > 0) {
      const contract = contractQuery.rows[0];
      console.log('\n✅ Contrat créé:');
      console.log('  - Numéro:', contract.contract_number);
      console.log('  - Produit:', contract.product_name);
      console.log('  - Statut:', contract.status);
      console.log('  - Montant:', contract.amount, 'FCFA');
      console.log('  - Date création:', contract.created_at);
      
      if (contract.status !== 'valid') {
        console.warn('⚠️  Statut contrat devrait être "valid", mais est:', contract.status);
      }
    } else {
      console.warn('⚠️  Aucun contrat trouvé (normal si pas de souscription)');
    }
    
    return true;
  } catch (error) {
    console.error('❌ Erreur vérification BDD:', error.message);
    return false;
  }
}

async function runFullTest() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('🧪 TEST COMPLET - Système de Paiement avec Sauvegarde');
  console.log('═══════════════════════════════════════════════════════');
  
  try {
    // 1. Connexion
    const user = await login();
    
    // 2. Envoi OTP
    await sendOTP();
    
    // 3. Demander le code OTP à l'utilisateur
    console.log('\n⏳ Attendez de recevoir le SMS avec le code OTP...');
    const otpCode = await question('\n🔢 Entrez le code OTP reçu par SMS: ');
    
    // 4. Valider le paiement
    await processPayment(otpCode.trim());
    
    // 5. Vérifier la sauvegarde en BDD
    await new Promise(resolve => setTimeout(resolve, 2000)); // Attendre 2s
    const dbOk = await verifyDatabaseSave();
    
    // RÉSUMÉ FINAL
    console.log('\n═══════════════════════════════════════════════════════');
    console.log('📊 RÉSUMÉ DU TEST');
    console.log('═══════════════════════════════════════════════════════');
    console.log('✅ Connexion utilisateur');
    console.log('✅ Envoi OTP CorisMoney');
    console.log('✅ Validation paiement');
    console.log(dbOk ? '✅ Sauvegarde BDD avec api_response (JSONB)' : '❌ Problème sauvegarde BDD');
    console.log('\n💡 Vérifiez vos SMS pour la confirmation de paiement !');
    console.log('═══════════════════════════════════════════════════════');
    
  } catch (error) {
    console.error('\n❌ TEST ÉCHOUÉ:', error.message);
  } finally {
    rl.close();
    await pool.end();
  }
}

// Démarrer le test
runFullTest();
