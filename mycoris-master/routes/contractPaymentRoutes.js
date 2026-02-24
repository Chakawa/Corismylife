/**
 * ===============================================
 * ROUTES DES PAIEMENTS DE CONTRATS
 * ===============================================
 * 
 * Gère les paiements pour:
 * - Les primes mensuelles
 * - Les primes annuelles
 * - Les versements initiaux
 * - Les paiements anticipés
 */

const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const PaymentService = require('../services/PaymentService');
const pool = require('../db');

// ✅ Toutes les routes nécessitent une authentification
router.use(verifyToken);

/**
 * POST /api/contracts/payment/initiate
 * Initie le paiement d'une prime de contrat
 * 
 * Body:
 * {
 *   contractId: number,
 *   amount: number,
 *   paymentMethod: 'Wave' | 'CorisMoney' | 'OrangeMoney',
 *   type: 'monthly' | 'annual' | 'initial'
 * }
 */
router.post('/payment/initiate', async (req, res) => {
  try {
    const { contractId, amount, paymentMethod, type } = req.body;
    const userId = req.user.id;

    // Validation
    if (!contractId || !amount || !paymentMethod) {
      return res.status(400).json({
        success: false,
        message: 'Données manquantes: contractId, amount, paymentMethod requis',
      });
    }

    if (amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Le montant doit être positif',
      });
    }

    // Vérifier que le contrat appartient à l'utilisateur
    const contractQuery = `
      SELECT c.*, p.numero_police, p.montant_prime
      FROM contrats c
      JOIN propositions p ON c.proposition_id = p.id
      WHERE c.id = $1 AND p.user_id = $2
    `;
    
    const contractResult = await pool.query(contractQuery, [contractId, userId]);
    if (contractResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Contrat non trouvé ou accès refusé',
      });
    }

    const contract = contractResult.rows[0];

    // Créer une transaction de paiement
    const insertPaymentQuery = `
      INSERT INTO payment_transactions (
        user_id,
        contract_id,
        amount,
        payment_method,
        premium_type,
        status,
        created_at
      )
      VALUES ($1, $2, $3, $4, $5, 'pending', NOW())
      RETURNING *
    `;

    const paymentResult = await pool.query(insertPaymentQuery, [
      userId,
      contractId,
      amount,
      paymentMethod,
      type || 'monthly',
    ]);

    const payment = paymentResult.rows[0];

    // Déléguer au service de paiement approprié
    const paymentService = new PaymentService(paymentMethod);
    const paymentSession = await paymentService.createPaymentSession({
      transactionId: payment.id,
      contractId,
      amount,
      description: `Paiement prime ${type || 'mensuelle'} - Contrat #${contract.numero_police}`,
      customerPhone: req.user.telephone,
    });

    if (!paymentSession.success) {
      // Marquer la transaction comme failed
      await pool.query(
        'UPDATE payment_transactions SET status = $1 WHERE id = $2',
        ['failed', payment.id]
      );

      return res.status(400).json({
        success: false,
        message: 'Impossible d\'initier le paiement',
        error: paymentSession.message,
      });
    }

    // Retourner les infos de session
    res.json({
      success: true,
      transactionId: payment.id,
      paymentSession: paymentSession.data,
    });

  } catch (error) {
    console.error('Erreur lors de l\'initiation du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message,
    });
  }
});

/**
 * POST /api/contracts/payment/confirm
 * Confirme un paiement après redirection de Wave/CorisMoney
 */
router.post('/payment/confirm', async (req, res) => {
  try {
    const { transactionId, paymentSession } = req.body;
    const userId = req.user.id;

    if (!transactionId) {
      return res.status(400).json({
        success: false,
        message: 'transactionId requis',
      });
    }

    // Récupérer la transaction
    const queryTransaction = `
      SELECT * FROM payment_transactions
      WHERE id = $1 AND user_id = $2
    `;

    const transactionResult = await pool.query(queryTransaction, [
      transactionId,
      userId,
    ]);

    if (transactionResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Transaction non trouvée',
      });
    }

    const transaction = transactionResult.rows[0];

    // Vérifier le statut du paiement via le service
    const paymentService = new PaymentService(transaction.payment_method);
    const status = await paymentService.verifyPayment(paymentSession);

    let newStatus = 'pending';
    if (status.success && status.data?.status === 'completed') {
      newStatus = 'completed';
    } else if (status.data?.status === 'failed') {
      newStatus = 'failed';
    }

    // Mettre à jour le statut
    await pool.query(
      'UPDATE payment_transactions SET status = $1, updated_at = NOW() WHERE id = $2',
      [newStatus, transactionId]
    );

    // Si paiement réussi, créer notification
    if (newStatus === 'completed') {
      await pool.query(
        `INSERT INTO notifications (
          user_id,
          type,
          title,
          message,
          created_at
        ) VALUES (
          $1, $2, $3, $4, NOW()
        )`,
        [
          userId,
          'payment',
          'Paiement Prime Confirmé',
          `Prime de ${transaction.amount} FCFA payée avec succès`,
        ]
      );
    }

    res.json({
      success: newStatus === 'completed',
      status: newStatus,
      message:
        newStatus === 'completed'
          ? 'Paiement confirmé avec succès'
          : 'Paiement en attente de confirmation',
    });

  } catch (error) {
    console.error('Erreur lors de la confirmation du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

/**
 * GET /api/contracts/:contractId/next-payment
 * Retourne la date et le montant du prochain paiement prévu
 */
router.get('/:contractId/next-payment', async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    const query = `
      SELECT c.*, p.numero_police, p.montant_prime, p.frequency
      FROM contrats c
      JOIN propositions p ON c.proposition_id = p.id
      WHERE c.id = $1 AND p.user_id = $2
    `;

    const result = await pool.query(query, [contractId, userId]);
    if (result.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Contrat non trouvé',
      });
    }

    const contract = result.rows[0];

    // Calculer la prochaine date de paiement
    const basePremium = contract.montant_prime || 0;
    const frequency = contract.frequency || 'monthly'; // monthly, annual, etc.

    let nextPaymentDate = new Date();
    if (frequency === 'monthly') {
      nextPaymentDate.setMonth(nextPaymentDate.getMonth() + 1);
    } else if (frequency === 'annual') {
      nextPaymentDate.setFullYear(nextPaymentDate.getFullYear() + 1);
    }

    res.json({
      success: true,
      contractId,
      nextPaymentDate,
      amount: basePremium,
      frequency,
      numeroPolice: contract.numero_police,
    });

  } catch (error) {
    console.error('Erreur lors de la récupération du paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

/**
 * GET /api/contracts/payment-history
 * Retourne historique des paiements
 */
router.get('/payment-history/:contractId', async (req, res) => {
  try {
    const { contractId } = req.params;
    const userId = req.user.id;

    // Vérifier l'accès au contrat
    const contractQuery = `
      SELECT * FROM contrats c
      JOIN propositions p ON c.proposition_id = p.id
      WHERE c.id = $1 AND p.user_id = $2
    `;

    const contractCheck = await pool.query(contractQuery, [contractId, userId]);
    if (contractCheck.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé',
      });
    }

    // Récupérer l'historique
    const historyQuery = `
      SELECT *
      FROM payment_transactions
      WHERE contract_id = $1 AND user_id = $2
      ORDER BY created_at DESC
      LIMIT 20
    `;

    const result = await pool.query(historyQuery, [contractId, userId]);

    res.json({
      success: true,
      history: result.rows,
      count: result.rows.length,
    });

  } catch (error) {
    console.error('Erreur lors de la récupération de l\'historique:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur',
    });
  }
});

module.exports = router;
