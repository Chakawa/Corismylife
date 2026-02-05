/**
 * Service de notification pour les paiements de contrats
 * Envoie des rappels automatiques 5 jours avant l'échéance
 * - SMS via API SMS CI (https://apis.letexto.com)
 * - Notification in-app dans la table notifications
 */

const pool = require('../db');

/// ============================================
/// CONFIGURATION SMS - API SMS CI
/// ============================================

const SMS_API_URL = 'https://apis.letexto.com/v1/messages/send';
const SMS_API_TOKEN = 'fa09e6cef91f77c4b7d8e2c067f1b22c'; // Token de production
const SMS_SENDER = 'CORIS ASSUR';

/**
 * Envoie un SMS via l'API SMS CI
 * @param {string} phoneNumber - Numéro avec indicatif (ex: 2250799283976)
 * @param {string} message - Message à envoyer
 * @returns {Object} { success: boolean, data/error }
 */
async function sendSMS(phoneNumber, message) {
  console.log('\n=== 📱 ENVOI SMS RAPPEL PAIEMENT ===');
  console.log('📞 Destinataire:', phoneNumber);
  console.log('📝 Message:', message);
  
  try {
    const data = JSON.stringify({
      from: SMS_SENDER,
      to: phoneNumber,
      content: message,
    });

    const response = await fetch(SMS_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SMS_API_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: data,
    });

    console.log('📊 Statut HTTP:', response.status);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Erreur SMS:', response.status, errorText);
      return { 
        success: false, 
        error: `HTTP ${response.status}`,
        details: errorText
      };
    }

    const responseData = await response.json();
    console.log('✅ SMS envoyé avec succès');
    console.log('=== ✅ FIN ENVOI SMS ===\n');
    return { success: true, data: responseData };
    
  } catch (error) {
    console.error('❌ ERREUR ENVOI SMS:', error.message);
    return { success: false, error: error.message };
  }
}

/**
 * Crée une notification in-app dans la table notifications
 * Le client verra cette notification quand il se connectera
 * @param {number} userId - ID de l'utilisateur
 * @param {object} contrat - Données du contrat
 * @returns {Object} Notification créée
 */
async function createInAppNotification(userId, contrat) {
  try {
    const title = '💰 Rappel de paiement';
    const message = `Votre paiement de ${contrat.prime.toLocaleString('fr-FR')} FCFA pour le contrat ${contrat.numepoli} est dû dans ${contrat.jours_restants} jour(s). Échéance: ${new Date(contrat.next_payment_date).toLocaleDateString('fr-FR')}.`;
    
    const query = `
      INSERT INTO notifications (user_id, type, title, message, is_read, created_at, updated_at)
      VALUES ($1, $2, $3, $4, false, NOW(), NOW())
      RETURNING *
    `;

    const result = await pool.query(query, [
      userId,
      'payment_reminder', // Type de notification
      title,
      message
    ]);

    console.log(`✅ Notification in-app créée pour user ${userId}`);
    return result.rows[0];
  } catch (error) {
    console.error('❌ Erreur création notification in-app:', error);
    throw error;
  }
}

class NotificationService {
  /**
   * Récupère tous les contrats nécessitant une notification
   * Joint avec users pour avoir le user_id
   */
  async getContratsNeedingNotification() {
    try {
      const query = `
        SELECT 
          c.id,
          c.numepoli,
          c.nom_prenom,
          c.telephone1,
          c.telephone2,
          c.next_payment_date,
          c.prime,
          c.codeprod,
          c.payment_status,
          c.periodicite,
          EXTRACT(DAY FROM (c.next_payment_date - CURRENT_DATE))::INTEGER as jours_restants,
          u.id as user_id,
          u.email,
          u.notification_preferences
        FROM contrats c
        LEFT JOIN users u ON (u.telephone = c.telephone1 OR u.telephone = c.telephone2)
        WHERE c.etat IN ('actif', 'en cours', 'valide', 'active')
          AND c.next_payment_date IS NOT NULL
          AND c.payment_status IN ('echeance_proche', 'en_retard')
          AND (
            c.notification_sent = false 
            OR c.last_notification_date IS NULL
            OR c.last_notification_date < CURRENT_DATE - INTERVAL '2 days'
          )
        ORDER BY c.next_payment_date
      `;

      const result = await pool.query(query);
      return result.rows;
    } catch (error) {
      console.error('Erreur récupération contrats pour notification:', error);
      throw error;
    }
  }

  /**
   * Marque une notification comme envoyée
   */
  async markNotificationAsSent(contratId) {
    try {
      const query = `
        UPDATE contrats
        SET notification_sent = true,
            last_notification_date = NOW(),
            updated_at = NOW()
        WHERE id = $1
        RETURNING *
      `;

      const result = await pool.query(query, [contratId]);
      return result.rows[0];
    } catch (error) {
      console.error('Erreur marquage notification:', error);
      throw error;
    }
  }

  /**
   * Envoie une notification de rappel de paiement au CLIENT
   * - SMS via API SMS CI
   * - Notification in-app dans la table notifications
   */
  async sendPaymentReminder(contrat) {
    try {
      console.log('\n📧 Envoi notification de paiement:');
      console.log(`   - Contrat: ${contrat.numepoli}`);
      console.log(`   - Client: ${contrat.nom_prenom}`);
      console.log(`   - Échéance: ${contrat.next_payment_date}`);
      console.log(`   - Jours restants: ${contrat.jours_restants}`);
      console.log(`   - Montant: ${contrat.prime} FCFA`);

      // Préparer le message
      const message = contrat.jours_restants < 0
        ? `CORIS: Votre paiement de ${contrat.prime} FCFA pour le contrat ${contrat.numepoli} est en retard de ${Math.abs(contrat.jours_restants)} jours. Veuillez régulariser via CorisMoney.`
        : `CORIS: Rappel de paiement - ${contrat.prime} FCFA à régler dans ${contrat.jours_restants} jour(s) pour votre contrat ${contrat.numepoli}. Payez via CorisMoney.`;

      let smsSuccess = false;
      let notifSuccess = false;
      const results = [];

      // 1. Envoyer le SMS au client
      if (contrat.telephone1) {
        console.log(`📱 Envoi SMS à ${contrat.telephone1}...`);
        const smsResult = await sendSMS(contrat.telephone1, message);
        smsSuccess = smsResult.success;
        
        if (smsResult.success) {
          console.log('✅ SMS envoyé avec succès');
          results.push({ type: 'SMS', success: true });
        } else {
          console.error('❌ Échec envoi SMS:', smsResult.error);
          results.push({ type: 'SMS', success: false, error: smsResult.error });
        }
      }

      // 2. Créer la notification in-app (si user_id existe)
      if (contrat.user_id) {
        console.log(`📲 Création notification in-app pour user ${contrat.user_id}...`);
        try {
          await createInAppNotification(contrat.user_id, contrat);
          notifSuccess = true;
          console.log('✅ Notification in-app créée');
          results.push({ type: 'IN_APP', success: true });
        } catch (error) {
          console.error('❌ Échec notification in-app:', error.message);
          results.push({ type: 'IN_APP', success: false, error: error.message });
        }
      } else {
        console.warn('⚠️  User ID non trouvé, notification in-app non créée');
      }

      return {
        success: smsSuccess || notifSuccess, // Succès si au moins un canal fonctionne
        sms: smsSuccess,
        inApp: notifSuccess,
        results: results,
      };
    } catch (error) {
      console.error('❌ Erreur envoi notification:', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Traite toutes les notifications en attente
   * À exécuter via un cron job (ex: tous les jours à 9h)
   */
  async processAllNotifications() {
    try {
      console.log('=== TRAITEMENT DES NOTIFICATIONS DE PAIEMENT ===');
      console.log('Date:', new Date().toISOString());

      const contrats = await this.getContratsNeedingNotification();
      console.log(`📋 ${contrats.length} contrat(s) nécessitant une notification`);

      const results = {
        total: contrats.length,
        sent: 0,
        failed: 0,
        errors: [],
      };

      for (const contrat of contrats) {
        try {
          // Envoyer la notification
          const result = await this.sendPaymentReminder(contrat);

          if (result.success) {
            // Marquer comme envoyée
            await this.markNotificationAsSent(contrat.id);
            results.sent++;
            console.log(`✅ Notification envoyée pour contrat ${contrat.numepoli}`);
          } else {
            results.failed++;
            results.errors.push({
              contratId: contrat.id,
              numepoli: contrat.numepoli,
              error: result.error,
            });
            console.error(`❌ Échec notification pour contrat ${contrat.numepoli}`);
          }
        } catch (error) {
          results.failed++;
          results.errors.push({
            contratId: contrat.id,
            numepoli: contrat.numepoli,
            error: error.message,
          });
          console.error(`❌ Erreur traitement contrat ${contrat.numepoli}:`, error);
        }
      }

      console.log('=== RÉSULTAT TRAITEMENT NOTIFICATIONS ===');
      console.log(`✅ Envoyées: ${results.sent}`);
      console.log(`❌ Échecs: ${results.failed}`);
      console.log('==============================================');

      return results;
    } catch (error) {
      console.error('Erreur processAllNotifications:', error);
      throw error;
    }
  }

  /**
   * Réinitialise les notifications pour un nouveau cycle de paiement
   * (appelé après qu'un paiement a été effectué)
   */
  async resetNotificationAfterPayment(contratId) {
    try {
      const query = `
        UPDATE contrats
        SET notification_sent = false,
            last_notification_date = NULL,
            updated_at = NOW()
        WHERE id = $1
      `;

      await pool.query(query, [contratId]);
      console.log(`🔄 Notification réinitialisée pour contrat ID ${contratId}`);
    } catch (error) {
      console.error('Erreur réinitialisation notification:', error);
      throw error;
    }
  }
}

module.exports = new NotificationService();
