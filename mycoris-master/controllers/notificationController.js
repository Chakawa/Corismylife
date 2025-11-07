/// ============================================
/// CONTRÔLEUR NOTIFICATIONS
/// ============================================
/// Gère toutes les opérations liées aux notifications :
/// - Récupération des notifications
/// - Comptage des non lues
/// - Marquage comme lue
/// - Marquage de toutes comme lues
/// - Suppression
/// ============================================

const pool = require('../db');

/// ============================================
/// RÉCUPÉRATION DES NOTIFICATIONS
/// ============================================

/**
 * Récupère toutes les notifications de l'utilisateur connecté
 * Triées par date de création (plus récentes en premier)
 * @param {Object} req - Requête Express (req.user.id contient l'ID utilisateur)
 * @param {Object} res - Réponse Express
 * @returns {Object} { success: true, notifications: [...], unread_count: number }
 */
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    // Récupérer toutes les notifications de l'utilisateur
    const notificationsResult = await pool.query(
      `SELECT id, type, title, message, is_read, created_at, updated_at
       FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    // Compter les notifications non lues
    const unreadResult = await pool.query(
      `SELECT COUNT(*) as count
       FROM notifications
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    const unreadCount = parseInt(unreadResult.rows[0].count);

    res.json({
      success: true,
      notifications: notificationsResult.rows,
      unread_count: unreadCount,
    });
  } catch (error) {
    console.error('❌ Erreur getNotifications:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des notifications',
    });
  }
};

/// ============================================
/// COMPTAGE DES NOTIFICATIONS NON LUES
/// ============================================

/**
 * Compte le nombre de notifications non lues de l'utilisateur
 * @param {Object} req - Requête Express (req.user.id contient l'ID utilisateur)
 * @param {Object} res - Réponse Express
 * @returns {Object} { success: true, count: number }
 */
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT COUNT(*) as count
       FROM notifications
       WHERE user_id = $1 AND is_read = false`,
      [userId]
    );

    const count = parseInt(result.rows[0].count);

    res.json({
      success: true,
      count: count,
    });
  } catch (error) {
    console.error('❌ Erreur getUnreadCount:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du comptage des notifications',
    });
  }
};

/// ============================================
/// MARQUAGE D'UNE NOTIFICATION COMME LUE
/// ============================================

/**
 * Marque une notification spécifique comme lue
 * Vérifie que la notification appartient bien à l'utilisateur connecté
 * @param {Object} req - Requête Express (req.params.id, req.user.id)
 * @param {Object} res - Réponse Express
 * @returns {Object} { success: true, message: "..." }
 */
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Mettre à jour la notification (uniquement si elle appartient à l'utilisateur)
    const result = await pool.query(
      `UPDATE notifications
       SET is_read = true, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification non trouvée',
      });
    }

    res.json({
      success: true,
      message: 'Notification marquée comme lue',
      notification: result.rows[0],
    });
  } catch (error) {
    console.error('❌ Erreur markAsRead:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du marquage de la notification',
    });
  }
};

/// ============================================
/// MARQUAGE DE TOUTES LES NOTIFICATIONS COMME LUES
/// ============================================

/**
 * Marque toutes les notifications de l'utilisateur comme lues
 * @param {Object} req - Requête Express (req.user.id contient l'ID utilisateur)
 * @param {Object} res - Réponse Express
 * @returns {Object} { success: true, message: "...", count: number }
 */
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    // Mettre à jour toutes les notifications non lues
    const result = await pool.query(
      `UPDATE notifications
       SET is_read = true, updated_at = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND is_read = false
       RETURNING id`,
      [userId]
    );

    const count = result.rows.length;

    res.json({
      success: true,
      message: `${count} notification(s) marquée(s) comme lue(s)`,
      count: count,
    });
  } catch (error) {
    console.error('❌ Erreur markAllAsRead:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du marquage des notifications',
    });
  }
};

/// ============================================
/// SUPPRESSION D'UNE NOTIFICATION
/// ============================================

/**
 * Supprime une notification spécifique
 * Vérifie que la notification appartient bien à l'utilisateur connecté
 * @param {Object} req - Requête Express (req.params.id, req.user.id)
 * @param {Object} res - Réponse Express
 * @returns {Object} { success: true, message: "..." }
 */
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Supprimer la notification (uniquement si elle appartient à l'utilisateur)
    const result = await pool.query(
      `DELETE FROM notifications
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Notification non trouvée',
      });
    }

    res.json({
      success: true,
      message: 'Notification supprimée avec succès',
    });
  } catch (error) {
    console.error('❌ Erreur deleteNotification:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de la notification',
    });
  }
};
