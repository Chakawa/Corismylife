const express = require('express');
const router = express.Router();
const corisMoneyService = require('../services/corisMoneyService');
const { verifyToken } = require('../middlewares/authMiddleware');
const pool = require('../db');

/**
 * @route   POST /api/payment/send-otp
 * @desc    Envoie un code OTP au client pour paiement
 * @access  Private
 */
router.post('/send-otp', verifyToken, async (req, res) => {
  try {
    const { codePays, telephone } = req.body;

    console.log('📨 ===== REQUÊTE ENVOI OTP =====');
    console.log('User ID:', req.user?.id);
    console.log('Code Pays:', codePays);
    console.log('Téléphone:', telephone);

    // Validation des paramètres
    if (!codePays || !telephone) {
      console.log('⚠️ Paramètres manquants');
      return res.status(400).json({
        success: false,
        message: 'Le code pays et le numéro de téléphone sont requis'
      });
    }

    // Appel du service CorisMoney
    const result = await corisMoneyService.sendOTP(codePays, telephone);

    if (result.success) {
      console.log('✅ OTP envoyé avec succès, enregistrement en BDD...');
      // Enregistrer la demande d'OTP en base de données (optionnel)
      await pool.query(
        `INSERT INTO payment_otp_requests (user_id, code_pays, telephone, created_at)
         VALUES ($1, $2, $3, NOW())`,
        [req.user.id, codePays, telephone]
      );

      console.log('✅ Enregistré en BDD');
      return res.status(200).json({
        success: true,
        message: result.message
      });
    } else {
      console.log('❌ Échec envoi OTP:', result.message);
      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Erreur lors de l\'envoi de l\'OTP:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de l\'envoi du code OTP',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/payment/process-payment
 * @desc    Traite un paiement via CorisMoney
 * @access  Private
 */
router.post('/process-payment', verifyToken, async (req, res) => {
  try {
    const { codePays, telephone, montant, codeOTP, subscriptionId, description } = req.body;

    // Validation des paramètres
    if (!codePays || !telephone || !montant || !codeOTP) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs sont requis (codePays, telephone, montant, codeOTP)'
      });
    }

    // Validation du montant
    if (isNaN(montant) || parseFloat(montant) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Le montant doit être un nombre positif'
      });
    }

    // Appel du service CorisMoney pour le paiement
    const result = await corisMoneyService.paiementBien(
      codePays,
      telephone,
      parseFloat(montant),
      codeOTP
    );

    if (result.success) {
      // Enregistrer la transaction en base de données
      const insertQuery = `
        INSERT INTO payment_transactions (
          user_id,
          subscription_id,
          transaction_id,
          code_pays,
          telephone,
          montant,
          statut,
          description,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
        RETURNING id
      `;

      const transactionResult = await pool.query(insertQuery, [
        req.user.id,
        subscriptionId || null,
        result.transactionId,
        codePays,
        telephone,
        parseFloat(montant),
        'SUCCESS',
        description || 'Paiement de prime d\'assurance'
      ]);

      // Mettre à jour le statut de la souscription si applicable
      if (subscriptionId) {
        await pool.query(
          `UPDATE subscriptions 
           SET statut = 'paid', 
               payment_method = 'CorisMoney',
               payment_transaction_id = $1,
               updated_at = NOW()
           WHERE id = $2`,
          [result.transactionId, subscriptionId]
        );
      }

      return res.status(200).json({
        success: true,
        message: result.message,
        transactionId: result.transactionId,
        montant: result.data.montant,
        paymentRecordId: transactionResult.rows[0].id
      });
    } else {
      // Enregistrer l'échec de la transaction
      await pool.query(
        `INSERT INTO payment_transactions (
          user_id,
          subscription_id,
          code_pays,
          telephone,
          montant,
          statut,
          error_message,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
        [
          req.user.id,
          subscriptionId || null,
          codePays,
          telephone,
          parseFloat(montant),
          'FAILED',
          JSON.stringify(result.error)
        ]
      );

      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error
      });
    }
  } catch (error) {
    console.error('Erreur lors du traitement du paiement:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors du traitement du paiement',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/client-info
 * @desc    Récupère les informations d'un client CorisMoney
 * @access  Private
 */
router.get('/client-info', verifyToken, async (req, res) => {
  try {
    const { codePays, telephone } = req.query;

    if (!codePays || !telephone) {
      return res.status(400).json({
        success: false,
        message: 'Le code pays et le numéro de téléphone sont requis'
      });
    }

    const result = await corisMoneyService.getClientInfo(codePays, telephone);

    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error
      });
    }
  } catch (error) {
    console.error('Erreur lors de la récupération des infos client:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/transaction-status/:transactionId
 * @desc    Vérifie le statut d'une transaction
 * @access  Private
 */
router.get('/transaction-status/:transactionId', verifyToken, async (req, res) => {
  try {
    const { transactionId } = req.params;

    if (!transactionId) {
      return res.status(400).json({
        success: false,
        message: 'L\'ID de transaction est requis'
      });
    }

    const result = await corisMoneyService.getTransactionStatus(transactionId);

    if (result.success) {
      // Mettre à jour le statut en base de données si nécessaire
      await pool.query(
        `UPDATE payment_transactions 
         SET statut = $1, updated_at = NOW()
         WHERE transaction_id = $2`,
        [result.data.status || 'VERIFIED', transactionId]
      );

      return res.status(200).json({
        success: true,
        data: result.data,
        message: result.message
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error
      });
    }
  } catch (error) {
    console.error('Erreur lors de la vérification du statut:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/history
 * @desc    Récupère l'historique des paiements d'un utilisateur
 * @access  Private
 */
router.get('/history', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    const result = await pool.query(
      `SELECT 
        id,
        transaction_id,
        subscription_id,
        montant,
        statut,
        description,
        code_pays,
        telephone,
        created_at,
        error_message
       FROM payment_transactions
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    return res.status(200).json({
      success: true,
      data: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'historique:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

module.exports = router;
