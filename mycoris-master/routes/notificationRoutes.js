/// ============================================
/// ROUTES NOTIFICATIONS
/// ============================================
/// Définit toutes les routes relatives aux notifications :
/// - GET /api/notifications : Récupérer toutes les notifications
/// - GET /api/notifications/unread-count : Compter les non lues
/// - PUT /api/notifications/:id/read : Marquer une notification comme lue
/// - PUT /api/notifications/mark-all-read : Marquer toutes comme lues
/// - DELETE /api/notifications/:id : Supprimer une notification
/// ============================================

const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { verifyToken } = require('../middleware/auth');

/// ============================================
/// ROUTES PROTÉGÉES (NÉCESSITENT UN TOKEN)
/// ============================================

/**
 * GET /api/notifications
 * Récupère toutes les notifications de l'utilisateur connecté
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, notifications: [...], unread_count: number }
 */
router.get('/', verifyToken, notificationController.getNotifications);

/**
 * GET /api/notifications/unread-count
 * Compte le nombre de notifications non lues
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, count: number }
 */
router.get('/unread-count', verifyToken, notificationController.getUnreadCount);

/**
 * PUT /api/notifications/:id/read
 * Marque une notification spécifique comme lue
 * Headers : Authorization: Bearer <token>
 * Params : id (ID de la notification)
 * Retour : { success: true, message: "Notification marquée comme lue" }
 */
router.put('/:id/read', verifyToken, notificationController.markAsRead);

/**
 * PUT /api/notifications/mark-all-read
 * Marque toutes les notifications de l'utilisateur comme lues
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, message: "Toutes les notifications marquées comme lues" }
 */
router.put('/mark-all-read', verifyToken, notificationController.markAllAsRead);

/**
 * DELETE /api/notifications/:id
 * Supprime une notification spécifique
 * Headers : Authorization: Bearer <token>
 * Params : id (ID de la notification)
 * Retour : { success: true, message: "Notification supprimée" }
 */
router.delete('/:id', verifyToken, notificationController.deleteNotification);

/// ============================================
/// ROUTES SYSTÈME - NOTIFICATIONS PAIEMENT
/// ============================================

/**
 * POST /api/notifications/process-payment-reminders
 * Traite toutes les notifications de rappel de paiement en attente
 * Envoie les SMS/Email pour les contrats ayant une échéance dans 5 jours
 * Headers : Authorization: Bearer <token>
 * Access : Admin uniquement
 * Retour : { success: true, sent: number, failed: number }
 */
router.post('/process-payment-reminders', verifyToken, async (req, res) => {
  try {
    // Vérifier que l'utilisateur est admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé - Admin uniquement',
      });
    }

    const paymentNotificationService = require('../services/notificationService');
    const results = await paymentNotificationService.processAllNotifications();

    return res.status(200).json({
      success: true,
      message: `Notifications envoyées: ${results.sent}/${results.total}`,
      data: results,
    });
  } catch (error) {
    console.error('Erreur traitement rappels paiement:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur traitement notifications',
      error: error.message,
    });
  }
});

/**
 * GET /api/notifications/pending-payment-reminders
 * Liste les contrats nécessitant un rappel de paiement
 * Headers : Authorization: Bearer <token>
 * Access : Admin uniquement
 * Retour : { success: true, count: number, data: [...] }
 */
router.get('/pending-payment-reminders', verifyToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé - Admin uniquement',
      });
    }

    const paymentNotificationService = require('../services/notificationService');
    const contrats = await paymentNotificationService.getContratsNeedingNotification();

    return res.status(200).json({
      success: true,
      count: contrats.length,
      data: contrats,
    });
  } catch (error) {
    console.error('Erreur récupération contrats en attente:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message,
    });
  }
});

module.exports = router;
