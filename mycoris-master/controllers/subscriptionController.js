/**
 * ===============================================
 * CONTRÔLEUR DES SOUSCRIPTIONS
 * ===============================================
 * 
 * Ce fichier gère toutes les opérations liées aux souscriptions :
 * - Création de souscription
 * - Mise à jour du statut
 * - Upload de documents
 * - Récupération des propositions
 * - Récupération des contrats
 * - Gestion des paiements
 */

const pool = require('../db');  // Connexion à la base de données PostgreSQL
const { generatePolicyNumber } = require('../utils/helpers');  // Génération numéro de police
const PDFDocument = require('pdfkit'); // Génération de PDF pour propositions

/**
 * ===============================================
 * CRÉER UNE NOUVELLE SOUSCRIPTION
 * ===============================================
 * 
 * Crée une nouvelle souscription dans la base de données.
 * Par défaut, le statut est "proposition" (en attente de paiement).
 * 
 * @route POST /subscriptions/create
 * @requires verifyToken - L'utilisateur doit être connecté
 * 
 * @param {object} req.body - Données de la souscription
 * @param {string} req.body.product_type - Type de produit (coris_serenite, coris_retraite, etc.)
 * @param {object} req.body...subscriptionData - Toutes les autres données (capital, prime, etc.)
 * 
 * @returns {object} La souscription créée avec son numéro de police
 * 
 * EXEMPLE DE DONNÉES :
 * {
 *   "product_type": "coris_serenite",
 *   "capital": 5000000,
 *   "prime": 250000,
 *   "duree": 10,
 *   "duree_type": "années",
 *   "periodicite": "annuel",
 *   "beneficiaire": {...},
 *   "contact_urgence": {...}
 * }
 */
exports.createSubscription = async (req, res) => {
  try {
    // Extraire le type de produit et le reste des données
    const {
      product_type,
      ...subscriptionData
    } = req.body;

    // Récupérer l'ID de l'utilisateur connecté (depuis le token JWT)
    const userId = req.user.id;
    
    // Générer un numéro de police unique pour cette souscription
    // Format: PROD-YYYY-XXXXX (ex: SER-2025-00123)
    const numeroPolice = await generatePolicyNumber(product_type);
    
    // Requête SQL pour insérer la nouvelle souscription
    // IMPORTANT : Le statut par défaut est "proposition" (pas encore payé)
    const query = `
      INSERT INTO subscriptions (user_id, numero_police, produit_nom, souscriptiondata)
      VALUES ($1, $2, $3, $4)
      RETURNING *;
    `;
    
    // Valeurs à insérer
    const values = [
      userId,             // $1 - ID de l'utilisateur
      numeroPolice,       // $2 - Numéro de police généré
      product_type,       // $3 - Type de produit
      subscriptionData    // $4 - Toutes les données (stockées en JSONB)
    ];
    
    // Exécuter la requête
    const result = await pool.query(query, values);
    
    // Retourner la souscription créée
    res.status(201).json({
      success: true,
      message: 'Souscription créée avec succès',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur création souscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la souscription'
    });
  }
};

/**
 * ===============================================
 * METTRE À JOUR LE STATUT D'UNE SOUSCRIPTION
 * ===============================================
 * 
 * Change le statut d'une souscription (proposition → contrat, etc.)
 * 
 * @route PUT /subscriptions/:id/status
 * @requires verifyToken
 * 
 * @param {number} req.params.id - ID de la souscription
 * @param {string} req.body.status - Nouveau statut ('proposition', 'contrat', 'annulé')
 * 
 * @returns {object} La souscription mise à jour
 */
exports.updateSubscriptionStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    // Requête SQL pour mettre à jour le statut
    // On met aussi à jour la date_validation si le contrat est activé
    const query = `
      UPDATE subscriptions 
      SET statut = $1, date_validation = CURRENT_TIMESTAMP
      WHERE id = $2 AND user_id = $3
      RETURNING *;
    `;
    
    const values = [status, id, req.user.id];
    const result = await pool.query(query, values);
    
    // Vérifier que la souscription existe et appartient à l'utilisateur
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    res.json({
      success: true,
      message: 'Statut mis à jour avec succès',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur mise à jour statut:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut'
    });
  }
};

/**
 * ===============================================
 * METTRE À JOUR LE STATUT DE PAIEMENT
 * ===============================================
 * 
 * Met à jour le statut d'une souscription après un paiement.
 * Si le paiement réussit → statut devient "contrat"
 * Si le paiement échoue → statut reste "proposition"
 * 
 * @route PUT /subscriptions/:id/payment-status
 * @requires verifyToken
 * 
 * @param {number} req.params.id - ID de la souscription
 * @param {boolean} req.body.payment_success - Succès du paiement (true/false)
 * @param {string} req.body.payment_method - Méthode de paiement (Wave, Orange Money, etc.)
 * @param {string} req.body.transaction_id - ID de la transaction
 * 
 * @returns {object} La souscription mise à jour
 * 
 * FLUX DE PAIEMENT :
 * 1. L'utilisateur choisit une méthode de paiement
 * 2. Le paiement est traité (Wave, Orange Money, etc.)
 * 3. Cette fonction est appelée avec le résultat
 * 4. Le statut est mis à jour en conséquence
 */
exports.updatePaymentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { payment_success, payment_method, transaction_id } = req.body;
    
    // Déterminer le nouveau statut en fonction du résultat du paiement
    const newStatus = payment_success ? 'contrat' : 'proposition';
    
    // Requête SQL pour mettre à jour le statut ET ajouter les infos de paiement
    const query = `
      UPDATE subscriptions 
      SET statut = $1, 
          souscriptiondata = jsonb_set(
            COALESCE(souscriptiondata, '{}'::jsonb),
            '{payment_info}',
            $2::jsonb
          ),
          date_validation = CASE WHEN $1 = 'contrat' THEN CURRENT_TIMESTAMP ELSE date_validation END
      WHERE id = $3 AND user_id = $4
      RETURNING *;
    `;
    
    // Créer un objet avec les informations de paiement
    const paymentInfo = JSON.stringify({
      payment_method: payment_method,      // Wave, Orange Money, etc.
      transaction_id: transaction_id,      // ID de la transaction
      payment_date: new Date().toISOString(),  // Date du paiement
      payment_success: payment_success     // Succès ou échec
    });
    
    const values = [newStatus, paymentInfo, id, req.user.id];
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    // Message différent selon le résultat du paiement
    res.json({
      success: true,
      message: payment_success 
        ? 'Paiement effectué avec succès, contrat activé' 
        : 'Paiement échoué, proposition conservée',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur mise à jour statut paiement:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du statut de paiement'
    });
  }
};

/**
 * ===============================================
 * UPLOADER UN DOCUMENT
 * ===============================================
 * 
 * Permet d'ajouter un document (pièce d'identité, etc.) à une souscription
 * 
 * @route POST /subscriptions/:id/upload-document
 * @requires verifyToken
 * @requires upload.single('document') - Middleware multer pour l'upload
 * 
 * @param {number} req.params.id - ID de la souscription
 * @param {file} req.file - Fichier uploadé (via multer)
 * 
 * @returns {object} La souscription mise à jour avec le chemin du document
 */
exports.uploadDocument = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Vérifier qu'un fichier a bien été uploadé
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier téléchargé'
      });
    }
    
    // Requête SQL pour ajouter le chemin du fichier dans souscriptiondata
    // On utilise jsonb_set pour ajouter une propriété dans le JSONB
    const query = `
      UPDATE subscriptions 
      SET souscriptiondata = jsonb_set(
        souscriptiondata, 
        '{piece_identite_path}', 
        $1
      )
      WHERE id = $2 AND user_id = $3
      RETURNING *;
    `;
    
    // Le chemin du fichier est stocké par multer dans req.file.path
    const values = [`"${req.file.path}"`, id, req.user.id];
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    res.json({
      success: true,
      message: 'Document téléchargé avec succès',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur upload document:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du téléchargement du document'
    });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER LES PROPOSITIONS DE L'UTILISATEUR
 * ===============================================
 * 
 * Retourne toutes les souscriptions avec statut "proposition"
 * (en attente de paiement) de l'utilisateur connecté
 * 
 * @route GET /subscriptions/user/propositions
 * @requires verifyToken
 * 
 * @returns {array} Liste des propositions triées par date (plus récent en premier)
 * 
 * UTILISÉ PAR : Page "Mes Propositions" dans l'app mobile
 */
exports.getUserPropositions = async (req, res) => {
  try {
    // Récupérer l'ID de l'utilisateur depuis le token JWT
    const userId = req.user.id;
    
    // Requête SQL pour récupérer uniquement les propositions
    const result = await pool.query(
      "SELECT * FROM subscriptions WHERE user_id = $1 AND statut = 'proposition' ORDER BY date_creation DESC",
      [userId]
    );
    
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error("Erreur getUserPropositions:", error);
    res.status(500).json({ success: false, message: "Erreur serveur" });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER LES CONTRATS DE L'UTILISATEUR
 * ===============================================
 * 
 * Retourne toutes les souscriptions avec statut "contrat"
 * (payées et activées) de l'utilisateur connecté
 * 
 * @route GET /subscriptions/user/contrats
 * @requires verifyToken
 * 
 * @returns {array} Liste des contrats triés par date (plus récent en premier)
 * 
 * UTILISÉ PAR : Page "Mes Contrats" dans l'app mobile
 */
exports.getUserContracts = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Requête SQL pour récupérer uniquement les contrats actifs
    const result = await pool.query(
      "SELECT * FROM subscriptions WHERE user_id = $1 AND statut = 'contrat' ORDER BY date_creation DESC",
      [userId]
    );
    
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error("Erreur getUserContracts:", error);
    res.status(500).json({ success: false, message: "Erreur serveur" });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER TOUTES LES SOUSCRIPTIONS
 * ===============================================
 * 
 * Retourne TOUTES les souscriptions de l'utilisateur
 * (propositions + contrats + annulés)
 * 
 * @route GET /subscriptions/user/all
 * @requires verifyToken
 * 
 * @returns {array} Liste de toutes les souscriptions
 */
exports.getUserSubscriptions = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Requête SQL pour récupérer TOUTES les souscriptions
    const result = await pool.query(
      "SELECT * FROM subscriptions WHERE user_id = $1 ORDER BY date_creation DESC",
      [userId]
    );
    
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error("Erreur getUserSubscriptions:", error);
    res.status(500).json({ success: false, message: "Erreur serveur" });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER UNE SOUSCRIPTION SIMPLE
 * ===============================================
 * 
 * Retourne les données d'une souscription spécifique
 * (sans les données utilisateur)
 * 
 * @route GET /subscriptions/detail/:id
 * @requires verifyToken
 * 
 * @param {number} req.params.id - ID de la souscription
 * @returns {object} Les données de la souscription
 */
exports.getSubscription = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    // Requête SQL pour récupérer la souscription
    // On vérifie aussi que la souscription appartient bien à l'utilisateur
    const result = await pool.query(
      "SELECT * FROM subscriptions WHERE id = $1 AND user_id = $2",
      [id, userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error("Erreur getSubscription:", error);
    res.status(500).json({ success: false, message: "Erreur serveur" });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER SOUSCRIPTION + DONNÉES UTILISATEUR
 * ===============================================
 * 
 * Retourne les données d'une souscription AVEC les informations
 * complètes de l'utilisateur (pour afficher le récapitulatif complet)
 * 
 * @route GET /subscriptions/:id
 * @requires verifyToken
 * 
 * @param {number} req.params.id - ID de la souscription
 * 
 * @returns {object} Objet contenant :
 *   - subscription : Les données de la souscription
 *   - user : Les informations complètes de l'utilisateur
 * 
 * UTILISÉ PAR : Page de détails d'une proposition (récapitulatif complet)
 * 
 * EXEMPLE DE RETOUR :
 * {
 *   "success": true,
 *   "data": {
 *     "subscription": {...},
 *     "user": {
 *       "id": 1,
 *       "nom": "Dupont",
 *       "prenom": "Jean",
 *       "email": "jean@example.com",
 *       "telephone": "+225...",
 *       "date_naissance": "1990-01-01",
 *       ...
 *     }
 *   }
 * }
 */
exports.getSubscriptionWithUserDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    
    // =========================================
    // ÉTAPE 1 : Récupérer la souscription
    // =========================================
    const subscriptionResult = await pool.query(
      "SELECT * FROM subscriptions WHERE id = $1 AND user_id = $2",
      [id, userId]
    );
    
    // Vérifier que la souscription existe
    if (subscriptionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    // =========================================
    // ÉTAPE 2 : Récupérer les infos utilisateur
    // =========================================
    // On récupère uniquement les champs nécessaires (sans le mot de passe !)
    const userResult = await pool.query(
      "SELECT id, civilite, nom, prenom, email, telephone, date_naissance, lieu_naissance, adresse FROM users WHERE id = $1",
      [userId]
    );
    
    // =========================================
    // ÉTAPE 3 : Formater les données utilisateur (comme dans /auth/profile)
    // =========================================
    const userData = userResult.rows[0] || null;
    if (userData && userData.date_naissance) {
      // Formater la date comme dans /auth/profile pour cohérence avec Flutter
      if (userData.date_naissance instanceof Date) {
        userData.date_naissance = userData.date_naissance.toISOString().split('T')[0];
      } else if (typeof userData.date_naissance === 'string') {
        // Si c'est déjà une string, s'assurer qu'elle est au format ISO
        try {
          const testDate = new Date(userData.date_naissance);
          if (!isNaN(testDate.getTime())) {
            userData.date_naissance = testDate.toISOString().split('T')[0];
          }
        } catch (e) {
          console.log('Erreur formatage date_naissance dans getSubscriptionWithUserDetails:', e);
        }
      }
    }
    
    // S'assurer que lieu_naissance est une string
    if (userData && userData.lieu_naissance && typeof userData.lieu_naissance !== 'string') {
      userData.lieu_naissance = String(userData.lieu_naissance);
    }
    
    // =========================================
    // ÉTAPE 4 : Retourner les deux ensembles de données
    // =========================================
    res.json({ 
      success: true, 
      data: {
        subscription: subscriptionResult.rows[0],  // Données de la souscription
        user: userData                              // Données de l'utilisateur formatées
      }
    });
  } catch (error) {
    console.error("Erreur getSubscriptionWithUserDetails:", error);
    res.status(500).json({ success: false, message: "Erreur serveur" });
  }
};

/**
 * ===============================================
 * ATTACHER UNE PROPOSITION À L'UTILISATEUR CONNECTÉ
 * ===============================================
 * @route POST /subscriptions/attach
 * Body: { numero_police?: string, id?: number }
 * Règles:
 *  - Trouve la souscription par numero_police ou id
 *  - Si user_id NULL → rattache au user courant
 *  - Si déjà rattachée à ce user → OK (idempotent)
 *  - Sinon → 409 (déjà rattachée à un autre utilisateur)
 */
exports.attachProposal = async (req, res) => {
  try {
    const { numero_police, id } = req.body || {};
    const userId = req.user.id;

    if (!numero_police && !id) {
      return res.status(400).json({ success: false, message: 'numero_police ou id requis' });
    }

    // Rechercher la souscription
    let query = 'SELECT * FROM subscriptions WHERE ' + (id ? 'id = $1' : 'numero_police = $1');
    const subResult = await pool.query(query, [id || numero_police]);
    if (subResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Proposition introuvable' });
    }
    const sub = subResult.rows[0];

    if (sub.user_id === userId) {
      return res.json({ success: true, message: 'Déjà rattachée à cet utilisateur', data: sub });
    }
    if (sub.user_id && sub.user_id !== userId) {
      return res.status(409).json({ success: false, message: 'Proposition déjà rattachée à un autre utilisateur' });
    }

    const upd = await pool.query(
      'UPDATE subscriptions SET user_id = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [userId, sub.id]
    );
    return res.json({ success: true, message: 'Proposition rattachée avec succès', data: upd.rows[0] });
  } catch (error) {
    console.error('Erreur attachProposal:', error);
    res.status(500).json({ success: false, message: 'Erreur lors du rattachement' });
  }
};

/**
 * ===============================================
 * GÉNÉRER LE PDF D'UNE SOUSCRIPTION/PROPOSITION
 * ===============================================
 * 
 * Génère un PDF téléchargeable contenant les informations clés
 * de la proposition/contrat. Le contenu est adapté selon le produit
 * en lisant les champs depuis la colonne JSONB `souscriptiondata`.
 * 
 * @route GET /subscriptions/:id/pdf
 * @requires verifyToken
 */
exports.getSubscriptionPDF = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Récupérer la souscription + utilisateur
    const subResult = await pool.query(
      "SELECT * FROM subscriptions WHERE id = $1 AND user_id = $2",
      [id, userId]
    );
    if (subResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Souscription non trouvée' });
    }
    const subscription = subResult.rows[0];

    // Récupérer les données utilisateur avec casting explicite pour les dates
    const userResult = await pool.query(
      `SELECT 
        id, 
        civilite, 
        nom, 
        prenom, 
        email, 
        telephone, 
        date_naissance::text as date_naissance,
        COALESCE(lieu_naissance, '')::text as lieu_naissance,
        adresse 
      FROM users 
      WHERE id = $1`,
      [userId]
    );
    const user = userResult.rows[0] || {};
    
    // Vérifier et convertir date_naissance si c'est un objet Date PostgreSQL
    // PostgreSQL peut retourner la date comme un objet Date JavaScript ou une string
    console.log('🔍 Avant conversion - date_naissance type:', typeof user.date_naissance, 'valeur:', user.date_naissance);
    console.log('🔍 Avant conversion - lieu_naissance type:', typeof user.lieu_naissance, 'valeur:', user.lieu_naissance);
    
    // Si date_naissance est une string vide ou null, essayer une autre requête
    if (!user.date_naissance || user.date_naissance === 'null' || user.date_naissance.trim() === '') {
      console.log('⚠️ date_naissance vide, tentative de récupération alternative...');
      const altResult = await pool.query(
        `SELECT date_naissance, lieu_naissance FROM users WHERE id = $1`,
        [userId]
      );
      if (altResult.rows[0]) {
        const altUser = altResult.rows[0];
        if (altUser.date_naissance) {
          user.date_naissance = altUser.date_naissance instanceof Date 
            ? altUser.date_naissance.toISOString().split('T')[0]
            : String(altUser.date_naissance);
          console.log('✅ date_naissance récupérée via requête alternative:', user.date_naissance);
        }
        if (altUser.lieu_naissance) {
          user.lieu_naissance = String(altUser.lieu_naissance);
          console.log('✅ lieu_naissance récupéré via requête alternative:', user.lieu_naissance);
        }
      }
    }
    
    if (user.date_naissance) {
      // Si c'est un objet Date (PostgreSQL peut retourner un objet Date directement)
      if (user.date_naissance instanceof Date) {
        console.log('✅ date_naissance est déjà un objet Date:', user.date_naissance);
        // Garder tel quel pour formatDate
      } else if (typeof user.date_naissance === 'object' && user.date_naissance !== null) {
        // Si c'est un objet Date PostgreSQL (souvent un objet avec des méthodes)
        try {
          const dateStr = user.date_naissance.toString();
          user.date_naissance = new Date(dateStr);
          console.log('✅ date_naissance converti depuis objet:', user.date_naissance);
        } catch (e) {
          console.log('❌ Erreur conversion date_naissance (objet):', e);
          user.date_naissance = null;
        }
      } else if (typeof user.date_naissance === 'string') {
        // Si c'est une string, s'assurer qu'elle est bien formatée
        try {
          const testDate = new Date(user.date_naissance);
          if (isNaN(testDate.getTime())) {
            console.log('❌ Date invalide (string):', user.date_naissance);
            user.date_naissance = null;
          } else {
            user.date_naissance = testDate;
            console.log('✅ date_naissance converti depuis string:', user.date_naissance);
          }
        } catch (e) {
          console.log('❌ Erreur conversion date_naissance (string):', e);
          user.date_naissance = null;
        }
      }
    } else {
      console.log('⚠️ date_naissance est null ou undefined');
    }
    
    // S'assurer que lieu_naissance est une string et n'est pas null/undefined
    if (user.lieu_naissance) {
      if (typeof user.lieu_naissance !== 'string') {
        user.lieu_naissance = String(user.lieu_naissance);
        console.log('✅ lieu_naissance converti en string:', user.lieu_naissance);
      }
    } else {
      console.log('⚠️ lieu_naissance est null, undefined ou vide');
      user.lieu_naissance = '';
    }
    
    // Debug: vérifier les données récupérées après conversion
    console.log('📋 User data for PDF (après conversion):', {
      id: user.id,
      nom: user.nom,
      prenom: user.prenom,
      date_naissance: user.date_naissance,
      date_naissance_type: typeof user.date_naissance,
      date_naissance_isDate: user.date_naissance instanceof Date,
      date_naissance_value: user.date_naissance instanceof Date ? user.date_naissance.toISOString() : user.date_naissance,
      lieu_naissance: user.lieu_naissance,
      lieu_naissance_type: typeof user.lieu_naissance,
      email: user.email
    });

    // Préparer le flux PDF - Marges réduites pour optimiser l'espace
    const doc = new PDFDocument({ size: 'A4', margin: 30 });
    const filename = `proposition_${subscription.numero_police || subscription.id}.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
    doc.pipe(res);

    // Helpers
    const fs = require('fs');
    const path = require('path');
    const exists = (p) => { try { return fs.existsSync(p); } catch { return false; } };
    const safe = (v) => (v === null || v === undefined ? '' : String(v));
    const money = (v) => {
      if (typeof v !== 'number') return safe(v);
      return `${Math.round(v).toLocaleString('fr-FR').replace(/\s/g, '.').replace(/,/g, '.')} FCFA`;
    };
    const productName = (subscription.produit_nom || '').toLowerCase();
    const TITLE = productName.includes('etude') ? 'CORIS ETUDE'
      : productName.includes('retraite') ? 'CORIS RETRAITE'
      : productName.includes('serenite') ? 'CORIS SERENITE'
      : productName.includes('emprunteur') ? 'FLEX EMPRUNTEUR'
      : productName.includes('familis') ? 'CORIS FAMILIS'
      : productName.includes('solidarite') ? 'CORIS SOLIDARITE'
      : productName.includes('epargne') ? 'CORIS EPARGNE BONUS'
      : (subscription.produit_nom || 'ASSURANCE VIE').toUpperCase();

    // Couleur bleue Coris - Gris normal pour les cases
    const bleuCoris = '#002B6B'; // Couleur principale (pour logo de secours)
    const grisNormal = '#A0A0A0'; // Gris normal pour les cases

    // Définir les constantes de positionnement - Optimisées pour une seule page
    const startX = 30;
    const fullW = 535; // Largeur maximale augmentée grâce aux marges réduites
    const boxH = 18; // Hauteur réduite pour les titres de sections
    let curY = 25; // Position initiale (légèrement réduite pour faire de la place)

    // Logo en haut à gauche - Positionné en premier, taille réduite à 115px
    const logoPaths = [
      path.join(process.cwd(), 'assets', 'logo1.png'),
      path.join(process.cwd(), 'assets', 'images', 'logo1.png'),
      path.join(process.cwd(), 'public', 'logo1.png'),
      path.join(process.cwd(), 'uploads', 'logo1.png'),
      path.join(__dirname, '..', 'assets', 'logo1.png'),
      path.join(__dirname, '..', 'assets', 'images', 'logo1.png'),
      path.join(__dirname, '..', 'public', 'logo1.png'),
    ];
    
    const logoSize = 115; // Logo réduit à 115px pour économiser l'espace
    const logoX = startX; // Positionné à gauche
    const logoY = curY; // Positionné en haut
    let logoAdded = false;
    
    for (const logoPath of logoPaths) {
      if (exists(logoPath)) {
        try {
          doc.image(logoPath, logoX, logoY, { width: logoSize });
          console.log('✅ Logo chargé depuis:', logoPath);
          logoAdded = true;
          break;
        } catch (e) {
          console.log('❌ Erreur chargement logo depuis', logoPath, ':', e.message);
        }
      }
    }
    
    if (!logoAdded) {
      console.log('⚠️ Aucun logo trouvé dans les emplacements suivants:', logoPaths);
      // Logo texte de secours en haut à gauche
      doc.rect(logoX, logoY, logoSize, 50)
        .fillAndStroke(bleuCoris, bleuCoris);
      doc.fontSize(14).fillColor('#FFFFFF').text('CORIS', logoX + 10, logoY + 10);
      doc.fontSize(10).fillColor('#FFFFFF').text('ASSURANCES', logoX + 10, logoY + 32);
    }

    // Titre principal - Positionné après le logo avec espacement
    doc.fontSize(14).fillColor('#000000').font('Helvetica-Bold');
    const titleY = logoY + logoSize + 8; // Positionné après le logo avec espacement
    // Le titre est centré sur toute la largeur
    doc.text(TITLE, startX, titleY, { width: fullW, align: 'center' });
    
    curY = titleY + 14; // Espacement après le titre

    // Case grise pour "CONDITIONS PARTICULIÈRES"
    doc.rect(startX, curY, fullW, boxH)
      .fillAndStroke(grisNormal, grisNormal);
    doc.fontSize(11).fillColor('#000000').font('Helvetica-Bold');
    doc.text('CONDITIONS PARTICULIÈRES', startX, curY + 5, { width: fullW, align: 'center' });
    
    curY += boxH + 6;

    // Small table helpers - Optimisés pour tenir sur une page
    doc.lineWidth(0.5);
    const rowH = 16; // Hauteur de ligne réduite
    const drawRow = (x, y, w, h, fillColor = null) => {
      if (fillColor) {
        // Utiliser le gris normal pour les cases
        doc.rect(x, y, w, h).fillAndStroke(grisNormal, grisNormal);
      } else {
        doc.rect(x, y, w, h).stroke();
      }
    };
    const write = (t, x, y, size = 9, color = '#000000', w = 250, bold = false) => {
      const text = safe(t);
      doc.font(bold ? 'Helvetica-Bold' : 'Helvetica')
        .fontSize(size)
        .fillColor(color);
      doc.text(text, x, y, { width: w, ellipsis: true, lineBreak: false });
    };
    const writeCentered = (t, x, y, w, size = 9, color = '#000000', bold = false) => {
      const text = safe(t);
      doc.font(bold ? 'Helvetica-Bold' : 'Helvetica')
        .fontSize(size)
        .fillColor(color);
      doc.text(text, x, y, { width: w, align: 'center', ellipsis: true, lineBreak: false });
    };

    // Formater les dates - amélioré pour gérer différents formats (y compris objets Date PostgreSQL)
    const formatDate = (dateInput) => {
      console.log('🔍 formatDate appelé avec:', dateInput, 'type:', typeof dateInput);
      if (!dateInput) {
        console.log('⚠️ formatDate: dateInput est null/undefined');
        return '';
      }
      try {
        let d;
        
        // Si c'est déjà un objet Date
        if (dateInput instanceof Date) {
          d = dateInput;
          console.log('✅ formatDate: Date détectée directement:', d);
        }
        // Si c'est une string ISO (avec ou sans 'T')
        else if (typeof dateInput === 'string') {
          if (dateInput.includes('T')) {
            d = new Date(dateInput);
            console.log('✅ formatDate: String ISO avec T:', d);
          } else if (dateInput.includes('/')) {
            // Format DD/MM/YYYY
            const parts = dateInput.split('/');
            if (parts.length === 3) {
              d = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]));
              console.log('✅ formatDate: String DD/MM/YYYY:', d);
            } else {
              console.log('⚠️ formatDate: Format DD/MM/YYYY invalide:', dateInput);
              return dateInput;
            }
          } else if (dateInput.includes('-')) {
            // Format YYYY-MM-DD
            d = new Date(dateInput);
            console.log('✅ formatDate: String YYYY-MM-DD:', d);
          } else {
            console.log('⚠️ formatDate: Format string non reconnu:', dateInput);
            return dateInput;
          }
        }
        // Si c'est un timestamp (nombre)
        else if (typeof dateInput === 'number') {
          d = new Date(dateInput);
          console.log('✅ formatDate: Timestamp:', d);
        }
        // Si c'est un objet (peut être un objet Date PostgreSQL)
        else if (typeof dateInput === 'object' && dateInput !== null) {
          // Essayer de convertir en string puis en Date
          try {
            const dateStr = dateInput.toString();
            d = new Date(dateStr);
            console.log('✅ formatDate: Objet converti:', d);
          } catch (e) {
            console.log('❌ formatDate: Erreur conversion objet:', e);
            return '';
          }
        }
        // Sinon, essayer de convertir directement
        else {
          d = new Date(dateInput);
          console.log('✅ formatDate: Conversion directe:', d);
        }
        
        // Vérifier que la date est valide
        if (!d || isNaN(d.getTime())) {
          console.log('❌ formatDate: Date invalide après conversion:', dateInput, '->', d);
          return '';
        }
        
        const formatted = `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
        console.log('✅ formatDate: Date formatée:', formatted);
        return formatted;
      } catch (e) {
        console.log('❌ formatDate: Erreur générale:', e, 'Input:', dateInput);
        return '';
      }
    };

    // Section N° Assuré et N° Police sur la même ligne pour réduire l'espace
    const infoBoxH = rowH * 1.2;
    drawRow(startX, curY, fullW, infoBoxH);
    
    // N° Assuré et N° Police sur la même ligne
    write('N° Assuré', startX + 5, curY + 5, 9, '#666', 80);
    write(`: ${String(user.id || subscription.id || '')}`, startX + 85, curY + 5, 9, '#000', 150, true);
    
    write('N° Police', startX + 250, curY + 5, 9, '#666', 80);
    write(`: ${subscription.numero_police || ''}`, startX + 330, curY + 5, 9, '#000', 200, true);
    
    curY += infoBoxH + 6;

    // Souscripteur - Case grise
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('Souscripteur', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH + 5;
    
    const d = subscription.souscriptiondata || {};
    const contactUrgence = d.contact_urgence || {};
    const usr = user || {};
    
    // Informations souscripteur - Optimisées pour tenir sur une page
    drawRow(startX, curY, fullW, rowH * 4.2);
    
    // Ligne 1: Nom et Prénom / Téléphone
    write('Nom et Prénom', startX + 5, curY + 3, 9, '#666', 120);
    write(`${safe(usr.nom)} ${safe(usr.prenom)}`, startX + 130, curY + 3, 9, '#000', 200);
    write('Téléphone', startX + 340, curY + 3, 9, '#666', 70);
    write(usr.telephone || '', startX + 415, curY + 3, 9, '#000', 115);
    
    // Ligne 2: Email
    write('Email', startX + 5, curY + 3 + 13, 9, '#666', 120);
    write(usr.email || '', startX + 130, curY + 3 + 13, 9, '#000', 400);
    
    // Ligne 3: Date de naissance / Lieu de naissance
    write('Date de naissance', startX + 5, curY + 3 + 26, 9, '#666', 120);
    const dateNaissanceFormatee = formatDate(usr.date_naissance);
    write(dateNaissanceFormatee || 'Non renseigné', startX + 130, curY + 3 + 26, 9, '#000', 180);
    write('Lieu de naissance', startX + 320, curY + 3 + 26, 9, '#666', 120);
    write(usr.lieu_naissance || 'Non renseigné', startX + 445, curY + 3 + 26, 9, '#000', 90);
    
    // Ligne 4: Adresse
    write('Adresse', startX + 5, curY + 3 + 39, 9, '#666', 120);
    write(usr.adresse || '', startX + 130, curY + 3 + 39, 9, '#000', 400);
    
    // Ligne 5: Contact d'urgence
    write('En cas d\'urgence', startX + 5, curY + 3 + 52, 9, '#666', 120);
    const contactUrgenceText = contactUrgence.nom ? `${contactUrgence.nom} - ${contactUrgence.contact || ''}` : 'Non renseigné';
    write(contactUrgenceText, startX + 130, curY + 3 + 52, 9, '#000', 400);
    
    curY += rowH * 4.2 + 5;

    // Période de garantie - Case grise
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('PÉRIODE DE GARANTIE', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH + 5;
    
    // d est déjà défini plus haut dans la section Souscripteur
    const dateEffet = d.date_effet || d.date_debut || d.date_debut_garantie || '';
    const dateEcheance = d.date_echeance || d.date_fin || d.date_echeance_contrat || d.date_fin_garantie || '';
    const duree = d.duree || d.duree_contrat || '';
    const dureeType = d.duree_type || d.type_duree || 'mois';
    const periodicite = d.periodicite || d.mode_souscription || d.mode_paiement || '';

    // Calculer la durée en mois si nécessaire
    let dureeMois = duree;
    let dureeAffichee = '';
    if (duree) {
      if (dureeType === 'ans' || dureeType === 'Années' || dureeType === 'années' || dureeType === 'an') {
        dureeMois = parseInt(duree) * 12;
        dureeAffichee = `${dureeMois} Mois`;
      } else if (dureeType === 'mois' || dureeType === 'Mois' || dureeType === 'mois') {
        dureeMois = parseInt(duree);
        dureeAffichee = `${dureeMois} Mois`;
      } else {
        // Si on a une durée mais pas de type, essayer de deviner
        const dureeNum = parseInt(duree);
        if (dureeNum > 0 && dureeNum < 100) {
          dureeMois = dureeNum;
          dureeAffichee = `${dureeMois} Mois`;
        } else {
          dureeAffichee = duree;
        }
      }
    } else {
      dureeAffichee = 'Non renseigné';
    }
    
    // Formater la périodicité
    let periodiciteFormatee = '';
    if (periodicite) {
      const perLower = periodicite.toLowerCase();
      if (perLower.includes('mensuel')) periodiciteFormatee = 'Mensuel';
      else if (perLower.includes('trimestriel')) periodiciteFormatee = 'Trimestriel';
      else if (perLower.includes('semestriel')) periodiciteFormatee = 'Semestriel';
      else if (perLower.includes('annuel')) periodiciteFormatee = 'Annuel';
      else periodiciteFormatee = periodicite.toUpperCase();
    } else {
      periodiciteFormatee = 'Non renseigné';
    }

    // Afficher les informations disponibles, avec "Non renseigné" pour ce qui manque
    drawRow(startX, curY, fullW, rowH);
    write('Du', startX + 5, curY + 4, 9, '#666', 20);
    write(formatDate(dateEffet) || 'Non renseigné', startX + 30, curY + 4, 9, '#000', 90);
    write('Au', startX + 130, curY + 4, 9, '#666', 20);
    write(formatDate(dateEcheance) || 'Non renseigné', startX + 155, curY + 4, 9, '#000', 90);
    write('Durée', startX + 255, curY + 4, 9, '#666', 35);
    write(dureeAffichee, startX + 295, curY + 4, 9, '#000', 60, true);
    write('Périodicité', startX + 365, curY + 4, 9, '#666', 60);
    write(periodiciteFormatee, startX + 430, curY + 4, 9, '#000', 105);
    curY += rowH + 5;

    // Assuré(e) - Case grise
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('Assuré(e)', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH + 5;
    
    drawRow(startX, curY, fullW, rowH * 1.8);
    write('Nom et Prénom', startX + 5, curY + 3, 9, '#666', 100);
    write(`${safe(usr.nom)} ${safe(usr.prenom)}`, startX + 115, curY + 3, 9, '#000', 200);
    write('Informations pers.', startX + 5, curY + 3 + 13, 9, '#666', 100);
    const dateNaissanceAssure = formatDate(usr.date_naissance);
    const lieuNaissanceAssure = usr.lieu_naissance || '';
    const sexe = usr.civilite === 'M.' || usr.civilite === 'Monsieur' ? 'M' : (usr.civilite === 'Mme' || usr.civilite === 'Madame' ? 'F' : '');
    const infoPers = `Né(e) le : ${dateNaissanceAssure || 'Non renseigné'} à : ${lieuNaissanceAssure || 'Non renseigné'} - sexe : ${sexe || 'Non renseigné'}`;
    write(infoPers, startX + 115, curY + 3 + 13, 9, '#000', 420);
    curY += rowH * 1.8 + 5;

    // Bénéficiaires - Case grise avec tableau
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('Bénéficiaires', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH;
    
    // En-têtes du tableau (en gras) - Colonnes optimisées
    const benefColW = [155, 75, 65, 55, 185]; // Bénéficiaires, Parenté, Né le, Part(%), Coordonnées
    const benefStartX = startX;
    let benefCurX = benefStartX;
    
    drawRow(startX, curY, fullW, rowH, grisNormal);
    write('Bénéficiaires', benefCurX + 4, curY + 4, 9, '#000000', benefColW[0] - 8, true);
    benefCurX += benefColW[0];
    write('Parenté', benefCurX + 4, curY + 4, 9, '#000000', benefColW[1] - 8, true);
    benefCurX += benefColW[1];
    write('Né le', benefCurX + 4, curY + 4, 9, '#000000', benefColW[2] - 8, true);
    benefCurX += benefColW[2];
    write('Part(%)', benefCurX + 4, curY + 4, 9, '#000000', benefColW[3] - 8, true);
    benefCurX += benefColW[3];
    write('Coordonnées', benefCurX + 4, curY + 4, 9, '#000000', benefColW[4] - 8, true);
    curY += rowH;
    
    // Récupérer les bénéficiaires selon le type de produit
    const isSolidarite = productName.includes('solidarite');
    let beneficiairesList = [];
    
    if (isSolidarite) {
      // Pour CORIS SOLIDARITÉ, combiner tous les membres (souscripteur, conjoints, enfants, ascendants) comme bénéficiaires
      const conjoints = Array.isArray(d.conjoints) ? d.conjoints : [];
      const enfants = Array.isArray(d.enfants) ? d.enfants : [];
      const ascendants = Array.isArray(d.ascendants) ? d.ascendants : [];
      
      // Souscripteur (en cas de vie)
      beneficiairesList.push({
        nom: `${safe(usr.nom)} ${safe(usr.prenom)} (en cas de vie)`,
        parente: 'Souscripteur',
        date_naissance: usr.date_naissance,
        part: '100%',
        coordonnees: usr.telephone || usr.email || ''
      });
      
      // Bénéficiaire en cas de décès
      const b = d.beneficiaire || {};
      if (b.nom) {
        beneficiairesList.push({
          nom: `${b.nom} (en cas de Décès)`,
          parente: b.lien_parente || 'Ayants Droit',
          date_naissance: b.date_naissance || b.dateNaissance,
          part: '',
          coordonnees: b.contact || ''
        });
      }
      
      // Ajouter conjoints, enfants, ascendants si nécessaire
      conjoints.forEach(c => {
        beneficiairesList.push({
          nom: c.nom_prenom || c.nom || 'Conjoint',
          parente: 'Conjoint',
          date_naissance: c.date_naissance || c.dateNaissance,
          part: '',
          coordonnees: ''
        });
      });
      
      enfants.forEach(e => {
        beneficiairesList.push({
          nom: e.nom_prenom || e.nom || 'Enfant',
          parente: 'Enfant',
          date_naissance: e.date_naissance || e.dateNaissance,
          part: '',
          coordonnees: ''
        });
      });
      
      ascendants.forEach(a => {
        beneficiairesList.push({
          nom: a.nom_prenom || a.nom || 'Ascendant',
          parente: 'Ascendant',
          date_naissance: a.date_naissance || a.dateNaissance,
          part: '',
          coordonnees: ''
        });
      });
    } else {
      // Pour les autres produits, utiliser le bénéficiaire standard
      const b = d.beneficiaire || {};
      if (b.nom) {
        beneficiairesList.push({
          nom: `${b.nom} (en cas de Décès)`,
          parente: b.lien_parente || 'Ayants Droit',
          date_naissance: b.date_naissance || b.dateNaissance,
          part: '',
          coordonnees: b.contact || ''
        });
      }
      
      // Ajouter le souscripteur (en cas de vie)
      beneficiairesList.push({
        nom: `${safe(usr.nom)} ${safe(usr.prenom)} (en cas de vie)`,
        parente: 'Souscripteur',
        date_naissance: usr.date_naissance,
        part: '100%',
        coordonnees: usr.telephone || usr.email || ''
      });
    }
    
    // Afficher les bénéficiaires (données rapprochées) - Maximum 3 bénéficiaires pour économiser l'espace
    const maxBeneficiaires = Math.min(beneficiairesList.length, 3);
    for (let idx = 0; idx < maxBeneficiaires; idx++) {
      const benef = beneficiairesList[idx];
      drawRow(startX, curY, fullW, rowH);
      benefCurX = benefStartX;
      write(benef.nom || '', benefCurX + 4, curY + 4, 8, '#000', benefColW[0] - 8);
      benefCurX += benefColW[0];
      write(benef.parente || '', benefCurX + 4, curY + 4, 8, '#000', benefColW[1] - 8);
      benefCurX += benefColW[1];
      write(formatDate(benef.date_naissance || ''), benefCurX + 4, curY + 4, 8, '#000', benefColW[2] - 8);
      benefCurX += benefColW[2];
      write(benef.part || '', benefCurX + 4, curY + 4, 8, '#000', benefColW[3] - 8);
      benefCurX += benefColW[3];
      write(benef.coordonnees || '', benefCurX + 4, curY + 4, 8, '#000', benefColW[4] - 8);
      curY += rowH;
    }
    
    curY += 5;

    // Caractéristiques - Case grise
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('Caractéristiques', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH + 5;
    
    const hasRente = productName.includes('etude') || productName.includes('retraite') || productName.includes('serenite');
    const hasCapital = productName.includes('solidarite') || productName.includes('familis') || productName.includes('emprunteur');
    
    // Optimiser : 2 lignes au lieu de plusieurs
    drawRow(startX, curY, fullW, rowH * 2);
    
    // Ligne 1: Cotisation Mensuelle / Taux d'intérêt Net
    write('Cotisation Mensuelle', startX + 5, curY + 3, 9, '#666', 130);
    write(money(d.prime || d.prime_mensuelle || d.prime_annuelle || 0), startX + 145, curY + 3, 9, '#000', 150);
    write("Taux d'intérêt Net", startX + 305, curY + 3, 9, '#666', 100);
    write('3,500%', startX + 410, curY + 3, 9, '#000', 125);
    
    // Ligne 2: Rente ou Capital (selon le produit)
    if (hasRente && d.rente_calculee) {
      write('Valeur de la Rente', startX + 5, curY + 3 + 13, 9, '#666', 130);
      write(money(d.rente_calculee || 0), startX + 145, curY + 3 + 13, 9, '#000', 150);
    } else if (hasCapital && (d.capital || d.capital_garanti)) {
      write('Valeur du Capital', startX + 5, curY + 3 + 13, 9, '#666', 130);
      write(money(d.capital || d.capital_garanti || 0), startX + 145, curY + 3 + 13, 9, '#000', 150);
    }
    
    curY += rowH * 2 + 5;

    // Garanties - Case grise avec en-têtes
    drawRow(startX, curY, fullW, boxH, grisNormal);
    write('Garanties', startX + 5, curY + 4, 9, '#000000', 180, true);
    writeCentered('Capital (FCFA)', startX + 200, curY + 4, 165, 9, '#000000', true);
    writeCentered('Primes Période (FCFA)', startX + 365, curY + 4, 170, 9, '#000000', true);
    curY += boxH;
    
    drawRow(startX, curY, fullW, rowH);
    write('Décès ou Invalidité Permanente Totale', startX + 5, curY + 4, 9, '#000', 185);
    writeCentered(money(d.capital || d.capital_garanti || 0), startX + 200, curY + 4, 165, 9);
    writeCentered(money(d.prime || d.prime_mensuelle || d.prime_annuelle || 0), startX + 365, curY + 4, 170, 9);
    curY += rowH;
    
    // Ligne "En Cas de Vie à Terme" si applicable
    if (hasRente || d.capital_garanti || d.capital) {
      drawRow(startX, curY, fullW, rowH);
      write('En Cas de Vie à Terme', startX + 5, curY + 4, 9, '#000', 185);
      writeCentered(money(d.capital_garanti || d.capital || 0), startX + 200, curY + 4, 165, 9);
      writeCentered('', startX + 365, curY + 4, 170, 9);
      curY += rowH;
    }
    
    curY += 5;

    // Décompte Prime - Case grise
    const decompteNum = safe(d.decompte_prime_num || `101${String(subscription.id).padStart(7,'0')}`);
    const decompteText = `Decompte Prime N° ${decompteNum}`;
    
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered(decompteText, startX, curY + 4, fullW, 9, '#000000', true);
    curY += boxH + 5;
    
    // Prime Nette, Accessoires, Prime Totale - Tableau horizontal compact
    const primeBoxW = Math.floor(fullW / 3);
    
    // En-têtes et valeurs dans la même ligne pour économiser l'espace
    drawRow(startX, curY, primeBoxW, rowH * 1.5);
    writeCentered('Prime Nette', startX, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(d.prime || d.prime_mensuelle || d.prime_annuelle || 0), startX, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    drawRow(startX + primeBoxW, curY, primeBoxW, rowH * 1.5);
    writeCentered('Accessoires', startX + primeBoxW, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(d.accessoires || 0), startX + primeBoxW, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    drawRow(startX + primeBoxW * 2, curY, primeBoxW, rowH * 1.5);
    writeCentered('Prime Totale', startX + primeBoxW * 2, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(d.prime_totale || d.prime || d.prime_mensuelle || d.prime_annuelle || 0), startX + primeBoxW * 2, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    curY += rowH * 1.5 + 6;

    // Vérifier si on peut tout mettre sur une page - Si non, réduire encore plus
    // Hauteur disponible: 842px (A4) - 30px (marge haut) - 30px (marge bas) = 782px
    const spaceNeeded = 110; // Espace nécessaire pour le bas (réduit)
    if (curY + spaceNeeded > 782) {
      console.log('⚠️ Attention: curY =', curY, 'spaceNeeded =', spaceNeeded, 'Total =', curY + spaceNeeded, '> 782px');
      // Réduire encore plus les espacements si nécessaire
      curY -= 10; // Réduire un peu l'espace précédent
    }

    // Mention légale - Descendue pour ne pas se mélanger avec les cases d'en haut
    doc.fontSize(8).fillColor('#000000').font('Helvetica');
    const mentionLegale = 'Sont annexées aux présentes conditions particulières, les conditions générales et éventuellement les conventions spéciales qui font partie du contrat.';
    curY += 8; // Espacement supplémentaire pour séparer des cases d'en haut
    doc.text(mentionLegale, startX, curY, { width: fullW, lineGap: 2, align: 'left' });
    curY += 12; // Espacement pour séparer de "Fait à Abidjan"

    // Date et lieu (Contrat saisi par supprimé comme demandé) - Séparé de la mention légale
    const dateContrat = new Date().toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
    doc.fontSize(8).fillColor('#000000').text(`Fait à Abidjan, le ${dateContrat} en 2 Exemplaires`, startX, curY, { width: fullW, align: 'left' });
    curY += 10;

    // Espaces pour signatures (2 colonnes: Souscripteur et Compagnie) - Réduits
    const sigWidth = 220;
    const sigGap = 30;
    const sigStartX = startX;
    const sigHeight = 30; // Hauteur réduite
    
    // Labels au-dessus des cases de signature
    doc.fontSize(7).fillColor('#000000').text('Le Souscripteur', sigStartX, curY, { width: sigWidth, align: 'center' });
    doc.fontSize(7).fillColor('#000000').text('La Compagnie', sigStartX + sigWidth + sigGap, curY, { width: sigWidth, align: 'center' });
    curY += 10; // Espacement entre les labels et les cases
    
    const sigY = curY; // Position des cases de signature

    // Dessiner les cases pour signatures
    drawRow(sigStartX, sigY, sigWidth, sigHeight);
    drawRow(sigStartX + sigWidth + sigGap, sigY, sigWidth, sigHeight);

    // Tampon de la compagnie (si disponible) - Plus petit
    const stampPaths = [
      path.join(process.cwd(), 'assets', 'stamp_coris.png'),
      path.join(process.cwd(), 'assets', 'images', 'stamp_coris.png'),
      path.join(__dirname, '..', 'assets', 'stamp_coris.png'),
    ];
    for (const stampPath of stampPaths) {
      if (exists(stampPath)) {
        try {
          doc.image(stampPath, sigStartX + sigWidth + sigGap + 65, sigY + 3, { width: 50 });
          console.log('✅ Tampon chargé depuis:', stampPath);
          break;
        } catch (e) {
          console.log('❌ Erreur chargement tampon depuis', stampPath, ':', e.message);
        }
      }
    }

    curY = sigY + sigHeight + 8;

    // Trait noir en bas (épaisseur 1 pour visibilité)
    doc.lineWidth(1).moveTo(startX, curY).lineTo(startX + fullW, curY).stroke('#000000');
    curY += 5;

    // Informations de l'entreprise en bas de page - Centré, taille réduite pour tenir sur une page
    doc.fontSize(6).fillColor('#000000').font('Helvetica');
    const footerText = "CORIS ASSURANCES VIE COTE D'IVOIRE-SA - régie par le code CIMA au capital social de 5.000.000.000 FCFA entièrement libéré. RCM: CI-ABJ-03-2824-B14-00013, NCC: 2400326 R, Compte: Cl166- 01001- 008904724101- 72, Plateau Bd de la République, Rue n°23 Angle Avenue Marchand, IMM CBI, 01BP4690 ABIDJAN - Tél: +225 27 20 15 65 - Email : corisvie-ci@coris-assurances.com";
    
    // Afficher le footer centré avec espacement minimal
    doc.text(footerText, startX, curY, { 
      width: fullW, 
      align: 'center', // Centré
      lineGap: 1 
    });
    
    // Calculer la hauteur utilisée par le texte
    const textHeight = doc.heightOfString(footerText, { width: fullW, align: 'center', lineGap: 1 });
    curY += textHeight;
    console.log('✅ Footer ajouté à curY =', curY, 'Total utilisé:', curY, '/ 782px disponibles');

    doc.end();
  } catch (error) {
    console.error('Erreur génération PDF:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la génération du PDF' });
  }
};
