/**
 * Script de test pour la fonctionnalité de changement de mot de passe
 * 
 * Teste 2 scénarios:
 * 1. Changement de mot de passe en auto-service (utilisateur connecté)
 * 2. Modification de mot de passe par l'admin
 */

const fetch = require('node-fetch');

const API_BASE = 'http://localhost:5000/api';

// Utilisateur de test (commercial)
const TEST_USER = {
  email: 'test.commercial@coris.ci',
  oldPassword: 'password123',
  newPassword: 'newpassword456'
};

// Admin pour test
const ADMIN_USER = {
  email: 'admin@coris.ci',
  password: 'admin123'
};

let userToken = '';
let adminToken = '';
let testUserId = '';

/**
 * Test 1: Login du commercial
 */
async function testLogin() {
  console.log('\n📝 Test 1: Login du commercial de test...');
  try {
    const response = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.oldPassword
      })
    });

    const data = await response.json();
    
    if (response.ok && data.token) {
      userToken = data.token;
      testUserId = data.user.id;
      console.log('✅ Login réussi');
      console.log(`   User ID: ${testUserId}`);
      console.log(`   Token: ${userToken.substring(0, 20)}...`);
      return true;
    } else {
      console.log('⚠️ Utilisateur de test non trouvé ou mot de passe incorrect');
      console.log('   Créez un utilisateur commercial avec ces identifiants:');
      console.log(`   Email: ${TEST_USER.email}`);
      console.log(`   Password: ${TEST_USER.oldPassword}`);
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur login:', error.message);
    return false;
  }
}

/**
 * Test 2: Changement de mot de passe en self-service
 */
async function testSelfServicePasswordChange() {
  console.log('\n📝 Test 2: Changement de mot de passe (self-service)...');
  try {
    const response = await fetch(`${API_BASE}/auth/change-password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userToken}`
      },
      body: JSON.stringify({
        oldPassword: TEST_USER.oldPassword,
        newPassword: TEST_USER.newPassword
      })
    });

    const data = await response.json();
    console.log(`   Status: ${response.status}`);
    console.log(`   Response:`, data);

    if (response.ok && data.success) {
      console.log('✅ Mot de passe changé avec succès');
      return true;
    } else {
      console.log('❌ Échec du changement de mot de passe');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    return false;
  }
}

/**
 * Test 3: Login avec le nouveau mot de passe
 */
async function testLoginWithNewPassword() {
  console.log('\n📝 Test 3: Login avec le nouveau mot de passe...');
  try {
    const response = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.newPassword
      })
    });

    const data = await response.json();
    
    if (response.ok && data.token) {
      console.log('✅ Login avec nouveau mot de passe réussi');
      userToken = data.token; // Mettre à jour le token
      return true;
    } else {
      console.log('❌ Login avec nouveau mot de passe échoué');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    return false;
  }
}

/**
 * Test 4: Login admin
 */
async function testAdminLogin() {
  console.log('\n📝 Test 4: Login administrateur...');
  try {
    const response = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: ADMIN_USER.email,
        password: ADMIN_USER.password
      })
    });

    const data = await response.json();
    
    if (response.ok && data.token) {
      adminToken = data.token;
      console.log('✅ Login admin réussi');
      return true;
    } else {
      console.log('⚠️ Utilisateur admin non trouvé');
      console.log('   Utilisez les identifiants admin existants');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    return false;
  }
}

/**
 * Test 5: Admin modifie le mot de passe utilisateur + code_apporteur
 */
async function testAdminPasswordChange() {
  console.log('\n📝 Test 5: Admin modifie le mot de passe et code_apporteur...');
  try {
    const response = await fetch(`${API_BASE}/admin/users/${testUserId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`
      },
      body: JSON.stringify({
        password: TEST_USER.oldPassword, // Remettre l'ancien mot de passe
        code_apporteur: 'TEST-COM-001'
      })
    });

    const data = await response.json();
    console.log(`   Status: ${response.status}`);
    console.log(`   Response:`, data);

    if (response.ok && data.success) {
      console.log('✅ Admin a modifié le mot de passe et code_apporteur');
      return true;
    } else {
      console.log('❌ Échec de la modification admin');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    return false;
  }
}

/**
 * Test 6: Login avec mot de passe remis par admin
 */
async function testLoginAfterAdminReset() {
  console.log('\n📝 Test 6: Login avec mot de passe remis par admin...');
  try {
    const response = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.oldPassword
      })
    });

    const data = await response.json();
    
    if (response.ok && data.token) {
      console.log('✅ Login réussi avec mot de passe remis par admin');
      console.log(`   Code apporteur: ${data.user.code_apporteur}`);
      return true;
    } else {
      console.log('❌ Login échoué');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    return false;
  }
}

/**
 * Exécution des tests
 */
async function runTests() {
  console.log('🧪 ========================================');
  console.log('🧪 TEST CHANGEMENT DE MOT DE PASSE');
  console.log('🧪 ========================================');

  let success = true;

  // Test 1: Login initial
  if (!await testLogin()) {
    console.log('\n❌ Impossible de continuer sans utilisateur de test');
    return;
  }

  // Test 2: Self-service password change
  if (!await testSelfServicePasswordChange()) {
    success = false;
  }

  // Test 3: Login avec nouveau mot de passe
  if (!await testLoginWithNewPassword()) {
    success = false;
  }

  // Test 4: Login admin
  if (!await testAdminLogin()) {
    console.log('\n⚠️ Tests admin ignorés (pas de compte admin configuré)');
  } else {
    // Test 5: Admin change password
    if (!await testAdminPasswordChange()) {
      success = false;
    }

    // Test 6: Login avec mot de passe remis par admin
    if (!await testLoginAfterAdminReset()) {
      success = false;
    }
  }

  console.log('\n🧪 ========================================');
  if (success) {
    console.log('✅ TOUS LES TESTS RÉUSSIS');
  } else {
    console.log('❌ CERTAINS TESTS ONT ÉCHOUÉ');
  }
  console.log('🧪 ========================================\n');
}

// Lancer les tests
runTests().catch(console.error);
