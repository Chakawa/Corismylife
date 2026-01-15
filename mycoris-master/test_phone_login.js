/**
 * Test de connexion avec un numéro sans +225
 */

const axios = require('axios');

async function testLogin() {
  try {
    console.log('🧪 Test de connexion avec numéro sans +225...\n');

    // Test 1: Connexion avec le numéro SANS +225
    const testPhone1 = '0700000001';
    const password = 'SuperAdmin2025!';

    console.log('📱 Test 1: Connexion avec', testPhone1);
    
    const response1 = await axios.post('http://localhost:5000/api/auth/login', {
      identifier: testPhone1,
      password: password
    });

    console.log('✅ Connexion réussie!');
    console.log('👤 Utilisateur:', response1.data.user.prenom, response1.data.user.nom);
    console.log('📞 Téléphone enregistré:', response1.data.user.telephone);
    console.log('🎫 Token reçu:', response1.data.token.substring(0, 50) + '...\n');

    // Test 2: Connexion avec le numéro AVEC +225
    const testPhone2 = '+2250700000001';
    
    console.log('📱 Test 2: Connexion avec', testPhone2);
    
    const response2 = await axios.post('http://localhost:5000/api/auth/login', {
      identifier: testPhone2,
      password: password
    });

    console.log('✅ Connexion réussie!');
    console.log('👤 Utilisateur:', response2.data.user.prenom, response2.data.user.nom);
    console.log('📞 Téléphone enregistré:', response2.data.user.telephone);
    console.log('🎫 Token reçu:', response2.data.token.substring(0, 50) + '...\n');

    console.log('🎉 Les deux méthodes de connexion fonctionnent!');

  } catch (error) {
    console.error('❌ Erreur lors du test:', error.response?.data?.message || error.message);
  }
}

testLogin();
