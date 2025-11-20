/**
 * ===============================================
 * CONTRÔLEUR DES SOUSCRIPTIONS
 * ===============================================
 * 
 * Ce fichier gère toutes les opérations liées aux souscriptions :
 * - Création de souscription (pour clients et commerciaux)
 * - Mise à jour du statut (proposition → contrat)
 * - Upload de documents (pièce d'identité, etc.)
 * - Récupération des propositions (en attente de paiement)
 * - Récupération des contrats (payés et activés)
 * - Gestion des paiements (Wave, Orange Money)
 * - Génération de PDF pour propositions/contrats
 * 
 * ARCHITECTURE :
 * - Utilise PostgreSQL pour le stockage des données
 * - Stocke les données flexibles dans une colonne JSONB (souscriptiondata)
 * - Gère deux workflows : client direct et commercial pour client
 * - Pour les commerciaux : stocke les infos client dans souscriptiondata.client_info
 * - Pour les clients : utilise directement user_id de la table users
 * 
 * SÉCURITÉ :
 * - Toutes les routes nécessitent une authentification JWT (verifyToken middleware)
 * - Vérification des permissions selon le rôle (commercial vs client)
 * - Validation des données avant insertion en base
 */

// ============================================
// IMPORTS ET DÉPENDANCES
// ============================================
const pool = require('../db');  // Pool de connexions PostgreSQL (gestion automatique des connexions)
const { generatePolicyNumber } = require('../utils/helpers');  // Fonction utilitaire pour générer un numéro de police unique (format: PROD-YYYY-XXXXX)
const PDFDocument = require('pdfkit'); // Bibliothèque pour générer des PDF dynamiques (utilisée pour les propositions/contrats)

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
      client_id, // ID du client (optionnel, pour les commerciaux - DEPRECATED: ne plus utiliser)
      client_info, // Informations du client (nom, prénom, date_naissance, etc.) - pour les commerciaux
      ...subscriptionData
    } = req.body;

    // Récupérer l'ID de l'utilisateur connecté (depuis le token JWT)
    const currentUserId = req.user.id;
    const userRole = req.user.role;
    const codeApporteur = req.user.code_apporteur;
    
    let userId = currentUserId;
    let finalCodeApporteur = null;
    
    // NOUVEAU WORKFLOW: Si c'est un commercial qui crée une souscription pour un client
    if (userRole === 'commercial') {
      // Le commercial enregistre son code_apporteur
      finalCodeApporteur = codeApporteur;
      
      // Si des informations client sont fournies, les ajouter dans souscription_data
      if (client_info) {
        subscriptionData.client_info = {
          nom: client_info.nom,
          prenom: client_info.prenom,
          date_naissance: client_info.date_naissance,
          lieu_naissance: client_info.lieu_naissance,
          telephone: client_info.telephone,
          email: client_info.email,
          adresse: client_info.adresse,
          civilite: client_info.civilite || client_info.genre,
          numero_piece_identite: client_info.numero_piece_identite || client_info.numero
        };
      }
      
      // Si un client_id est fourni (ancien workflow), on l'utilise mais on enregistre aussi le code_apporteur
      if (client_id) {
        // Vérifier que le client appartient au commercial
        const clientCheckQuery = `
          SELECT id FROM users 
          WHERE id = $1 AND code_apporteur = $2 AND role = 'client'
        `;
        const clientCheckResult = await pool.query(clientCheckQuery, [client_id, codeApporteur]);
        
        if (clientCheckResult.rows.length > 0) {
          userId = client_id;
        }
        // Si le client n'existe pas, on laisse userId = currentUserId (commercial)
        // et on enregistre les infos client dans souscription_data
      }
      // Si pas de client_id, userId reste celui du commercial
      // Les infos client sont dans souscription_data.client_info
    }
    
    // Générer un numéro de police unique pour cette souscription
    // Format: PROD-YYYY-XXXXX (ex: SER-2025-00123)
    const numeroPolice = await generatePolicyNumber(product_type);
    
    // Requête SQL pour insérer la nouvelle souscription
    // IMPORTANT : Le statut par défaut est "proposition" (pas encore payé)
    const query = `
      INSERT INTO subscriptions (user_id, numero_police, produit_nom, souscriptiondata, code_apporteur)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    
    // Valeurs à insérer
    const values = [
      userId,             // $1 - ID de l'utilisateur (client ou commercial)
      numeroPolice,       // $2 - Numéro de police généré
      product_type,       // $3 - Type de produit
      subscriptionData,  // $4 - Toutes les données (stockées en JSONB)
      finalCodeApporteur  // $5 - Code apporteur du commercial (si commercial)
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
 * METTRE À JOUR UNE SOUSCRIPTION (PROPOSITION)
 * ===============================================
 * 
 * Permet de modifier les données d'une proposition existante.
 * Utilisé quand un client clique sur "Modifier" depuis la page de détails.
 * 
 * @route PUT /subscriptions/:id/update
 * @requires verifyToken
 * 
 * @param {number} req.params.id - ID de la souscription à modifier
 * @param {object} req.body - Nouvelles données de la souscription
 * 
 * @returns {object} La souscription mise à jour
 */
exports.updateSubscription = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      product_type,
      client_info,
      ...subscriptionData
    } = req.body;

    // Récupérer l'ID de l'utilisateur connecté
    const currentUserId = req.user.id;
    const userRole = req.user.role;

    // Si c'est un commercial et qu'il y a des infos client, les ajouter
    if (userRole === 'commercial' && client_info) {
      subscriptionData.client_info = {
        nom: client_info.nom,
        prenom: client_info.prenom,
        date_naissance: client_info.date_naissance,
        lieu_naissance: client_info.lieu_naissance,
        telephone: client_info.telephone,
        email: client_info.email,
        adresse: client_info.adresse,
        civilite: client_info.civilite || client_info.genre,
        numero_piece_identite: client_info.numero_piece_identite || client_info.numero
      };
    }

    // Requête SQL pour mettre à jour la souscription
    const query = `
      UPDATE subscriptions 
      SET produit_nom = $1, souscriptiondata = $2
      WHERE id = $3 AND user_id = $4
      RETURNING *;
    `;

    const values = [
      product_type || null,
      subscriptionData,
      id,
      currentUserId
    ];

    const result = await pool.query(query, values);

    // Vérifier que la souscription existe et appartient à l'utilisateur
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée ou vous n\'avez pas les droits pour la modifier'
      });
    }

    res.json({
      success: true,
      message: 'Souscription mise à jour avec succès',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur mise à jour souscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour de la souscription'
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
    
    console.log('=== UPLOAD DOCUMENT ===');
    console.log('📄 Souscription ID:', id);
    console.log('👤 User ID:', req.user.id);
    console.log('📁 Nom fichier:', req.file.filename);
    console.log('📂 Chemin complet:', req.file.path);
    console.log('📊 Taille:', (req.file.size / 1024).toFixed(2), 'KB');
    console.log('📝 Type MIME:', req.file.mimetype);
    
    // Vérifier que le fichier existe bien sur le disque
    if (!fs.existsSync(req.file.path)) {
      console.error('❌ ERREUR: Le fichier n\'a pas été créé sur le disque!');
      return res.status(500).json({
        success: false,
        message: 'Erreur: le fichier n\'a pas été sauvegardé'
      });
    }
    console.log('✅ Fichier exist sur le disque');
    
    // Construire l'URL complète du document
    const fileName = req.file.filename;
    const documentUrl = `/uploads/identity-cards/${fileName}`;
    console.log('🔗 URL du document:', documentUrl);
    
    // Récupérer l'ancien document pour le supprimer
    const oldDocQuery = `
      SELECT souscriptiondata->>'piece_identite' as old_doc,
             souscriptiondata->>'piece_identite_url' as old_url
      FROM subscriptions 
      WHERE id = $1 AND user_id = $2
    `;
    const oldDocResult = await pool.query(oldDocQuery, [id, req.user.id]);
    
    // Supprimer l'ancien fichier s'il existe
    if (oldDocResult.rows.length > 0 && oldDocResult.rows[0].old_doc) {
      const oldFileName = oldDocResult.rows[0].old_doc;
      const oldFilePath = path.join(__dirname, '../uploads/identity-cards', oldFileName);
      if (fs.existsSync(oldFilePath)) {
        fs.unlinkSync(oldFilePath);
        console.log('🗑️ Ancien document supprimé:', oldFileName);
      }
    }
    
    // Mettre à jour avec le nom du fichier ET l'URL
    const query = `
      UPDATE subscriptions 
      SET souscriptiondata = jsonb_set(
        jsonb_set(
          souscriptiondata,
          '{piece_identite}',
          $1
        ),
        '{piece_identite_url}',
        $2
      ),
      updated_at = CURRENT_TIMESTAMP
      WHERE id = $3 AND user_id = $4
      RETURNING *;
    `;
    
    const values = [
      JSON.stringify(fileName),
      JSON.stringify(documentUrl),
      id,
      req.user.id
    ];
    
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      // Supprimer le fichier uploadé si la souscription n'existe pas
      fs.unlinkSync(req.file.path);
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    console.log('✅ Document uploadé avec succès');
    
    res.json({
      success: true,
      message: 'Document téléchargé avec succès',
      data: {
        subscription: result.rows[0],
        document: {
          filename: fileName,
          url: documentUrl
        }
      }
    });
  } catch (error) {
    console.error('❌ Erreur upload document:', error);
    
    // Supprimer le fichier en cas d'erreur
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors du téléchargement du document'
    });
  }
};

/**
 * Récupérer un document d'une souscription
 */
exports.getDocument = async (req, res) => {
  try {
    const { id, filename } = req.params;
    
    console.log('=== RÉCUPÉRATION DOCUMENT ===');
    console.log('📄 Souscription ID:', id);
    console.log('📁 Nom fichier:', filename);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Vérifier que l'utilisateur a accès à cette souscription
    const checkQuery = `
      SELECT 
        s.id, 
        s.user_id, 
        s.souscriptiondata->>'piece_identite' as doc_name,
        s.souscriptiondata->>'code_apporteur' as code_apporteur
      FROM subscriptions s
      WHERE s.id = $1
    `;
    
    const checkResult = await pool.query(checkQuery, [id]);
    
    if (checkResult.rows.length === 0) {
      console.error('❌ Souscription non trouvée');
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    const subscription = checkResult.rows[0];
    console.log('📋 Subscription user_id:', subscription.user_id);
    console.log('📋 Code apporteur:', subscription.code_apporteur);
    console.log('📋 Document name:', subscription.doc_name);
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    // 1. C'est le propriétaire de la souscription
    if (subscription.user_id === req.user.id) {
      hasAccess = true;
      console.log('✅ Accès autorisé: propriétaire');
    }
    
    // 2. C'est un admin
    else if (req.user.role === 'admin') {
      hasAccess = true;
      console.log('✅ Accès autorisé: admin');
    }
    
    // 3. C'est un commercial et c'est sa souscription (code_apporteur)
    else if (req.user.role === 'commercial' && req.user.code_apporteur) {
      if (subscription.code_apporteur === req.user.code_apporteur) {
        hasAccess = true;
        console.log('✅ Accès autorisé: commercial avec code_apporteur correspondant');
      }
    }
    
    if (!hasAccess) {
      console.error('❌ Accès refusé');
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce document'
      });
    }
    
    // Vérifier que le fichier demandé correspond au document de la souscription
    if (subscription.doc_name !== filename) {
      console.error('❌ Fichier non autorisé:', filename, '!==', subscription.doc_name);
      return res.status(403).json({
        success: false,
        message: 'Fichier non autorisé'
      });
    }
    
    const filePath = path.join(__dirname, '../uploads/identity-cards', filename);
    console.log('📂 Chemin fichier:', filePath);
    
    if (!fs.existsSync(filePath)) {
      console.error('❌ Fichier non trouvé sur le disque');
      return res.status(404).json({
        success: false,
        message: 'Fichier non trouvé sur le serveur'
      });
    }
    
    console.log('✅ Envoi du fichier');
    res.sendFile(filePath);
  } catch (error) {
    console.error('❌ Erreur récupération document:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du document'
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
    const userRole = req.user.role;
    
    let result;
    
    // Si c'est un commercial, récupérer uniquement les souscriptions avec son code_apporteur
    if (userRole === 'commercial') {
      const codeApporteur = req.user.code_apporteur;
      if (!codeApporteur) {
        return res.json({ success: true, data: [] });
      }
      result = await pool.query(
        "SELECT * FROM subscriptions WHERE code_apporteur = $1 AND statut = 'proposition' ORDER BY date_creation DESC",
        [codeApporteur]
      );
    } else {
      // Si c'est un client, récupérer:
      // 1. Les souscriptions où user_id correspond
      // 2. Les souscriptions où code_apporteur existe ET le numéro dans souscription_data correspond au numéro du client
      const userResult = await pool.query(
        "SELECT telephone FROM users WHERE id = $1",
        [userId]
      );
      const userTelephone = userResult.rows[0]?.telephone || '';
      
      // Extraire le numéro de téléphone (sans indicatif)
      const telephoneNumber = userTelephone.replace(/^\+?\d{1,4}\s*/, '').trim();
      
      result = await pool.query(
        `SELECT * FROM subscriptions 
         WHERE statut = 'proposition' 
         AND (
           user_id = $1 
           OR (
             code_apporteur IS NOT NULL 
             AND souscriptiondata->'client_info'->>'telephone' LIKE $2
           )
         )
         ORDER BY date_creation DESC`,
        [userId, `%${telephoneNumber}%`]
      );
    }
    
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
    const userRole = req.user.role;
    
    let result;
    
    // Si c'est un commercial, récupérer uniquement les souscriptions avec son code_apporteur
    if (userRole === 'commercial') {
      const codeApporteur = req.user.code_apporteur;
      if (!codeApporteur) {
        return res.json({ success: true, data: [] });
      }
      result = await pool.query(
        "SELECT * FROM subscriptions WHERE code_apporteur = $1 AND statut = 'contrat' ORDER BY date_creation DESC",
        [codeApporteur]
      );
    } else {
      // Si c'est un client, récupérer:
      // 1. Les souscriptions où user_id correspond
      // 2. Les souscriptions où code_apporteur existe ET le numéro dans souscription_data correspond au numéro du client
      const userResult = await pool.query(
        "SELECT telephone FROM users WHERE id = $1",
        [userId]
      );
      const userTelephone = userResult.rows[0]?.telephone || '';
      
      // Extraire le numéro de téléphone (sans indicatif)
      const telephoneNumber = userTelephone.replace(/^\+?\d{1,4}\s*/, '').trim();
      
      result = await pool.query(
        `SELECT * FROM subscriptions 
         WHERE statut = 'contrat' 
         AND (
           user_id = $1 
           OR (
             code_apporteur IS NOT NULL 
             AND souscriptiondata->'client_info'->>'telephone' LIKE $2
           )
         )
         ORDER BY date_creation DESC`,
        [userId, `%${telephoneNumber}%`]
      );
    }
    
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
    const userRole = req.user.role;
    
    let result;
    
    // Si c'est un commercial, récupérer uniquement les souscriptions avec son code_apporteur
    if (userRole === 'commercial') {
      const codeApporteur = req.user.code_apporteur;
      if (!codeApporteur) {
        return res.json({ success: true, data: [] });
      }
      result = await pool.query(
        "SELECT * FROM subscriptions WHERE code_apporteur = $1 ORDER BY date_creation DESC",
        [codeApporteur]
      );
    } else {
      // Si c'est un client, récupérer:
      // 1. Les souscriptions où user_id correspond
      // 2. Les souscriptions où code_apporteur existe ET le numéro dans souscription_data correspond au numéro du client
      const userResult = await pool.query(
        "SELECT telephone FROM users WHERE id = $1",
        [userId]
      );
      const userTelephone = userResult.rows[0]?.telephone || '';
      
      // Extraire le numéro de téléphone (sans indicatif)
      const telephoneNumber = userTelephone.replace(/^\+?\d{1,4}\s*/, '').trim();
      
      result = await pool.query(
        `SELECT * FROM subscriptions 
         WHERE (
           user_id = $1 
           OR (
             code_apporteur IS NOT NULL 
             AND souscriptiondata->'client_info'->>'telephone' LIKE $2
           )
         )
         ORDER BY date_creation DESC`,
        [userId, `%${telephoneNumber}%`]
      );
    }
    
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
    const userRole = req.user.role;
    
    // =========================================
    // ÉTAPE 1 : Récupérer la souscription
    // =========================================
    let subscriptionResult;
    
    if (userRole === 'commercial') {
      const codeApporteur = req.user.code_apporteur;
      if (!codeApporteur) {
        return res.status(404).json({
          success: false,
          message: 'Souscription non trouvée'
        });
      }
      subscriptionResult = await pool.query(
        "SELECT * FROM subscriptions WHERE id = $1 AND code_apporteur = $2",
        [id, codeApporteur]
      );
    } else {
      // Pour un client, vérifier user_id OU code_apporteur avec numéro correspondant
      const userResult = await pool.query(
        "SELECT telephone FROM users WHERE id = $1",
        [userId]
      );
      const userTelephone = userResult.rows[0]?.telephone || '';
      const telephoneNumber = userTelephone.replace(/^\+?\d{1,4}\s*/, '').trim();
      
      subscriptionResult = await pool.query(
        `SELECT * FROM subscriptions 
         WHERE id = $1 
         AND (
           user_id = $2 
           OR (
             code_apporteur IS NOT NULL 
             AND souscriptiondata->'client_info'->>'telephone' LIKE $3
           )
         )`,
        [id, userId, `%${telephoneNumber}%`]
      );
    }
    
    // Vérifier que la souscription existe
    if (subscriptionResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }
    
    const subscription = subscriptionResult.rows[0];
    
    // =========================================
    // ÉTAPE 2 : Récupérer les infos utilisateur
    // =========================================
    // Si la souscription a été créée par un commercial, utiliser les infos client dans souscription_data
    let userData = null;
    
    if (subscription.code_apporteur && subscription.souscriptiondata?.client_info) {
      // Utiliser les infos client depuis souscription_data
      const clientInfo = subscription.souscriptiondata.client_info;
      userData = {
        id: subscription.user_id || null,
        civilite: clientInfo.civilite || clientInfo.genre || 'Monsieur',
        nom: clientInfo.nom || '',
        prenom: clientInfo.prenom || '',
        email: clientInfo.email || '',
        telephone: clientInfo.telephone || '',
        date_naissance: clientInfo.date_naissance || null,
        lieu_naissance: clientInfo.lieu_naissance || '',
        adresse: clientInfo.adresse || ''
      };
    } else {
      // Sinon, récupérer depuis la table users
      const userResult = await pool.query(
        "SELECT id, civilite, nom, prenom, email, telephone, date_naissance, lieu_naissance, adresse FROM users WHERE id = $1",
        [subscription.user_id || userId]
      );
      userData = userResult.rows[0] || null;
    }
    
    // =========================================
    // ÉTAPE 3 : Formater les données utilisateur (comme dans /auth/profile)
    // =========================================
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
        subscription: subscription,  // Données de la souscription
        user: userData              // Données de l'utilisateur formatées (client ou depuis souscription_data)
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
    const userRole = req.user.role;
    const codeApporteur = req.user.code_apporteur;

    // Récupérer la souscription
    // Si c'est un commercial, vérifier le code_apporteur
    // Si c'est un client, vérifier user_id ou code_apporteur avec téléphone correspondant
    let subResult;
    if (userRole === 'commercial' && codeApporteur) {
      subResult = await pool.query(
        "SELECT * FROM subscriptions WHERE id = $1 AND code_apporteur = $2",
        [id, codeApporteur]
      );
    } else {
      // Pour les clients, vérifier user_id ou code_apporteur avec téléphone correspondant
      const userResult = await pool.query(
        "SELECT telephone FROM users WHERE id = $1",
        [userId]
      );
      const userTelephone = userResult.rows[0]?.telephone || '';
      const telephoneNumber = userTelephone.replace(/^\+?\d{1,4}\s*/, '').trim();
      
      subResult = await pool.query(
        `SELECT * FROM subscriptions 
         WHERE id = $1 
         AND (
           user_id = $2 
           OR (
             code_apporteur IS NOT NULL 
             AND souscriptiondata->'client_info'->>'telephone' LIKE $3
           )
         )`,
        [id, userId, `%${telephoneNumber}%`]
      );
    }
    
    if (subResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Souscription non trouvée' });
    }
    const subscription = subResult.rows[0];

    // Récupérer les données utilisateur
    // Si la souscription a un code_apporteur et des client_info, utiliser ces infos en priorité
    let user = {};
    if (subscription.code_apporteur && subscription.souscriptiondata?.client_info) {
      // Utiliser les infos client depuis souscription_data
      const clientInfo = subscription.souscriptiondata.client_info;
      user = {
        id: subscription.user_id || null,
        civilite: clientInfo.civilite || '',
        nom: clientInfo.nom || '',
        prenom: clientInfo.prenom || '',
        email: clientInfo.email || '',
        telephone: clientInfo.telephone || '',
        date_naissance: clientInfo.date_naissance || null,
        lieu_naissance: clientInfo.lieu_naissance || '',
        adresse: clientInfo.adresse || ''
      };
    } else if (subscription.user_id) {
      // Récupérer depuis la table users
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
        [subscription.user_id]
      );
      user = userResult.rows[0] || {};
    }
    
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
    const isEtude = productName.includes('etude');
    const isRetraite = productName.includes('retraite');
    const isSerenite = productName.includes('serenite');
    const isEmprunteur = productName.includes('emprunteur');
    const isFamilis = productName.includes('familis');
    const isSolidarite = productName.includes('solidarite');
    const isEpargne = productName.includes('epargne');
    
    const TITLE = isEtude ? 'CORIS ETUDE'
      : isRetraite ? 'CORIS RETRAITE'
      : isSerenite ? 'CORIS SERENITE'
      : isEmprunteur ? 'FLEX EMPRUNTEUR'
      : isFamilis ? 'CORIS FAMILIS'
      : isSolidarite ? 'CORIS SOLIDARITE'
      : isEpargne ? 'CORIS EPARGNE BONUS'
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
    // Pour Coris Étude, calculer la durée réelle du contrat (jusqu'à 17 ans)
    let dureeContratAffichee = dureeAffichee;
    if (isEtude && d.age_enfant) {
      const dureeReelle = 17 - parseInt(d.age_enfant);
      dureeContratAffichee = `${dureeReelle} ans (jusqu'à 17 ans)`;
    }
    
    drawRow(startX, curY, fullW, rowH);
    write('Du', startX + 5, curY + 4, 9, '#666', 20);
    write(formatDate(dateEffet) || 'Non renseigné', startX + 30, curY + 4, 9, '#000', 90);
    write('Au', startX + 130, curY + 4, 9, '#666', 20);
    write(formatDate(dateEcheance) || 'Non renseigné', startX + 155, curY + 4, 9, '#000', 90);
    write('Durée', startX + 255, curY + 4, 9, '#666', 35);
    write(dureeContratAffichee, startX + 295, curY + 4, 9, '#000', 60, true);
    write('Périodicité', startX + 365, curY + 4, 9, '#666', 60);
    write(periodiciteFormatee, startX + 430, curY + 4, 9, '#000', 105);
    curY += rowH + 5;

    // Assuré(e) - Case grise
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('Assuré(e)', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH + 5;
    
    // Pour Coris Étude, afficher aussi la date de naissance du parent si disponible
    const hasParentInfo = isEtude && (d.date_naissance_parent || d.age_parent);
    const rowsNeeded = hasParentInfo ? 2.5 : 1.8;
    
    drawRow(startX, curY, fullW, rowH * rowsNeeded);
    write('Nom et Prénom', startX + 5, curY + 3, 9, '#666', 100);
    write(`${safe(usr.nom)} ${safe(usr.prenom)}`, startX + 115, curY + 3, 9, '#000', 200);
    write('Informations pers.', startX + 5, curY + 3 + 13, 9, '#666', 100);
    const dateNaissanceAssure = formatDate(usr.date_naissance);
    const lieuNaissanceAssure = usr.lieu_naissance || '';
    const sexe = usr.civilite === 'M.' || usr.civilite === 'Monsieur' ? 'M' : (usr.civilite === 'Mme' || usr.civilite === 'Madame' ? 'F' : '');
    const infoPers = `Né(e) le : ${dateNaissanceAssure || 'Non renseigné'} à : ${lieuNaissanceAssure || 'Non renseigné'} - sexe : ${sexe || 'Non renseigné'}`;
    write(infoPers, startX + 115, curY + 3 + 13, 9, '#000', 420);
    
    // Ajouter la date de naissance du parent pour Coris Étude
    if (hasParentInfo) {
      write('Parent (Coris Étude)', startX + 5, curY + 3 + 26, 9, '#666', 100);
      const dateNaissanceParent = formatDate(d.date_naissance_parent);
      const ageParent = d.age_parent || '';
      const parentInfo = `Date de naissance : ${dateNaissanceParent || 'Non renseignée'} - Âge : ${ageParent || 'Non renseigné'} ans`;
      write(parentInfo, startX + 115, curY + 3 + 26, 9, '#000', 420);
    }
    
    curY += rowH * rowsNeeded + 5;

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
    // isSolidarite est déjà défini plus haut
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
    
    // Calculer Prime Nette (Cotisation Périodique)
    // Utiliser prime_calculee en priorité, sinon prime, sinon montant
    const primeNette = d.prime_calculee || d.prime || d.montant || d.prime_mensuelle || d.prime_annuelle || 0;
    
    // Déterminer le nombre de lignes nécessaires
    let caracteristiquesLignes = 1;
    if (isEtude && d.rente_calculee) caracteristiquesLignes++;
    else if (isRetraite && (d.capital || d.capital_garanti)) caracteristiquesLignes++;
    else if (isSerenite && d.rente_calculee) caracteristiquesLignes++;
    else if ((isSolidarite || isFamilis || isEmprunteur) && (d.capital || d.capital_garanti)) caracteristiquesLignes++;
    else if (isEpargne && (d.capital || d.capital_garanti)) caracteristiquesLignes++;
    
    drawRow(startX, curY, fullW, rowH * caracteristiquesLignes);
    
    // Ligne 1: Cotisation Périodique / Taux d'intérêt Net
    // Afficher la périodicité pour Coris Étude
    const cotisationLabel = isEtude && periodiciteFormatee ? `Prime ${periodiciteFormatee}` : 'Cotisation Périodique';
    write(cotisationLabel, startX + 5, curY + 3, 9, '#666', 130);
    write(money(primeNette), startX + 145, curY + 3, 9, '#000', 150);
    write("Taux d'intérêt Net", startX + 305, curY + 3, 9, '#666', 100);
    write('3,500%', startX + 410, curY + 3, 9, '#000', 125);
    
    // Ligne 2: Rente ou Capital (selon le produit)
    if (caracteristiquesLignes > 1) {
      if ((isEtude || isSerenite) && d.rente_calculee) {
        write('Valeur de la Rente', startX + 5, curY + 3 + 13, 9, '#666', 130);
        write(money(d.rente_calculee || 0), startX + 145, curY + 3 + 13, 9, '#000', 150);
      } else if ((isRetraite || isSolidarite || isFamilis || isEmprunteur || isEpargne) && (d.capital || d.capital_garanti)) {
        write('Capital au terme', startX + 5, curY + 3 + 13, 9, '#666', 130);
        write(money(d.capital || d.capital_garanti || 0), startX + 145, curY + 3 + 13, 9, '#000', 150);
      }
    }
    
    curY += rowH * caracteristiquesLignes + 5;

    // Garanties - Adapté selon le produit
    // Pré-calculer le nombre de lignes de garanties avant de créer l'en-tête
    let garantiesLignes = 0;
    const capitalDeces = d.capital || d.capital_garanti || d.capital_deces || 0;
    const capitalVie = d.capital_garanti || d.capital || 0;
    
    // Compter les lignes de garanties selon le produit
    if (isEtude) {
      if (capitalDeces > 0) garantiesLignes++;
      if (capitalVie > 0 && d.rente_calculee) garantiesLignes++;
    } else if (isRetraite) {
      if (capitalVie > 0) garantiesLignes++;
    } else if (isEpargne) {
      // Pas de garanties affichées
    } else if (isSerenite) {
      if (capitalDeces > 0) garantiesLignes++;
    } else if (isSolidarite) {
      if (capitalDeces > 0) garantiesLignes++;
    } else if (isEmprunteur) {
      if (capitalDeces > 0) garantiesLignes++;
      if (d.garantie_prevoyance && d.capital_prevoyance) garantiesLignes++;
      if (d.garantie_perte_emploi && d.capital_perte_emploi) garantiesLignes++;
    } else {
      if (capitalDeces > 0) garantiesLignes++;
      if (capitalVie > 0 && (isFamilis || d.capital_garanti)) garantiesLignes++;
    }
    
    // Créer l'en-tête seulement s'il y a des garanties à afficher
    if (garantiesLignes > 0) {
      drawRow(startX, curY, fullW, boxH, grisNormal);
      write('Garanties', startX + 5, curY + 4, 9, '#000000', 180, true);
      writeCentered('Capital (FCFA)', startX + 200, curY + 4, 165, 9, '#000000', true);
      writeCentered('Primes Période (FCFA)', startX + 365, curY + 4, 170, 9, '#000000', true);
      curY += boxH;
      
      garantiesLignes = 0; // Réinitialiser pour compter les lignes affichées
      
      // Coris Etude : Décès (si renseigné) + Vie à terme (si renseigné)
      if (isEtude) {
        if (capitalDeces > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Garantie en cas de décès', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalDeces), startX + 200, curY + 4, 165, 9);
          writeCentered(money(primeNette), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
        if (capitalVie > 0 && d.rente_calculee) {
          drawRow(startX, curY, fullW, rowH);
          write('En Cas de Vie à Terme', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalVie), startX + 200, curY + 4, 165, 9);
          writeCentered('', startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      // Coris Retraite : Pas de décès, seulement Capital au terme
      else if (isRetraite) {
        if (capitalVie > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Capital au terme', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalVie), startX + 200, curY + 4, 165, 9);
          writeCentered('', startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      // Epargne Bonus : Pas de décès/invalidité
      else if (isEpargne) {
        // Pas de garanties affichées
      }
      // Coris Sérénité : Décès (si renseigné), pas de Vie à terme
      else if (isSerenite) {
        if (capitalDeces > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Décès ou Invalidité Permanente Totale', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalDeces), startX + 200, curY + 4, 165, 9);
          writeCentered(money(primeNette), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      // Coris Solidarité : Décès (si renseigné), pas de Vie à terme
      else if (isSolidarite) {
        if (capitalDeces > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Décès ou Invalidité Permanente Totale', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalDeces), startX + 200, curY + 4, 165, 9);
          writeCentered(money(primeNette), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      // Flex Emprunteur : Décès (si renseigné) + Prévoyance + Perte d'emploi (si renseignés), pas de Vie à terme
      else if (isEmprunteur) {
        if (capitalDeces > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Décès ou Invalidité Permanente Totale', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalDeces), startX + 200, curY + 4, 165, 9);
          writeCentered(money(primeNette), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
        // Prévoyance
        if (d.garantie_prevoyance && d.capital_prevoyance) {
          drawRow(startX, curY, fullW, rowH);
          write('Prévoyance', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(d.capital_prevoyance || 0), startX + 200, curY + 4, 165, 9);
          writeCentered(money(d.prime_prevoyance || 0), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
        // Perte d'emploi
        if (d.garantie_perte_emploi && d.capital_perte_emploi) {
          drawRow(startX, curY, fullW, rowH);
          write('Perte d\'emploi', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(d.capital_perte_emploi || 0), startX + 200, curY + 4, 165, 9);
          writeCentered(money(d.prime_perte_emploi || 0), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      // Autres produits (Coris Familis, etc.) : Décès + Vie à terme (si renseignés)
      else {
        if (capitalDeces > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Décès ou Invalidité Permanente Totale', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalDeces), startX + 200, curY + 4, 165, 9);
          writeCentered(money(primeNette), startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
        if (capitalVie > 0 && (isFamilis || d.capital_garanti)) {
          drawRow(startX, curY, fullW, rowH);
          write('En Cas de Vie à Terme', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalVie), startX + 200, curY + 4, 165, 9);
          writeCentered('', startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      
      // Ajouter un espacement après les garanties
      curY += 5;
    }

    // Décompte Prime - Case grise
    const decompteNum = safe(d.decompte_prime_num || `101${String(subscription.id).padStart(7,'0')}`);
    const decompteText = `Decompte Prime N° ${decompteNum}`;
    
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered(decompteText, startX, curY + 4, fullW, 9, '#000000', true);
    curY += boxH + 5;
    
    // Calculer Accessoires selon le produit
    // Flex Emprunteur = 1000 FCFA
    // Coris Etude, Coris Retraite, Coris Sérénité = 5000 FCFA
    // Autres produits (Epargne Bonus, Coris Solidarité, Coris Familis) = 0 FCFA
    let accessoiresMontant = 0;
    if (isEmprunteur) {
      accessoiresMontant = 1000;
    } else if (isEtude || isRetraite || isSerenite) {
      accessoiresMontant = 5000;
    } else {
      // Epargne Bonus, Coris Solidarité, Coris Familis et autres = 0
      accessoiresMontant = 0;
    }
    
    // Prime Totale = Accessoires + Prime Nette
    const primeTotale = accessoiresMontant + primeNette;
    
    // Prime Nette, Accessoires, Prime Totale - Tableau horizontal compact
    const primeBoxW = Math.floor(fullW / 3);
    
    // En-têtes et valeurs dans la même ligne pour économiser l'espace
    drawRow(startX, curY, primeBoxW, rowH * 1.5);
    writeCentered('Prime Nette', startX, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(primeNette), startX, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    drawRow(startX + primeBoxW, curY, primeBoxW, rowH * 1.5);
    writeCentered('Accessoires', startX + primeBoxW, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(accessoiresMontant), startX + primeBoxW, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    drawRow(startX + primeBoxW * 2, curY, primeBoxW, rowH * 1.5);
    writeCentered('Prime Totale', startX + primeBoxW * 2, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(primeTotale), startX + primeBoxW * 2, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
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

    curY = sigY + sigHeight + 12; // Espacement augmenté pour séparer du trait noir

    // Trait noir en bas (épaisseur 1 pour visibilité) - Descendu légèrement
    doc.lineWidth(1).moveTo(startX, curY).lineTo(startX + fullW, curY).stroke('#000000');
    curY += 8; // Espacement augmenté après le trait noir

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

    // Pour Coris Solidarité : Ajouter une deuxième page avec les bénéficiaires détaillés
    if (isSolidarite) {
      doc.addPage();
      curY = 30; // Réinitialiser la position Y pour la nouvelle page
      
      // Titre de la page
      doc.fontSize(14).fillColor('#000000').font('Helvetica-Bold');
      doc.text('CORIS SOLIDARITE - BÉNÉFICIAIRES', startX, curY, { width: fullW, align: 'center' });
      curY += 20;
      
      // En-tête du tableau des bénéficiaires
      drawRow(startX, curY, fullW, boxH, grisNormal);
      const benefDetailColW = [180, 100, 120, 135]; // Nom et Prénom, Date de Naissance, Lieu de Naissance, Capital décès
      let benefDetailCurX = startX;
      
      write('Nom et Prénom', benefDetailCurX + 4, curY + 4, 9, '#000000', benefDetailColW[0] - 8, true);
      benefDetailCurX += benefDetailColW[0];
      write('Date de Naissance', benefDetailCurX + 4, curY + 4, 9, '#000000', benefDetailColW[1] - 8, true);
      benefDetailCurX += benefDetailColW[1];
      write('Lieu de Naissance', benefDetailCurX + 4, curY + 4, 9, '#000000', benefDetailColW[2] - 8, true);
      benefDetailCurX += benefDetailColW[2];
      write('Capital décès', benefDetailCurX + 4, curY + 4, 9, '#000000', benefDetailColW[3] - 8, true);
      curY += boxH;
      
      // Récupérer tous les bénéficiaires (souscripteur, conjoints, enfants, ascendants)
      const conjoints = Array.isArray(d.conjoints) ? d.conjoints : [];
      const enfants = Array.isArray(d.enfants) ? d.enfants : [];
      const ascendants = Array.isArray(d.ascendants) ? d.ascendants : [];
      const beneficiaireDeces = d.beneficiaire || {};
      
      // Souscripteur
      drawRow(startX, curY, fullW, rowH);
      benefDetailCurX = startX;
      write(`${safe(usr.nom)} ${safe(usr.prenom)}`, benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[0] - 8);
      benefDetailCurX += benefDetailColW[0];
      write(formatDate(usr.date_naissance || ''), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[1] - 8);
      benefDetailCurX += benefDetailColW[1];
      write(usr.lieu_naissance || '', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[2] - 8);
      benefDetailCurX += benefDetailColW[2];
      write(money(d.capital || d.capital_deces || 0), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[3] - 8);
      curY += rowH;
      
      // Bénéficiaire en cas de décès (si renseigné)
      if (beneficiaireDeces.nom) {
        drawRow(startX, curY, fullW, rowH);
        benefDetailCurX = startX;
        write(beneficiaireDeces.nom || '', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[0] - 8);
        benefDetailCurX += benefDetailColW[0];
        write(formatDate(beneficiaireDeces.date_naissance || beneficiaireDeces.dateNaissance || ''), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[1] - 8);
        benefDetailCurX += benefDetailColW[1];
        write(beneficiaireDeces.lieu_naissance || beneficiaireDeces.lieuNaissance || '', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[2] - 8);
        benefDetailCurX += benefDetailColW[2];
        write(money(d.capital || d.capital_deces || 0), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[3] - 8);
        curY += rowH;
      }
      
      // Conjoints
      conjoints.forEach((c) => {
        drawRow(startX, curY, fullW, rowH);
        benefDetailCurX = startX;
        write(c.nom_prenom || c.nom || 'Conjoint', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[0] - 8);
        benefDetailCurX += benefDetailColW[0];
        write(formatDate(c.date_naissance || c.dateNaissance || ''), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[1] - 8);
        benefDetailCurX += benefDetailColW[1];
        write(c.lieu_naissance || c.lieuNaissance || '', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[2] - 8);
        benefDetailCurX += benefDetailColW[2];
        write(money(c.capital_deces || d.capital || d.capital_deces || 0), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[3] - 8);
        curY += rowH;
      });
      
      // Enfants
      enfants.forEach((e) => {
        drawRow(startX, curY, fullW, rowH);
        benefDetailCurX = startX;
        write(e.nom_prenom || e.nom || 'Enfant', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[0] - 8);
        benefDetailCurX += benefDetailColW[0];
        write(formatDate(e.date_naissance || e.dateNaissance || ''), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[1] - 8);
        benefDetailCurX += benefDetailColW[1];
        write(e.lieu_naissance || e.lieuNaissance || '', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[2] - 8);
        benefDetailCurX += benefDetailColW[2];
        write(money(e.capital_deces || d.capital || d.capital_deces || 0), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[3] - 8);
        curY += rowH;
      });
      
      // Ascendants
      ascendants.forEach((a) => {
        drawRow(startX, curY, fullW, rowH);
        benefDetailCurX = startX;
        write(a.nom_prenom || a.nom || 'Ascendant', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[0] - 8);
        benefDetailCurX += benefDetailColW[0];
        write(formatDate(a.date_naissance || a.dateNaissance || ''), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[1] - 8);
        benefDetailCurX += benefDetailColW[1];
        write(a.lieu_naissance || a.lieuNaissance || '', benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[2] - 8);
        benefDetailCurX += benefDetailColW[2];
        write(money(a.capital_deces || d.capital || d.capital_deces || 0), benefDetailCurX + 4, curY + 4, 9, '#000', benefDetailColW[3] - 8);
        curY += rowH;
      });
      
      console.log('✅ Page 2 ajoutée pour Coris Solidarité avec bénéficiaires détaillés');
    }

    doc.end();
  } catch (error) {
    console.error('Erreur génération PDF:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la génération du PDF' });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER UN DOCUMENT (PIÈCE D'IDENTITÉ)
 * ===============================================
 * 
 * Permet de télécharger le document téléchargé lors de la souscription.
 * 
 * @route GET /subscriptions/:id/document/:filename
 * @requires verifyToken
 */
exports.getDocument = async (req, res) => {
  try {
    const { id, filename } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Vérifier que la souscription existe et appartient à l'utilisateur
    const checkQuery = `
      SELECT s.id, s.user_id, s.souscriptiondata->>'piece_identite' as piece_identite
      FROM subscriptions s
      WHERE s.id = $1
    `;
    const checkResult = await pool.query(checkQuery, [id]);

    if (checkResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Souscription non trouvée' 
      });
    }

    const subscription = checkResult.rows[0];

    // Vérifier les permissions
    if (userRole !== 'admin' && userRole !== 'commercial' && subscription.user_id !== userId) {
      return res.status(403).json({ 
        success: false, 
        message: 'Accès non autorisé' 
      });
    }

    // Vérifier que le nom de fichier correspond
    if (subscription.piece_identite !== filename) {
      return res.status(404).json({ 
        success: false, 
        message: 'Document non trouvé' 
      });
    }

    // Construire le chemin du fichier
    const path = require('path');
    const filePath = path.join(__dirname, '../uploads/kyc', filename);

    // Vérifier que le fichier existe
    const fs = require('fs');
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ 
        success: false, 
        message: 'Fichier non trouvé sur le serveur' 
      });
    }

    // Envoyer le fichier
    res.sendFile(filePath);

  } catch (error) {
    console.error('Erreur récupération document:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la récupération du document',
      error: error.message 
    });
  }
};
