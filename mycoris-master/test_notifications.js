/**
 * ========================================
 * SCRIPT DE TEST - SYSTÈME DE NOTIFICATIONS
 * ========================================
 * 
 * Ce script teste toutes les fonctions de création de notifications
 * pour s'assurer qu'elles fonctionnent correctement.
 * 
 * UTILISATION :
 * node test_notifications.js
 */

const {
  notifySubscriptionCreated,
  notifyPaymentPending,
  notifyPaymentSuccess,
  notifyPaymentFailed,
  notifyPasswordChanged,
  notifyProfileUpdated,
  notifyDocumentUploaded,
  notifyContractGenerated,
  notifyPropositionGenerated,
  notifySubscriptionModified,
} = require('./services/notificationHelper');

const pool = require('./db');

async function testNotifications() {
  console.log('🧪 Début des tests du système de notifications\n');

  try {
    // Test 1: Trouver un utilisateur de test
    const userResult = await pool.query(
      "SELECT id, email FROM users WHERE role = 'client' LIMIT 1"
    );

    if (userResult.rows.length === 0) {
      console.error('❌ Aucun utilisateur client trouvé. Créez d\'abord un compte client.');
      return;
    }

    const testUserId = userResult.rows[0].id;
    const testEmail = userResult.rows[0].email;
    console.log(`✅ Utilisateur de test trouvé: ${testEmail} (ID: ${testUserId})\n`);

    // Test 2: Créer une notification de souscription
    console.log('📝 Test 1: Notification de souscription créée...');
    await notifySubscriptionCreated(testUserId, 'CORIS SÉRÉNITÉ', 'SER-2026-00123');
    console.log('✅ Notification créée avec succès\n');

    // Test 3: Notification de paiement en attente
    console.log('💰 Test 2: Notification de paiement en attente...');
    await notifyPaymentPending(testUserId, 'CORIS SÉRÉNITÉ', 250000);
    console.log('✅ Notification créée avec succès\n');

    // Test 4: Notification de paiement réussi
    console.log('✅ Test 3: Notification de paiement réussi...');
    await notifyPaymentSuccess(testUserId, 'CORIS SÉRÉNITÉ', 250000, 'Wave');
    console.log('✅ Notification créée avec succès\n');

    // Test 5: Notification de changement de mot de passe
    console.log('🔒 Test 4: Notification de changement de mot de passe...');
    await notifyPasswordChanged(testUserId);
    console.log('✅ Notification créée avec succès\n');

    // Test 6: Notification de proposition générée
    console.log('📋 Test 5: Notification de proposition générée...');
    await notifyPropositionGenerated(testUserId, 'CORIS SÉRÉNITÉ', 'PROP-2026-00456');
    console.log('✅ Notification créée avec succès\n');

    // Test 7: Notification de contrat généré
    console.log('📄 Test 6: Notification de contrat généré...');
    await notifyContractGenerated(testUserId, 'CORIS SÉRÉNITÉ', 'CONT-2026-00789');
    console.log('✅ Notification créée avec succès\n');

    // Test 8: Vérifier toutes les notifications créées
    console.log('🔍 Vérification: Récupération de toutes les notifications...');
    const notifResult = await pool.query(
      `SELECT id, type, title, message, is_read, created_at
       FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 10`,
      [testUserId]
    );

    console.log(`\n📊 ${notifResult.rows.length} notification(s) trouvée(s):\n`);
    notifResult.rows.forEach((notif, index) => {
      console.log(`${index + 1}. ${notif.title}`);
      console.log(`   Type: ${notif.type}`);
      console.log(`   Message: ${notif.message}`);
      console.log(`   Lu: ${notif.is_read ? 'Oui' : 'Non'}`);
      console.log(`   Date: ${notif.created_at}`);
      console.log('');
    });

    // Test 9: Compter les notifications non lues
    const unreadResult = await pool.query(
      `SELECT COUNT(*) as count
       FROM notifications
       WHERE user_id = $1 AND is_read = false`,
      [testUserId]
    );

    console.log(`📬 Notifications non lues: ${unreadResult.rows[0].count}\n`);

    console.log('✅ ✅ ✅ Tous les tests réussis !');
    console.log('\n📱 Vous pouvez maintenant tester dans l\'application Flutter:');
    console.log('   1. Connectez-vous avec le compte:', testEmail);
    console.log('   2. Allez dans la page "Notifications"');
    console.log('   3. Vous devriez voir toutes les notifications de test\n');

  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  } finally {
    // Fermer la connexion
    await pool.end();
  }
}

// Exécuter les tests
testNotifications();
