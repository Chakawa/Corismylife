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
const fs = require('fs');  // Module Node.js pour les opérations sur le système de fichiers
const path = require('path');  // Module Node.js pour manipuler les chemins de fichiers
const {
  notifySubscriptionCreated,
  notifyPaymentPending,
  notifyPaymentSuccess,
  notifyPropositionGenerated,
  notifyContractGenerated,
  notifySubscriptionModified
} = require('../services/notificationHelper');  // Helper pour créer des notifications automatiques

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
      signature, // Signature du client en base64
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
          numero_piece_identite: client_info.numero_piece_identite || client_info.numero,
          profession: client_info.profession || '',
          secteur_activite: client_info.secteur_activite || ''
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
    
    // Sauvegarder la signature si elle existe
    let signaturePath = null;
    if (signature) {
      try {
        // Créer le dossier signatures s'il n'existe pas
        const signaturesDir = path.join(process.cwd(), 'uploads', 'signatures');
        if (!fs.existsSync(signaturesDir)) {
          fs.mkdirSync(signaturesDir, { recursive: true });
        }
        
        // Décoder la signature base64
        const signatureBuffer = Buffer.from(signature, 'base64');
        console.log('📝 Signature reçue - Taille buffer:', signatureBuffer.length, 'bytes');
        console.log('🔍 HEADER REÇU:', signatureBuffer.slice(0, 20).toString('hex'));
        
        // Générer un nom de fichier unique
        const signatureFilename = `signature_${numeroPolice}_${Date.now()}.png`;
        signaturePath = path.join(signaturesDir, signatureFilename);
        
        // Sauvegarder l'image
        fs.writeFileSync(signaturePath, signatureBuffer);
        
        // VÉRIFIER le fichier immédiatement après sauvegarde
        const savedFile = fs.readFileSync(signaturePath);
        console.log('🔍 HEADER FICHIER SAUVEGARDÉ:', savedFile.slice(0, 20).toString('hex'));
        console.log('✅ Les headers match?', signatureBuffer.slice(0, 20).equals(savedFile.slice(0, 20)) ? 'OUI ✅' : 'NON ❌');
        
        // Stocker le chemin relatif dans les données de souscription
        subscriptionData.signature_path = `uploads/signatures/${signatureFilename}`;
        
        console.log('✅ Signature sauvegardée:', signaturePath, '- Taille fichier:', signatureBuffer.length);
      } catch (error) {
        console.error('❌ Erreur sauvegarde signature:', error.message);
        // On continue même si la signature échoue
      }
    }
    
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
    
    // 🔔 NOTIFICATION CLIENT : Souscription créée
    try {
      const productName = product_type.replace(/_/g, ' ').toUpperCase();
      await notifySubscriptionCreated(userId, productName, numeroPolice);
      
      // Notification de paiement en attente (car statut = proposition)
      if (subscriptionData.montant_cotisation || subscriptionData.prime_totale || subscriptionData.montant_versement) {
        const amount = subscriptionData.montant_cotisation || subscriptionData.prime_totale || subscriptionData.montant_versement;
        await notifyPaymentPending(userId, productName, amount);
      }
    } catch (notifError) {
      console.error('❌ Erreur notification client:', notifError.message);
    }
    
    // Créer une notification pour tous les admins
    try {
      const adminQuery = "SELECT id FROM users WHERE role = 'admin'";
      const adminResult = await pool.query(adminQuery);
      
      if (adminResult.rows.length > 0) {
        const productName = product_type.replace(/_/g, ' ').toUpperCase();
        const clientName = client_info 
          ? `${client_info.prenom} ${client_info.nom}` 
          : 'Client';
        
        const notificationMessage = `Nouvelle souscription ${productName} pour ${clientName} - Police: ${numeroPolice}`;
        
        for (const admin of adminResult.rows) {
          await pool.query(`
            INSERT INTO notifications 
              (admin_id, type, title, message, reference_id, reference_type, action_url, created_at)
            VALUES 
              ($1, $2, $3, $4, $5, $6, $7, NOW())
          `, [
            admin.id,
            'new_subscription',
            `Nouvelle souscription ${productName}`,
            notificationMessage,
            result.rows[0].id,
            'subscription',
            `/souscriptions?id=${result.rows[0].id}`
          ]);
        }
      }
    } catch (notifError) {
      console.error('Erreur création notification admin:', notifError.message);
      // Ne pas bloquer la création de souscription
    }
    
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
      signature,
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
        numero_piece_identite: client_info.numero_piece_identite || client_info.numero,
        profession: client_info.profession || '',
        secteur_activite: client_info.secteur_activite || ''
      };
    }
    
    // Traiter la signature si elle existe
    if (signature) {
      try {
        // Récupérer la souscription actuelle pour obtenir le numéro de police
        const currentSubQuery = 'SELECT numero_police FROM subscriptions WHERE id = $1';
        const currentSub = await pool.query(currentSubQuery, [id]);
        
        if (currentSub.rows.length > 0) {
          const numeroPolice = currentSub.rows[0].numero_police;
          
          // Créer le dossier signatures s'il n'existe pas
          const signaturesDir = path.join(process.cwd(), 'uploads', 'signatures');
          if (!fs.existsSync(signaturesDir)) {
            fs.mkdirSync(signaturesDir, { recursive: true });
          }
          
          // Décoder la signature base64
          const signatureBuffer = Buffer.from(signature, 'base64');
          console.log('📝 [UPDATE] Signature reçue - Taille buffer:', signatureBuffer.length, 'bytes');
          console.log('🔍 [UPDATE] HEADER REÇU:', signatureBuffer.slice(0, 20).toString('hex'));
          
          // Générer un nom de fichier unique
          const signatureFilename = `signature_${numeroPolice}_${Date.now()}.png`;
          const signaturePath = path.join(signaturesDir, signatureFilename);
          
          // Sauvegarder l'image
          fs.writeFileSync(signaturePath, signatureBuffer);
          
          // VÉRIFIER le fichier immédiatement après sauvegarde
          const savedFile = fs.readFileSync(signaturePath);
          console.log('🔍 [UPDATE] HEADER FICHIER SAUVEGARDÉ:', savedFile.slice(0, 20).toString('hex'));
          console.log('✅ [UPDATE] Les headers match?', signatureBuffer.slice(0, 20).equals(savedFile.slice(0, 20)) ? 'OUI ✅' : 'NON ❌');
          
          // Stocker le chemin relatif
          subscriptionData.signature_path = `uploads/signatures/${signatureFilename}`;
          
          console.log('✅ Signature mise à jour:', signaturePath, '- Taille:', signatureBuffer.length);
        }
      } catch (error) {
        console.error('❌ Erreur mise à jour signature:', error.message);
      }
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
 * 
 * ⚠️ TODO - INTÉGRATION API DE PAIEMENT ⚠️
 * ==========================================
 * CETTE FONCTION DOIT ÊTRE MODIFIÉE POUR INTÉGRER L'API DE PAIEMENT
 * 
 * Actions à effectuer :
 * 1. Appeler l'API Wave/Orange Money pour initier le paiement
 * 2. Récupérer le transaction_id depuis la réponse de l'API
 * 3. Gérer les callbacks/webhooks de l'API pour le statut final
 * 4. Mettre à jour automatiquement le statut selon la réponse de l'API
 * 
 * APIs à intégrer :
 * - Wave API: https://developer.wave.com/
 * - Orange Money API: Documentation fournie par Orange CI
 * 
 * Ne pas oublier :
 * - Clés API (à stocker dans .env)
 * - Gestion des erreurs API
 * - Timeouts et retry logic
 * - Webhooks pour notifications asynchrones
 * ==========================================
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
    const updatedSub = result.rows[0];
    if (!payment_success) {
      return res.json({
        success: true,
        message: 'Votre proposition a été enregistrée avec succès. Vous pouvez effectuer le paiement plus tard depuis votre espace client.',
        data: updatedSub
      });
    }

    // Si paiement réussi, personnaliser le message selon le produit
    const prod = (updatedSub.produit_nom || '').toLowerCase();
    const isFamilis = prod.includes('familis');
    const isSerenite = prod.includes('serenite');
    const isEtude = prod.includes('etude');
    const productTitle = isFamilis ? 'CORIS FAMILIS' : isSerenite ? 'CORIS SERENITE' : isEtude ? 'CORIS ETUDE' : (updatedSub.produit_nom || 'votre contrat').toUpperCase();

    res.json({
      success: true,
      message: `Félicitations! Votre contrat ${productTitle} est maintenant actif. Vous recevrez un message de confirmation sous peu.`,
      data: updatedSub
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
    
    // Récupérer la souscription cible
    // Note: Un commercial peut uploader pour une souscription créée pour un client
    const targetQuery = `
      SELECT souscriptiondata,
             user_id,
             code_apporteur
      FROM subscriptions
      WHERE id = $1
        AND (user_id = $2 OR code_apporteur = (SELECT code_apporteur FROM users WHERE id = $2))
    `;
    const targetResult = await pool.query(targetQuery, [id, req.user.id]);

    if (targetResult.rows.length === 0) {
      // Supprimer le fichier uploadé si la souscription n'existe pas
      fs.unlinkSync(req.file.path);
      console.log('⚠️ Souscription non trouvée ou accès refusé pour user_id:', req.user.id, 'subscription_id:', id);
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée ou accès refusé'
      });
    }
    
    // Mettre à jour:
    // 1) les champs historiques (piece_identite, piece_identite_url, piece_identite_label)
    // 2) la collection multi-documents (piece_identite_documents)
    const originalName = req.file.originalname || req.file.filename;
    const newDocument = {
      filename: fileName,
      url: documentUrl,
      label: originalName,
      uploaded_at: new Date().toISOString()
    };

    const query2 = `
      UPDATE subscriptions 
      SET souscriptiondata = jsonb_set(
        jsonb_set(
          jsonb_set(
            jsonb_set(
              COALESCE(souscriptiondata, '{}'::jsonb),
              '{piece_identite_documents}',
              COALESCE(COALESCE(souscriptiondata, '{}'::jsonb)->'piece_identite_documents', '[]'::jsonb) || jsonb_build_array($4::jsonb)
            ),
            '{piece_identite}',
            $1
          ),
          '{piece_identite_url}',
          $2
        ),
        '{piece_identite_label}',
        $3
      ),
      updated_at = CURRENT_TIMESTAMP
      WHERE id = $5 
        AND (user_id = $6 OR code_apporteur = (SELECT code_apporteur FROM users WHERE id = $6))
      RETURNING *;
    `;

    const values = [
      JSON.stringify(fileName),
      JSON.stringify(documentUrl),
      JSON.stringify(originalName),
      JSON.stringify(newDocument),
      id,
      req.user.id
    ];

    const result = await pool.query(query2, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée ou accès refusé'
      });
    }
    
    console.log('✅ Document uploadé avec succès');

    const docs = result.rows[0]?.souscriptiondata?.piece_identite_documents;
    
    res.json({
      success: true,
      message: 'Document téléchargé avec succès',
      data: {
        subscription: result.rows[0],
        document: {
          filename: fileName,
          url: documentUrl,
          label: originalName
        },
        documents: Array.isArray(docs) ? docs : []
      }
    });
  } catch (error) {
    console.error('❌ Erreur upload document:', error);
    console.error('❌ Stack trace:', error.stack);
    
    // Supprimer le fichier en cas d'erreur
    if (req.file && fs.existsSync(req.file.path)) {
      try {
        fs.unlinkSync(req.file.path);
        console.log('🗑️ Fichier uploadé supprimé suite à l\'erreur');
      } catch (unlinkError) {
        console.error('❌ Impossible de supprimer le fichier:', unlinkError);
      }
    }
    
    // Retourner un message d'erreur plus détaillé
    const errorMessage = error.code === '23505' 
      ? 'Un document avec ce nom existe déjà'
      : error.code === '23503'
        ? 'Souscription non trouvée'
        : error.message || 'Erreur lors du téléchargement du document';
    
    res.status(500).json({
      success: false,
      message: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Récupérer un document d'une souscription
 */
exports.getDocument = async (req, res) => {
  try {
    const { id, filename } = req.params;
    // Normaliser le nom reçu (URL encodée, chemin complet, backslashes)
    // pour éviter les 404 quand l'app envoie un chemin au lieu d'un nom de fichier.
    const decodedFilename = decodeURIComponent(String(filename || ''));
    const requestedFilename = path.basename(decodedFilename.split('\\').join('/'));
    
    console.log('=== RÉCUPÉRATION DOCUMENT ===');
    console.log('📄 Souscription ID:', id);
    console.log('📁 Nom fichier brut:', filename);
    console.log('📁 Nom fichier normalisé:', requestedFilename);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Vérifier que l'utilisateur a accès à cette souscription
    const checkQuery = `
      SELECT 
        s.id, 
        s.user_id, 
        s.code_apporteur,
        s.souscriptiondata->>'piece_identite' as doc_name,
        s.souscriptiondata->>'piece_identite_url' as doc_url,
        s.souscriptiondata->'client_info'->>'telephone' as client_info_telephone
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
      // Comparer en convertissant les deux en string pour éviter les problèmes de type
      if (String(subscription.code_apporteur) === String(req.user.code_apporteur)) {
        hasAccess = true;
        console.log('✅ Accès autorisé: commercial avec code_apporteur correspondant');
      } else {
        console.log('❌ Code apporteur ne correspond pas:', req.user.code_apporteur, 'vs', subscription.code_apporteur, '(types:', typeof req.user.code_apporteur, 'vs', typeof subscription.code_apporteur, ')');
      }
    }
    
    // 4. Client dont le téléphone correspond à client_info.telephone (souscription faite par un commercial)
    else if (req.user.role === 'client' && subscription.code_apporteur && subscription.client_info_telephone) {
      try {
        const userResult = await pool.query('SELECT telephone FROM users WHERE id = $1', [req.user.id]);
        const userTelephone = userResult.rows[0]?.telephone || '';
        // Comparer les numéros en ignorant les préfixes internationaux
        const cleanUser = userTelephone.replace(/^\+?\d{1,4}[\s-]?/, '').replace(/\s/g, '');
        const cleanClientInfo = subscription.client_info_telephone.replace(/^\+?\d{1,4}[\s-]?/, '').replace(/\s/g, '');
        if (cleanUser && cleanClientInfo && cleanClientInfo.includes(cleanUser)) {
          hasAccess = true;
          console.log('✅ Accès autorisé: client via téléphone client_info');
        } else {
          console.log('❌ Téléphone client ne correspond pas:', cleanUser, 'vs', cleanClientInfo);
        }
      } catch (e) {
        console.log('❌ Erreur vérification téléphone client:', e.message);
      }
    }
    
    if (!hasAccess) {
      console.error('❌ Accès refusé');
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce document'
      });
    }
    
    // Résolution robuste du fichier:
    // 1) nom demandé normalisé,
    // 2) nom stocké en base,
    // 3) basename de l'URL stockée.
    const dbDocName = subscription.doc_name
      ? path.basename(String(subscription.doc_name).split('\\').join('/'))
      : null;
    const dbDocUrlName = subscription.doc_url
      ? path.basename(String(subscription.doc_url).split('\\').join('/'))
      : null;

    const candidateNames = [...new Set([
      requestedFilename,
      dbDocName,
      dbDocUrlName,
    ].filter(Boolean))];

    const searchFolders = [
      path.join(__dirname, '../uploads/identity-cards'),
      path.join(__dirname, '../uploads/kyc'),
    ];

    let resolvedFilePath = null;

    for (const candidate of candidateNames) {
      for (const folder of searchFolders) {
        const candidatePath = path.join(folder, candidate);
        if (fs.existsSync(candidatePath)) {
          resolvedFilePath = candidatePath;
          break;
        }
      }
      if (resolvedFilePath) break;
    }

    // Fallback: si le fichier précis est introuvable, tenter le dernier document
    // de l'utilisateur dans les dossiers documents (utile après migration/renommage).
    if (!resolvedFilePath) {
      for (const folder of searchFolders) {
        if (!fs.existsSync(folder)) continue;
        const userPrefix = `identity_${subscription.user_id}_`;
        const userFiles = fs
          .readdirSync(folder)
          .filter((name) => name.startsWith(userPrefix));

        if (userFiles.length > 0) {
          userFiles.sort();
          resolvedFilePath = path.join(folder, userFiles[userFiles.length - 1]);
          break;
        }
      }
    }

    // Fallback complémentaire: retrouver un fichier avec le même timestamp
    // (utile si le préfixe utilisateur a changé entre upload et lecture).
    if (!resolvedFilePath && requestedFilename) {
      const timestampMatch = requestedFilename.match(/identity_\d+_(\d+)_/i);
      const timestampToken = timestampMatch ? timestampMatch[1] : null;

      if (timestampToken) {
        for (const folder of searchFolders) {
          if (!fs.existsSync(folder)) continue;
          const byTimestamp = fs
            .readdirSync(folder)
            .filter((name) => name.includes(`_${timestampToken}_`));

          if (byTimestamp.length > 0) {
            byTimestamp.sort();
            resolvedFilePath = path.join(folder, byTimestamp[byTimestamp.length - 1]);
            break;
          }
        }
      }
    }

    console.log('📂 Candidats fichier:', candidateNames);
    console.log('📂 Chemin résolu:', resolvedFilePath);
    console.log('🔍 Fichier existe?', resolvedFilePath ? fs.existsSync(resolvedFilePath) : false);

    if (!resolvedFilePath || !fs.existsSync(resolvedFilePath)) {
      console.error('❌ Fichier non trouvé sur le disque');
      console.error('📂 Contenu du dossier identity-cards:');
      const identityCardsDir = path.join(__dirname, '../uploads/identity-cards');
      if (fs.existsSync(identityCardsDir)) {
        const files = fs.readdirSync(identityCardsDir);
        console.log('📁 Fichiers présents:', files);
      } else {
        console.error('❌ Le dossier identity-cards n\'existe pas!');
      }
      return res.status(404).json({
        success: false,
        message: 'Fichier non trouvé sur le serveur'
      });
    }
    
    console.log('✅ Envoi du fichier');
    res.sendFile(resolvedFilePath);
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
    
    console.log('=== RÉCUPÉRATION DÉTAILS SUBSCRIPTION/CONTRAT ===');
    console.log('📋 ID:', id);
    console.log('👤 User ID:', userId);
    console.log('🎭 Role:', userRole);
    
    // =========================================
    // ÉTAPE 1 : Récupérer la souscription
    // =========================================
    let subscriptionResult;
    
    if (userRole === 'commercial') {
      const codeApporteur = req.user.code_apporteur;
      if (!codeApporteur) {
        console.log('❌ Code apporteur manquant');
        return res.status(404).json({
          success: false,
          message: 'Souscription non trouvée'
        });
      }
      // Comparer avec String() pour éviter les problèmes de type
      subscriptionResult = await pool.query(
        "SELECT * FROM subscriptions WHERE id = $1 AND CAST(code_apporteur AS TEXT) = CAST($2 AS TEXT)",
        [id, codeApporteur]
      );
      console.log('🔍 Recherche avec code_apporteur:', codeApporteur, '- Trouvé:', subscriptionResult.rows.length);
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
        profession: clientInfo.profession || '',
        secteur_activite: clientInfo.secteur_activite || '',
        email: clientInfo.email || '',
        telephone: clientInfo.telephone || '',
        date_naissance: clientInfo.date_naissance || null,
        lieu_naissance: clientInfo.lieu_naissance || '',
        adresse: clientInfo.adresse || ''
      };
    } else {
      // Sinon, récupérer depuis la table users
      const userResult = await pool.query(
        "SELECT id, civilite, nom, prenom, profession, email, telephone, date_naissance, lieu_naissance, adresse FROM users WHERE id = $1",
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
    // ÉTAPE 4 : Récupérer les réponses au questionnaire médical
    // =========================================
    let questionnaireReponses = [];
    try {
      const questResult = await pool.query(
        `SELECT sq.id, sq.question_id, sq.reponse_oui_non, sq.reponse_text,
                sq.reponse_detail_1, sq.reponse_detail_2, sq.reponse_detail_3,
                qm.code, qm.libelle, qm.type_question, qm.ordre,
                qm.champ_detail_1_label, qm.champ_detail_2_label, qm.champ_detail_3_label
         FROM souscription_questionnaire sq
         JOIN questionnaire_medical qm ON sq.question_id = qm.id
         WHERE sq.subscription_id = $1
         ORDER BY qm.ordre ASC`,
        [id]
      );
      questionnaireReponses = questResult.rows;
      console.log(`📋 QUESTIONNAIRE MÉDICAL: ${questionnaireReponses.length} réponses récupérées pour souscription ${id}`);
      if (questionnaireReponses.length > 0) {
        console.log('📝 Détail questionnaire:');
        questionnaireReponses.forEach((row, idx) => {
          console.log(`  ${idx + 1}. "${row.libelle}" → ${row.reponse_oui_non || row.reponse_text || 'N/A'}`);
        });
      }
    } catch (e) {
      console.log('⚠️ Pas de questionnaire médical pour cette souscription ou erreur:', e.message);
    }

    // =========================================
    // ÉTAPE 5 : Enrichir avec les infos de paiement (Wave/OM/etc.)
    // =========================================
    let enrichedSubscription = subscription;
    try {
      const latestPaymentResult = await pool.query(
        `SELECT transaction_id, provider, montant, statut, created_at, session_id, api_response
         FROM payment_transactions
         WHERE subscription_id = $1
         ORDER BY created_at DESC
         LIMIT 1`,
        [id]
      );

      if (latestPaymentResult.rows.length > 0) {
        const latestPayment = latestPaymentResult.rows[0];
        const currentData = enrichedSubscription.souscriptiondata || {};
        const currentPaymentInfo = currentData.payment_info || {};
        const apiResponse = latestPayment.api_response || {};

        const totalsResult = await pool.query(
          `SELECT COALESCE(SUM(montant), 0) AS total_paid
           FROM payment_transactions
           WHERE subscription_id = $1
             AND LOWER(statut) IN (
               'success', 'succeeded', 'paid', 'completed',
               'validated', 'confirmed', 'ok',
               'validé', 'validée', 'confirmé', 'confirmée'
             )`,
          [id]
        );

        const totalPaid = Number(totalsResult.rows[0]?.total_paid || 0);

        const pick = (obj, paths = []) => {
          for (const path of paths) {
            const value = path
              .split('.')
              .reduce((acc, key) => (acc && acc[key] !== undefined ? acc[key] : undefined), obj);
            if (value !== undefined && value !== null && `${value}` !== '') return value;
          }
          return null;
        };

        const providerPaymentId =
          pick(apiResponse, [
            'payment_id',
            'provider_payment_id',
            'id',
            'transaction_id',
            'sessionId',
            'session_id',
            'data.payment_id',
            'data.provider_payment_id',
            'data.id',
            'data.transaction_id',
            'data.sessionId',
            'data.session_id',
            'apiResponse.payment_id',
            'apiResponse.provider_payment_id',
            'apiResponse.id',
            'apiResponse.transaction_id',
            'apiResponse.data.payment_id',
            'apiResponse.data.provider_payment_id',
            'apiResponse.data.id',
            'apiResponse.data.transaction_id',
          ]) ||
          latestPayment.session_id ||
          latestPayment.transaction_id ||
          null;

        const mergedPaymentInfo = {
          ...currentPaymentInfo,
          payment_method:
            latestPayment.provider ||
            currentPaymentInfo.payment_method ||
            enrichedSubscription.payment_method ||
            null,
          transaction_id:
            latestPayment.transaction_id ||
            currentPaymentInfo.transaction_id ||
            null,
          payment_id:
            providerPaymentId ||
            currentPaymentInfo.payment_id ||
            currentPaymentInfo.provider_payment_id ||
            null,
          payment_date:
            latestPayment.created_at ||
            currentPaymentInfo.payment_date ||
            enrichedSubscription.date_validation ||
            null,
          payment_success:
            typeof currentPaymentInfo.payment_success === 'boolean'
              ? currentPaymentInfo.payment_success
              : (latestPayment.statut || '').toString().toUpperCase() === 'SUCCESS',
          amount:
            latestPayment.montant ||
            currentPaymentInfo.amount ||
            enrichedSubscription.montant ||
            null,
          montant_encaisse: totalPaid,
          total_paid: totalPaid,
          provider_status:
            latestPayment.statut ||
            currentPaymentInfo.provider_status ||
            null,
          session_id:
            latestPayment.session_id ||
            currentPaymentInfo.session_id ||
            null,
        };

        enrichedSubscription = {
          ...enrichedSubscription,
          montant_encaisse: totalPaid,
          total_paid: totalPaid,
          payment_transaction_id: latestPayment.transaction_id || latestPayment.session_id || enrichedSubscription.payment_transaction_id || null,
          souscriptiondata: {
            ...currentData,
            payment_info: mergedPaymentInfo,
            paiement: {
              ...currentData.paiement,
              ...mergedPaymentInfo,
            },
            montant_encaisse: totalPaid,
            total_paid: totalPaid,
          },
        };
      }
    } catch (paymentInfoError) {
      console.warn('⚠️ Impossible d\'enrichir les infos de paiement:', paymentInfoError.message);
    }

    // =========================================
    // ÉTAPE 6 : Retourner les deux ensembles de données
    // =========================================
    console.log(`\n✅ RETOUR COMPLET: subscription + user + ${questionnaireReponses.length} questionnaire_reponses`);
    res.json({ 
      success: true, 
      data: {
        subscription: {
          ...enrichedSubscription,
          questionnaire_reponses: questionnaireReponses  // ← Inclure dans subscription
        },
        user: userData,                       // Données de l'utilisateur formatées
        questionnaire_reponses: questionnaireReponses  // Aussi au top level pour compatibilité
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

    console.log('📄 getSubscriptionPDF - Demande PDF pour souscription:', id);
    console.log('👤 Utilisateur:', { userId, userRole, codeApporteur });

    // Récupérer la souscription
    // Si c'est un admin, accès à toutes les souscriptions
    // Si c'est un commercial, vérifier le code_apporteur
    // Si c'est un client, vérifier user_id ou code_apporteur avec téléphone correspondant
    let subResult;
    if (userRole === 'admin' || userRole === 'superadmin' || userRole === 'super_admin') {
      console.log('✅ Admin détecté - Accès à toutes les souscriptions');
      // Les admins peuvent voir toutes les souscriptions
      subResult = await pool.query(
        "SELECT * FROM subscriptions WHERE id = $1",
        [id]
      );
    } else if (userRole === 'commercial' && codeApporteur) {
      console.log('✅ Commercial détecté - Vérification code_apporteur');
      subResult = await pool.query(
        "SELECT * FROM subscriptions WHERE id = $1 AND code_apporteur = $2",
        [id, codeApporteur]
      );
    } else {
      console.log('✅ Client détecté - Vérification user_id');
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
    
    console.log('📊 Résultat requête:', subResult.rows.length, 'souscription(s) trouvée(s)');
    
    if (subResult.rows.length === 0) {
      console.log('❌ Souscription non trouvée pour l\'utilisateur');
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
        adresse: clientInfo.adresse || '',
        profession: clientInfo.profession || '',
        secteur_activite: clientInfo.secteur_activite || ''
      };
    } else if (subscription.user_id) {
      // Récupérer depuis la table users
      const userResult = await pool.query(
        `SELECT 
          id, 
          role,
          civilite, 
          nom, 
          prenom, 
          email, 
          telephone, 
          date_naissance::text as date_naissance,
          COALESCE(lieu_naissance, '')::text as lieu_naissance,
          adresse,
          COALESCE(profession, '') as profession,
          COALESCE(secteur_activite, '') as secteur_activite
        FROM users 
        WHERE id = $1`,
        [subscription.user_id]
      );
      user = userResult.rows[0] || {};
      // Si l'utilisateur récupéré est un commercial (souscription créée par lui-même sans client_info),
      // ne pas afficher son email personnel dans le PDF du client
      if (subscription.code_apporteur && user.role === 'commercial') {
        user.email = '';
      }
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
    const isEpargneBonus = productName.includes('epargne') && productName.includes('bonus');
    const isAssurePrestige = productName.includes('assure') || productName.includes('prestige');
    const isBonPlan = productName.includes('bon') && productName.includes('plan');
    
    const TITLE = isEtude ? 'CORIS ETUDE'
      : isRetraite ? 'CORIS RETRAITE'
      : isSerenite ? 'CORIS SERENITE'
      : isEmprunteur ? 'FLEX EMPRUNTEUR'
      : isFamilis ? 'CORIS FAMILIS'
      : isSolidarite ? 'CORIS SOLIDARITE'
      : isEpargne ? 'CORIS EPARGNE BONUS'
      : isAssurePrestige ? 'CORIS ASSURE PRESTIGE'
      : isBonPlan ? 'MON BON PLAN CORIS'
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
    drawRow(startX, curY, fullW, rowH * 5.2);
    
    // Ligne 1: Nom et Prénom / Téléphone
    write('Nom et Prénom', startX + 5, curY + 3, 9, '#666', 120);
    write(`${safe(usr.nom)} ${safe(usr.prenom)}`, startX + 130, curY + 3, 9, '#000', 200);
    write('Téléphone', startX + 340, curY + 3, 9, '#666', 70);
    write(usr.telephone || '', startX + 415, curY + 3, 9, '#000', 115);
    
    // Ligne 2: Email
    write('Email', startX + 5, curY + 3 + 13, 9, '#666', 120);
    write(usr.email || 'Non renseigné', startX + 130, curY + 3 + 13, 9, '#000', 400);
    
    // Ligne 3: Date de naissance / Lieu de naissance
    write('Date de naissance', startX + 5, curY + 3 + 26, 9, '#666', 120);
    const dateNaissanceFormatee = formatDate(usr.date_naissance);
    write(dateNaissanceFormatee || 'Non renseigné', startX + 130, curY + 3 + 26, 9, '#000', 180);
    write('Lieu de naissance', startX + 320, curY + 3 + 26, 9, '#666', 120);
    write(usr.lieu_naissance || 'Non renseigné', startX + 445, curY + 3 + 26, 9, '#000', 90);
    
    // Ligne 4: Adresse / Profession / Secteur d'activité
    write('Adresse', startX + 5, curY + 3 + 39, 9, '#666', 60);
    write(usr.adresse || '', startX + 70, curY + 3 + 39, 9, '#000', 155);
    write('Profession', startX + 230, curY + 3 + 39, 9, '#666', 60);
    write(usr.profession || '', startX + 295, curY + 3 + 39, 9, '#000', 110);
    write("Secteur d'act.", startX + 410, curY + 3 + 39, 9, '#666', 65);
    write(usr.secteur_activite || '', startX + 478, curY + 3 + 39, 9, '#000', 87);
    
    // Ligne 5: Contact d'urgence
    write('En cas d\'urgence', startX + 5, curY + 3 + 52, 9, '#666', 120);
    const contactUrgenceText = contactUrgence.nom ? `${contactUrgence.nom} - ${contactUrgence.contact || ''}` : 'Non renseigné';
    write(contactUrgenceText, startX + 130, curY + 3 + 52, 9, '#000', 400);
    
    curY += rowH * 5.2 + 5;

    // Période de garantie - Case grise
    drawRow(startX, curY, fullW, boxH, grisNormal);
    writeCentered('PÉRIODE DE GARANTIE', startX, curY + 4, fullW, 10, '#000000', true);
    curY += boxH + 5;
    
    // d est déjà défini plus haut dans la section Souscripteur
    const dateEffet = d.date_effet || d.date_debut || d.date_debut_garantie || '';
    let dateEcheance = d.date_echeance || d.date_fin || d.date_echeance_contrat || d.date_fin_garantie || '';
    const duree = d.duree || d.duree_contrat || '';
    const dureeType = d.duree_type || d.type_duree || 'mois';
    const periodicite = d.periodicite || d.mode_souscription || d.mode_paiement || '';
    
    // Calculer la date d'échéance si elle n'existe pas
    if (!dateEcheance && dateEffet && duree) {
      try {
        const dateEffetObj = new Date(dateEffet);
        const dureeNum = parseInt(duree);
        if (!isNaN(dateEffetObj.getTime()) && !isNaN(dureeNum)) {
          if (dureeType === 'ans' || dureeType === 'Années' || dureeType === 'années' || dureeType === 'an') {
            dateEffetObj.setFullYear(dateEffetObj.getFullYear() + dureeNum);
          } else {
            dateEffetObj.setMonth(dateEffetObj.getMonth() + dureeNum);
          }
          dateEcheance = dateEffetObj.toISOString();
          console.log('✅ Date échéance calculée:', dateEcheance);
        }
      } catch (e) {
        console.log('❌ Erreur calcul date échéance:', e.message);
      }
    }

    // Calculer la durée en mois si nécessaire
    let dureeMois = duree;
    let dureeAffichee = '';
    if (duree) {
      if (dureeType === 'ans' || dureeType === 'Années' || dureeType === 'années' || dureeType === 'an') {
        dureeMois = parseInt(duree) * 12;
        dureeAffichee = `${duree} ans`;
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
    
    // Pour Coris Assure Prestige : affichage spécifique
    if (isAssurePrestige) {
      const versementInitial = d.versement_initial || 0;
      const fraisAccessoires = 0; // Pas de frais accessoires pour Coris Assure Prestige
      const primeTotal = versementInitial + fraisAccessoires;
      
      drawRow(startX, curY, fullW, rowH * 2);
      
      // Ligne 1: Versement Initial / Taux d'intérêt Net
      write('Versement Initial', startX + 5, curY + 3, 9, '#666', 130);
      write(money(versementInitial), startX + 145, curY + 3, 9, '#000', 150);
      write("Taux d'intérêt Net", startX + 305, curY + 3, 9, '#666', 100);
      write('3,500%', startX + 410, curY + 3, 9, '#000', 125);
      
      // Ligne 2: Frais Accessoires / Prime Total
      write('Frais Accessoires', startX + 5, curY + 3 + 13, 9, '#666', 130);
      write(money(fraisAccessoires), startX + 145, curY + 3 + 13, 9, '#000', 150);
      write("Prime Total", startX + 305, curY + 3 + 13, 9, '#666', 100);
      write(money(primeTotal), startX + 410, curY + 3 + 13, 9, '#000', 125);
      
      curY += rowH * 2 + 5;
    } else if (isBonPlan) {
      // Pour Mon Bon Plan Coris : affichage avec Versement Initial et Capital Décès
      const montantCotisation = d.montant_cotisation || primeNette;
      
      drawRow(startX, curY, fullW, rowH * 2);
      
      // Ligne 1: Versement Initial / Taux d'intérêt Net
      write('Versement Initial', startX + 5, curY + 3, 9, '#666', 130);
      write(money(montantCotisation), startX + 145, curY + 3, 9, '#000', 150);
      write("Taux d'intérêt Net", startX + 305, curY + 3, 9, '#666', 100);
      write('3,500%', startX + 410, curY + 3, 9, '#000', 125);
      
      // Ligne 2: Capital Décès (garantie fixe de 120000F)
      write('Capital Décès', startX + 5, curY + 3 + 13, 9, '#666', 130);
      write(money(120000), startX + 145, curY + 3 + 13, 9, '#000', 150);
      
      curY += rowH * 2 + 5;
    } else {
      // Déterminer le nombre de lignes nécessaires
      let caracteristiquesLignes = 1;
      if (isEtude && d.rente_calculee) caracteristiquesLignes++;
      else if (isRetraite && (d.capital || d.capital_garanti)) caracteristiquesLignes++;
      else if (isSerenite && d.rente_calculee) caracteristiquesLignes++;
      else if ((isSolidarite || isFamilis || isEmprunteur) && (d.capital || d.capital_garanti)) caracteristiquesLignes++;
      else if (isEpargne && (d.capital || d.capital_garanti)) caracteristiquesLignes++;
      
      // Pour Coris Solidarité, ajouter 2 lignes supplémentaires pour les membres (conjoints+enfants, ascendants)
      if (isSolidarite) caracteristiquesLignes += 2;
      
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
      
      // Ligne 3: Nombre de membres pour Coris Solidarité
      if (isSolidarite) {
        const nbConjoints = Array.isArray(d.conjoints) ? d.conjoints.length : 0;
        const nbEnfants = Array.isArray(d.enfants) ? d.enfants.length : 0;
        const nbAscendants = Array.isArray(d.ascendants) ? d.ascendants.length : 0;
        
        write('Nombre de conjoints', startX + 5, curY + 3 + 26, 9, '#666', 130);
        write(nbConjoints.toString(), startX + 145, curY + 3 + 26, 9, '#000', 150);
        write('Nombre d\'enfants', startX + 305, curY + 3 + 26, 9, '#666', 100);
        write(nbEnfants.toString(), startX + 410, curY + 3 + 26, 9, '#000', 125);
        
        // Ligne 4: Nombre d'ascendants
        write('Nombre d\'ascendants', startX + 5, curY + 3 + 39, 9, '#666', 130);
        write(nbAscendants.toString(), startX + 145, curY + 3 + 39, 9, '#000', 150);
      }
      
      curY += rowH * caracteristiquesLignes + 5;
    }

    // Garanties - Adapté selon le produit
    // Pré-calculer le nombre de lignes de garanties avant de créer l'en-tête
    let garantiesLignes = 0;
    const capitalDeces = d.capital || d.capital_garanti || d.capital_deces || 0;
    const capitalVie = d.capital_garanti || d.capital || 0;
    
    // Compter les lignes de garanties selon le produit
    if (isAssurePrestige) {
      // Coris Assure Prestige : Capital décès + Prime décès
      if (capitalDeces > 0) garantiesLignes++;
      if (d.prime_deces_annuelle || d.prime_annuelle) garantiesLignes++;
    } else if (isBonPlan) {
      // Mon Bon Plan Coris : Pas de section Garanties (Capital Décès déjà dans Caractéristiques)
      garantiesLignes = 0;
    } else if (isEtude) {
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
      // Coris Assure Prestige : Capital décès + Prime décès
      else if (isAssurePrestige) {
        const primeDecesAnnuelle = d.prime_deces_annuelle || d.prime_annuelle || 0;
        
        // Ligne 1: Capital décès avec sa valeur
        if (capitalDeces > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Capital Décès', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(capitalDeces), startX + 200, curY + 4, 165, 9);
          writeCentered('', startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
        
        // Ligne 2: Prime décès annuelle avec sa valeur
        if (primeDecesAnnuelle > 0) {
          drawRow(startX, curY, fullW, rowH);
          write('Prime Décès Annuelle', startX + 5, curY + 4, 9, '#000', 185);
          writeCentered(money(primeDecesAnnuelle), startX + 200, curY + 4, 165, 9);
          writeCentered('', startX + 365, curY + 4, 170, 9);
          curY += rowH;
          garantiesLignes++;
        }
      }
      // Mon Bon Plan Coris : Pas d'affichage (Capital Décès déjà dans Caractéristiques)
      else if (isBonPlan) {
        // Rien à afficher ici
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
    // Pour Coris Assure Prestige et Mon Bon Plan : Prime Nette = Versement Initial
    const primeNetteAffichee = (isAssurePrestige || isBonPlan) ? (d.versement_initial || d.montant_versement || d.montant_cotisation || primeNette) : primeNette;
    
    // Prime Totale = Prime Nette + Accessoires
    const primeTotaleAffichee = primeNetteAffichee + accessoiresMontant;
    
    drawRow(startX, curY, primeBoxW, rowH * 1.5);
    writeCentered('Prime Nette', startX, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(primeNetteAffichee), startX, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    drawRow(startX + primeBoxW, curY, primeBoxW, rowH * 1.5);
    writeCentered('Accessoires', startX + primeBoxW, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(accessoiresMontant), startX + primeBoxW, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
    drawRow(startX + primeBoxW * 2, curY, primeBoxW, rowH * 1.5);
    writeCentered('Prime Totale', startX + primeBoxW * 2, curY + 3, primeBoxW, 8, '#666');
    writeCentered(money(primeTotaleAffichee), startX + primeBoxW * 2, curY + 3 + 11, primeBoxW, 8, '#000', true);
    
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

    // Date et lieu - Séparé de la mention légale
    const dateContrat = new Date().toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' });
    doc.fontSize(8).fillColor('#000000').text(`Fait à Abidjan, le ${dateContrat} en 2 Exemplaires`, startX, curY, { width: fullW, align: 'left' });
    curY += 10;

    // Bloc "Contrat saisi par / Apporteur"
    {
      const assistance = subscription.souscriptiondata?.assistance_commerciale || {};
      const isAideParCommercial = assistance.is_aide_par_commercial === true;
      const hasCodeApporteur = !!subscription.code_apporteur;
      const clientNomComplet = `${user.prenom || ''} ${user.nom || ''}`.trim();

      let contratSaisiPar = clientNomComplet;
      let apporteurLabel = '';

      if (hasCodeApporteur && !isAideParCommercial) {
        // Commercial a saisi lui-même → chercher son nom dans users
        let commercialNom = '';
        try {
          const commResult = await pool.query(
            'SELECT nom, prenom FROM users WHERE code_apporteur = $1 LIMIT 1',
            [subscription.code_apporteur]
          );
          if (commResult.rows.length > 0) {
            const c = commResult.rows[0];
            commercialNom = `${c.prenom || ''} ${c.nom || ''}`.trim();
          }
        } catch (e) { /* ignore */ }
        // Si le nom du commercial est trouvé, on l'utilise ; sinon on met le code apporteur
        contratSaisiPar = commercialNom || `Commercial (${String(subscription.code_apporteur).trim()})`;
        apporteurLabel = String(subscription.code_apporteur).trim();
      } else if (isAideParCommercial) {
        // Client aidé par un commercial
        const commNom = assistance.commercial_nom_prenom || '';
        const commCode = assistance.commercial_code_apporteur || '';
        apporteurLabel = [commNom, commCode].filter(Boolean).join(' - ');
      }
      // Sinon client seul → pas d'apporteur

      const boxH = 22;
      doc.rect(startX, curY, fullW, boxH).stroke();
      doc.fontSize(7.5).fillColor('#000000').font('Helvetica-Bold');
      doc.text(`Contrat saisi par : ${contratSaisiPar}`, startX + 4, curY + 6, { width: fullW / 2 - 8, align: 'left' });
      if (apporteurLabel) {
        doc.text(`Apporteur : ${apporteurLabel}`, startX + fullW / 2 + 4, curY + 6, { width: fullW / 2 - 8, align: 'left' });
      }
      doc.font('Helvetica');
      curY += boxH + 4;
    }

    // Espaces pour signatures (2 colonnes: Souscripteur et Compagnie) - Alignés et compacts
    const sigWidth = 260;
    const sigGap = 15;
    const sigStartX = startX;
    const sigHeight = 42; // Hauteur réduite pour tenir sur une page
    
    // Labels au-dessus des zones de signature
    doc.fontSize(7).fillColor('#000000').text('Le Souscripteur', sigStartX, curY, { width: sigWidth, align: 'center' });
    doc.fontSize(7).fillColor('#000000').text('La Compagnie', sigStartX + sigWidth + sigGap, curY, { width: sigWidth, align: 'center' });
    curY += 8; // Espacement réduit entre les labels et les zones
    
    const sigY = curY; // Position des zones de signature

    // Dessiner les deux cases pour signatures - Même largeur pour alignement
    drawRow(sigStartX, sigY, sigWidth, sigHeight);
    drawRow(sigStartX + sigWidth + sigGap, sigY, sigWidth, sigHeight);
    
    // Afficher la signature du client si elle existe
    const signaturePath = subscription.souscriptiondata?.signature_path;
    if (signaturePath) {
      const absoluteSignaturePath = path.join(process.cwd(), signaturePath);
      if (exists(absoluteSignaturePath)) {
        try {
          console.log('📝 Chargement signature depuis:', absoluteSignaturePath);
          
          // Padding équilibré pour masquer les bordures tout en gardant la signature visible
          const sigPadding = 6;
          const maxWidth = sigWidth - (sigPadding * 2);
          const maxHeight = sigHeight - (sigPadding * 2);
          
          // Insérer la signature en conservant les proportions (fit) pour éviter la distorsion
          doc.image(absoluteSignaturePath, 
            sigStartX + sigPadding, 
            sigY + sigPadding, 
            { 
              fit: [maxWidth, maxHeight],
              align: 'center',
              valign: 'center'
            }
          );
          console.log('✅ Signature client ajoutée au PDF (zone: ' + maxWidth + 'x' + maxHeight + 'px)');
        } catch (error) {
          console.log('❌ Erreur chargement signature client:', error.message);
        }
      } else {
        console.log('⚠️ Fichier signature introuvable:', absoluteSignaturePath);
      }
    }

    // Tampon de la compagnie (si disponible) - Plus petit et centré
    const stampPaths = [
      path.join(process.cwd(), 'assets', 'stamp_coris.png'),
      path.join(process.cwd(), 'assets', 'images', 'stamp_coris.png'),
      path.join(__dirname, '..', 'assets', 'stamp_coris.png'),
    ];
    for (const stampPath of stampPaths) {
      if (exists(stampPath)) {
        try {
          doc.image(stampPath, sigStartX + sigWidth + sigGap + 60, sigY + 3, { width: 50 });
          console.log('✅ Tampon chargé depuis:', stampPath);
          break;
        } catch (e) {
          console.log('❌ Erreur chargement tampon depuis', stampPath, ':', e.message);
        }
      }
    }

    curY = sigY + sigHeight + 12;

    // Footer en position absolue en bas de page (ne consomme plus d'espace de contenu)
    const footerText = "CORIS ASSURANCES VIE COTE D'IVOIRE-SA - régie par le code CIMA au capital social de 5.000.000.000 FCFA entièrement libéré. RCM: CI-ABJ-03-2824-B14-00013, NCC: 2400326 R, Compte: Cl166- 01001- 008904724101- 72, Plateau Bd de la République, Rue n°23 Angle Avenue Marchand, IMM CBI, 01BP4690 ABIDJAN - Tél: +225 27 20 15 65 - Email : corisvie-ci@coris-assurances.com";
    const footerTextHeight = doc.heightOfString(footerText, { width: fullW, align: 'center', lineGap: 1 });
    const footerTextY = doc.page.height - 28 - footerTextHeight;
    const footerLineY = footerTextY - 6;
    doc.lineWidth(1).moveTo(startX, footerLineY).lineTo(startX + fullW, footerLineY).stroke('#000000');
    doc.fontSize(6).fillColor('#000000').font('Helvetica');
    doc.text(footerText, startX, footerTextY, { width: fullW, align: 'center', lineGap: 1 });
    console.log('✅ Footer absolu ajouté à y =', footerTextY, '/ page height:', doc.page.height);

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
      
      // Page 3 : Conditions générales pour CORIS SOLIDARITÉ
      doc.addPage();
      curY = 30;
      
      // Titre centré
      doc.fontSize(11).fillColor('#000000').font('Helvetica-Bold');
      doc.text('Résumé des conditions générales', startX, curY, { width: fullW, align: 'center' });
      curY += 12;
      doc.fontSize(9).font('Helvetica-Oblique');
      doc.text('(Valant notice d\'information)', startX, curY, { width: fullW, align: 'center' });
      curY += 16;

      // Article 1
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 1 : Objet du contrat', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le contrat CORIS SOLIDARITE est un contrat collectif d\'assurance vie à adhésion facultative et cotisations définies.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('Il garantit, en cas de décès ou de Perte Totale et Irréversible d\'Autonomie de l\'assuré (PTIA), pendant la durée du contrat, le versement d\'un capital forfaitaire défini à la souscription au(x) bénéficiaire(s) désigné(s) au contrat qui est destiné à couvrir les frais funéraires exposés lors du décès de l\'un des membres de la famille assurée.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 24;
      
      // Article 2
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 2 : Conditions d\'adhésion - Durée', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('L\'adhésion est réservée à toutes personnes physiques âgées de moins de soixante-quatre (64) ans, qui souhaitent garantir une meilleure prise en charge des obsèques de leurs proches sans se ruiner.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      doc.text('Le groupe familial de base assuré est composé :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• du souscripteur : qui est l\'assuré principal qui signe le contrat et paie les primes. Il est propriétaire du contrat d\'assurance ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• d\'un (1) conjoint du souscripteur ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• de six (06) enfants mineurs du souscripteur reconnus, âgés de 12 ans minimum et de 21 ans maximum à la date de souscription, sans activité rémunérée, et non mariés ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 14;
      doc.text('Le contrat offre en option la possibilité au souscripteur d\'incorporer des adhérents tels que les ascendants directs (père et mère) du souscripteur et/ou de son conjoint, les enfants et conjoints supplémentaires.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.text('Le groupe familial assuré est composé au maximum de quatre (04) personnes âgées de plus de 65 ans et de moins de soixante-dix (70) ans.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      doc.text('L\'adhésion est conclue pour une durée initiale d\'une (1) année et se renouvelle par tacite reconduction jusqu\'au 70ème anniversaire de l\'adhérent.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 18;
      
      // Article 3
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 3 : Paiement de la prime', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le montant de la cotisation est fonction du capital garanti et payable par tout moyen à votre convenance (espèces, chèque, virement bancaire, prélèvement à la source, moyens électroniques). La périodicité peut être mensuelle, trimestrielle, semestrielle, annuelle.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 24;
      
      // Article 4
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 4 : Renonciation', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le souscripteur peut renoncer au contrat dans le délai de trente (30) jours à compter du paiement de la première cotisation, par lettre recommandée avec avis de réception ou tout autre moyen faisant foi de la réception. Il lui est alors restitué les cotisations versées déduction faite des coûts de police dans un délai maximal de quinze (15) jours à compter de la date de réception de ladite renonciation. Au-delà de ce délai, les sommes non restituées produisent de plein droit un intérêt de retard de 2,5% par mois indépendamment de toute réclamation.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 5
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 5 : Rachat -Reduction', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le contrat CORIS SOLIDARITE est une assurance temporaire en cas de décès donc dépourvu de valeur de réduction ou de rachat et ne peut donner droit à aucune avance.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 18;
      
      // Article 6
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 6 : Garanties du contrat', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('En cas décès ou de Perte Totale et Irréversible d\'Autonomie d\'un membre de la famille assurée pendant la période de garantie: le versement d\'un capital dont le montant est défini à la souscription au(x) bénéficiaire(s) désigné(s) au contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 14;
      doc.text('Le souscripteur assuré principale, à sa demande et pour une notification du décès d\'un membre de la famille assurée sous soixante-douze (72) heures reçoit de celui-ci un bon de prise en charge auprès du réseau des professionnels de pompes funèbres de CORIS ASSURANCES VIE CI selon l\'option de garantie souscrite. Ce contrat offre quatre (04) options de capitaux garantis à savoir : 500 000 F CFA ; 1 000 000 F CFA ; 1 500 000 F CFA ; 2 000 000 F CFA.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 24;
      doc.text('Le souscripteur, en accord avec l\'assureur, a la possibilité de modifier, à chaque date d\'anniversaire du contrat, le montant du capital garanti. Cette modification impacte la prime et sera matérialisée par un avenant au contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 22;
      
      // Article 7 (Délai de Carence)
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 7 : Délai de Carence', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Un délai de quatre-vingt-dix (90) jours francs est observé entre la date de paiement de la première prime et la prise d\'effet de toutes les garanties. Pendant ce délai, seuls les décès accidentels sont couverts.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 18;
      
      // Article 8 (Paiement des sommes assurées)
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 8 : Paiement des sommes assurées', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('En cas de décès ou PTIA : l\'original de votre contrat ; l\'extrait d\'acte de décès ; la fiche d\'état civil du (ou des) bénéficiaire(s) désignée(s) ; la fiche d\'état civil du (ou des) de l\'assuré.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 12;
      doc.text('La délivrance du bon de prise en charge est soumise à la présentation de la déclaration de décès (constat de décès par un agent médical habilité) de l\'assuré ; copie de votre contrat ; la fiche d\'état civil du (ou des) bénéficiaire(s) désignée(s) ; la fiche d\'état civil du (ou des) de l\'assuré.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 14;
      doc.text('En cas de pluralité de bénéficiaires notre paiement intervient sur quittance conjointe des intéressés', startX, curY, { width: fullW, lineGap: 1 });
      curY += 20;
      
      // Article 9
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 9 : Cessation des garanties', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Pour chaque assuré autre qu\'un Enfant Assuré, la garantie prend fin :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• au décès de l\'assuré ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• à la prochaine échéance suivant le décès du Souscripteur ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• au 70ième anniversaire de l\'assuré ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• en cas de résiliation du contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 12;
      doc.text('Pour chaque Enfant Assuré, les garanties prennent fin :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• au décès de l\'Enfant Assuré ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• au 21ième anniversaire de l\'Enfant assuré ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• à la prochaine échéance suivant le décès du Souscripteur/l\'Assuré principal;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('• en cas de résiliation du contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 18;
      
      // Article 10
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 10 : Participation aux bénéfices', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Conformément aux dispositions de l\'article 81 du Code des Assurances CIMA, les contrats collectifs en cas de décès ne bénéficient pas de la clause de participation bénéficiaire.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 18;
      
      // Article 11
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 11 : Exclusions', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('L\'assureur garantit tous les risques de décès et de Perte Totale et Irréversible d\'Autonomie quelles qu\'en soient la cause et les circonstances sous réserve des dispositions suivantes :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 12;
      doc.text('• L\'assurance en cas de décès est nulle d\'effet si l\'assuré se donne volontairement et consciencieusement la mort au cours des deux (2) premières années de son adhésion ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 12;
      doc.text('• En cas de guerre civile ou étrangère, les risques ne pourront être couverts qu\'aux conditions déterminées par la législation (art.94 du code CIMA) ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 12;
      doc.text('• L\'assureur couvre les risques de décès résultant d\'un accident de navigation aérienne à condition que l\'appareil soit pourvu d\'un certificat valable de navigation ou si le pilote qui peut être l\'assuré lui-même effectue un vol autorisé par son brevet ou sa licence. Sont toutefois exclus : les actes terroristes, les compétitions, records ou tentatives de records, les vols acrobatiques, d\'apprentissages ou sur prototypes.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 12 (Non-paiement des primes)
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 12 : Non-paiement des primes', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('L\'assureur n\'a pas d\'action pour exiger le paiement des primes afférentes aux contrats d\'assurance vie ou de capitalisation.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 10;
      doc.text('Lorsqu\'une prime ou une fraction de prime n\'est pas payée dans les dix (10) jours de son échéance, l\'assureur adresse au contractant une lettre recommandée, par laquelle il l\'informe qu\'à l\'expiration d\'un délai de quarante (40) jours à dater de l\'envoi de cette lettre, le défaut de paiement entraîne soit la résiliation du contrat en cas d\'inexistence ou d\'insuffisance de la valeur de rachat, soit la réduction du contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 13 (Incorporation ou retrait)
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 13 : Incorporation ou retrait d\'adhérent', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le souscripteur a la possibilité d\'incorporer ou de retirer les membres de sa famille conformément aux conditions d\'adhésion ci-dessus.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 18;
      
      // Article 14 (Prescription)
      doc.fontSize(7).font('Helvetica-Bold');
      doc.text('Article 14 : Prescription', startX, curY, { width: fullW });
      curY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Comme le stipule l\'article 28 du Code des assurances de la Conférence Interafricaine des Marchés d\'Assurances (CIMA), toute action dérivant de ce présent contrat est prescrite par dix (10) ans, à compter de la date de survenance de l\'évènement qui y donne naissance.', startX, curY, { width: fullW, lineGap: 1 });
      
      console.log('✅ Page 3 ajoutée pour Coris Solidarité avec conditions générales');
    }

    // Pour Coris Sérénité : Ajouter une deuxième page avec les conditions générales
    if (isSerenite) {
      doc.addPage();
      curY = 30;
      
      // Titre centré
      doc.fontSize(12).fillColor('#000000').font('Helvetica-Bold');
      doc.text('Résumé des conditions générales', startX, curY, { width: fullW, align: 'center' });
      curY += 14;
      doc.fontSize(10).font('Helvetica-Oblique');
      doc.text('(Valant notice d\'information)', startX, curY, { width: fullW, align: 'center' });
      curY += 18;

      // Article 1
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 1 : Objet du contrat', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le contrat CORIS SERENITE PLUS est un contrat individuel d\'assurance vie à adhésion facultative et cotisations définies.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      doc.text('Il garantit, en cas de décès ou de Perte Totale et Irréversible d\'Autonomie de l\'assuré (PTIA), quelle que soit la date de survenance, le versement d\'un capital dont le montant est défini à la souscription au(x) bénéficiaire(s) désigné(s) au contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 20;
      
      // Article 2
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 2 : Adhésion', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('L\'adhésion est réservée à toutes personnes physiques âgées de plus dix-huit (18) ans et de moins de soixante-dix (70) ans et satisfaire aux formalités médicales.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 20;
      
      // Article 3
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 3 : Paiement de la prime', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le montant de la cotisation est fonction du capital garanti et de l\'âge de l\'assuré à la date d\'effet de la souscription et payable par tout moyen à votre convenance (espèces, chèque, virement bancaire, prélèvement à la source, moyens électroniques). La périodicité peut être mensuelle, trimestrielle, semestrielle, annuelle ou unique. Les frais de dossier unique sont fixés à 5 000 F CFA.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 4
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 4 : Rémunération du contrat', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Les cotisations nettes de frais sont capitalisées au taux d\'intérêt annuel de 3,5%. Le contrat prévoit chaque année l\'attribution d\'une participation aux bénéfices (PB) au moins égale à 90% des résultats techniques et 85% des résultats financiers et au minimum à 2% du résultat avant impôt de l\'exercice. La répartition de la participation aux bénéfices entre toutes les catégories de contrats se fait au prorata des provisions mathématiques moyennes de chaque catégorie.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 5 : Renonciation
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 5 : Renonciation', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le souscripteur peut renoncer au contrat dans le délai de trente (30) jours à compter du paiement de la première cotisation, par lettre recommandée avec avis de réception ou tout autre moyen faisant foi de la réception. Il lui est alors restitué les cotisations versées déduction faite des coûts de police dans un délai maximal de quinze (15) jours à compter de la date de réception de ladite renonciation. Au-delà de ce délai, les sommes non restituées produisent de plein droit un intérêt de retard de 2,5% par mois indépendamment de toute réclamation.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 6 : Rachat - Réduction
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 6 : Rachat - Réduction', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Après deux années effectives de cotisations ou de versement d\'au moins 15% des cotisations prévues sur toute la durée du contrat, le souscripteur peut mettre fin au contrat en contrepartie de la cessation de toutes les garanties. En cas de rachat, la valeur de rachat est égale à 95% de la provision mathématique de la deuxième à la cinquième année, plus 1% par année pour atteindre 100% à la fin de la dixième année. Le paiement de la valeur de rachat total met fin au contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      doc.text('Lorsque le souscripteur cesse de payer ses primes alors que le contrat a une valeur de rachat, les garanties du contrat CORIS SERENITE PLUS sont réévaluées et continuent pour des capitaux assurés réduits.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;

      // Article 7
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 7 : Rachat Partiel - Avances', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le rachat partiel et l\'avance ne sont pas autorisés.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      
      // Article 8
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 8 : Garanties du contrat', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('• à tout moment, après au moins deux primes annuelles ou 15% du cumul des primes prévues au contrat, le souscripteur peut disposer d\'une partie de ses cotisations en rachetant son contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.text('• En cas décès ou de Perte Totale et Irréversible d\'Autonomie pendant la période de garantie: le versement d\'un capital dont le montant est défini à la souscription au(x) bénéficiaire(s) désigné(s) au contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.text('Le souscripteur, en accord avec l\'assureur, a la possibilité de modifier, en cours de contrat, le montant du capital garanti. Cette modification impacte la prime et sera matérialisée par un avenant au contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      
      // Article 9
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 9 : Paiement des sommes assurées', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le paiement des sommes assurées est effectué à notre siège social, dans les 15 jours suivant la remise des pièces justificatives :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('En cas de rachat : ', startX, curY, { width: fullW, continued: true });
      doc.font('Helvetica').text('la lettre de demande de rachat du contrat ; l\'original de votre contrat et la fiche d\'état civil de l\'assuré ;', { lineGap: 1 });
      curY += 15;
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('En cas de décès : ', startX, curY, { width: fullW, continued: true });
      doc.font('Helvetica').text('l\'original de votre contrat ; le certificat de genre de mort ; l\'extrait d\'acte de décès ; la fiche d\'état civil du (ou des) bénéficiaire(s) désignée(s) ; la fiche d\'état civil du (ou des) de l\'assuré.', { lineGap: 1 });
      curY += 15;
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('En cas de Perte Totale et Irréversible d\'Autonomie : ', startX, curY, { width: fullW, continued: true });
      doc.font('Helvetica').text('l\'original de votre contrat ; le certificat médical constatant votre état d\'invalidité ; la (ou les) fiche(s) d\'état civil de la (ou des) personnes (s) désignée (s) comme bénéficiaire (s) ; l\'acte de naissance de l\'assuré.', { lineGap: 1 });
      curY += 18;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('En cas de pluralité de bénéficiaires notre paiement intervient sur quittance conjointe des intéressés', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      
      // Article 10 avec tableaux
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 10 : Valeurs minimum de rachats garanties', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Capital décès : 1 000 000 F CFA ; durée de cotisation de 25 ans ; un âge de 35 ans et une prime mensuelle de 1 698 F CFA.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      
      // Deux tableaux côte à côte
      const colWSmall = [32, 48, 48]; // Année, Cumul, Valeur
      const tableRowH = 16;
      const tableW = colWSmall[0] + colWSmall[1] + colWSmall[2];
      const spaceBetween = 10;
      const table1X = startX;
      const table2X = startX + tableW + spaceBetween;
      
      // Tableau 1 (années 1-4)
      let tableY = curY;
      
      // En-têtes tableau 1
      drawRow(table1X, tableY, colWSmall[0], tableRowH, grisNormal);
      writeCentered('Année', table1X, tableY + 6, colWSmall[0], 6.5, '#000', true);
      drawRow(table1X + colWSmall[0], tableY, colWSmall[1], tableRowH, grisNormal);
      writeCentered('Cumul\ncotisations', table1X + colWSmall[0], tableY + 3, colWSmall[1], 6, '#000', true);
      drawRow(table1X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH, grisNormal);
      writeCentered('Valeur\nde rachat', table1X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6, '#000', true);
      
      // En-têtes tableau 2
      drawRow(table2X, tableY, colWSmall[0], tableRowH, grisNormal);
      writeCentered('Année', table2X, tableY + 6, colWSmall[0], 6.5, '#000', true);
      drawRow(table2X + colWSmall[0], tableY, colWSmall[1], tableRowH, grisNormal);
      writeCentered('Cumul\ncotisations', table2X + colWSmall[0], tableY + 3, colWSmall[1], 6, '#000', true);
      drawRow(table2X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH, grisNormal);
      writeCentered('Valeur\nde rachat', table2X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6, '#000', true);
      
      tableY += tableRowH;
      
      // Données tableau 1
      const data1 = [
        ['1', '20\n377', '0'],
        ['2', '40 755', '29 261'],
        ['3', '61\n132', '44\n658'],
        ['4', '81\n509', '61\n177']
      ];
      
      // Données tableau 2
      const data2 = [
        ['5', '101\n886', '76\n897'],
        ['6', '122\n264', '93 708'],
        ['7', '142\n641', '110\n634'],
        ['8', '163 018', '128 628']
      ];
      
      // Afficher les données des deux tableaux en parallèle
      for (let i = 0; i < 4; i++) {
        // Tableau 1
        drawRow(table1X, tableY, colWSmall[0], tableRowH);
        writeCentered(data1[i][0], table1X, tableY + 6, colWSmall[0], 6.5);
        drawRow(table1X + colWSmall[0], tableY, colWSmall[1], tableRowH);
        writeCentered(data1[i][1], table1X + colWSmall[0], tableY + 3, colWSmall[1], 6);
        drawRow(table1X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH);
        writeCentered(data1[i][2], table1X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6);
        
        // Tableau 2
        drawRow(table2X, tableY, colWSmall[0], tableRowH);
        writeCentered(data2[i][0], table2X, tableY + 6, colWSmall[0], 6.5);
        drawRow(table2X + colWSmall[0], tableY, colWSmall[1], tableRowH);
        writeCentered(data2[i][1], table2X + colWSmall[0], tableY + 3, colWSmall[1], 6);
        drawRow(table2X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH);
        writeCentered(data2[i][2], table2X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6);
        
        tableY += tableRowH;
      }
      
      console.log('✅ Page 2 ajoutée pour Coris Sérénité avec résumé des conditions générales');
    }

    // Pour Coris Etude : Ajouter une deuxième page avec les conditions générales (basé sur Sérénité)
    if (isEtude) {
      doc.addPage();
      curY = 30;
      
      // Titre centré
      doc.fontSize(12).fillColor('#000000').font('Helvetica-Bold');
      doc.text('Résumé des conditions générales', startX, curY, { width: fullW, align: 'center' });
      curY += 14;
      doc.fontSize(10).font('Helvetica-Oblique');
      doc.text('(Valant notice d\'information)', startX, curY, { width: fullW, align: 'center' });
      curY += 18;

      // Article 1
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 1 : Objet du contrat', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le contrat CORIS ETUDE est un contrat individuel d\'assurance vie à adhésion facultative et cotisations définies.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      doc.text('Il permet aux parents ou tuteurs d\'enfants de garantir des rentes certaines, pendant une durée au choix ou d\'un capital, pour l\'éducation des enfants, en cas de vie, mais aussi en cas de décès ou de Perte Totale et Irréversible d\'Autonomie pendant la période de cotisation.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 20;
      
      // Article 2
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 2 : Adhésion', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('L\'adhésion est réservée à toutes personnes physiques âgées de plus dix-huit (18) ans et de moins de soixante-cinq (65) ans et satisfaire aux formalités médicales.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 20;
      
      // Article 3
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 3 : Versement des cotisations', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('La cotisation ne peut être inférieure à 10 000 F CFA par mois et payable par tout moyen à votre convenance (espèces, chèque, virement bancaire, prélèvement à la source, moyens électroniques). La périodicité peut être mensuelle, trimestrielle, semestrielle, annuelle ou unique. Les frais de dossier unique sont fixés à 5 000 F CFA. Le souscripteur a la possibilité de modifier sa prime à la date d\'anniversaire du contrat.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 4
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 4 : Rémunération du contrat', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Les cotisations nettes de frais sont capitalisées au taux d\'intérêt annuel de 3,5%. Le contrat prévoit chaque année l\'attribution d\'une participation aux bénéfices (PB) au moins égale à 90% des résultats techniques et 85% des résultats financiers et au minimum à 2% du résultat avant impôt de l\'exercice. La répartition de la participation aux bénéfices entre toutes les catégories de contrats se fait au prorata des provisions mathématiques moyennes de chaque catégorie.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 5 : Renonciation
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 5 : Renonciation', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le souscripteur peut renoncer au contrat dans le délai de trente (30) jours à compter du paiement de la première cotisation, par lettre recommandée avec avis de réception ou tout autre moyen faisant foi de la réception. Il lui est alors restitué les cotisations versées déduction faite des coûts de police dans un délai maximal de quinze (15) jours à compter de la date de réception de ladite renonciation. Au-delà de ce délai, les sommes non restituées produisent de plein droit un intérêt de retard de 2,5% par mois indépendamment de toute réclamation.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;
      
      // Article 6 : Rachat - Réduction (Article 5 dans le document fourni)
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 6 : Rachat -Reduction', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Après deux années effectives de cotisations ou de versement d\'au moins 15% des cotisations prévues sur toute la durée du contrat, le souscripteur peut mettre fin au contrat en contrepartie de la cessation de toutes les garanties. En cas de rachat, la valeur de rachat est égale à 95% de la provision mathématique de la deuxième à la cinquième année, plus 1% par année pour atteindre 100% à la fin de la dixième année.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      doc.text('Lorsque le souscripteur cesse de payer ses primes alors que le contrat a une valeur de rachat, les garanties du contrat CORIS ETUDE sont réévaluées et continuent pour des montants assurés réduits. Le rachat partiel n\'est pas autorisé.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 30;

      // Article 7 : Garanties du contrat (Article 6 dans le document fourni)
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 7 : Garanties du contrat', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('✓ En cas de vie au terme du différé : Versement d\'une rente certaine annuelle payable à terme échu sur une durée définie à la souscription (durée standard fixée à 5 ans).', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.text('✓ En cas décès ou de Perte Totale ou Irréversible d\'Autonomie pendant la durée de cotisation (différé) :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 14;
      doc.text('    Au moment du sinistre : versement d\'un capital dont le montant est égal à 50 % de la rente annuelle prévue au contrat ;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      doc.text('    A partir de la première date d\'anniversaire du contrat suivant le sinistre, et ce jusqu\'au terme du différé : versement de 50% de la rente annuelle définie à la souscription;', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      doc.text('    Au terme de la période de cotisation et ce jusqu\'au terme du contrat: versement de la rente annuelle payable à terme échu dont le montant a été défini à la souscription.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      
      // Article 8 : Avances (Article 7 dans le document fourni)
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 8 : Avances', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Dans la limite de la valeur de rachat de votre contrat, nous pouvons vous accorder des avances sur contrat. La demande d\'avance se fait au moyen d\'un écrit daté et signé ainsi qu\'une copie de la carte nationale d\'identité ou du passeport en cours de validité du souscripteur.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.text('L\'avance demandée n\'excède pas le 1/3 de votre compte épargne constituée. Les frais de dossier et le taux d\'intérêt de l\'avance sont définis dans le contrat d\'avance.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      
      // Article 9 : Paiement des sommes assurées (Article 8 dans le document fourni)
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 9 : Paiement des sommes assurées', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Le paiement des sommes assurées est effectué à notre siège social, dans les 15 jours suivant la remise des pièces justificatives :', startX, curY, { width: fullW, lineGap: 1 });
      curY += 15;
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('En cas de vie : ', startX, curY, { width: fullW, continued: true });
      doc.font('Helvetica').text('la lettre de demande de liquidation du contrat ; l\'original de votre contrat et la fiche d\'état civil de l\'assuré ;', { lineGap: 1 });
      curY += 15;
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('En cas de décès : ', startX, curY, { width: fullW, continued: true });
      doc.font('Helvetica').text('l\'original de votre contrat ; le certificat de genre de mort ; l\'extrait d\'acte de décès ; la fiche d\'état civil du (ou des) bénéficiaire(s) désignée(s) ; la fiche d\'état civil du (ou des) de l\'assuré.', { lineGap: 1 });
      curY += 15;
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('En cas de Perte Totale et Irréversible d\'Autonomie : ', startX, curY, { width: fullW, continued: true });
      doc.font('Helvetica').text('l\'original de votre contrat ; le certificat médical constatant votre état d\'invalidité ; la (ou les) fiche(s) d\'état civil de la (ou des) personnes (s) désignée (s) comme bénéficiaire (s) ; l\'acte de naissance de l\'assuré.', { lineGap: 1 });
      curY += 18;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('En cas de pluralité de bénéficiaires notre paiement intervient sur quittance conjointe des intéressés', startX, curY, { width: fullW, lineGap: 1 });
      curY += 25;
      
      // Article 10 avec tableaux (Article 9 dans le document fourni)
      doc.fontSize(7.5).font('Helvetica-Bold');
      doc.text('Article 10 : Valeurs minimum de rachats garanties', startX, curY, { width: fullW });
      curY += 9;
      doc.font('Helvetica').fontSize(6.5);
      doc.text('Rente annuelle de 600 000 FCFA payable pendant 5 ans ; durée de cotisation de 15 ans ; un âge de 35 ans et une prime mensuelle de 14 639 F CFA.', startX, curY, { width: fullW, lineGap: 1 });
      curY += 11;
      
      // Deux tableaux côte à côte
      const colWSmall = [32, 48, 48]; // Année, Cumul, Valeur
      const tableRowH = 16;
      const tableW = colWSmall[0] + colWSmall[1] + colWSmall[2];
      const spaceBetween = 10;
      const table1X = startX;
      const table2X = startX + tableW + spaceBetween;
      
      // Tableau 1 (années 1-4)
      let tableY = curY;
      
      // En-têtes tableau 1
      drawRow(table1X, tableY, colWSmall[0], tableRowH, grisNormal);
      writeCentered('Année', table1X, tableY + 6, colWSmall[0], 6.5, '#000', true);
      drawRow(table1X + colWSmall[0], tableY, colWSmall[1], tableRowH, grisNormal);
      writeCentered('Cumul\ncotisations', table1X + colWSmall[0], tableY + 3, colWSmall[1], 6, '#000', true);
      drawRow(table1X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH, grisNormal);
      writeCentered('Valeur\nde rachat', table1X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6, '#000', true);
      
      // En-têtes tableau 2
      drawRow(table2X, tableY, colWSmall[0], tableRowH, grisNormal);
      writeCentered('Année', table2X, tableY + 6, colWSmall[0], 6.5, '#000', true);
      drawRow(table2X + colWSmall[0], tableY, colWSmall[1], tableRowH, grisNormal);
      writeCentered('Cumul\ncotisations', table2X + colWSmall[0], tableY + 3, colWSmall[1], 6, '#000', true);
      drawRow(table2X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH, grisNormal);
      writeCentered('Valeur\nde rachat', table2X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6, '#000', true);
      
      tableY += tableRowH;
      
      // Données tableau 1 (Années 1-4)
      const data1 = [
        ['1', '175\n665', '0'],
        ['2', '351\n329', '239\n260'],
        ['3', '526\n994', '384\n155'],
        ['4', '702\n658', '534\n043']
      ];
      
      // Données tableau 2 (Années 5-8)
      const data2 = [
        ['5', '878\n323', '689\n103'],
        ['6', '1 053\n987', '849\n549'],
        ['7', '1 229\n652', '1 015\n575'],
        ['8', '1 405\n316', '1 187\n591']
      ];
      
      // Afficher les données des deux tableaux en parallèle
      for (let i = 0; i < 4; i++) {
        // Tableau 1
        drawRow(table1X, tableY, colWSmall[0], tableRowH);
        writeCentered(data1[i][0], table1X, tableY + 6, colWSmall[0], 6.5);
        drawRow(table1X + colWSmall[0], tableY, colWSmall[1], tableRowH);
        writeCentered(data1[i][1], table1X + colWSmall[0], tableY + 3, colWSmall[1], 6);
        drawRow(table1X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH);
        writeCentered(data1[i][2], table1X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6);
        
        // Tableau 2
        drawRow(table2X, tableY, colWSmall[0], tableRowH);
        writeCentered(data2[i][0], table2X, tableY + 6, colWSmall[0], 6.5);
        drawRow(table2X + colWSmall[0], tableY, colWSmall[1], tableRowH);
        writeCentered(data2[i][1], table2X + colWSmall[0], tableY + 3, colWSmall[1], 6);
        drawRow(table2X + colWSmall[0] + colWSmall[1], tableY, colWSmall[2], tableRowH);
        writeCentered(data2[i][2], table2X + colWSmall[0] + colWSmall[1], tableY + 3, colWSmall[2], 6);
        
        tableY += tableRowH;
      }
      
      console.log('✅ Page 2 ajoutée pour Coris Etude avec résumé des conditions générales');
    }

    // Pour Coris Retraite : Ajouter une deuxième page avec les conditions générales en 2 colonnes
    if (isRetraite) {
      doc.addPage();
      curY = 30;
      
      // Titre principal
      doc.font('Helvetica-Bold').fontSize(11);
      doc.text('Résumé des conditions générales', startX, curY, { width: fullW, align: 'center' });
      curY += 12;
      doc.font('Helvetica-Oblique').fontSize(9);
      doc.text('(Valant notice d\'information)', startX, curY, { width: fullW, align: 'center' });
      curY += 15;

      // Définir les colonnes
      const colWidth = (fullW - 15) / 2; // 15px d'espace entre colonnes
      const colLeftX = startX;
      const colRightX = startX + colWidth + 15;
      let leftY = curY;
      let rightY = curY;

      // COLONNE GAUCHE
      // Article 1
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 1 : Objet du contrat', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le contrat CORIS RETRAITE est un contrat individuel d\'assurance vie à adhésion facultative et cotisations définies.', colLeftX, leftY, { width: colWidth, lineGap: 0.5 });
      leftY += 14;
      doc.text('Il permet au souscripteur de se constituer une épargne complémentaire pour la retraite, totalement libérale ou convertible en rente certaine ou viagère au moment de son départ à la retraite. A cet effet, chaque souscripteur dispose d\'un Compte Individuel Retraite (C.I.R) alimenté par les cotisations nettes qui sont affectées.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 34;

      // Article 2
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 2 : Conditions d\'adhésion', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('L\'adhésion est réservée à toutes personnes physiques âgées de plus de dix-huit (18) ans et justifiant de leur capacité à payer les primes.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 21;

      // Article 3
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 3 : Versement des cotisations', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('La cotisation ne peut être inférieure à 10 000 F CFA par mois et est payable par tout moyen à votre convenance (espèces, chèque, virement bancaire, prélèvement à la source, moyens électroniques). La périodicité peut être mensuelle, trimestrielle, semestrielle, annuelle ou unique. Les frais de dossier unique sont fixés à 5 000 F CFA. Le souscripteur a la possibilité de modifier sa prime à tout moment pendant la durée de cotisation. Il existe deux types de versements :', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 39;
      doc.text('•  Versements réguliers : les cotisations sont versées suivant la périodicité définie aux conditions particulières jusqu\'au terme du contrat.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 16;
      doc.text('•  Versements libres : le souscripteur peut effectuer des versements libres complémentaires à tout moment. Il choisit librement les dates et les montants de ses versements.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 25;

      // Article 4
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 4 : Rémunération du contrat', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Les cotisations nettes de frais sont capitalisées au taux d\'intérêt annuel de 3,5%. Le contrat prévoit chaque année l\'attribution d\'une participation aux bénéfices (PB) au moins égale à 90% des résultats techniques et 85% des résultats financiers et au minimum à 2% du résultat avant impôt de l\'exercice. La répartition de la participation aux bénéfices entre toutes les catégories de contrats se fait au prorata des provisions mathématiques moyennes de chaque catégorie.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 39;

      // Article 5
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 5 : Renonciation', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le souscripteur peut renoncer au contrat dans le délai de trente (30) jours à compter du paiement de la première cotisation, par lettre recommandée avec avis de réception ou tout autre moyen faisant foi de la réception. Il lui est alors restitué les cotisations versées déduction faite des coûts de police dans un délai maximal de quinze (15) jours à compter de la date de réception de ladite renonciation. Au-delà de ce délai, les sommes non restituées produisent de plein droit un intérêt de retard de 2,5% par mois indépendamment de toute réclamation.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 48;

      // Article 6
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 6 : Rachat - Réduction', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Après deux années effectives de cotisations ou de versement d\'au moins 15% des cotisations prévues sur toute la durée du contrat, le souscripteur peut mettre fin au contrat en contrepartie de la cessation de toutes les garanties. En cas de rachat, la valeur de rachat est égale à 95% de la provision mathématique de la deuxième à la cinquième année, plus 1% par année pour atteindre 100% à la fin de la dixième année.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 38;
      doc.text('Lorsque le souscripteur cesse de payer ses primes alors que le contrat a une valeur de rachat, les garanties du contrat CORIS RETRAITE sont réévaluées et continuent pour des montants assurés réduits.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 27;

      // Article 7
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 7 : Rachat Partiel', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Dans la limite de la valeur de rachat de votre contrat, vous avez la possibilité de racheter une partie de votre épargne constituée, aux conditions cumulatives suivantes :', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 14;
      doc.text('•  que deux années de primes ou 15% des primes prévues au contrat aient été payées ;', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 11;
      doc.text('•  que le montant brut demandé n\'excède pas 45% de la valeur votre Compte Individuel Retraite (C.I.R) ;', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 13;
      doc.text('•  que la valeur résiduelle ne soit pas inférieure au SMIG.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 19;

      // Article 8 (maintenant dans colonne gauche)
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 8 : Avances', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Dans la limite de la valeur de rachat de votre contrat, nous pouvons vous accorder des avances sur contrat. La demande d\'avance se fait au moyen d\'un écrit daté et signé ainsi qu\'une copie de la carte nationale d\'identité ou du passeport en cours de validité du souscripteur. L\'avance demandée n\'excède pas le tiers (1/3) de la valeur votre Compte Individuel Retraite (C.I.R). Les frais de dossier et le taux d\'intérêt de l\'avance sont définis dans le contrat d\'avance.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 42;

      // Article 9 (dans colonne gauche)
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 9 : Garanties accordées', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('En cas de vie au terme du contrat : l\'assureur verse au souscripteur le capital minimum garanti, plus la participation aux bénéfices.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 14;
      doc.text('En cas de décès ou Perte Totale et Irréversible d\'Autonomie avant le terme du contrat : l\'assureur verse aux bénéficiaires désignés au contrat la valeur du Compte Individuel Retraite (C.I.R) constituée au moment du décès.', colLeftX, leftY, { width: colWidth, lineGap: 1 });

      // COLONNE DROITE
      // Article 10 (début colonne droite)
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 10 : Paiement des sommes assurées', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le paiement des sommes assurées est effectué à notre siège social, dans les 15 jours suivant la remise des pièces justificatives :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 16;
      doc.font('Helvetica-Bold').fontSize(6);
      doc.text('a) En cas de vie :', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('•  l\'original du contrat ;', colRightX, rightY, { width: colWidth });
      rightY += 11;
      doc.font('Helvetica').fontSize(6);
      doc.text('•  les pièces justificatives de l\'identité de l\'assuré.', colRightX, rightY, { width: colWidth });
      rightY += 11;
      doc.font('Helvetica-Bold').fontSize(6);
      doc.text('b) En cas de décès :', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('•  l\'original du contrat ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 11;
      doc.font('Helvetica').fontSize(6);
      doc.text('•  l\'extrait d\'acte de décès ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 11;
      doc.font('Helvetica').fontSize(6);
      doc.text('•  le certificat médical constatant votre état de Perte Totale et Irréversible d\'Autonomie ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 11;
      doc.font('Helvetica').fontSize(6);
      doc.text('•  la (ou les) fiche(s) d\'état civil de la (ou des) personnes(s) désignée(s) comme bénéficiaire(s).', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 11;
      doc.text('En cas de pluralité de bénéficiaires notre paiement intervient sur quittance conjointe des intéressés.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 20;

      // Article 11 avec tableau (dans colonne droite)
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.text('Article 11 : Valeurs minimum de rachats garanties', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le tableau des valeurs minimum de rachat garanties à l\'anniversaire de la date d\'effet à condition que le souscripteur soit à jour de ses cotisations (cotisation minimum de 10 000 F CFA).', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 16;

      // Tableau compact dans la colonne
      const tableStartX = colRightX;
      const colWidths = [25, 70, 65]; // Largeur augmentée pour titres sur une ligne
      const tableRowH = 12;
      
      let tblY = rightY;
      
      // En-têtes
      doc.font('Helvetica-Bold').fontSize(6);
      doc.rect(tableStartX, tblY, colWidths[0], tableRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Année', tableStartX + 1, tblY + 4, { width: colWidths[0] - 2, align: 'center' });
      doc.rect(tableStartX + colWidths[0], tblY, colWidths[1], tableRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Cumul cotisations', tableStartX + colWidths[0] + 1, tblY + 4, { width: colWidths[1] - 2, align: 'center' });
      doc.rect(tableStartX + colWidths[0] + colWidths[1], tblY, colWidths[2], tableRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Valeurs de rachat', tableStartX + colWidths[0] + colWidths[1] + 1, tblY + 4, { width: colWidths[2] - 2, align: 'center' });

      const tableData = [
        ['1', '120 000', '0'],
        ['2', '240 000', '188 800'],
        ['3', '360 000', '305 873'],
        ['4', '480 000', '427 043'],
        ['5', '600 000', '552 454'],
        ['6', '720 000', '682 254'],
        ['7', '840 000', '816 598'],
        ['8', '960 000', '955 643']
      ];

      doc.font('Helvetica').fontSize(6.5);
      tableData.forEach((row) => {
        tblY += tableRowH;
        doc.rect(tableStartX, tblY, colWidths[0], tableRowH).stroke();
        doc.fillColor('#000').text(row[0], tableStartX + 1, tblY + 4, { width: colWidths[0] - 2, align: 'center' });
        doc.rect(tableStartX + colWidths[0], tblY, colWidths[1], tableRowH).stroke();
        doc.fillColor('#000').text(row[1], tableStartX + colWidths[0] + 1, tblY + 4, { width: colWidths[1] - 2, align: 'center' });
        doc.rect(tableStartX + colWidths[0] + colWidths[1], tblY, colWidths[2], tableRowH).stroke();
        doc.fillColor('#000').text(row[2], tableStartX + colWidths[0] + colWidths[1] + 1, tblY + 4, { width: colWidths[2] - 2, align: 'center' });
      });

      rightY = tblY + tableRowH + 12;

      // Article 12 (dans colonne droite)
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.fillColor('#000').text('Article 12 : Prescription', colRightX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(6);
      doc.fillColor('#000').text('Comme le stipule l\'article 28 du Code des assurances de la Conférence Interafricaine des Marchés d\'Assurances (CIMA), toute action dérivant de ce présent contrat est prescrite par dix (10) ans, à compter de la date de survenance de l\'évènement qui y donne naissance.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 25;

      // Article 13 (dans colonne droite)
      doc.font('Helvetica-Bold').fontSize(6.5);
      doc.fillColor('#000').text('Article 13 : Clause données personnelles', colRightX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(5.5);
      doc.fillColor('#000').text('CORIS ASSURANCES VIE CI est le responsable des traitements des données à caractère personnel (DCP) du client, collectées et traitées directement ou par le biais d\'un intermédiaire, aux fins de signer et intégrer les cotisations, avenants, renouvellement de contrat d\'assurance. A cet effet, les DCP du client peuvent être communiquées ou transférées :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 28;
      doc.fillColor('#000').text('•  aux entités du groupe CORIS et leurs filiales, à des fins de prospection commerciale ou de conclusion d\'autres contrats ou en cas de mise en commun de moyens ou de regroupements de sociétés ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 17;
      doc.fillColor('#000').text('•  aux prestataires, partenaires et professionnels règlementés (médecin, avocats, notaire, Commissaire aux Comptes ...) avec lesquels nous travaillons et qui ont l\'obligation de se conformer à la loi 2013-450 relative à la protection des DCP ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 22;
      doc.fillColor('#000').text('•  aux autorités administratives, financières, judicaires, agences d\'Etats, organismes publics, ou agents assermentés de l\'Autorité de protection, sur demande et dans la limite de ce qui est permis par la règlementation.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 22;
      doc.fillColor('#000').text('Les traitements de DCP sont réalisés conformément à la loi N°2013-450 du 19 juin 2013 relative à la protection des DCP, et suivant les dispositions de la politique de CORIS ASSURANCES VIE CI sur la protection des DCP. Par ailleurs, les DCP seront conservées uniquement pour la durée nécessaire à l\'accomplissement de ladite finalité, et pendant une durée supplémentaire de dix (10) ans après la fin de la relation avec l\'assuré.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 40;
      doc.fillColor('#000').text('En vertu des dispositions des articles 28 à 33 la loi N°2013-450 du 19 juin 2013, le client dispose des droits d\'accès à ses DCP, d\'être informé, de s\'opposer et de demander leur effacement si leur traitement n\'est plus nécessaire pour la finalité décrite, en adressant une demande au correspondant à la protection des DCP à l\'adresse : corisvie-ci@coris-assurances.com.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 28;
      doc.fillColor('#000').text('En signant le présent contrat d\'assurance, le client consent au traitement des DCP découlant de la relation contractuelle avec l\'Assureur.', colRightX, rightY, { width: colWidth, lineGap: 1 });

      console.log('✅ Page 2 ajoutée pour Coris Retraite avec résumé des conditions générales en 2 colonnes');
    }

    // Pour Coris Epargne Bonus : Ajouter une deuxième page avec les conditions générales en 2 colonnes + 2 tableaux
    if (isEpargneBonus) {
      doc.addPage();
      curY = 30;
      
      // Titre principal
      doc.font('Helvetica-Bold').fontSize(11);
      doc.text('Résumé des conditions générales', startX, curY, { width: fullW, align: 'center' });
      curY += 12;
      doc.font('Helvetica-Oblique').fontSize(9);
      doc.text('(Valant notice d\'information)', startX, curY, { width: fullW, align: 'center' });
      curY += 15;

      // Définir les colonnes
      const colWidth = (fullW - 15) / 2;
      const colLeftX = startX;
      const colRightX = startX + colWidth + 15;
      let leftY = curY;
      let rightY = curY;

      // COLONNE GAUCHE
      // Article 1
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 1 : Objet du contrat', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le contrat CORIS EPARGNE BONUS est un contrat individuel d\'assurance vie à adhésion facultative et cotisations définies', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 14;
      doc.text('Il permet de :', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 10;
      doc.text('• Constituer une épargne payable sous forme de capital à l\'échéance du contrat ;', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 10;
      doc.text('• Avoir la chance d\'obtenir le montant du capital à l\'échéance par anticipation lors du tirage au sort ;', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 16;
      doc.text('En cas de décès ou PTIA avant le terme du contrat : l\'assureur verse au(x) bénéficiaire(s) désigné(s) au contrat de l\'épargne constituée au moment du décès.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 20;

      // Article 2
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 2 : Conditions d\'adhésion', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('L\'adhésion est réservée à toutes personnes physiques âgées de plus de dix-huit (18) ans et justifiant de leur capacité à payer les primes.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 24;

      // Article 3
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 3 : Versement des cotisations', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('La cotisation périodique est fixée par le souscripteur sur sa proposition d\'assurance avec un minimum de 5 500 F CFA par mois. Les cotisations sont forfaitaires et se déclinent par paliers. Les frais de dossier sont fixés à 500 F CFA par mois. Il n\'est pas possible d\'effectuer un versement libre ou exceptionnel sur ce contrat.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 34;

      // Article 4
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 4 : Rémunération du contrat', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Les cotisations nettes de frais sont capitalisées au taux d\'intérêt annuel de 3,5%. Le contrat prévoit chaque année l\'attribution d\'une participation aux bénéfices (PB) au moins égale à 90% des résultats techniques et 85% des résultats financiers et au minimum à 2% du résultat avant impôt de l\'exercice. La répartition de la participation aux bénéfices entre toutes les catégories de contrats se fait au prorata des provisions mathématiques moyennes de chaque catégorie.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 40;

      // Article 5
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 5 : Renonciation', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le souscripteur peut renoncer au contrat dans le délai de trente (30) jours à compter du paiement de la première cotisation, par lettre recommandée avec avis de réception ou tout autre moyen faisant foi de la réception. Il lui est alors restitué les cotisations versées déduction faite des coûts de police dans un délai maximal de quinze (15) jours à compter de la date de réception de ladite renonciation. Au-delà de ce délai, les sommes non restituées produisent de plein droit un intérêt de retard de 2,5% par mois indépendamment de toute réclamation.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 49;

      // Article 6
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 6 : Rachat – Réduction', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Après deux années effectives de cotisations ou de versement d\'au moins 15% des cotisations prévues sur toute la durée du contrat, le souscripteur peut mettre fin au contrat en contrepartie de la cessation de toutes les garanties. En cas de rachat, la valeur de rachat est égale à 95% de la provision mathématique de la deuxième à la cinquième année, plus 1% par année pour atteindre 100% à la fin de la dixième année.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 38;
      doc.text('Lorsque le souscripteur cesse de payer ses primes alors que le contrat a une valeur de rachat, les garanties du contrat CORIS EPARGNE BONUS sont réévaluées et continuent pour des montants assurés réduits. Tout contrat réduit est exclu du tirage au sort.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 28;

      // Article 7
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 7 : Rachat Partiel - Avance', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le rachat partiel et l\'avance ne sont pas autorisés sur ce contrat.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 18;

      // Article 8
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 8 : Conditions du tirage au sort', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le « TIRAGE AU SORT CORIS EPARGNE BONUS » est un jeu de hasard qui permet à tout client ayant un contrat d\'assurance CORIS EPARGNE BONUS de prendre part à un tirage au sort lui permettant d\'avoir la chance d\'obtenir le capital correspondant à son palier de façon anticipée, si son contrat est tiré au sort.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 30;
      doc.text('Pour participer au tirage au sort, le souscripteur ne doit être frappé d\'aucune forme d\'incapacité juridique, doit être à jour de ses cotisations et avoir un contrat en cours de validité depuis au moins trois (3) mois.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 24;
      doc.text('Le tirage au sort et le règlement du capital anticipé impliquent la fin du contrat. Le souscripteur tiré au sort peut néanmoins souscrire un nouveau contrat.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 16;
      doc.text('Le tirage au sort se déroule une fois par trimestre à partir de 1 000 souscriptions par palier de prime en présence d\'un huissier de justice.', colLeftX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 22;

      // Article 9 - Première partie (colonne gauche)
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 9 : Garanties accordées', colLeftX, leftY, { width: colWidth });
      leftY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('En cas de vie au terme du contrat : l\'assureur verse au souscripteur le capital minimum garanti, plus la participation aux bénéfices.', colLeftX, leftY, { width: colWidth, lineGap: 1 });

      // COLONNE DROITE
      // Article 9 - Deuxième partie (colonne droite)
      doc.font('Helvetica').fontSize(6);
      doc.text('En cas de tirage au sort : le paiement du capital souscrit à l\'échéance par anticipation.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 12;
      doc.text('Les options de garanties se présentent comme suit :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 14;

      // Tableau 1: Options de garanties (dans colonne droite)
      const optionColWidths = [45, 50, 60, 40];
      const optionRowH = 12;
      let optionY = rightY;

      // En-têtes
      doc.font('Helvetica-Bold').fontSize(5.5);
      doc.rect(colRightX, optionY, optionColWidths[0], optionRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Option', colRightX + 1, optionY + 4, { width: optionColWidths[0] - 2, align: 'center' });
      doc.rect(colRightX + optionColWidths[0], optionY, optionColWidths[1], optionRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Prime TTC/mois', colRightX + optionColWidths[0] + 1, optionY + 2, { width: optionColWidths[1] - 2, align: 'center' });
      doc.rect(colRightX + optionColWidths[0] + optionColWidths[1], optionY, optionColWidths[2], optionRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Capital terme/tirage', colRightX + optionColWidths[0] + optionColWidths[1] + 1, optionY + 2, { width: optionColWidths[2] - 2, align: 'center' });
      doc.rect(colRightX + optionColWidths[0] + optionColWidths[1] + optionColWidths[2], optionY, optionColWidths[3], optionRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Durée', colRightX + optionColWidths[0] + optionColWidths[1] + optionColWidths[2] + 1, optionY + 4, { width: optionColWidths[3] - 2, align: 'center' });

      // Données
      const optionData = [
        ['Palier 1', '5 500', '1 000 000', '15 ans'],
        ['Palier 2', '10 500', '2 000 000', '15 ans'],
        ['Palier 3', '20 500', '4 000 000', '15 ans'],
        ['Palier 4', '30 500', '6 000 000', '15 ans']
      ];

      doc.font('Helvetica').fontSize(5.5);
      optionData.forEach((row) => {
        optionY += optionRowH;
        doc.rect(colRightX, optionY, optionColWidths[0], optionRowH).stroke();
        doc.fillColor('#000').text(row[0], colRightX + 1, optionY + 4, { width: optionColWidths[0] - 2, align: 'center' });
        doc.rect(colRightX + optionColWidths[0], optionY, optionColWidths[1], optionRowH).stroke();
        doc.fillColor('#000').text(row[1], colRightX + optionColWidths[0] + 1, optionY + 4, { width: optionColWidths[1] - 2, align: 'center' });
        doc.rect(colRightX + optionColWidths[0] + optionColWidths[1], optionY, optionColWidths[2], optionRowH).stroke();
        doc.fillColor('#000').text(row[2], colRightX + optionColWidths[0] + optionColWidths[1] + 1, optionY + 4, { width: optionColWidths[2] - 2, align: 'center' });
        doc.rect(colRightX + optionColWidths[0] + optionColWidths[1] + optionColWidths[2], optionY, optionColWidths[3], optionRowH).stroke();
        doc.fillColor('#000').text(row[3], colRightX + optionColWidths[0] + optionColWidths[1] + optionColWidths[2] + 1, optionY + 4, { width: optionColWidths[3] - 2, align: 'center' });
      });

      rightY = optionY + optionRowH + 18;

      // Article 10
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 10 : Paiement des sommes assurées', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Le paiement des sommes assurées est effectué à notre siège social, dans les 15 jours suivant la remise des pièces justificatives :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 16;
      doc.font('Helvetica-Bold').fontSize(6);
      doc.text('a) En cas de vie ou de tirage au sort :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('• l\'original du contrat ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 8;
      doc.text('• les pièces justificatives de l\'identité de l\'assuré.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 10;
      doc.font('Helvetica-Bold').fontSize(6);
      doc.text('b) En cas de décès ou PTIA :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('• l\'original du contrat ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 8;
      doc.text('• l\'extrait d\'acte de décès ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 8;
      doc.text('• le certificat médical constatant votre état de Perte Totale et Irréversible d\'Autonomie ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 10;
      doc.text('• la (ou les) fiche(s) d\'état civil de la (ou des) personnes(s) désignée(s) comme bénéficiaire(s).', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 12;
      doc.text('En cas de pluralité de bénéficiaires notre paiement intervient sur quittance conjointe des intéressés.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 20;

      // Article 11 avec tableau 2 (dans colonne droite)
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.text('Article 11 : Valeurs minimum de rachats garanties', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.text('Pour une souscription au palier de 5 500 F CFA pour une durée du contrat fixée à 15 ans, les valeurs de rachat des huit (08) premières années sont :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 18;

      // Tableau 2: Valeurs de rachat
      const rachatColWidths = [25, 60, 55];
      const rachatRowH = 11;
      const tableStartX = colRightX;
      let rachatY = rightY;

      // En-têtes
      doc.font('Helvetica-Bold').fontSize(5.5);
      doc.rect(tableStartX, rachatY, rachatColWidths[0], rachatRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Année', tableStartX + 1, rachatY + 4, { width: rachatColWidths[0] - 2, align: 'center' });
      doc.rect(tableStartX + rachatColWidths[0], rachatY, rachatColWidths[1], rachatRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Cumul cotisations', tableStartX + rachatColWidths[0] + 1, rachatY + 4, { width: rachatColWidths[1] - 2, align: 'center' });
      doc.rect(tableStartX + rachatColWidths[0] + rachatColWidths[1], rachatY, rachatColWidths[2], rachatRowH).fillAndStroke('#E8E8E8', '#000');
      doc.fillColor('#000').text('Valeur rachat', tableStartX + rachatColWidths[0] + rachatColWidths[1] + 1, rachatY + 4, { width: rachatColWidths[2] - 2, align: 'center' });

      // Données
      const rachatData = [
        ['1', '60 000', '0'],
        ['2', '120 000', '77 859'],
        ['3', '180 000', '131 837'],
        ['4', '240 000', '187 481'],
        ['5', '300 000', '244 843'],
        ['6', '360 000', '303 976'],
        ['7', '420 000', '364 934'],
        ['8', '480 000', '427 774']
      ];

      doc.font('Helvetica').fontSize(5.5);
      rachatData.forEach((row) => {
        rachatY += rachatRowH;
        doc.rect(tableStartX, rachatY, rachatColWidths[0], rachatRowH).stroke();
        doc.fillColor('#000').text(row[0], tableStartX + 1, rachatY + 4, { width: rachatColWidths[0] - 2, align: 'center' });
        doc.rect(tableStartX + rachatColWidths[0], rachatY, rachatColWidths[1], rachatRowH).stroke();
        doc.fillColor('#000').text(row[1], tableStartX + rachatColWidths[0] + 1, rachatY + 4, { width: rachatColWidths[1] - 2, align: 'center' });
        doc.rect(tableStartX + rachatColWidths[0] + rachatColWidths[1], rachatY, rachatColWidths[2], rachatRowH).stroke();
        doc.fillColor('#000').text(row[2], tableStartX + rachatColWidths[0] + rachatColWidths[1] + 1, rachatY + 4, { width: rachatColWidths[2] - 2, align: 'center' });
      });

      rightY = rachatY + rachatRowH + 14;

      // Article 12
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.fillColor('#000').text('Article 12 : Prescription', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(6);
      doc.fillColor('#000').text('Comme le stipule l\'article 28 du Code des assurances de la Conférence Interafricaine des Marchés d\'Assurances (CIMA), toute action dérivant de ce présent contrat est prescrite par dix (10) ans, à compter de la date de survenance de l\'évènement qui y donne naissance.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 28;

      // Article 13
      doc.fontSize(6.5).font('Helvetica-Bold');
      doc.fillColor('#000').text('Article 13 : Clause données personnelles', colRightX, rightY, { width: colWidth });
      rightY += 8;
      doc.font('Helvetica').fontSize(5.5);
      doc.fillColor('#000').text('CORIS ASSURANCES VIE CI est le responsable des traitements des données à caractère personnel (DCP) du client, collectées et traitées directement ou par le biais d\'un intermédiaire, aux fins de signer et intégrer les cotisations, avenants, renouvellement de contrat d\'assurance. A cet effet, les DCP du client peuvent être communiquées ou transférées :', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 30;
      doc.fillColor('#000').text('• aux entités du groupe CORIS et leurs filiales, à des fins de prospection commerciale ou de conclusion d\'autres contrats ou en cas de mise en commun de moyens ou de regroupements de sociétés ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 18;
      doc.fillColor('#000').text('• aux prestataires, partenaires et professionnels règlementés (médecin, avocats, notaire, Commissaire aux Comptes …) avec lesquels nous travaillons et qui ont l\'obligation de se conformer à la loi 2013-450 relative à la protection des DCP ;', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 22;
      doc.fillColor('#000').text('• aux autorités administratives, financières, judicaires, agences d\'Etats, organismes publics, ou agents assermentés de l\'Autorité de protection, sur demande et dans la limite de ce qui est permis par la règlementation.', colRightX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 22;
      doc.fillColor('#000').text('Les traitements de DCP sont réalisés conformément à la loi N°2013-450 du 19 juin 2013 relative à la protection des DCP, et suivant les dispositions de la politique de CORIS ASSURANCES VIE CI sur la protection des DCP. Par ailleurs, les DCP seront conservées uniquement pour la durée nécessaire à l\'accomplissement de ladite finalité, et pendant une durée supplémentaire de dix (10) ans après la fin de la relation avec l\'assuré. En vertu des dispositions des articles 28 à 33 la loi N°2013-450 du 19 juin 2013, le client dispose des droits d\'accès à ses DCP, d\'être informé, de s\'opposer et de demander leur effacement si leur traitement n\'est plus nécessaire pour la finalité décrite, en adressant une demande au correspondant à la protection des DCP à l\'adresse : corisvie-ci@coris-assurances.com. En signant le présent contrat d\'assurance, le client consent au traitement des DCP découlant de la relation contractuelle avec l\'Assureur.', colRightX, rightY, { width: colWidth, lineGap: 1 });

      console.log('✅ Page 2 ajoutée pour Coris Epargne Bonus avec résumé des conditions générales en 2 colonnes et 2 tableaux');
    }

    // Pour Coris Familis : Ajouter une deuxième page avec les conditions générales
    if (isFamilis) {
      doc.addPage();
      curY = 30;
      
      // Titre principal
      doc.font('Helvetica-Bold').fontSize(14);
      doc.text('CORIS Familis', startX, curY, { width: fullW, align: 'center' });
      curY += 25;

      // Layout en 2 colonnes
      const colWidth = fullW * 0.48;
      const rightColX = startX + fullW * 0.52;
      let leftY = curY;
      let rightY = curY;

      // COLONNE GAUCHE
      // Préambule
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Préambule', startX, leftY, { width: colWidth });
      leftY += 12;
      doc.font('Helvetica').fontSize(7);
      doc.text('Le présent document constitue la notice d\'information prévue par la législation. Il résume les dispositions du contrat d\'assurance souscrit auprès de Coris Assurances Vie Côte D\'Ivoire. Votre contrat d\'assurance est constitué de conditions générales, de conditions particulières et des formalités d\'adhésion. Le preneur d\'assurance déclare avoir pris connaissance des conditions générales et y adhère. Les conditions générales sont à votre disposition auprès de votre agence ou sur simple demande.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 68;

      // Objet du contrat
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Objet du contrat', startX, leftY, { width: colWidth });
      leftY += 12;
      doc.font('Helvetica').fontSize(7);
      doc.text('Le contrat Familis vise à garantir l\'assuré selon son âge et la formule de garantie choisie, contre les risques de décès ou de perte totale et irréversible d\'autonomie survenant pendant une durée déterminée dans le certificat d\'adhésion.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 40;

      // Garanties accordées
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Garanties accordées', startX, leftY, { width: colWidth });
      leftY += 12;
      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• La garantie décès :', startX, leftY, { width: colWidth });
      leftY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('À la suite d\'un décès consécutif à un accident ou à une maladie survenue en cours de contrat et si le décès survient avant le terme du contrat, ou de perte totale et irréversible d\'autonomie de l\'assuré, et au plus tard avant la fin de l\'année au cours de laquelle l\'assuré atteint l\'âge de 65ans, Coris Assurances Vie Burkina garantit le versement d\'un capital défini à la souscription au bénéficiaire désigné.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 68;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• L\'option doublement de capital :', startX, leftY, { width: colWidth });
      leftY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('cette option permet le doublement du capital garanti en cas de décès de l\'assuré par accident dans la limite de cent millions (100 000 000) FCFA par assuré.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 30;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• L\'option frais funéraires :', startX, leftY, { width: colWidth });
      leftY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('cette option permet de prendre en charge les dépenses liées aux obsèques de l\'assuré.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 22;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• L\'option frais médicaux :', startX, leftY, { width: colWidth });
      leftY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('cette option permet de prendre en charge les frais engagés suite à un accident (en dehors des accidents de travail) dans la limite du montant du capital garanti.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 30;

      doc.font('Helvetica').fontSize(7);
      doc.text('Le paiement du capital garanti en cas de décès entraîne la fin de toutes les garanties pour l\'assuré concerné.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 22;

      // Paiement du capital garanti
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Paiement du capital garanti', startX, leftY, { width: colWidth });
      leftY += 12;
      doc.font('Helvetica').fontSize(7);
      doc.text('Le décès ou la PTIA de l\'assuré entraine le versement du capital garanti. Ce capital est mis à disposition du bénéficiaire qui produit les pièces justificatives.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 28;
      doc.text('Tous les règlements s\'effectuent en FCFA. Après le décès de l\'assuré et à compter de la réception des pièces justificatives nécessaires au paiement, Coris s\'engage à verser, dans un délai qui ne doit pas excéder 15 jours ouvrés, le capital au bénéficiaire.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 40;
      doc.text('Pour ce qui concerne l\'option frais funéraires, le règlement intervient 48h après réception de l\'ensemble des pièces justificatives.', startX, leftY, { width: colWidth, lineGap: 1 });
      leftY += 28;

      // Renonciation au contrat
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Renonciation au contrat', startX, leftY, { width: colWidth });
      leftY += 12;
      doc.font('Helvetica').fontSize(7);
      doc.text('L\'assuré peut renoncer au contrat, par lettre transmise à l\'assureur avec accusé de réception, 30 jours à compter de la date de signature du certificat d\'adhésion. Dès réception de la lettre par l\'Assureur, les effets du contrat cessent.', startX, leftY, { width: colWidth, lineGap: 1 });

      // COLONNE DROITE
      // Acceptation du bénéfice
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Acceptation du bénéfice', rightColX, rightY, { width: colWidth });
      rightY += 12;
      doc.font('Helvetica').fontSize(7);
      doc.text('Le bénéficiaire a la possibilité de confirmer à tout moment, avec l\'accord écrit de l\'assuré, qu\'il accepte cette désignation : il la rend ainsi irrévocable. Dans un tel cas de figure, la modification de la désignation de bénéficiaire au profit d\'une autre personne sans l\'accord préalable du bénéficiaire acceptant.', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 50;

      // Pièces à fournir en cas de sinistre
      doc.font('Helvetica-Bold').fontSize(9);
      doc.text('Pièces à fournir en cas de sinistre', rightColX, rightY, { width: colWidth });
      rightY += 12;
      doc.font('Helvetica').fontSize(7);
      doc.text('En cas de réalisation du risque, les pièces suivantes sont à fournir en fonction de votre situation :', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 20;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• Dans tous les cas :', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('  - la déclaration de sinistre à retirer auprès de Coris Assurances Vie Burkina est à remplir et signer par le représentant légal de l\'assuré ;', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 22;
      doc.text('  - une copie du contrat d\'assurance;', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.text('  - le questionnaire médical à retirer auprès de Coris est à remplir et signer par le médecin traitant ou le médecin ayant constaté le décès.', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 25;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• Décès', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('  - un acte de décès de l\'assuré ;', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.text('  - une photocopie datée et signée de la carte nationale d\'identité ou du passeport en cours de validité du bénéficiaire et un acte désignant le ou les bénéficiaires.', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 25;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• PTIA', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('  - un certificat médical attestant de l\'invalidité.', rightColX, rightY, { width: colWidth });
      rightY += 15;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• En cas de décès par accident', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('  - un courrier précisant la nature, les circonstances, la date et le lieu de l\'accident ;', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 18;
      doc.text('  - les preuves de l\'accident telles que rapport de police, procès-verbal de gendarmerie.', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 20;

      doc.font('Helvetica-Bold').fontSize(7);
      doc.text('• Remboursement des frais médicaux', rightColX, rightY, { width: colWidth });
      rightY += 10;
      doc.font('Helvetica').fontSize(7);
      doc.text('En cas de sinistre, le souscripteur où à défaut l\'assuré doit :', rightColX, rightY, { width: colWidth });
      rightY += 12;
      doc.text('  - Donner, sous peine de déchéance, sauf cas fortuit ou de force majeure, dès qu\'il en a connaissance et au plus tard dans les cinq jours ouvrés, l\'avis du sinistre à l\'Assureur ou à son représentant local, par écrit de préférence par lettre recommandée ou verbalement, contre récépissé ;', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 42;
      doc.text('  - Indiquer dans la déclaration du sinistre ou, en cas d\'impossibilité, dans une déclaration ultérieure faite dans le plus bref délai, les nom, prénoms, âge et domicile de la victime, les date, lieu et circonstances du sinistre, les nom et adresse du médecin appelé à donner les premiers soins et, s\'il y a lieu, les nom et adresse de l\'auteur et, si possible, des témoins de ce sinistre. Cette déclaration doit également indiquer si les représentants de l\'autorité sont intervenus et s\'il a été établi un procès-verbal ou un constat ;', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 72;
      doc.text('  - Transmettre les reçus d\'achat de médicaments et les tickets de caisse y relatifs.', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 18;

      doc.font('Helvetica').fontSize(7);
      doc.text('Les pièces sont à envoyer sous pli confidentiel à l\'attention du médecin conseil de Coris en cas de pièces médicales.', rightColX, rightY, { width: colWidth, lineGap: 1 });
      rightY += 18;
      doc.text('Coris Assurances Vie Burkina se réserve le droit de se livrer à toute enquête, de réclamer des documents complémentaires.', rightColX, rightY, { width: colWidth, lineGap: 1 });

      console.log('✅ Page 2 ajoutée pour Coris Familis avec notice d\'information');
    }

    doc.end();
  } catch (error) {
    console.error('Erreur génération PDF:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la génération du PDF' });
  }
  
};

// Note: getDocument is implemented earlier in this file (single canonical handler)

/**
 * 📋 RÉCUPÉRER LES QUESTIONS DU QUESTIONNAIRE MÉDICAL
 * Récupère toutes les questions actives depuis la base de données
 */
const getQuestionsQuestionnaireMedical = async (req, res) => {
  try {
    console.log('📋 Récupération des questions du questionnaire médical');

    const result = await pool.query(
      `SELECT id, code, libelle, type_question, ordre,
              champ_detail_1_label,
              champ_detail_2_label,
              champ_detail_3_label,
              obligatoire, actif
       FROM questionnaire_medical
       WHERE actif = TRUE
       ORDER BY ordre ASC`
    );

    console.log(`✅ ${result.rows.length} questions récupérées`);

    res.json({
      success: true,
      questions: result.rows
    });

  } catch (error) {
    console.error('❌ Erreur récupération questions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des questions',
      error: error.message
    });
  }
};

/**
 * 📋 SAUVEGARDER LES RÉPONSES AU QUESTIONNAIRE MÉDICAL
 * Enregistre ou met à jour les réponses au questionnaire médical
 * Pour les produits: Coris Sérénité, Coris Familis, Coris Étude
 */
const saveQuestionnaireMedical = async (req, res) => {
  try {
    const { id } = req.params; // ID de la souscription
    const userId = req.user.id;
    const { reponses } = req.body; // Array de réponses: [{question_id, reponse_oui_non, reponse_texte, detail_1, detail_2, detail_3}]

    console.log('💾 Sauvegarde questionnaire médical pour souscription:', id);
    console.log('📝 Nombre de réponses:', reponses?.length);
    console.log('📋 Réponses reçues:', JSON.stringify(reponses, null, 2));

    if (!reponses || !Array.isArray(reponses)) {
      return res.status(400).json({
        success: false,
        message: 'Format de données invalide. Attendu: {reponses: [...]}'
      });
    }

    // Vérifier que la souscription existe et appartient à l'utilisateur
    const subscriptionCheck = await pool.query(
      'SELECT id, user_id FROM subscriptions WHERE id = $1',
      [id]
    );

    if (subscriptionCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }

    const subscription = subscriptionCheck.rows[0];

    // Vérifier les droits (propriétaire ou commercial)
    const userCheck = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userCheck.rows[0]?.role;

    if (subscription.user_id !== userId && userRole !== 'commercial') {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    // Début de la transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      let savedCount = 0;

      // Pour chaque réponse, faire un UPSERT (INSERT ou UPDATE)
      for (const reponse of reponses) {
        const {
          question_id,
          reponse_oui_non,
          reponse_text,
          reponse_detail_1,
          reponse_detail_2,
          reponse_detail_3
        } = reponse;

        console.log(`📝 Traitement question ${question_id}: réponse=${reponse_oui_non || reponse_text}`);

        // Vérifier si la réponse existe déjà
        const existingReponse = await client.query(
          'SELECT id FROM souscription_questionnaire WHERE subscription_id = $1 AND question_id = $2',
          [id, question_id]
        );

        if (existingReponse.rows.length > 0) {
          // Mise à jour
          const updateResult = await client.query(
            `UPDATE souscription_questionnaire
             SET reponse_oui_non = $1,
                 reponse_text = $2,
                 reponse_detail_1 = $3,
                 reponse_detail_2 = $4,
                 reponse_detail_3 = $5,
                 updated_at = CURRENT_TIMESTAMP
             WHERE subscription_id = $6 AND question_id = $7
             RETURNING id`,
            [reponse_oui_non, reponse_text, reponse_detail_1, reponse_detail_2, reponse_detail_3, id, question_id]
          );
          console.log(`✏️ Question ${question_id} MISE À JOUR`);
          savedCount++;
        } else {
          // Insertion
          const insertResult = await client.query(
            `INSERT INTO souscription_questionnaire
             (subscription_id, question_id, reponse_oui_non, reponse_text, reponse_detail_1, reponse_detail_2, reponse_detail_3)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             RETURNING id`,
            [id, question_id, reponse_oui_non, reponse_text, reponse_detail_1, reponse_detail_2, reponse_detail_3]
          );
          console.log(`✅ Question ${question_id} INSÉRÉE - ID: ${insertResult.rows[0].id}`);
          savedCount++;
        }
      }

      await client.query('COMMIT');
      console.log(`✅ Questionnaire médical sauvegardé - ${savedCount}/${reponses.length} réponses enregistrées`);

      // Vérifier que tout a bien été sauvegardé
      const verification = await pool.query(
        `SELECT COUNT(*) as total FROM souscription_questionnaire WHERE subscription_id = $1`,
        [id]
      );
      console.log(`🔍 VÉRIFICATION: ${verification.rows[0].total} réponses totales en BD pour souscription ${id}`);

      res.json({
        success: true,
        message: 'Questionnaire médical enregistré avec succès',
        saved_count: savedCount
      });

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }

  } catch (error) {
    console.error('❌ Erreur sauvegarde questionnaire médical:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'enregistrement du questionnaire médical',
      error: error.message
    });
  }
};

/**'
 * 📋 RÉCUPÉRER LES RÉPONSES AU QUESTIONNAIRE MÉDICAL
 * Récupère les réponses au questionnaire médical d'une souscription
 */
const getQuestionnaireMedical = async (req, res) => {
  try {
    const { id } = req.params; // ID de la souscription
    const userId = req.user.id;

    console.log('📖 Récupération réponses questionnaire pour souscription:', id);

    // Vérifier que la souscription existe et appartient à l'utilisateur
    const subscriptionCheck = await pool.query(
      'SELECT id, user_id FROM subscriptions WHERE id = $1',
      [id]
    );

    if (subscriptionCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Souscription non trouvée'
      });
    }

    const subscription = subscriptionCheck.rows[0];

    // Vérifier les droits (propriétaire ou commercial)
    const userCheck = await pool.query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userCheck.rows[0]?.role;

    if (subscription.user_id !== userId && userRole !== 'commercial') {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé'
      });
    }

    // Récupérer les réponses avec les questions associées
    const result = await pool.query(
      `SELECT sq.id, sq.question_id, sq.reponse_oui_non, sq.reponse_text,
              sq.reponse_detail_1, sq.reponse_detail_2, sq.reponse_detail_3,
              qm.code, qm.libelle, qm.type_question, qm.ordre,
              qm.champ_detail_1_label, qm.champ_detail_2_label, qm.champ_detail_3_label
       FROM souscription_questionnaire sq
       JOIN questionnaire_medical qm ON sq.question_id = qm.id
       WHERE sq.subscription_id = $1
       ORDER BY qm.ordre ASC`,
      [id]
    );

    console.log(`✅ ${result.rows.length} réponses récupérées pour souscription ${id}`);
    if (result.rows.length > 0) {
      console.log('📋 Détail des réponses:');
      result.rows.forEach((row, idx) => {
        console.log(`  ${idx + 1}. Question "${row.libelle}" → Réponse: ${row.reponse_oui_non || row.reponse_text || 'N/A'}`);
      });
    } else {
      console.log('⚠️ Aucune réponse trouvée pour cette souscription');
    }

    // Retourner sous la clé attendue par le frontend
    res.json({
      success: true,
      reponses: result.rows
    });

  } catch (error) {
    console.error('❌ Erreur récupération réponses questionnaire:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des réponses',
      error: error.message
    });
  }
};

exports.getQuestionsQuestionnaireMedical = getQuestionsQuestionnaireMedical;
exports.saveQuestionnaireMedical = saveQuestionnaireMedical;
exports.getQuestionnaireMedical = getQuestionnaireMedical;

/**
 * GET /api/subscriptions/:id/questionnaire-medical/print
 * Génère la page HTML imprimable du questionnaire médical.
 * Accessible aux admins, au commercial auteur de la souscription, et au client concerné.
 */
const getQuestionnaireMedicalPrint = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUser = req.user;
    const accessQuery = await pool.query(
      `SELECT s.id, s.user_id, s.code_apporteur,
              s.souscriptiondata->'client_info'->>'telephone' as client_info_telephone
       FROM subscriptions s WHERE s.id = $1`,
      [id]
    );
    if (accessQuery.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Souscription introuvable' });
    }
    const acc = accessQuery.rows[0];
    let hasAccess = false;
    if (currentUser.role === 'admin') hasAccess = true;
    else if (acc.user_id === currentUser.id) hasAccess = true;
    else if (currentUser.role === 'commercial' && acc.code_apporteur) {
      const commRow = await pool.query(
        'SELECT code_apporteur FROM users WHERE id = $1 LIMIT 1', [currentUser.id]
      );
      if (commRow.rows.length > 0 && commRow.rows[0].code_apporteur === acc.code_apporteur) hasAccess = true;
    } else if (currentUser.role === 'client' && acc.client_info_telephone) {
      const clientRow = await pool.query('SELECT telephone FROM users WHERE id = $1 LIMIT 1', [currentUser.id]);
      if (clientRow.rows.length > 0 && clientRow.rows[0].telephone === acc.client_info_telephone) hasAccess = true;
    }
    if (!hasAccess) {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }

    const subResult = await pool.query(
      `SELECT s.id, s.numero_police, s.produit_nom, s.souscriptiondata, s.date_creation, s.code_apporteur,
              u.nom, u.prenom, u.email, u.telephone, u.date_naissance
       FROM subscriptions s
       LEFT JOIN users u ON u.id = s.user_id
       WHERE s.id = $1`,
      [id]
    );
    const sub = subResult.rows[0];
    const subData = sub.souscriptiondata || {};
    const clientInfo = subData.client_info || {};
    const clientNom = clientInfo.nom || sub.nom || 'N/A';
    const clientPrenom = clientInfo.prenom || sub.prenom || 'N/A';
    const clientEmail = clientInfo.email || (sub.code_apporteur ? '' : (sub.email || ''));
    const clientTel = clientInfo.telephone || sub.telephone || 'N/A';
    const clientDob = clientInfo.date_naissance || sub.date_naissance || null;
    const clientAddr = clientInfo.adresse || 'N/A';
    const clientCivil = clientInfo.civilite || clientInfo.genre || '';
    const numeroRef = sub.numero_police || `SUB-${id}`;

    const produitLabel = (sub.produit_nom || 'N/A')
      .replace(/_/g, ' ')
      .split(' ')
      .map(w => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ');

    const questResult = await pool.query(
      `SELECT sq.reponse_oui_non, sq.reponse_text,
              sq.reponse_detail_1, sq.reponse_detail_2, sq.reponse_detail_3,
              qm.code, qm.libelle, qm.type_question, qm.ordre,
              qm.champ_detail_1_label, qm.champ_detail_2_label, qm.champ_detail_3_label
       FROM souscription_questionnaire sq
       JOIN questionnaire_medical qm ON sq.question_id = qm.id
       WHERE sq.subscription_id = $1
       ORDER BY qm.ordre ASC`,
      [id]
    );
    const reponses = questResult.rows;

    const lignesHtml = reponses.length === 0
      ? `<tr><td colspan="3" style="text-align:center;color:#888;padding:20px;font-style:italic;">Aucune réponse enregistrée pour cette souscription.</td></tr>`
      : reponses.map((r, i) => {
          let reponseHtml;
          if (r.reponse_oui_non !== null && r.reponse_oui_non !== undefined) {
            const isOui = r.reponse_oui_non === true || r.reponse_oui_non === 'true';
            reponseHtml = isOui
              ? `<span style="background:#fde8e8;color:#c0392b;padding:3px 10px;border-radius:12px;font-weight:bold;font-size:12px;">OUI</span>`
              : `<span style="background:#e8f8e8;color:#27ae60;padding:3px 10px;border-radius:12px;font-weight:bold;font-size:12px;">NON</span>`;
          } else {
            reponseHtml = `<span style="color:#333;">${r.reponse_text || '—'}</span>`;
          }
          const details = [
            r.champ_detail_1_label && r.reponse_detail_1 ? `<div style="margin-top:4px;font-size:11px;color:#555;"><em>${String(r.champ_detail_1_label).replace(/</g,'&lt;')}:</em> ${String(r.reponse_detail_1).replace(/</g,'&lt;')}</div>` : '',
            r.champ_detail_2_label && r.reponse_detail_2 ? `<div style="margin-top:2px;font-size:11px;color:#555;"><em>${String(r.champ_detail_2_label).replace(/</g,'&lt;')}:</em> ${String(r.reponse_detail_2).replace(/</g,'&lt;')}</div>` : '',
            r.champ_detail_3_label && r.reponse_detail_3 ? `<div style="margin-top:2px;font-size:11px;color:#555;"><em>${String(r.champ_detail_3_label).replace(/</g,'&lt;')}:</em> ${String(r.reponse_detail_3).replace(/</g,'&lt;')}</div>` : ''
          ].join('');
          return `<tr style="background:${i % 2 === 0 ? '#ffffff' : '#f7faff'};">
            <td style="padding:10px 12px;border:1px solid #d0d8e8;color:#888;font-size:12px;text-align:center;width:50px;">${r.code || i + 1}</td>
            <td style="padding:10px 12px;border:1px solid #d0d8e8;line-height:1.5;">${String(r.libelle).replace(/</g,'&lt;')}</td>
            <td style="padding:10px 12px;border:1px solid #d0d8e8;min-width:130px;">${reponseHtml}${details}</td>
          </tr>`;
        }).join('');

    const dateImpression = new Date().toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' });
    const dateSouscription = sub.date_creation ? new Date(sub.date_creation).toLocaleDateString('fr-FR') : 'N/A';

    const html = `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Questionnaire Médical — ${numeroRef}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Arial', sans-serif; color: #222; font-size: 13px; background: #f5f7fb; }
    .page { max-width: 800px; margin: 0 auto; background: #fff; padding: 32px 36px; }
    .logo-container { display: flex; align-items: center; gap: 10px; }
    .logo-text { line-height: 1; }
    .logo-text .brand { font-size: 22px; font-weight: 900; color: #1a4b8c; letter-spacing: 1px; }
    .logo-text .sub { font-size: 11px; color: #e67e22; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; }
    .header { display: flex; align-items: center; justify-content: space-between; border-bottom: 3px solid #1a4b8c; padding-bottom: 16px; margin-bottom: 24px; }
    .header-right { text-align: right; }
    .header-right h1 { font-size: 17px; color: #1a4b8c; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; }
    .header-right h2 { font-size: 12px; color: #666; font-weight: normal; margin-top: 3px; }
    .header-right .date { font-size: 11px; color: #999; margin-top: 6px; }
    .section-title { background: linear-gradient(90deg, #1a4b8c 0%, #2563eb 100%); color: white; padding: 8px 14px; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.8px; border-radius: 5px; margin-bottom: 12px; margin-top: 20px; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0; border: 1px solid #d0d8e8; border-radius: 6px; overflow: hidden; margin-bottom: 4px; }
    .info-item { padding: 9px 14px; border-bottom: 1px solid #e8edf5; border-right: 1px solid #e8edf5; }
    .info-item:nth-child(even) { border-right: none; }
    .info-item label { font-size: 10px; color: #888; display: block; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px; }
    .info-item span { font-weight: 600; color: #1a2a4a; font-size: 13px; }
    table { width: 100%; border-collapse: collapse; }
    thead tr { background: linear-gradient(90deg, #1a4b8c 0%, #2563eb 100%); }
    thead th { padding: 10px 12px; color: white; text-align: left; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; border: none; }
    tbody tr:last-child td { border-bottom: 1px solid #d0d8e8; }
    .signature-block { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; margin-top: 28px; border-top: 1px solid #d0d8e8; padding-top: 16px; }
    .sig-box .sig-title { font-size: 12px; font-weight: 600; color: #1a4b8c; margin-bottom: 8px; }
    .sig-box .sig-line { border-top: 1px solid #555; margin-top: 55px; }
    .sig-box .sig-sub { font-size: 10px; color: #888; margin-top: 4px; }
    .footer { margin-top: 20px; padding-top: 10px; border-top: 1px solid #e0e0e0; display: flex; justify-content: space-between; font-size: 10px; color: #aaa; }
    .no-print { margin-bottom: 20px; }
    .btn-print { background: #1a4b8c; color: white; border: none; padding: 10px 24px; font-size: 14px; border-radius: 8px; cursor: pointer; font-weight: 600; box-shadow: 0 3px 8px rgba(26,75,140,0.3); }
    .btn-print:hover { background: #0d3275; }
    @media print {
      body { background: white; }
      .page { padding: 0; max-width: 100%; box-shadow: none; }
      .no-print { display: none !important; }
      @page { margin: 1.5cm 1.8cm; size: A4 portrait; }
      thead tr { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .section-title { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
<div class="page">
  <div class="no-print">
    <button class="btn-print" onclick="window.print()">🖨️&nbsp; Imprimer</button>
    <span style="margin-left:14px;color:#888;font-size:12px;">Ctrl+P pour imprimer directement</span>
  </div>
  <div class="header">
    <div class="logo-container">
      <img src="/public/logo1.png" alt="CORIS" style="height:48px;width:auto;object-fit:contain;">
      <div class="logo-text">
        <div class="brand">CORIS</div>
        <div class="sub">Assurance Vie</div>
      </div>
    </div>
    <div class="header-right">
      <h1>Questionnaire Médical</h1>
      <h2>Déclaration d'état de santé du souscripteur</h2>
      <div class="date">Imprimé le ${dateImpression}</div>
    </div>
  </div>
  <div class="section-title">📋 Informations de la souscription</div>
  <div class="info-grid">
    <div class="info-item"><label>N° Police / Référence</label><span>${numeroRef}</span></div>
    <div class="info-item"><label>Produit</label><span>${produitLabel}</span></div>
    <div class="info-item"><label>Date de souscription</label><span>${dateSouscription}</span></div>
    <div class="info-item"><label>Statut réponses</label><span>${reponses.length > 0 ? `${reponses.length} réponse(s) enregistrée(s)` : 'Aucune réponse'}</span></div>
  </div>
  <div class="section-title">👤 Identité du souscripteur</div>
  <div class="info-grid">
    <div class="info-item"><label>Nom</label><span>${String(clientNom).replace(/</g,'&lt;')}</span></div>
    <div class="info-item"><label>Prénom</label><span>${String(clientPrenom).replace(/</g,'&lt;')}</span></div>
    <div class="info-item"><label>Date de naissance</label><span>${clientDob ? new Date(clientDob).toLocaleDateString('fr-FR') : 'N/A'}</span></div>
    <div class="info-item"><label>Civilité</label><span>${clientCivil || 'N/A'}</span></div>
    <div class="info-item"><label>Téléphone</label><span>${String(clientTel).replace(/</g,'&lt;')}</span></div>
    <div class="info-item"><label>Email</label><span>${clientEmail ? String(clientEmail).replace(/</g,'&lt;') : 'Non renseigné'}</span></div>
    <div class="info-item" style="grid-column:1/3;"><label>Adresse</label><span>${String(clientAddr).replace(/</g,'&lt;')}</span></div>
  </div>
  <div class="section-title">🏥 Formulaire Médical — Questions &amp; Réponses</div>
  <table>
    <thead><tr>
      <th style="width:50px;text-align:center;">N°</th>
      <th>Question médicale</th>
      <th style="width:160px;">Réponse</th>
    </tr></thead>
    <tbody>${lignesHtml}</tbody>
  </table>
  <div class="signature-block">
    <div class="sig-box">
      <div class="sig-title">Signature du souscripteur</div>
      <div class="sig-line"></div>
      <div class="sig-sub">${String(clientPrenom).replace(/</g,'&lt;')} ${String(clientNom).replace(/</g,'&lt;')}</div>
    </div>
    <div class="sig-box">
      <div class="sig-title">Cachet &amp; Signature du médecin traitant</div>
      <div class="sig-line"></div>
      <div class="sig-sub">Médecin ayant examiné le souscripteur</div>
    </div>
  </div>
  <div class="footer">
    <span>CORIS Assurance Vie — Questionnaire médical — Réf. ${numeroRef}</span>
    <span>Document confidentiel</span>
  </div>
</div>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
  } catch (error) {
    console.error('Erreur impression questionnaire médical:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la génération du questionnaire' });
  }
};
exports.getQuestionnaireMedicalPrint = getQuestionnaireMedicalPrint;
 
