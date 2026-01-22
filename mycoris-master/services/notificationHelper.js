/// ============================================
/// HELPER NOTIFICATIONS
/// ============================================
/// Fonctions utilitaires pour créer facilement des notifications
/// automatiques lors des actions importantes dans l'application
/// ============================================

const pool = require('../db');

/**
 * Types de notifications disponibles
 */
const NOTIFICATION_TYPES = {
  SUBSCRIPTION_CREATED: 'subscription_created',
  PAYMENT_PENDING: 'payment_pending',
  PAYMENT_SUCCESS: 'payment_success',
  PAYMENT_FAILED: 'payment_failed',
  PASSWORD_CHANGED: 'password_changed',
  PROFILE_UPDATED: 'profile_updated',
  DOCUMENT_UPLOADED: 'document_uploaded',
  CONTRACT_GENERATED: 'contract_generated',
  PROPOSITION_GENERATED: 'proposition_generated',
  SUBSCRIPTION_MODIFIED: 'subscription_modified',
  REMINDER: 'reminder',
  SYSTEM: 'system',
};

/**
 * Crée une notification pour un utilisateur
 * @param {number} userId - ID de l'utilisateur
 * @param {string} type - Type de notification (voir NOTIFICATION_TYPES)
 * @param {string} title - Titre de la notification
 * @param {string} message - Message détaillé
 * @returns {Promise<Object>} La notification créée
 */
async function createNotification(userId, type, title, message) {
  try {
    const result = await pool.query(
      `INSERT INTO notifications (user_id, type, title, message, is_read, created_at, updated_at)
       VALUES ($1, $2, $3, $4, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING *`,
      [userId, type, title, message]
    );

    console.log(`✅ Notification créée pour user ${userId}: ${title}`);
    return result.rows[0];
  } catch (error) {
    console.error('❌ Erreur création notification:', error);
    // Ne pas bloquer l'opération principale si la notification échoue
    return null;
  }
}

/**
 * Notification lors de la création d'une souscription
 */
async function notifySubscriptionCreated(userId, productName, subscriptionCode) {
  const title = '🎉 Souscription enregistrée';
  const message = `Votre souscription "${productName}" (${subscriptionCode}) a été enregistrée avec succès. Vous recevrez bientôt votre proposition.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.SUBSCRIPTION_CREATED,
    title,
    message
  );
}

/**
 * Notification de paiement en attente
 */
async function notifyPaymentPending(userId, productName, amount) {
  const title = '⏳ Paiement en attente';
  const message = `Votre souscription "${productName}" est en attente de paiement. Montant : ${amount} FCFA. Veuillez effectuer le paiement pour activer votre contrat.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.PAYMENT_PENDING,
    title,
    message
  );
}

/**
 * Notification de paiement réussi
 */
async function notifyPaymentSuccess(userId, productName, amount, paymentMethod) {
  const title = '✅ Paiement confirmé';
  const message = `Votre paiement de ${amount} FCFA via ${paymentMethod} pour "${productName}" a été confirmé. Votre contrat sera bientôt activé.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.PAYMENT_SUCCESS,
    title,
    message
  );
}

/**
 * Notification de paiement échoué
 */
async function notifyPaymentFailed(userId, productName, reason) {
  const title = '❌ Échec du paiement';
  const message = `Le paiement pour "${productName}" a échoué. Raison : ${reason}. Veuillez réessayer.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.PAYMENT_FAILED,
    title,
    message
  );
}

/**
 * Notification de changement de mot de passe
 */
async function notifyPasswordChanged(userId) {
  const title = '🔒 Mot de passe modifié';
  const message = 'Votre mot de passe a été modifié avec succès. Si vous n\'êtes pas à l\'origine de cette modification, contactez immédiatement le support.';
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.PASSWORD_CHANGED,
    title,
    message
  );
}

/**
 * Notification de mise à jour du profil
 */
async function notifyProfileUpdated(userId) {
  const title = '✏️ Profil mis à jour';
  const message = 'Vos informations personnelles ont été mises à jour avec succès.';
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.PROFILE_UPDATED,
    title,
    message
  );
}

/**
 * Notification lors du téléchargement de document
 */
async function notifyDocumentUploaded(userId, documentType) {
  const title = '📄 Document téléchargé';
  const message = `Votre ${documentType} a été téléchargé avec succès et est en cours de vérification.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.DOCUMENT_UPLOADED,
    title,
    message
  );
}

/**
 * Notification de génération de contrat
 */
async function notifyContractGenerated(userId, productName, contractNumber) {
  const title = '📋 Contrat généré';
  const message = `Votre contrat "${productName}" (${contractNumber}) est disponible. Vous pouvez le consulter dans la section "Mes Contrats".`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.CONTRACT_GENERATED,
    title,
    message
  );
}

/**
 * Notification de génération de proposition
 */
async function notifyPropositionGenerated(userId, productName, propositionNumber) {
  const title = '📝 Proposition disponible';
  const message = `Votre proposition "${productName}" (${propositionNumber}) est prête. Consultez-la dans "Mes Propositions" et procédez au paiement pour activer votre contrat.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.PROPOSITION_GENERATED,
    title,
    message
  );
}

/**
 * Notification de modification de souscription
 */
async function notifySubscriptionModified(userId, productName) {
  const title = '🔄 Souscription modifiée';
  const message = `Votre souscription "${productName}" a été modifiée avec succès. Une nouvelle proposition sera générée.`;
  
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.SUBSCRIPTION_MODIFIED,
    title,
    message
  );
}

/**
 * Notification de rappel personnalisée
 */
async function notifyReminder(userId, title, message) {
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.REMINDER,
    title,
    message
  );
}

/**
 * Notification système
 */
async function notifySystem(userId, title, message) {
  return await createNotification(
    userId,
    NOTIFICATION_TYPES.SYSTEM,
    title,
    message
  );
}

module.exports = {
  NOTIFICATION_TYPES,
  createNotification,
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
  notifyReminder,
  notifySystem,
};
