/**
 * CRON JOB - RAPPELS DE PAIEMENT
 * 
 * Ce script envoie automatiquement des rappels de paiement
 * pour les contrats dont l'échéance approche (5 jours avant).
 * 
 * Configuration recommandée:
 * - Exécution quotidienne à 9h00 du matin
 * - Cron expression: 0 9 * * *
 * 
 * Installation:
 * npm install node-cron
 * 
 * Utilisation dans server.js:
 * require('./cron/paymentReminders');
 */

const cron = require('node-cron');
const notificationService = require('../services/notificationService');

/**
 * Tâche planifiée: Envoi des rappels de paiement
 * S'exécute chaque jour à 9h00 (heure du serveur)
 */
const paymentReminderJob = cron.schedule('0 9 * * *', async () => {
  console.log('===================================');
  console.log('🔔 CRON: Démarrage envoi rappels de paiement');
  console.log('Date:', new Date().toLocaleString('fr-FR'));
  console.log('===================================');

  try {
    const results = await notificationService.processAllNotifications();

    console.log('✅ Traitement terminé:');
    console.log(`   - Total contrats traités: ${results.total}`);
    console.log(`   - Notifications envoyées: ${results.sent}`);
    console.log(`   - Échecs: ${results.failed}`);

    if (results.errors.length > 0) {
      console.error('⚠️  Erreurs détectées:');
      results.errors.forEach((error, index) => {
        console.error(`   ${index + 1}. ${error}`);
      });
    }
  } catch (error) {
    console.error('❌ ERREUR CRITIQUE dans le cron job:', error);
    console.error(error.stack);
  }

  console.log('===================================\n');
}, {
  scheduled: true,
  timezone: "Africa/Abidjan" // Fuseau horaire de la Côte d'Ivoire
});

/**
 * Fonction manuelle pour tester le job
 * Peut être appelée directement: node -e "require('./cron/paymentReminders').runManual()"
 */
async function runManual() {
  console.log('🔧 Exécution manuelle du job de rappels...');
  
  try {
    const results = await notificationService.processAllNotifications();
    console.log('Résultats:', results);
    process.exit(0);
  } catch (error) {
    console.error('Erreur:', error);
    process.exit(1);
  }
}

// Lancement du cron job
console.log('✅ Cron job "Rappels de paiement" démarré');
console.log('   Schedule: Tous les jours à 9h00 (Africa/Abidjan)');
console.log('   Prochaine exécution: Chaque jour à 9h00');

module.exports = {
  paymentReminderJob,
  runManual,
};
