const express = require('express');
const router = express.Router();
const corisMoneyService = require('../services/corisMoneyService');
const waveCheckoutService = require('../services/waveCheckoutService');
const { verifyToken } = require('../middlewares/authMiddleware');
const pool = require('../db');

/**
 * Calcule la prochaine date de paiement en fonction de la périodicité
 * @param {Date} startDate - Date de début
 * @param {string} periodicite - Périodicité (mensuelle, trimestrielle, semestrielle, annuelle, unique)
 * @returns {Date} Prochaine date de paiement
 */
function calculateNextPaymentDate(startDate, periodicite) {
  const nextDate = new Date(startDate);
  
  switch(periodicite?.toLowerCase()) {
    case 'mensuelle':
    case 'mensuel':
      nextDate.setMonth(nextDate.getMonth() + 1);
      break;
    case 'trimestrielle':
    case 'trimestriel':
      nextDate.setMonth(nextDate.getMonth() + 3);
      break;
    case 'semestrielle':
    case 'semestriel':
      nextDate.setMonth(nextDate.getMonth() + 6);
      break;
    case 'annuelle':
    case 'annuel':
      nextDate.setFullYear(nextDate.getFullYear() + 1);
      break;
    case 'unique':
    default:
      // Pour les paiements uniques, pas de prochaine échéance
      return null;
  }
  
  return nextDate;
}

function mapWaveStatusToInternal(status) {
  const normalized = (status || '').toString().toLowerCase();
  if (['paid', 'success', 'succeeded', 'completed', 'complete'].includes(normalized)) {
    return 'SUCCESS';
  }
  if (['failed', 'error', 'cancelled', 'canceled', 'expired'].includes(normalized)) {
    return 'FAILED';
  }
  return 'PENDING';
}

function extractWaveSessionId(payload = {}) {
  return (
    payload.sessionId ||
    payload.session_id ||
    payload.id ||
    payload.checkout_session_id ||
    payload.reference ||
    null
  );
}

async function upsertContractAfterPayment({ subscriptionId, userId, paymentMethod, paymentTransactionId }) {
  const subscriptionData = await pool.query(
    'SELECT * FROM subscriptions WHERE id = $1',
    [subscriptionId]
  );

  if (subscriptionData.rows.length === 0) {
    return { contractCreated: false };
  }

  const subscription = subscriptionData.rows[0];
  const nextPaymentDate = calculateNextPaymentDate(new Date(), subscription.periodicite);

  await pool.query(
    `UPDATE subscriptions 
      SET statut = 'paid',
          payment_method = $1,
          payment_transaction_id = $2,
          updated_at = NOW()
      WHERE id = $3`,
    [paymentMethod, paymentTransactionId, subscriptionId]
  );

  const productPrefix = subscription.product_name 
    ? subscription.product_name.substring(0, 3).toUpperCase() 
    : 'XXX';
  const contractNumber = `CORIS-${productPrefix}-${Date.now()}`;

  await pool.query(
    `INSERT INTO contracts (
      subscription_id,
      user_id,
      contract_number,
      product_name,
      status,
      amount,
      periodicite,
      start_date,
      next_payment_date,
      duration_years,
      payment_method,
      created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
    ON CONFLICT (subscription_id) DO UPDATE SET
      status = 'valid',
      payment_method = EXCLUDED.payment_method,
      next_payment_date = EXCLUDED.next_payment_date,
      updated_at = NOW()`,
    [
      subscriptionId,
      userId,
      contractNumber,
      subscription.product_name,
      'valid',
      subscription.montant,
      subscription.periodicite,
      new Date(),
      nextPaymentDate,
      subscription.duree || 1,
      paymentMethod
    ]
  );

  return {
    contractCreated: true,
    contractNumber,
  };
}

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

    // ✅ ÉTAPE 1 : Vérifier l'existence du client CorisMoney
    console.log('🔍 Vérification du compte CorisMoney pour:', telephone);
    const clientInfo = await corisMoneyService.getClientInfo(codePays, telephone);
    
    if (!clientInfo.success) {
      console.error('❌ Client introuvable dans CorisMoney:', clientInfo.error);
      return res.status(404).json({
        success: false,
        message: '❌ Compte CorisMoney introuvable pour ce numéro',
        detail: 'Veuillez vérifier que votre compte CorisMoney est bien activé pour ce numéro de téléphone.',
        errorCode: 'ACCOUNT_NOT_FOUND'
      });
    }

    console.log('✅ Client CorisMoney trouvé:', clientInfo.data);
    
    // Vérifier le solde disponible
    const soldeDisponible = parseFloat(clientInfo.data.solde || clientInfo.data.balance || 0);
    const montantRequis = parseFloat(montant);
    
    if (soldeDisponible < montantRequis) {
      console.warn(`⚠️ Solde insuffisant: ${soldeDisponible} FCFA < ${montantRequis} FCFA`);
      return res.status(400).json({
        success: false,
        message: '💰 Solde insuffisant',
        detail: `Votre solde actuel (${soldeDisponible.toLocaleString()} FCFA) est insuffisant pour effectuer ce paiement (${montantRequis.toLocaleString()} FCFA).`,
        soldeDisponible: soldeDisponible,
        montantRequis: montantRequis,
        errorCode: 'INSUFFICIENT_BALANCE'
      });
    }

    console.log(`✅ Solde suffisant: ${soldeDisponible} FCFA >= ${montantRequis} FCFA`);

    // ✅ ÉTAPE 2 : Effectuer le paiement
    console.log('💳 Lancement du paiement CorisMoney...');
    const result = await corisMoneyService.paiementBien(
      codePays,
      telephone,
      montantRequis,
      codeOTP
    );

    if (result.success) {
      console.log('✅ Réponse paiement CorisMoney:', result.data);
      
      // ⚠️ IMPORTANT : Vérifier le statut réel de la transaction
      let transactionStatus = 'PENDING';
      let errorMessage = null;
      
      // Si un transactionId est retourné, vérifier son statut
      if (result.transactionId) {
        console.log('🔍 Vérification du statut de la transaction:', result.transactionId);
        
        // Attendre 2 secondes pour que CorisMoney traite la transaction
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const statusResult = await corisMoneyService.getTransactionStatus(result.transactionId);
        
        if (statusResult.success && statusResult.data) {
          console.log('📊 Statut reçu:', statusResult.data);
          
          // Analyser le statut de la transaction
          const status = statusResult.data.statut || statusResult.data.status;
          
          if (status === 'SUCCESS' || status === 'COMPLETED') {
            transactionStatus = 'SUCCESS';
          } else if (status === 'FAILED' || status === 'INSUFFICIENT_BALANCE') {
            transactionStatus = 'FAILED';
            errorMessage = statusResult.data.message || 'Solde insuffisant ou paiement échoué';
          } else {
            transactionStatus = 'PENDING';
          }
        } else {
          console.warn('⚠️ Impossible de vérifier le statut, marquage comme PENDING');
          transactionStatus = 'PENDING';
        }
      }
      
      // Enregistrer la transaction en base de données avec le VRAI statut
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
          error_message,
          api_response,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
        RETURNING id
      `;

      const transactionResult = await pool.query(insertQuery, [
        req.user.id,
        subscriptionId || null,
        result.transactionId,
        codePays,
        telephone,
        parseFloat(montant),
        transactionStatus,
        description || 'Paiement de prime d\'assurance',
        errorMessage,
        JSON.stringify(result.data || result) // Sauvegarder la réponse complète de l'API
      ]);

      // ⚠️ Ne transformer en contrat QUE si le paiement est vraiment réussi
      if (transactionStatus === 'SUCCESS' && subscriptionId) {
        console.log('🎉 Paiement confirmé ! Transformation de la proposition en contrat...');
        
        // Mettre à jour le statut de la souscription
        await pool.query(
          `UPDATE subscriptions 
           SET statut = 'paid', 
               payment_method = 'CorisMoney',
               payment_transaction_id = $1,
               updated_at = NOW()
           WHERE id = $2`,
          [result.transactionId, subscriptionId]
        );
        
        // Créer le contrat
        const subscriptionData = await pool.query(
          'SELECT * FROM subscriptions WHERE id = $1',
          [subscriptionId]
        );
        
        if (subscriptionData.rows.length > 0) {
          const subscription = subscriptionData.rows[0];
          
          // Calculer la prochaine échéance
          const nextPaymentDate = calculateNextPaymentDate(
            new Date(),
            subscription.periodicite
          );
          
          // Créer le contrat
          await pool.query(
            `INSERT INTO contracts (
              subscription_id,
              user_id,
              contract_number,
              product_name,
              status,
              amount,
              periodicite,
              start_date,
              next_payment_date,
              duration_years,
              payment_method,
              created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
            ON CONFLICT (subscription_id) DO UPDATE SET
              status = 'valid',
              next_payment_date = $9,
              updated_at = NOW()`,
            [
              subscriptionId,
              req.user.id,
              `CORIS-${subscription.product_name.substring(0, 3).toUpperCase()}-${Date.now()}`,
              subscription.product_name,
              'valid',  // Statut 'valid' quand le paiement est effectué
              subscription.montant,
              subscription.periodicite,
              new Date(),
              nextPaymentDate,
              subscription.duree || 1,
              'CorisMoney'
            ]
          );
          
          console.log('✅ Contrat créé avec succès !');
          
          // 📱 ENVOYER SMS DE CONFIRMATION AU CLIENT
          try {
            const userQuery = await pool.query(
              'SELECT nom_prenom, telephone FROM users WHERE id = $1',
              [req.user.id]
            );
            
            if (userQuery.rows.length > 0) {
              const user = userQuery.rows[0];
              const contractNumber = `CORIS-${subscription.product_name.substring(0, 3).toUpperCase()}-${Date.now()}`;
              
              const smsMessage = `Bonjour ${user.nom_prenom}, votre paiement de ${parseFloat(montant).toLocaleString()} FCFA a été effectué avec succès ! Votre contrat ${contractNumber} est maintenant VALIDE. Merci de votre confiance. CORIS Assurance`;
              
              // Envoyer le SMS
              const smsResult = await sendSMS(`225${user.telephone}`, smsMessage);
              
              if (smsResult.success) {
                console.log('✅ SMS de confirmation envoyé au client');
              } else {
                console.error('⚠️ Échec envoi SMS confirmation:', smsResult.error);
              }
            }
          } catch (smsError) {
            console.error('⚠️ Erreur envoi SMS:', smsError.message);
            // Ne pas bloquer le flux si le SMS échoue
          }
        }

        return res.status(200).json({
          success: true,
          message: 'Paiement effectué avec succès',
          transactionId: result.transactionId,
          montant: parseFloat(montant),
          paymentRecordId: transactionResult.rows[0].id,
          contractCreated: true
        });
      } else if (transactionStatus === 'FAILED') {
        console.error('❌ Paiement échoué:', errorMessage);
        return res.status(400).json({
          success: false,
          message: errorMessage || 'Le paiement a échoué. Vérifiez votre solde CorisMoney.',
          transactionId: result.transactionId,
          status: 'FAILED'
        });
      } else {
        // PENDING
        console.warn('⏳ Transaction en attente de confirmation');
        return res.status(202).json({
          success: true,
          message: 'Transaction en cours de traitement. Vérifiez le statut dans quelques instants.',
          transactionId: result.transactionId,
          status: 'PENDING',
          paymentRecordId: transactionResult.rows[0].id
        });
      }
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

      // Messages d'erreur plus explicites
      let errorMessage = result.message || 'Erreur lors du paiement';
      let errorCode = 'PAYMENT_FAILED';
      
      // Analyser le code d'erreur CorisMoney
      if (result.error && result.error.code) {
        const code = result.error.code.toString();
        
        if (code === '-1') {
          errorMessage = '❌ Erreur lors du paiement CorisMoney';
          errorCode = 'CORISMONEY_ERROR';
        } else if (code.includes('OTP') || code.includes('otp')) {
          errorMessage = '🔑 Code OTP invalide ou expiré';
          errorCode = 'INVALID_OTP';
        } else if (code.includes('BALANCE') || code.includes('INSUFFICIENT')) {
          errorMessage = '💰 Solde insuffisant';
          errorCode = 'INSUFFICIENT_BALANCE';
        }
      }

      return res.status(400).json({
        success: false,
        message: errorMessage,
        errorCode: errorCode,
        detail: result.error || result.message
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
 * @route   POST /api/payment/wave/create-session
 * @desc    Crée une session de paiement Wave Checkout
 * @access  Private
 */
router.post('/wave/create-session', verifyToken, async (req, res) => {
  try {
    const {
      subscriptionId,
      montant,
      amount,
      currency,
      customerPhone,
      codePays,
      description,
      successUrl,
      errorUrl,
      webhookUrl,
      clientReference,
      metadata,
    } = req.body;

    const normalizedAmount = Number(amount ?? montant);
    if (!Number.isFinite(normalizedAmount) || normalizedAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Montant invalide pour initier le paiement Wave',
      });
    }

    const waveResult = await waveCheckoutService.createCheckoutSession({
      amount: normalizedAmount,
      currency,
      customerPhone,
      description: description || `Paiement souscription #${subscriptionId || 'N/A'}`,
      successUrl,
      errorUrl,
      webhookUrl,
      clientReference,
      metadata: {
        ...(metadata || {}),
        subscriptionId: subscriptionId || null,
        userId: req.user.id,
      },
    });

    if (!waveResult.success) {
      return res.status(400).json({
        success: false,
        message: waveResult.message || 'Impossible de créer la session Wave',
        error: waveResult.error,
      });
    }

    const sessionId = waveResult.sessionId;
    const transactionId = `WAVE-${sessionId || Date.now()}`;
    const internalStatus = mapWaveStatusToInternal(waveResult.status);

    const inserted = await pool.query(
      `INSERT INTO payment_transactions (
        user_id,
        subscription_id,
        transaction_id,
        code_pays,
        telephone,
        montant,
        statut,
        description,
        api_response,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
      RETURNING id`,
      [
        req.user.id,
        subscriptionId || null,
        transactionId,
        codePays || '225',
        customerPhone || 'N/A',
        normalizedAmount,
        internalStatus,
        description || 'Paiement Wave',
        JSON.stringify({
          provider: 'WAVE',
          sessionId,
          launchUrl: waveResult.launchUrl,
          status: waveResult.status,
          data: waveResult.data,
        }),
      ]
    );

    return res.status(200).json({
      success: true,
      message: 'Session Wave créée avec succès',
      data: {
        paymentRecordId: inserted.rows[0].id,
        transactionId,
        sessionId,
        launchUrl: waveResult.launchUrl,
        status: waveResult.status,
      },
    });
  } catch (error) {
    console.error('Erreur création session Wave:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la création de la session Wave',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/payment/wave/status/:sessionId
 * @desc    Vérifie le statut d'une session Wave
 * @access  Private
 */
router.get('/wave/status/:sessionId', verifyToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { subscriptionId, transactionId } = req.query;

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'sessionId Wave requis',
      });
    }

    const statusResult = await waveCheckoutService.getCheckoutSession(sessionId);

    if (!statusResult.success) {
      return res.status(400).json({
        success: false,
        message: statusResult.message || 'Impossible de récupérer le statut Wave',
        error: statusResult.error,
      });
    }

    const internalStatus = mapWaveStatusToInternal(statusResult.status);
    const resolvedTransactionId = transactionId || `WAVE-${sessionId}`;

    const paymentTxResult = await pool.query(
      `UPDATE payment_transactions
       SET statut = $1,
           api_response = $2,
           updated_at = NOW()
       WHERE transaction_id = $3
          OR (api_response->>'sessionId') = $4
          OR (api_response->>'id') = $4
       RETURNING *`,
      [
        internalStatus,
        JSON.stringify({
          provider: 'WAVE',
          sessionId,
          status: statusResult.status,
          data: statusResult.data,
        }),
        resolvedTransactionId,
        sessionId,
      ]
    );

    const paymentTx = paymentTxResult.rows[0] || null;
    const resolvedSubscriptionId = Number(subscriptionId || paymentTx?.subscription_id || 0) || null;

    let contractCreated = false;
    let contractNumber = null;

    if (internalStatus === 'SUCCESS' && resolvedSubscriptionId) {
      try {
        const contractResult = await upsertContractAfterPayment({
          subscriptionId: resolvedSubscriptionId,
          userId: req.user.id,
          paymentMethod: 'Wave',
          paymentTransactionId: resolvedTransactionId,
        });

        contractCreated = contractResult.contractCreated;
        contractNumber = contractResult.contractNumber || null;
      } catch (contractError) {
        console.warn('⚠️  Impossible de créer le contrat (table manquante?):', contractError.message);
        // Continue sans bloquer - utile pour les tests
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Statut Wave récupéré',
      data: {
        provider: 'WAVE',
        sessionId,
        transactionId: paymentTx?.transaction_id || resolvedTransactionId,
        status: internalStatus,
        providerStatus: statusResult.status,
        contractCreated,
        contractNumber,
        apiResponse: statusResult.data,
      },
    });
  } catch (error) {
    console.error('Erreur statut Wave:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la vérification du statut Wave',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/payment/wave/webhook
 * @desc    Reçoit les notifications webhook Wave
 * @access  Public
 */
router.post('/wave/webhook', async (req, res) => {
  try {
    const signature = req.headers['x-wave-signature'];
    const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body || {});

    const signatureValid = waveCheckoutService.verifyWebhookSignature({ signature, rawBody });
    if (!signatureValid) {
      return res.status(401).json({
        success: false,
        message: 'Signature webhook Wave invalide',
      });
    }

    const payload = req.body || {};
    const sessionId = extractWaveSessionId(payload) || extractWaveSessionId(payload.data || {});

    if (!sessionId) {
      return res.status(400).json({
        success: false,
        message: 'sessionId introuvable dans le webhook Wave',
      });
    }

    const statusResult = await waveCheckoutService.getCheckoutSession(sessionId);
    if (!statusResult.success) {
      return res.status(400).json({
        success: false,
        message: statusResult.message || 'Impossible de vérifier la session Wave',
      });
    }

    const internalStatus = mapWaveStatusToInternal(statusResult.status);

    const txResult = await pool.query(
      `UPDATE payment_transactions
       SET statut = $1,
           api_response = $2,
           updated_at = NOW()
       WHERE transaction_id = $3
          OR (api_response->>'sessionId') = $4
          OR (api_response->>'id') = $4
       RETURNING *`,
      [
        internalStatus,
        JSON.stringify({
          provider: 'WAVE',
          sessionId,
          webhookPayload: payload,
          status: statusResult.status,
          data: statusResult.data,
        }),
        `WAVE-${sessionId}`,
        sessionId,
      ]
    );

    const tx = txResult.rows[0] || null;

    if (tx && internalStatus === 'SUCCESS' && tx.subscription_id && tx.user_id) {
      await upsertContractAfterPayment({
        subscriptionId: tx.subscription_id,
        userId: tx.user_id,
        paymentMethod: 'Wave',
        paymentTransactionId: tx.transaction_id,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Webhook Wave traité',
    });
  } catch (error) {
    console.error('Erreur webhook Wave:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors du traitement du webhook Wave',
      error: error.message,
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

/**
 * @route   GET /api/payment/contracts
 * @desc    Récupère tous les contrats actifs d'un utilisateur
 * @access  Private
 */
router.get('/contracts', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT 
        c.id,
        c.contract_number,
        c.product_name,
        c.status,
        c.amount,
        c.periodicite,
        c.start_date,
        c.next_payment_date,
        c.end_date,
        c.duration_years,
        c.payment_method,
        c.total_paid,
        c.created_at,
        s.id as subscription_id,
        s.beneficiaires,
        s.capital_garanti,
        -- Calcul du nombre de paiements restants
        CASE 
          WHEN c.periodicite = 'unique' THEN 0
          WHEN c.periodicite = 'mensuelle' THEN 
            GREATEST(0, EXTRACT(MONTH FROM AGE(c.end_date, CURRENT_DATE))::INTEGER)
          WHEN c.periodicite = 'trimestrielle' THEN 
            GREATEST(0, (EXTRACT(MONTH FROM AGE(c.end_date, CURRENT_DATE)) / 3)::INTEGER)
          WHEN c.periodicite = 'semestrielle' THEN 
            GREATEST(0, (EXTRACT(MONTH FROM AGE(c.end_date, CURRENT_DATE)) / 6)::INTEGER)
          WHEN c.periodicite = 'annuelle' THEN 
            GREATEST(0, EXTRACT(YEAR FROM AGE(c.end_date, CURRENT_DATE))::INTEGER)
          ELSE 0
        END as payments_remaining,
        -- Statut du prochain paiement
        CASE 
          WHEN c.next_payment_date IS NULL THEN 'Paiement unique effectué'
          WHEN c.next_payment_date < CURRENT_DATE THEN 'En retard'
          WHEN c.next_payment_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'Échéance proche'
          ELSE 'À jour'
        END as payment_status
       FROM contracts c
       LEFT JOIN subscriptions s ON c.subscription_id = s.id
       WHERE c.user_id = $1
       ORDER BY c.created_at DESC`,
      [userId]
    );

    return res.status(200).json({
      success: true,
      data: result.rows,
      total: result.rows.length
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des contrats:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/contracts/:id
 * @desc    Récupère les détails d'un contrat spécifique
 * @access  Private
 */
router.get('/contracts/:id', verifyToken, async (req, res) => {
  try {
    const contractId = req.params.id;
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT 
        c.*,
        s.beneficiaires,
        s.capital_garanti,
        s.questionnaire_medical,
        s.documents,
        u.nom_prenom as client_name,
        u.email as client_email,
        u.telephone as client_phone,
        -- Historique des paiements pour ce contrat
        (
          SELECT json_agg(
            json_build_object(
              'transaction_id', pt.transaction_id,
              'montant', pt.montant,
              'statut', pt.statut,
              'date', pt.created_at
            ) ORDER BY pt.created_at DESC
          )
          FROM payment_transactions pt
          WHERE pt.subscription_id = c.subscription_id
        ) as payment_history
       FROM contracts c
       LEFT JOIN subscriptions s ON c.subscription_id = s.id
       LEFT JOIN users u ON c.user_id = u.id
       WHERE c.id = $1 AND c.user_id = $2`,
      [contractId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    return res.status(200).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur lors de la récupération du contrat:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

module.exports = router;
