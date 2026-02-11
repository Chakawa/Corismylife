/**
 * TEST PERSONNALISÉ - Votre numéro : 2250576097537
 * 
 * Mode DEV activé pour simuler (car pas de compte testbed)
 * Objectif: Voir le flux complet + recevoir le SMS
 */

const axios = require('axios');
const readline = require('readline');

// Configuration
const BASE_URL = 'http://127.0.0.1:5000'; // IPv4 au lieu de localhost pour éviter les problèmes IPv6

// VOTRE NUMÉRO
const PAYMENT_DATA = {
  codePays: '225',
  telephone: '0576097537',
  montant: '100',
  description: 'Test avec mon numéro personnel'
};

let token = '';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function login() {
  console.log('\n🔑 Connexion utilisateur...');
  console.log('📧 Email: fofanachaka76@gmail.com');
  
  const password = await question('🔐 Entrez votre mot de passe: ');
  
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'fofanachaka76@gmail.com',
      password: password.trim()
    });
    token = response.data.token;
    console.log('✅ Connecté');
    return response.data.user;
  } catch (error) {
    console.error('❌ Erreur connexion:', error.response?.data || error.message);
    throw error;
  }
}

async function sendOTP() {
  console.log('\n📱 Envoi du code OTP à votre numéro...');
  console.log('📞 Numéro:', PAYMENT_DATA.codePays + PAYMENT_DATA.telephone);
  
  try {
    const response = await axios.post(
      `${BASE_URL}/api/payment/send-otp`,
      PAYMENT_DATA,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    console.log('✅ OTP envoyé !');
    console.log('💵 Montant:', PAYMENT_DATA.montant, 'FCFA');
    return response.data;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    throw error;
  }
}

async function processPayment(otpCode) {
  console.log('\n💳 Traitement du paiement...');
  try {
    const response = await axios.post(
      `${BASE_URL}/api/payment/process-payment`,
      { ...PAYMENT_DATA, codeOTP: otpCode },
      { headers: { Authorization: `Bearer ${token}` } }
    );
    
    console.log('\n✅ PAIEMENT TRAITÉ !');
    console.log('📝 Réponse:', response.data);
    return response.data;
  } catch (error) {
    // Normal si pas de compte testbed
    console.log('\n⚠️  Erreur attendue (pas de compte testbed):');
    console.log(error.response?.data || error.message);
    return null;
  }
}

async function runTest() {
  console.log('════════════════════════════════════════════════════════');
  console.log('🧪 TEST AVEC VOTRE NUMÉRO: 2250576097537');
  console.log('════════════════════════════════════════════════════════');
  
  try {
    // 1. Connexion
    await login();
    
    // 2. Envoi OTP
    await sendOTP();
    
    // 3. Demander le code OTP
    console.log('\n⏳ Vérifiez votre téléphone (2250576097537)...');
    const otpCode = await question('\n🔢 Entrez le code OTP reçu par SMS: ');
    
    // 4. Traiter le paiement
    await processPayment(otpCode.trim());
    
    console.log('\n════════════════════════════════════════════════════════');
    console.log('✅ TEST TERMINÉ');
    console.log('💡 Vérifiez si vous avez reçu le SMS !');
    console.log('════════════════════════════════════════════════════════');
    
  } catch (error) {
    console.error('\n❌ ERREUR:', error.message);
  } finally {
    rl.close();
  }
}

runTest();
