/**
 * ========================================
 * ROUTES API CORISMONEY - VERSION COMMENTÉE
 * ========================================
 * 
 * Ce fichier définit toutes les routes API pour les paiements CorisMoney.
 * Toutes les routes sont protégées par le middleware JWT (verifyToken).
 * 
 * Routes disponibles:
 * - POST   /api/payment/send-otp           : Envoyer code OTP par SMS
 * - POST   /api/payment/process-payment    : Traiter un paiement avec OTP
 * - GET    /api/payment/client-info        : Récupérer infos client CorisMoney
 * - GET    /api/payment/transaction-status : Vérifier statut d'une transaction
 * - GET    /api/payment/history            : Historique des paiements d'un utilisateur
 * 
 * Sécurité:
 * - Toutes les routes nécessitent un token JWT valide
 * - Le token est vérifié par le middleware verifyToken
 * - L'utilisateur connecté est disponible dans req.user
 */

const express = require('express');
const router = express.Router();
const corisMoneyService = require('../services/corisMoneyService');
const { verifyToken } = require('../middlewares/authMiddleware');
const pool = require('../db');

/**
 * ========================================
 * ROUTE 1 : ENVOI DU CODE OTP
 * ========================================
 * 
 * Envoie un code OTP (One-Time Password) par SMS au numéro CorisMoney du client.
 * Le client devra saisir ce code pour valider le paiement.
 * 
 * @route   POST /api/payment/send-otp
 * @access  Private (nécessite un token JWT)
 * 
 * Body de la requête:
 * {
 *   "codePays": "225",           // Code téléphonique du pays (ex: "225" pour CI)
 *   "telephone": "0700000000"    // Numéro de téléphone du client
 * }
 * 
 * Réponse SUCCESS (200):
 * {
 *   "success": true,
 *   "message": "Code OTP envoyé avec succès"
 * }
 * 
 * Réponse ERREUR (400):
 * {
 *   "success": false,
 *   "message": "Erreur lors de l'envoi du code OTP",
 *   "error": { ... }
 * }
 */
router.post('/send-otp', verifyToken, async (req, res) => {
  try {
    // Extraction des paramètres du body de la requête
    const { codePays, telephone } = req.body;

    // VALIDATION : Vérifier que tous les champs requis sont présents
    if (!codePays || !telephone) {
      return res.status(400).json({
        success: false,
        message: 'Le code pays et le numéro de téléphone sont requis'
      });
    }

    // APPEL AU SERVICE CORISMONEY
    // Le service génère le hash SHA256 et appelle l'API CorisMoney
    const result = await corisMoneyService.sendOTP(codePays, telephone);

    if (result.success) {
      // ENREGISTREMENT EN BASE DE DONNÉES (optionnel mais recommandé)
      // Cela permet de tracer toutes les demandes d'OTP
      await pool.query(
        `INSERT INTO payment_otp_requests (user_id, code_pays, telephone, created_at)
         VALUES ($1, $2, $3, NOW())`,
        [req.user.id, codePays, telephone]  // req.user.id vient du token JWT
      );

      // Retourner la réponse de succès
      return res.status(200).json({
        success: true,
        message: result.message
      });
    } else {
      // En cas d'erreur de l'API CorisMoney
      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error
      });
    }
  } catch (error) {
    // En cas d'erreur serveur (exception)
    console.error('Erreur lors de l\'envoi de l\'OTP:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de l\'envoi du code OTP',
      error: error.message
    });
  }
});

/**
 * ========================================
 * ROUTE 2 : TRAITEMENT DU PAIEMENT
 * ========================================
 * 
 * Traite le paiement après que le client ait reçu et saisi le code OTP.
 * Cette route débite le compte CorisMoney du client et crédite le compte marchand.
 * 
 * @route   POST /api/payment/process-payment
 * @access  Private (nécessite un token JWT)
 * 
 * Body de la requête:
 * {
 *   "codePays": "225",                  // Code téléphonique du pays
 *   "telephone": "0700000000",          // Numéro de téléphone du client
 *   "montant": 50000,                   // Montant en FCFA (nombre)
 *   "codeOTP": "123456",                // Code OTP reçu par SMS
 *   "subscriptionId": 123,              // ID de la souscription (optionnel)
 *   "description": "Prime SÉRÉNITÉ"     // Description du paiement (optionnel)
 * }
 * 
 * Réponse SUCCESS (200):
 * {
 *   "success": true,
 *   "message": "Paiement effectué avec succès",
 *   "transactionId": "CM2024011523456789",
 *   "data": { ... }
 * }
 * 
 * Réponse ERREUR (400):
 * {
 *   "success": false,
 *   "message": "Erreur lors du paiement",
 *   "error": "CODE OTP INVALIDE"
 * }
 */
router.post('/process-payment', verifyToken, async (req, res) => {
  try {
    // Extraction des paramètres du body de la requête
    const { codePays, telephone, montant, codeOTP, subscriptionId, description } = req.body;

    // VALIDATION 1 : Vérifier que tous les champs requis sont présents
    if (!codePays || !telephone || !montant || !codeOTP) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs sont requis (codePays, telephone, montant, codeOTP)'
      });
    }

    // VALIDATION 2 : Vérifier que le montant est valide (nombre positif)
    if (isNaN(montant) || parseFloat(montant) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Le montant doit être un nombre positif'
      });
    }

    // APPEL AU SERVICE CORISMONEY
    // Le service génère le hash SHA256 et appelle l'API CorisMoney pour le paiement
    const result = await corisMoneyService.paiementBien(
      codePays,
      telephone,
      parseFloat(montant),  // Convertir en nombre décimal
      codeOTP
    );

    if (result.success) {
      // ENREGISTREMENT EN BASE DE DONNÉES
      // Cela permet de tracer toutes les transactions et d'avoir un historique
      const insertQuery = `
        INSERT INTO payment_transactions (
          user_id,              -- ID de l'utilisateur qui paie
          subscription_id,      -- ID de la souscription liée (optionnel)
          transaction_id,       -- ID unique de la transaction CorisMoney
          code_pays,           -- Code du pays
          telephone,           -- Numéro de téléphone
          montant,             -- Montant payé
          statut,              -- Statut de la transaction (SUCCESS, FAILED, etc.)
          description,         -- Description du paiement
          created_at,          -- Date de création
          updated_at           -- Date de mise à jour
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
        RETURNING id
      `;

      const values = [
        req.user.id,                    // ID utilisateur du token JWT
        subscriptionId || null,         // ID souscription (peut être null)
        result.transactionId,           // ID unique de CorisMoney
        codePays,                       // Code pays
        telephone,                      // Téléphone
        parseFloat(montant),            // Montant
        'SUCCESS',                      // Statut (paiement réussi)
        description || 'Paiement CorisMoney'  // Description
      ];

      // Exécuter la requête d'insertion
      const insertResult = await pool.query(insertQuery, values);
      const paymentRecordId = insertResult.rows[0].id;

      // SI UNE SOUSCRIPTION EST LIÉE : Mettre à jour son statut
      if (subscriptionId) {
        await pool.query(
          `UPDATE subscriptions 
           SET statut = 'contrat', 
               updated_at = NOW() 
           WHERE id = $1`,
          [subscriptionId]
        );
      }

      // Retourner la réponse de succès avec l'ID de transaction
      return res.status(200).json({
        success: true,
        message: result.message,
        transactionId: result.transactionId,
        paymentRecordId: paymentRecordId,
        data: result.data
      });
    } else {
      // EN CAS D'ERREUR DE PAIEMENT : Enregistrer quand même en BDD avec statut FAILED
      const insertQuery = `
        INSERT INTO payment_transactions (
          user_id, subscription_id, code_pays, telephone, montant,
          statut, description, error_message, created_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
        RETURNING id
      `;

      const values = [
        req.user.id,
        subscriptionId || null,
        codePays,
        telephone,
        parseFloat(montant),
        'FAILED',  // Statut échec
        description || 'Paiement CorisMoney',
        JSON.stringify(result.error)  // Message d'erreur
      ];

      await pool.query(insertQuery, values);

      // Retourner l'erreur
      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error
      });
    }
  } catch (error) {
    // En cas d'erreur serveur (exception)
    console.error('Erreur lors du traitement du paiement:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors du traitement du paiement',
      error: error.message
    });
  }
});

/**
 * ========================================
 * ROUTE 3 : INFORMATIONS CLIENT CORISMONEY
 * ========================================
 * 
 * Récupère les informations d'un compte CorisMoney (nom, prénom, solde, etc.)
 * pour vérifier que le compte existe avant de demander un paiement.
 * 
 * @route   GET /api/payment/client-info
 * @access  Private (nécessite un token JWT)
 * 
 * Query parameters:
 * - codePays (ex: "225")
 * - telephone (ex: "0700000000")
 * 
 * URL exemple: /api/payment/client-info?codePays=225&telephone=0700000000
 * 
 * Réponse SUCCESS (200):
 * {
 *   "success": true,
 *   "data": {
 *     "nom": "FOFANA",
 *     "prenoms": "Chaka",
 *     "telephone": "0576093737",
 *     "numeroCompte": "0033000148306",
 *     "solde": 125000
 *   }
 * }
 */
router.get('/client-info', verifyToken, async (req, res) => {
  try {
    // Extraction des paramètres de la requête (query string)
    const { codePays, telephone } = req.query;

    // VALIDATION : Vérifier que tous les champs requis sont présents
    if (!codePays || !telephone) {
      return res.status(400).json({
        success: false,
        message: 'Le code pays et le numéro de téléphone sont requis'
      });
    }

    // APPEL AU SERVICE CORISMONEY
    const result = await corisMoneyService.getClientInfo(codePays, telephone);

    // Retourner la réponse
    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
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
 * ========================================
 * ROUTE 4 : STATUT D'UNE TRANSACTION
 * ========================================
 * 
 * Vérifie le statut d'une transaction CorisMoney en utilisant son ID unique.
 * Utile pour vérifier qu'un paiement a bien été traité.
 * 
 * @route   GET /api/payment/transaction-status/:transactionId
 * @access  Private (nécessite un token JWT)
 * 
 * URL exemple: /api/payment/transaction-status/CM2024011523456789
 * 
 * Réponse SUCCESS (200):
 * {
 *   "success": true,
 *   "data": {
 *     "transactionId": "CM2024011523456789",
 *     "statut": "SUCCESS",
 *     "montant": 50000,
 *     "dateHeure": "2024-01-15T14:23:45Z"
 *   }
 * }
 */
router.get('/transaction-status/:transactionId', verifyToken, async (req, res) => {
  try {
    // Extraction de l'ID de transaction depuis l'URL
    const { transactionId } = req.params;

    // VALIDATION : Vérifier que l'ID est présent
    if (!transactionId) {
      return res.status(400).json({
        success: false,
        message: 'L\'ID de transaction est requis'
      });
    }

    // APPEL AU SERVICE CORISMONEY
    const result = await corisMoneyService.getTransactionStatus(transactionId);

    // Retourner la réponse
    if (result.success) {
      return res.status(200).json({
        success: true,
        data: result.data
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
 * ========================================
 * ROUTE 5 : HISTORIQUE DES PAIEMENTS
 * ========================================
 * 
 * Récupère l'historique de tous les paiements CorisMoney d'un utilisateur.
 * Les paiements sont triés par date (plus récents en premier).
 * 
 * @route   GET /api/payment/history
 * @access  Private (nécessite un token JWT)
 * 
 * Query parameters (optionnels):
 * - limit (ex: 10) : Nombre maximum de résultats
 * - offset (ex: 0) : Décalage pour la pagination
 * 
 * URL exemple: /api/payment/history?limit=10&offset=0
 * 
 * Réponse SUCCESS (200):
 * {
 *   "success": true,
 *   "data": [
 *     {
 *       "id": 1,
 *       "transaction_id": "CM2024011523456789",
 *       "montant": 50000,
 *       "statut": "SUCCESS",
 *       "description": "Prime SÉRÉNITÉ",
 *       "created_at": "2024-01-15T14:23:45Z"
 *     },
 *     ...
 *   ],
 *   "total": 25
 * }
 */
router.get('/history', verifyToken, async (req, res) => {
  try {
    // Extraction des paramètres de pagination (optionnels)
    const limit = parseInt(req.query.limit) || 50;    // Par défaut: 50 résultats
    const offset = parseInt(req.query.offset) || 0;   // Par défaut: commence à 0

    // REQUÊTE SQL : Récupérer l'historique des paiements de l'utilisateur connecté
    const query = `
      SELECT 
        id,
        transaction_id,
        subscription_id,
        code_pays,
        telephone,
        montant,
        statut,
        description,
        error_message,
        created_at,
        updated_at
      FROM payment_transactions
      WHERE user_id = $1           -- Filtrer par utilisateur connecté
      ORDER BY created_at DESC     -- Trier par date (plus récents en premier)
      LIMIT $2                     -- Limiter le nombre de résultats
      OFFSET $3                    -- Décalage pour la pagination
    `;

    const result = await pool.query(query, [req.user.id, limit, offset]);

    // REQUÊTE SQL : Compter le nombre total de transactions
    const countQuery = `
      SELECT COUNT(*) as total
      FROM payment_transactions
      WHERE user_id = $1
    `;

    const countResult = await pool.query(countQuery, [req.user.id]);
    const total = parseInt(countResult.rows[0].total);

    // Retourner les résultats
    return res.status(200).json({
      success: true,
      data: result.rows,     // Liste des transactions
      total: total,          // Nombre total de transactions
      limit: limit,          // Limite de résultats
      offset: offset         // Décalage actuel
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

// Export du routeur pour utilisation dans server.js
module.exports = router;
