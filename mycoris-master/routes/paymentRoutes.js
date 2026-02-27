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
  const alreadyConfirmed =
    (subscription.statut || '').toString().toLowerCase() === 'contrat' &&
    (subscription.payment_transaction_id || '') === (paymentTransactionId || '');
  const nextPaymentDate = calculateNextPaymentDate(new Date(), subscription.periodicite);

  await pool.query(
    `UPDATE subscriptions 
      SET statut = 'contrat',
          date_validation = CURRENT_TIMESTAMP,
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

  let smsSent = false;
  if (!alreadyConfirmed && subscription.telephone) {
    try {
      const { sendSMS } = require('../services/notificationService');
      const rawPhone = `${subscription.telephone}`.replace(/\D/g, '');
      const phoneNumber = rawPhone.startsWith('225') ? rawPhone : `225${rawPhone}`;
      const montantFormatted = Number(subscription.montant || 0).toLocaleString('fr-FR', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
      });
      const productName = subscription.product_name || subscription.produit_nom || 'votre produit';
      const smsMessage = `✅ Paiement Wave confirmé. Montant: ${montantFormatted} FCFA. Votre proposition est maintenant un contrat (${productName}). CORIS Assurance.`;

      const smsResult = await sendSMS(phoneNumber, smsMessage);
      smsSent = !!smsResult?.success;
      console.log('📱 SMS confirmation contrat (auto):', smsSent ? '✅' : '⚠️');
    } catch (smsError) {
      console.error('⚠️ Erreur envoi SMS auto contrat:', smsError.message);
    }
  }

  return {
    contractCreated: true,
    contractNumber,
    smsSent,
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

    console.log('âœ… Client CorisMoney trouvÃ©:', clientInfo.data);
    
    // VÃ©rifier le solde disponible
    const soldeDisponible = parseFloat(clientInfo.data.solde || clientInfo.data.balance || 0);
    const montantRequis = parseFloat(montant);
    
    if (soldeDisponible < montantRequis) {
      console.warn(`âš ï¸ Solde insuffisant: ${soldeDisponible} FCFA < ${montantRequis} FCFA`);
      return res.status(400).json({
        success: false,
        message: 'ðŸ’° Solde insuffisant',
        detail: `Votre solde actuel (${soldeDisponible.toLocaleString()} FCFA) est insuffisant pour effectuer ce paiement (${montantRequis.toLocaleString()} FCFA).`,
        soldeDisponible: soldeDisponible,
        montantRequis: montantRequis,
        errorCode: 'INSUFFICIENT_BALANCE'
      });
    }

    console.log(`âœ… Solde suffisant: ${soldeDisponible} FCFA >= ${montantRequis} FCFA`);

    // âœ… Ã‰TAPE 2 : Effectuer le paiement
    console.log('ðŸ’³ Lancement du paiement CorisMoney...');
    const result = await corisMoneyService.paiementBien(
      codePays,
      telephone,
      montantRequis,
      codeOTP
    );

    if (result.success) {
      console.log('âœ… RÃ©ponse paiement CorisMoney:', result.data);
      
      // âš ï¸ IMPORTANT : VÃ©rifier le statut rÃ©el de la transaction
      let transactionStatus = 'PENDING';
      let errorMessage = null;
      
      // Si un transactionId est retournÃ©, vÃ©rifier son statut
      if (result.transactionId) {
        console.log('ðŸ” VÃ©rification du statut de la transaction:', result.transactionId);
        
        // Attendre 2 secondes pour que CorisMoney traite la transaction
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const statusResult = await corisMoneyService.getTransactionStatus(result.transactionId);
        
        if (statusResult.success && statusResult.data) {
          console.log('ðŸ“Š Statut reÃ§u:', statusResult.data);
          
          // Analyser le statut de la transaction
          const status = statusResult.data.statut || statusResult.data.status;
          
          if (status === 'SUCCESS' || status === 'COMPLETED') {
            transactionStatus = 'SUCCESS';
          } else if (status === 'FAILED' || status === 'INSUFFICIENT_BALANCE') {
            transactionStatus = 'FAILED';
            errorMessage = statusResult.data.message || 'Solde insuffisant ou paiement Ã©chouÃ©';
          } else {
            transactionStatus = 'PENDING';
          }
        } else {
          console.warn('âš ï¸ Impossible de vÃ©rifier le statut, marquage comme PENDING');
          transactionStatus = 'PENDING';
        }
      }
      
      // Enregistrer la transaction en base de donnÃ©es avec le VRAI statut
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
        JSON.stringify(result.data || result) // Sauvegarder la rÃ©ponse complÃ¨te de l'API
      ]);

      // âš ï¸ Ne transformer en contrat QUE si le paiement est vraiment rÃ©ussi
      if (transactionStatus === 'SUCCESS' && subscriptionId) {
        console.log('ðŸŽ‰ Paiement confirmÃ© ! Transformation de la proposition en contrat...');
        
        // Mettre Ã  jour le statut de la souscription
        await pool.query(
          `UPDATE subscriptions 
           SET statut = 'paid', 
               payment_method = 'CorisMoney',
               payment_transaction_id = $1,
               updated_at = NOW()
           WHERE id = $2`,
          [result.transactionId, subscriptionId]
        );
        
        // CrÃ©er le contrat
        const subscriptionData = await pool.query(
          'SELECT * FROM subscriptions WHERE id = $1',
          [subscriptionId]
        );
        
        if (subscriptionData.rows.length > 0) {
          const subscription = subscriptionData.rows[0];
          
          // Calculer la prochaine Ã©chÃ©ance
          const nextPaymentDate = calculateNextPaymentDate(
            new Date(),
            subscription.periodicite
          );
          
          // CrÃ©er le contrat
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
              'valid',  // Statut 'valid' quand le paiement est effectuÃ©
              subscription.montant,
              subscription.periodicite,
              new Date(),
              nextPaymentDate,
              subscription.duree || 1,
              'CorisMoney'
            ]
          );
          
          console.log('âœ… Contrat crÃ©Ã© avec succÃ¨s !');
          
          // ðŸ“± ENVOYER SMS DE CONFIRMATION AU CLIENT
          try {
            const userQuery = await pool.query(
              'SELECT nom_prenom, telephone FROM users WHERE id = $1',
              [req.user.id]
            );
            
            if (userQuery.rows.length > 0) {
              const user = userQuery.rows[0];
              const contractNumber = `CORIS-${subscription.product_name.substring(0, 3).toUpperCase()}-${Date.now()}`;
              
              const smsMessage = `Bonjour ${user.nom_prenom}, votre paiement de ${parseFloat(montant).toLocaleString()} FCFA a Ã©tÃ© effectuÃ© avec succÃ¨s ! Votre contrat ${contractNumber} est maintenant VALIDE. Merci de votre confiance. CORIS Assurance`;
              
              // Envoyer le SMS
              const smsResult = await sendSMS(`225${user.telephone}`, smsMessage);
              
              if (smsResult.success) {
                console.log('âœ… SMS de confirmation envoyÃ© au client');
              } else {
                console.error('âš ï¸ Ã‰chec envoi SMS confirmation:', smsResult.error);
              }
            }
          } catch (smsError) {
            console.error('âš ï¸ Erreur envoi SMS:', smsError.message);
            // Ne pas bloquer le flux si le SMS Ã©choue
          }
        }

        return res.status(200).json({
          success: true,
          message: 'Paiement effectuÃ© avec succÃ¨s',
          transactionId: result.transactionId,
          montant: parseFloat(montant),
          paymentRecordId: transactionResult.rows[0].id,
          contractCreated: true
        });
      } else if (transactionStatus === 'FAILED') {
        console.error('âŒ Paiement Ã©chouÃ©:', errorMessage);
        return res.status(400).json({
          success: false,
          message: errorMessage || 'Le paiement a Ã©chouÃ©. VÃ©rifiez votre solde CorisMoney.',
          transactionId: result.transactionId,
          status: 'FAILED'
        });
      } else {
        // PENDING
        console.warn('â³ Transaction en attente de confirmation');
        return res.status(202).json({
          success: true,
          message: 'Transaction en cours de traitement. VÃ©rifiez le statut dans quelques instants.',
          transactionId: result.transactionId,
          status: 'PENDING',
          paymentRecordId: transactionResult.rows[0].id
        });
      }
    } else {
      // Enregistrer l'Ã©chec de la transaction
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
          errorMessage = 'âŒ Erreur lors du paiement CorisMoney';
          errorCode = 'CORISMONEY_ERROR';
        } else if (code.includes('OTP') || code.includes('otp')) {
          errorMessage = 'ðŸ”‘ Code OTP invalide ou expirÃ©';
          errorCode = 'INVALID_OTP';
        } else if (code.includes('BALANCE') || code.includes('INSUFFICIENT')) {
          errorMessage = 'ðŸ’° Solde insuffisant';
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
 * @desc    CrÃ©e une session de paiement Wave Checkout
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

    // 1) CrÃ©er session Wave chez le provider.
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
        message: waveResult.message || 'Impossible de crÃ©er la session Wave',
        error: waveResult.error,
      });
    }

    // 2) Normaliser session/URL pour ne jamais casser l'ouverture cÃ´tÃ© app.
    const safeSessionId = waveResult.sessionId;
    const safeLaunchUrl =
      waveResult.launchUrl || (safeSessionId ? `https://pay.wave.com/c/${safeSessionId}` : null);

    if (!safeSessionId || !safeLaunchUrl) {
      return res.status(400).json({
        success: false,
        message: 'RÃ©ponse Wave incomplÃ¨te: sessionId/launchUrl manquant',
        error: waveResult.data || waveResult.error || null,
      });
    }

    const sessionId = safeSessionId;
    const transactionId = `WAVE-${sessionId || Date.now()}`;
    const internalStatus = mapWaveStatusToInternal(waveResult.status);

    // 3) Persister immÃ©diatement la transaction pour suivi/polling/reconcile.
    const inserted = await pool.query(
      `INSERT INTO payment_transactions (
        user_id,
        subscription_id,
        transaction_id,
        provider,
        session_id,
        code_pays,
        telephone,
        montant,
        statut,
        description,
        api_response,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
      RETURNING id`,
      [
        req.user.id,
        subscriptionId || null,
        transactionId,
        'Wave',
        sessionId || null,
        codePays || '225',
        customerPhone || 'N/A',
        normalizedAmount,
        internalStatus,
        description || 'Paiement Wave',
        JSON.stringify({
          provider: 'WAVE',
          sessionId,
          launchUrl: safeLaunchUrl,
          status: waveResult.status,
          data: waveResult.data,
        }),
      ]
    );

    return res.status(200).json({
      success: true,
      message: 'Session Wave crÃ©Ã©e avec succÃ¨s',
      data: {
        paymentRecordId: inserted.rows[0].id,
        transactionId,
        sessionId,
        launchUrl: safeLaunchUrl,
        status: waveResult.status,
      },
    });
  } catch (error) {
    console.error('Erreur crÃ©ation session Wave:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la crÃ©ation de la session Wave',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/payment/wave/status/:sessionId
 * @desc    VÃ©rifie le statut d'une session Wave
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

    // 1) Interroger Wave pour le statut temps rÃ©el.
    const statusResult = await waveCheckoutService.getCheckoutSession(sessionId);

    if (!statusResult.success) {
      // 2) Fallback local: si Wave est indisponible, renvoyer le dernier statut connu en base.
      const resolvedTransactionId = transactionId || `WAVE-${sessionId}`;
      const localTxResult = await pool.query(
        `SELECT transaction_id, statut, subscription_id, api_response
         FROM payment_transactions
         WHERE transaction_id = $1
            OR session_id = $2
            OR (api_response->>'sessionId') = $2
            OR (api_response->>'id') = $2
         ORDER BY updated_at DESC NULLS LAST, created_at DESC
         LIMIT 1`,
        [resolvedTransactionId, sessionId]
      );

      if (localTxResult.rows.length > 0) {
        const localTx = localTxResult.rows[0];
        const localStatus = (localTx.statut || 'PENDING').toString().toUpperCase();

        return res.status(200).json({
          success: true,
          message: 'Statut Wave retournÃ© depuis la base locale (fallback)',
          data: {
            provider: 'WAVE',
            sessionId,
            transactionId: localTx.transaction_id || resolvedTransactionId,
            status: localStatus,
            providerStatus: null,
            contractCreated: false,
            contractNumber: null,
            apiResponse: localTx.api_response || null,
            source: 'local-fallback',
          },
        });
      }

      return res.status(400).json({
        success: false,
        message: statusResult.message || 'Impossible de rÃ©cupÃ©rer le statut Wave',
        error: statusResult.error,
      });
    }

    const internalStatus = mapWaveStatusToInternal(statusResult.status);
    const resolvedTransactionId = transactionId || `WAVE-${sessionId}`;

    // 3) Mettre Ã  jour la transaction locale avec la rÃ©ponse provider.
    const paymentTxResult = await pool.query(
      `UPDATE payment_transactions
       SET statut = $1,
           provider = 'Wave',
           session_id = COALESCE(session_id, $2),
           api_response = $3,
           updated_at = NOW()
       WHERE transaction_id = $4
          OR (api_response->>'sessionId') = $5
          OR (api_response->>'id') = $5
       RETURNING *`,
      [
        internalStatus,
        sessionId,
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

    // 4) Si succÃ¨s, transformer la proposition en contrat et tracer le paiement.
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
        console.warn('âš ï¸  Impossible de crÃ©er le contrat (table manquante?):', contractError.message);
        // Continue sans bloquer - utile pour les tests
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Statut Wave rÃ©cupÃ©rÃ©',
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
      message: 'Erreur serveur lors de la vÃ©rification du statut Wave',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/payment/wave/reconcile
 * @desc    RÃ©concilie les paiements Wave en attente pour l'utilisateur connectÃ©
 * @access  Private
 */
router.post('/wave/reconcile', verifyToken, async (req, res) => {
  try {
    const pendingTxResult = await pool.query(
      `SELECT id, user_id, subscription_id, transaction_id, statut, api_response
       FROM payment_transactions
       WHERE user_id = $1
         AND transaction_id LIKE 'WAVE-%'
         AND COALESCE(statut, 'PENDING') <> 'SUCCESS'
         AND created_at >= NOW() - INTERVAL '7 days'
       ORDER BY created_at DESC
       LIMIT 20`,
      [req.user.id]
    );

    let checked = 0;
    let successCount = 0;
    let failedCount = 0;

    for (const tx of pendingTxResult.rows) {
      const apiResponse = tx.api_response || {};
      const sessionId =
        apiResponse.sessionId ||
        apiResponse.id ||
        apiResponse.data?.id ||
        tx.transaction_id?.replace(/^WAVE-/, '') ||
        null;

      if (!sessionId) continue;

      checked += 1;
      const statusResult = await waveCheckoutService.getCheckoutSession(sessionId);
      if (!statusResult.success) continue;

      const internalStatus = mapWaveStatusToInternal(statusResult.status);

      await pool.query(
        `UPDATE payment_transactions
         SET statut = $1,
             provider = 'Wave',
             session_id = COALESCE(session_id, $2),
             api_response = COALESCE(api_response::jsonb, '{}'::jsonb) || $3::jsonb,
             updated_at = NOW()
         WHERE id = $4`,
        [
          internalStatus,
          sessionId,
          JSON.stringify({
            provider: 'WAVE',
            sessionId,
            reconciledAt: new Date().toISOString(),
            providerStatus: statusResult.status,
            data: statusResult.data || null,
          }),
          tx.id,
        ]
      );

      if (internalStatus === 'SUCCESS') {
        successCount += 1;
        if (tx.subscription_id && tx.user_id) {
          await upsertContractAfterPayment({
            subscriptionId: tx.subscription_id,
            userId: tx.user_id,
            paymentMethod: 'Wave',
            paymentTransactionId: tx.transaction_id,
          });
        }
      } else if (internalStatus === 'FAILED') {
        failedCount += 1;
      }
    }

    return res.status(200).json({
      success: true,
      message: 'RÃ©conciliation Wave terminÃ©e',
      data: {
        checked,
        successCount,
        failedCount,
      },
    });
  } catch (error) {
    console.error('Erreur rÃ©conciliation Wave:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la rÃ©conciliation Wave',
      error: error.message,
    });
  }
});

/**
 * @route   POST /api/payment/wave/webhook
 * @desc    ReÃ§oit les notifications webhook Wave
 * @access  Public
 */
router.post('/wave/webhook', async (req, res) => {
  try {
    const signature = req.headers['x-wave-signature'];
    const rawBody = req.rawBody || (typeof req.body === 'string' ? req.body : JSON.stringify(req.body || {}));

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
        message: statusResult.message || 'Impossible de vÃ©rifier la session Wave',
      });
    }

    const internalStatus = mapWaveStatusToInternal(statusResult.status);

    const txResult = await pool.query(
      `UPDATE payment_transactions
         SET statut = $1,
           provider = 'Wave',
           session_id = COALESCE(session_id, $2),
           api_response = $3,
           updated_at = NOW()
       WHERE transaction_id = $4
          OR (api_response->>'sessionId') = $5
          OR (api_response->>'id') = $5
       RETURNING *`,
      [
        internalStatus,
        sessionId,
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
      message: 'Webhook Wave traitÃ©',
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
 * @desc    RÃ©cupÃ¨re les informations d'un client CorisMoney
 * @access  Private
 */
router.get('/client-info', verifyToken, async (req, res) => {
  try {
    const { codePays, telephone } = req.query;

    if (!codePays || !telephone) {
      return res.status(400).json({
        success: false,
        message: 'Le code pays et le numÃ©ro de tÃ©lÃ©phone sont requis'
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
    console.error('Erreur lors de la rÃ©cupÃ©ration des infos client:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/transaction-status/:transactionId
 * @desc    VÃ©rifie le statut d'une transaction
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
      // Mettre Ã  jour le statut en base de donnÃ©es si nÃ©cessaire
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
    console.error('Erreur lors de la vÃ©rification du statut:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/history
 * @desc    RÃ©cupÃ¨re l'historique des paiements d'un utilisateur
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
    console.error('Erreur lors de la rÃ©cupÃ©ration de l\'historique:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/contracts
 * @desc    RÃ©cupÃ¨re tous les contrats actifs d'un utilisateur
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
          WHEN c.next_payment_date IS NULL THEN 'Paiement unique effectuÃ©'
          WHEN c.next_payment_date < CURRENT_DATE THEN 'En retard'
          WHEN c.next_payment_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'Ã‰chÃ©ance proche'
          ELSE 'Ã€ jour'
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
    console.error('Erreur lors de la rÃ©cupÃ©ration des contrats:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/payment/contracts/:id
 * @desc    RÃ©cupÃ¨re les dÃ©tails d'un contrat spÃ©cifique
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
        message: 'Contrat non trouvÃ©'
      });
    }

    return res.status(200).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur lors de la rÃ©cupÃ©ration du contrat:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/payment/confirm-wave-payment/:subscriptionId
 * @desc    Finaliser un paiement Wave rÃ©ussi:
 *          1. Changer le statut de 'proposition' Ã  'contrat'
 *          2. Envoyer un SMS de confirmation au client
 * @access  Private
 * @param   subscriptionId - ID de la souscription/proposition
 */
router.post('/confirm-wave-payment/:subscriptionId', verifyToken, async (req, res) => {
  try {
    const { subscriptionId } = req.params;
    const userId = req.user.id;

    // 1ï¸âƒ£ RÃ‰CUPÃ‰RER LES INFOS DE LA SOUSCRIPTION
    const subQuery = await pool.query(
      `SELECT 
        s.id, s.produit_nom, s.montant, s.user_id,
        u.nom_prenom, u.telephone, u.email
       FROM subscriptions s
       LEFT JOIN users u ON s.user_id = u.id
       WHERE s.id = $1 AND s.user_id = $2`,
      [subscriptionId, userId]
    );

    if (subQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvÃ©e'
      });
    }

    const subscription = subQuery.rows[0];

    // 2ï¸âƒ£ CHANGER LE STATUT Ã€ 'contrat'
    const updateStatusQuery = await pool.query(
      `UPDATE subscriptions 
       SET statut = 'contrat', 
           date_validation = CURRENT_TIMESTAMP,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      [subscriptionId, userId]
    );

    if (updateStatusQuery.rows.length === 0) {
      return res.status(500).json({
        success: false,
        message: 'Impossible de mettre Ã  jour le statut de la proposition'
      });
    }

    const updatedSubscription = updateStatusQuery.rows[0];

    // 3ï¸âƒ£ ENVOYER UN SMS DE CONFIRMATION
    try {
      if (subscription.telephone) {
        const { sendSMS } = require('../services/notificationService');
        
        const montantFormatted = parseFloat(subscription.montant).toLocaleString('fr-FR', {
          minimumFractionDigits: 0,
          maximumFractionDigits: 0
        });

        const smsMessage = `âœ… Paiement Wave confirmÃ©! Montant: ${montantFormatted} FCFA pour ${subscription.produit_nom}. Votre proposition est maintenant un contrat. Merci. CORIS Assurance`;

        const phoneNumber = '225' + subscription.telephone;
        const smsResult = await sendSMS(phoneNumber, smsMessage);

        console.log('ðŸ“± SMS de confirmation envoyÃ©:', smsResult.success ? 'âœ…' : 'âš ï¸');
      }
    } catch (smsError) {
      console.error('âš ï¸ Erreur envoi SMS:', smsError.message);
      // Ne pas bloquer si SMS Ã©choue
    }

    // 4ï¸âƒ£ RETOURNER LE SUCCÃˆS
    return res.status(200).json({
      success: true,
      message: 'âœ… Paiement confirmÃ© ! La proposition est maintenant un contrat.',
      data: {
        subscriptionId: updatedSubscription.id,
        statut: updatedSubscription.statut,
        date_validation: updatedSubscription.date_validation,
        produit: subscription.produit_nom,
        montant: subscription.montant,
        client: subscription.nom_prenom
      }
    });

  } catch (error) {
    console.error('Erreur confirmation Wave payment:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la confirmation du paiement',
      error: error.message
    });
  }
});

/**
 * @route   GET /wave-success
 * @desc    Page de succÃ¨s affichÃ©e aprÃ¨s paiement rÃ©ussi Wave
 * @access  Public (Wave redirige l'utilisateur)
 * 
 * URL appelÃ©e par Wave aprÃ¨s succÃ¨s du paiement
 * Affiche un message de confirmation et ferme la session browser
 */
router.get('/wave-success', async (req, res) => {
  try {
    const { amount, currency } = req.query;
    const session_id =
      req.query.session_id ||
      req.query.sessionId ||
      req.query.id ||
      req.query.checkout_session_id ||
      null;
    const reference =
      req.query.reference ||
      req.query.client_reference ||
      req.query.clientReference ||
      req.query.merchant_reference ||
      session_id ||
      null;
    let verifiedInternalStatus = 'PENDING';
    let verifiedAmount = null;
    let verifiedCurrency = currency || null;
    let verifiedReference = reference || null;

    const pick = (obj, paths) => {
      for (const path of paths) {
        const value = path.split('.').reduce((acc, key) => (acc && acc[key] !== undefined ? acc[key] : undefined), obj);
        if (value !== undefined && value !== null && `${value}` !== '') return value;
      }
      return null;
    };

    console.log('âœ… WAVE SUCCESS PAGE APPELÃ‰E');
    console.log('   Session ID:', session_id);
    console.log('   Montant:', amount, currency);
    console.log('   RÃ©fÃ©rence:', reference);

    // ðŸ”’ SÃ‰CURITÃ‰: VÃ©rifier le statut auprÃ¨s de Wave
    if (session_id) {
      try {
        const sessionStatus = await waveCheckoutService.getCheckoutSession(session_id);
        console.log('ðŸ“Š VÃ©rification Wave:', sessionStatus.status);

        if (sessionStatus?.success) {
          verifiedInternalStatus = mapWaveStatusToInternal(sessionStatus.status);
          const sessionData = sessionStatus.data || {};
          verifiedAmount = sessionData.amount ?? sessionData.amount_paid ?? amount ?? null;
          verifiedCurrency = sessionData.currency || verifiedCurrency || 'XOF';
          verifiedReference =
            sessionData.client_reference ||
            sessionData.reference ||
            verifiedReference ||
            session_id;

          const txResult = await pool.query(
            `UPDATE payment_transactions
             SET statut = $1,
                 api_response = COALESCE(api_response::jsonb, '{}'::jsonb) || $2::jsonb,
                 updated_at = NOW()
             WHERE transaction_id = $3
                OR (api_response->>'sessionId') = $4
                OR (api_response->>'id') = $4
             RETURNING *`,
            [
              verifiedInternalStatus,
              JSON.stringify({
                provider: 'WAVE',
                sessionId: session_id,
                verifiedFrom: 'success_url',
                providerStatus: sessionStatus.status,
                data: sessionStatus.data || null,
              }),
              `WAVE-${session_id}`,
              session_id,
            ]
          );

          const tx = txResult.rows[0] || null;
          const txApi = tx?.api_response || {};
          verifiedAmount = verifiedAmount || pick(sessionData, [
            'amount',
            'amount_total',
            'amount_paid',
            'checkout_session.amount',
            'data.amount',
          ]) || pick(txApi, [
            'amount',
            'data.amount',
            'apiResponse.amount',
            'apiResponse.data.amount',
          ]);

          verifiedCurrency = verifiedCurrency || pick(sessionData, [
            'currency',
            'checkout_session.currency',
            'data.currency',
          ]) || pick(txApi, ['currency', 'data.currency', 'apiResponse.currency', 'apiResponse.data.currency']) || 'XOF';

          verifiedReference = verifiedReference || pick(sessionData, [
            'client_reference',
            'reference',
            'merchant_reference',
            'checkout_session.client_reference',
            'data.client_reference',
          ]) || pick(txApi, [
            'client_reference',
            'reference',
            'data.client_reference',
            'apiResponse.client_reference',
            'apiResponse.data.client_reference',
          ]) || session_id;

          if (tx && verifiedInternalStatus === 'SUCCESS' && tx.subscription_id && tx.user_id) {
            await upsertContractAfterPayment({
              subscriptionId: tx.subscription_id,
              userId: tx.user_id,
              paymentMethod: 'Wave',
              paymentTransactionId: tx.transaction_id,
            });
          }
        }
      } catch (e) {
        console.warn('âš ï¸ Impossible de vÃ©rifier le statut Wave:', e.message);
      }
    }

    const displayAmountRaw = verifiedAmount ?? amount;
    const parsedAmount = Number(displayAmountRaw);
    const formattedAmount = Number.isFinite(parsedAmount)
      ? parsedAmount.toLocaleString('fr-FR', { maximumFractionDigits: 0 })
      : null;
    const displayCurrency = verifiedCurrency || 'XOF';
    const displayReference = verifiedReference || 'N/A';

    const successTitle =
      verifiedInternalStatus === 'SUCCESS'
        ? 'Paiement RÃ©ussi! ðŸŽ‰'
        : verifiedInternalStatus === 'FAILED'
            ? 'Paiement Non ConfirmÃ© âš ï¸'
            : 'Paiement En VÃ©rification â³';

    const successMessage =
      verifiedInternalStatus === 'SUCCESS'
        ? 'Votre paiement a Ã©tÃ© vÃ©rifiÃ© avec succÃ¨s auprÃ¨s de Wave. Votre session se ferme automatiquement dans '
        : verifiedInternalStatus === 'FAILED'
            ? 'Le statut retournÃ© par Wave indique un Ã©chec. Veuillez rÃ©essayer. Fermeture dans '
            : 'Votre paiement est en cours de vÃ©rification cÃ´tÃ© Wave. Fermeture dans ';

    // ðŸŒ Page HTML de confirmation avec style moderne
    const htmlPage = `
      <!DOCTYPE html>
      <html lang="fr">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Paiement RÃ©ussi - CORIS Assurance</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }

          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }

          .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 40px;
            max-width: 500px;
            text-align: center;
            animation: slideUp 0.6s ease-out;
          }

          @keyframes slideUp {
            from {
              opacity: 0;
              transform: translateY(30px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }

          .checkmark {
            width: 80px;
            height: 80px;
            margin: 0 auto 30px;
            background: #10B981;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            animation: popIn 0.6s ease-out;
          }

          @keyframes popIn {
            0% {
              transform: scale(0);
            }
            50% {
              transform: scale(1.2);
            }
            100% {
              transform: scale(1);
            }
          }

          .checkmark svg {
            stroke: white;
            stroke-linecap: round;
            stroke-linejoin: round;
            animation: drawCheck 0.6s ease-out 0.3s forwards;
            animation-fill-mode: forwards;
            opacity: 0;
          }

          @keyframes drawCheck {
            to {
              opacity: 1;
            }
          }

          h1 {
            color: #002B6B;
            font-size: 28px;
            margin-bottom: 10px;
            font-weight: 600;
          }

          p {
            color: #64748B;
            font-size: 16px;
            margin-bottom: 20px;
            line-height: 1.6;
          }

          .details {
            background: #F8FAFC;
            border-left: 4px solid #10B981;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: left;
          }

          .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            color: #475569;
            font-size: 14px;
          }

          .detail-row strong {
            color: #002B6B;
          }

          .actions {
            display: grid;
            gap: 12px;
            margin-top: 30px;
          }

          button, a {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
            display: inline-block;
          }

          .btn-primary {
            background: linear-gradient(135deg, #10B981 0%, #059669 100%);
            color: white;
          }

          .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(16, 185, 129, 0.3);
          }

          .btn-secondary {
            background: #E2E8F0;
            color: #002B6B;
          }

          .btn-secondary:hover {
            background: #CBD5E1;
          }

          .loading-spinner {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            margin-right: 10px;
            vertical-align: middle;
          }

          @keyframes spin {
            to { transform: rotate(360deg); }
          }

          .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #E2E8F0;
            color: #94A3B8;
            font-size: 12px;
          }

          .close-btn {
            position: absolute;
            top: 20px;
            right: 20px;
            background: #E2E8F0;
            border: none;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 24px;
            color: #64748B;
            transition: all 0.3s ease;
          }

          .close-btn:hover {
            background: #CBD5E1;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <button class="close-btn" onclick="closeWindow()">âœ•</button>

          <div class="checkmark">
            <svg width="50" height="50" viewBox="0 0 50 50" fill="none">
              <path d="M10 25L20 35L40 15" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>

          <h1>${successTitle}</h1>
          <p>${successMessage}</p>

          <div class="details">
            <div class="detail-row">
              <strong>Montant payÃ©:</strong>
              <span>${formattedAmount || 'N/A'} ${displayCurrency}</span>
            </div>
            <div class="detail-row">
              <strong>ID de session:</strong>
              <span>${session_id ? session_id.substring(0, 15) + '...' : 'N/A'}</span>
            </div>
            <div class="detail-row">
              <strong>RÃ©fÃ©rence:</strong>
              <span>${displayReference}</span>
            </div>
            <div class="detail-row">
              <strong>Heure:</strong>
              <span>${new Date().toLocaleString('fr-FR')}</span>
            </div>
          </div>

          <p>Un SMS de confirmation a Ã©tÃ© envoyÃ© Ã  votre numÃ©ro de tÃ©lÃ©phone.</p>

          <div class="actions">
            <button class="btn-primary" onclick="returnToApp()">
              <span class="loading-spinner"></span> Retourner Ã  l'application
            </button>
            <button class="btn-secondary" onclick="closeWindow()">Fermer</button>
          </div>

          <div class="footer">
            <p>Â© 2026 CORIS Assurance - Tous droits rÃ©servÃ©s</p>
            <p>Cliquez sur "Retourner Ã  l'application" pour revenir dans l'app.</p>
          </div>
        </div>

        <script>
          function closeWindow() {
            if (window.opener) {
              window.opener.focus();
              window.close();
            } else {
              window.close();
            }
          }

          function returnToApp() {
            // Rediriger vers le protocole custom ou fallback
            if (window.opener) {
              window.opener.focus();
              window.close();
            } else {
              // Schema custom pour rediriger vers l'app Flutter
              window.location.href = 'coris://payment-success?session_id=${session_id}';
              // Fallback si le schema n'est pas reconnu
              setTimeout(() => {
                window.location.href = 'intent://payment-success?session_id=${session_id || ''}#Intent;scheme=coris;package=com.example.mycorislife;end';
              }, 700);
            }
          }

          // Avertir le parent (si ouverture en popup)
          if (window.opener && typeof window.opener !== 'undefined') {
            try {
              window.opener.postMessage({
                type: 'WAVE_PAYMENT_SUCCESS',
                sessionId: '${session_id}',
                amount: ${amount || 0},
                currency: '${currency || 'XOF'}',
                reference: '${reference || ''}'
              }, '*');
            } catch (e) {
              console.error('Erreur postMessage:', e);
            }
          }
        </script>
      </body>
      </html>
    `;

    res.type('text/html').send(htmlPage);
  } catch (error) {
    console.error('Erreur page success:', error);
    res.status(500).type('text/html').send(`
      <html>
      <body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; background: #f0f0f0;">
        <div style="background: white; padding: 40px; border-radius: 8px; text-align: center;">
          <h1 style="color: #e74c3c;">Erreur</h1>
          <p>Une erreur s'est produite lors du traitement de votre paiement.</p>
          <p>Code: ${error.message}</p>
          <a href="/" style="color: #3498db; text-decoration: none;">Retour</a>
        </div>
      </body>
      </html>
    `);
  }
});

/**
 * @route   GET /wave-error
 * @desc    Page d'erreur affichÃ©e aprÃ¨s Ã©chec du paiement Wave
 * @access  Public (Wave redirige l'utilisateur)
 */
router.get('/wave-error', async (req, res) => {
  try {
    const session_id =
      req.query.session_id ||
      req.query.sessionId ||
      req.query.id ||
      req.query.checkout_session_id ||
      null;
    const reason =
      req.query.reason ||
      req.query.error_reason ||
      req.query.message ||
      null;
    const error_code =
      req.query.error_code ||
      req.query.code ||
      req.query.status_code ||
      null;
    let verifiedInternalStatus = 'FAILED';

    console.log('âŒ WAVE ERROR PAGE APPELÃ‰E');
    console.log('   Session ID:', session_id);
    console.log('   Raison:', reason);
    console.log('   Code erreur:', error_code);

    // ðŸ”’ SÃ‰CURITÃ‰: VÃ©rifier le statut auprÃ¨s de Wave
    if (session_id) {
      try {
        const sessionStatus = await waveCheckoutService.getCheckoutSession(session_id);
        console.log('ðŸ“Š VÃ©rification Wave:', sessionStatus.status);

        if (sessionStatus?.success) {
          verifiedInternalStatus = mapWaveStatusToInternal(sessionStatus.status);

          const txResult = await pool.query(
            `UPDATE payment_transactions
             SET statut = $1,
                 api_response = COALESCE(api_response::jsonb, '{}'::jsonb) || $2::jsonb,
                 updated_at = NOW()
             WHERE transaction_id = $3
                OR (api_response->>'sessionId') = $4
                OR (api_response->>'id') = $4
             RETURNING *`,
            [
              verifiedInternalStatus,
              JSON.stringify({
                provider: 'WAVE',
                sessionId: session_id,
                verifiedFrom: 'error_url',
                providerStatus: sessionStatus.status,
                data: sessionStatus.data || null,
              }),
              `WAVE-${session_id}`,
              session_id,
            ]
          );

          const tx = txResult.rows[0] || null;
          if (tx && verifiedInternalStatus === 'SUCCESS' && tx.subscription_id && tx.user_id) {
            await upsertContractAfterPayment({
              subscriptionId: tx.subscription_id,
              userId: tx.user_id,
              paymentMethod: 'Wave',
              paymentTransactionId: tx.transaction_id,
            });
          }
        }
      } catch (e) {
        console.warn('âš ï¸ Impossible de vÃ©rifier le statut Wave:', e.message);
      }
    }

    const errorTitle =
      verifiedInternalStatus === 'SUCCESS'
        ? 'Paiement ConfirmÃ© âœ…'
        : verifiedInternalStatus === 'PENDING'
            ? 'Paiement En VÃ©rification â³'
            : 'Paiement Ã‰chouÃ© âŒ';

    const errorMessage =
      verifiedInternalStatus === 'SUCCESS'
        ? 'Le paiement a finalement Ã©tÃ© confirmÃ© cÃ´tÃ© Wave. Vous pouvez revenir dans l\'application.'
        : verifiedInternalStatus === 'PENDING'
            ? 'Le paiement est encore en cours de vÃ©rification. Veuillez patienter quelques instants puis vÃ©rifier dans l\'application.'
            : 'Votre paiement n\'a pas pu Ãªtre complÃ©tÃ©. Veuillez rÃ©essayer.';

    // ðŸŒ Page HTML d'erreur avec style moderne
    const htmlPage = `
      <!DOCTYPE html>
      <html lang="fr">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Paiement Ã‰chouÃ© - CORIS Assurance</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }

          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
          }

          .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 40px;
            max-width: 500px;
            text-align: center;
            animation: slideUp 0.6s ease-out;
          }

          @keyframes slideUp {
            from {
              opacity: 0;
              transform: translateY(30px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }

          .error-icon {
            width: 80px;
            height: 80px;
            margin: 0 auto 30px;
            background: #EF4444;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            animation: shake 0.6s ease-out;
          }

          @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-10px); }
            75% { transform: translateX(10px); }
          }

          .error-icon svg {
            stroke: white;
            stroke-width: 3;
            stroke-linecap: round;
          }

          h1 {
            color: #002B6B;
            font-size: 28px;
            margin-bottom: 10px;
            font-weight: 600;
          }

          p {
            color: #64748B;
            font-size: 16px;
            margin-bottom: 20px;
            line-height: 1.6;
          }

          .error-details {
            background: #FEF2F2;
            border-left: 4px solid #EF4444;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: left;
          }

          .detail-row {
            padding: 8px 0;
            color: #475569;
            font-size: 14px;
          }

          .error-reason {
            background: #FCE7E7;
            padding: 12px;
            border-radius: 6px;
            color: #DC2626;
            font-weight: 500;
            margin-bottom: 12px;
          }

          .actions {
            display: grid;
            gap: 12px;
            margin-top: 30px;
          }

          button, a {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
            display: inline-block;
          }

          .btn-primary {
            background: #002B6B;
            color: white;
          }

          .btn-primary:hover {
            transform: translateY(-2px);
            background: #1a3a5f;
          }

          .btn-secondary {
            background: #E2E8F0;
            color: #002B6B;
          }

          .btn-secondary:hover {
            background: #CBD5E1;
          }

          .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #E2E8F0;
            color: #94A3B8;
            font-size: 12px;
          }

          .close-btn {
            position: absolute;
            top: 20px;
            right: 20px;
            background: #E2E8F0;
            border: none;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 24px;
            color: #64748B;
            transition: all 0.3s ease;
          }

          .close-btn:hover {
            background: #CBD5E1;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <button class="close-btn" onclick="closeWindow()">âœ•</button>

          <div class="error-icon">
            <svg width="50" height="50" viewBox="0 0 50 50" fill="none">
              <line x1="15" y1="15" x2="35" y2="35"/>
              <line x1="35" y1="15" x2="15" y2="35"/>
            </svg>
          </div>

          <h1>${errorTitle}</h1>
          <p>${errorMessage}</p>

          <div class="error-details">
            <div class="error-reason">
              ${reason ? reason.replace(/^\w/, (c) => c.toUpperCase()) : 'Raison inconnue'}
            </div>
            <div class="detail-row">
              <strong>Code erreur:</strong> ${error_code || 'N/A'}
            </div>
            <div class="detail-row">
              <strong>Session ID:</strong> ${session_id ? session_id.substring(0, 15) + '...' : 'N/A'}
            </div>
            <div class="detail-row">
              <strong>Heure:</strong> ${new Date().toLocaleString('fr-FR')}
            </div>
          </div>

          <div class="actions">
            <button class="btn-primary" onclick="returnToApp()">
              Retour Ã  l'application
            </button>
            <button class="btn-secondary" onclick="closeWindow()">Fermer</button>
          </div>

          <div class="footer">
            <p>Â© 2026 CORIS Assurance - Tous droits rÃ©servÃ©s</p>
            <p>Si vous avez besoin d'aide, contactez notre support: support@corisassurance.ci</p>
          </div>
        </div>

        <script>
          function closeWindow() {
            if (window.opener) {
              window.opener.focus();
              window.close();
            } else {
              window.close();
            }
          }

          function returnToApp() {
            if (window.opener) {
              window.opener.focus();
              window.close();
            } else {
              window.location.href = 'coris://payment-error?session_id=${session_id}';
              setTimeout(() => {
                window.location.href = 'intent://payment-error?session_id=${session_id || ''}#Intent;scheme=coris;package=com.example.mycorislife;end';
              }, 700);
            }
          }

          // Notifier le parent si ouverture en popup
          if (window.opener && typeof window.opener !== 'undefined') {
            try {
              window.opener.postMessage({
                type: 'WAVE_PAYMENT_ERROR',
                sessionId: '${session_id}',
                reason: '${reason || 'unknown'}',
                errorCode: '${error_code || 'unknown'}'
              }, '*');
            } catch (e) {
              console.error('Erreur postMessage:', e);
            }
          }
        </script>
      </body>
      </html>
    `;

    res.type('text/html').send(htmlPage);
  } catch (error) {
    console.error('Erreur page error:', error);
    res.status(500).type('text/html').send(`
      <html>
      <body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; background: #f0f0f0;">
        <div style="background: white; padding: 40px; border-radius: 8px; text-align: center;">
          <h1 style="color: #e74c3c;">Erreur</h1>
          <p>Une erreur s'est produite.</p>
          <a href="/" style="color: #3498db; text-decoration: none;">Retour</a>
        </div>
      </body>
      </html>
    `);
  }
});

module.exports = router;
