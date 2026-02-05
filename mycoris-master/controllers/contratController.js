/**
 * ===============================================
 * CONTRÔLEUR DES CONTRATS
 * ===============================================
 * 
 * Gère les opérations liées aux contrats depuis la table `contrats` :
 * - Récupération des contrats d'un client (via telephone1)
 * - Récupération des contrats d'un commercial (via codeappo)
 * - Affichage des détails d'un contrat
 */

const pool = require('../db');

/**
 * Récupère tous les contrats d'un client via son numéro de téléphone
 * Route: GET /api/contrats/client/:telephone
 */
exports.getContratsByTelephone = async (req, res) => {
  try {
    const { telephone } = req.params;
    
    console.log('=== RÉCUPÉRATION CONTRATS CLIENT ===');
    console.log('📞 Téléphone:', telephone);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Nettoyer le numéro: enlever +225 s'il existe
    let cleanPhone = telephone;
    if (telephone.startsWith('+225')) {
      cleanPhone = telephone.substring(4); // Enlever +225
    }
    console.log('📞 Téléphone nettoyé:', cleanPhone);
    
    // Récupérer tous les contrats du client avec informations de paiement
    // On cherche avec les deux formats: avec et sans +225
    const query = `
      SELECT 
        id,
        codeprod,
        codeinte,
        codeappo,
        numepoli,
        duree,
        dateeffet,
        dateeche,
        periodicite,
        domiciliation,
        capital,
        rente,
        prime,
        montant_encaisse,
        impaye,
        etat,
        telephone1,
        telephone2,
        nom_prenom,
        datenaissance,
        next_payment_date,
        last_payment_date,
        payment_method,
        payment_status,
        total_paid,
        CASE 
          WHEN next_payment_date IS NULL THEN NULL
          ELSE EXTRACT(DAY FROM (next_payment_date - CURRENT_DATE))::INTEGER
        END as jours_restants
      FROM contrats
      WHERE telephone1 = $1 
         OR telephone1 = $2
         OR telephone2 = $1
         OR telephone2 = $2
      ORDER BY 
        CASE payment_status
          WHEN 'en_retard' THEN 1
          WHEN 'echeance_proche' THEN 2
          WHEN 'a_jour' THEN 3
          ELSE 4
        END,
        next_payment_date NULLS LAST,
        dateeffet DESC
    `;
    
    const phoneWithPrefix = '+225' + cleanPhone;
    const result = await pool.query(query, [cleanPhone, phoneWithPrefix]);
    
    console.log(`✅ ${result.rows.length} contrat(s) trouvé(s)`);
    
    res.json({
      success: true,
      count: result.rows.length,
      contrats: result.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération contrats client:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

/**
 * Récupère tous les contrats d'un commercial via son code apporteur
 * Route: GET /api/contrats/commercial/:codeappo
 */
exports.getContratsByCodeApporteur = async (req, res) => {
  try {
    const { codeappo } = req.params;
    
    console.log('=== RÉCUPÉRATION CONTRATS COMMERCIAL ===');
    console.log('💼 Code apporteur:', codeappo);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Vérifier que l'utilisateur est un commercial
    if (req.user.role !== 'commercial') {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé aux commerciaux'
      });
    }
    
    // Récupérer tous les contrats du commercial
    const query = `
      SELECT 
        id,
        codeprod,
        codeinte,
        codeappo,
        numepoli,
        duree,
        dateeffet,
        dateeche,
        periodicite,
        domiciliation,
        capital,
        rente,
        prime,
        montant_encaisse,
        impaye,
        etat,
        telephone1,
        telephone2,
        nom_prenom,
        datenaissance
      FROM contrats
      WHERE codeappo = $1
      ORDER BY dateeffet DESC
    `;
    
    const result = await pool.query(query, [codeappo]);
    
    console.log(`✅ ${result.rows.length} contrat(s) trouvé(s)`);
    
    res.json({
      success: true,
      count: result.rows.length,
      contrats: result.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération contrats commercial:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

/**
 * Récupère les détails complets d'un contrat par numepoli (numéro de police)
 * Route: GET /api/commercial/contrat_details/:numepoli
 */
exports.getContratDetailsByNumepoli = async (req, res) => {
  try {
    const { numepoli } = req.params;
    
    console.log('=== RÉCUPÉRATION DÉTAILS CONTRAT PAR NUMEPOLI ===');
    console.log('📋 Numéro de police:', numepoli);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Récupérer tous les détails du contrat + bénéficiaires
    const contratQuery = `
      SELECT *
      FROM contrats
      WHERE numepoli = $1
    `;
    
    const contratResult = await pool.query(contratQuery, [numepoli]);
    
    if (contratResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }
    
    const contrat = contratResult.rows[0];
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    // 1. Admin a accès à tout
    if (req.user.role === 'admin') {
      hasAccess = true;
    }
    // 2. Commercial a accès à ses contrats
    else if (req.user.role === 'commercial' && req.user.code_apporteur === contrat.codeappo) {
      hasAccess = true;
    }
    // 3. Client a accès à ses contrats (via téléphone)
    else if (req.user.role === 'client') {
      // Récupérer le téléphone du user
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      if (userResult.rows.length > 0) {
        const userPhone = userResult.rows[0].telephone;
        
        // Nettoyer le numéro: enlever +225 s'il existe
        let cleanPhone = userPhone;
        if (userPhone.startsWith('+225')) {
          cleanPhone = userPhone.substring(4);
        }
        const phoneWithPrefix = '+225' + cleanPhone;
        
        // Comparer avec et sans +225
        if (contrat.telephone1 === cleanPhone || contrat.telephone1 === phoneWithPrefix ||
            contrat.telephone2 === cleanPhone || contrat.telephone2 === phoneWithPrefix) {
          hasAccess = true;
        }
      }
    }
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce contrat'
      });
    }
    
    // Récupérer les bénéficiaires
    const benefQuery = `
      SELECT *
      FROM beneficiaires
      WHERE numepoli = $1
      ORDER BY id
    `;
    
    const benefResult = await pool.query(benefQuery, [numepoli]);
    
    console.log('✅ Contrat trouvé avec', benefResult.rows.length, 'bénéficiaire(s)');
    
    res.json({
      success: true,
      contrat: contrat,
      beneficiaires: benefResult.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération détails contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
};

/**
 * Récupère les détails complets d'un contrat spécifique
 * Route: GET /api/contrats/:id
 */
exports.getContratDetails = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('=== RÉCUPÉRATION DÉTAILS CONTRAT ===');
    console.log('📋 Contrat ID:', id);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Récupérer tous les détails du contrat
    const query = `
      SELECT *
      FROM contrats
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }
    
    const contrat = result.rows[0];
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    // 1. Admin a accès à tout
    if (req.user.role === 'admin') {
      hasAccess = true;
    }
    // 2. Commercial a accès à ses contrats
    else if (req.user.role === 'commercial' && req.user.code_apporteur === contrat.codeappo) {
      hasAccess = true;
    }
    // 3. Client a accès à ses contrats (via téléphone)
    else if (req.user.role === 'client') {
      // Récupérer le téléphone du user
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      if (userResult.rows.length > 0) {
        const userPhone = userResult.rows[0].telephone;
        
        // Nettoyer le numéro: enlever +225 s'il existe
        let cleanPhone = userPhone;
        if (userPhone.startsWith('+225')) {
          cleanPhone = userPhone.substring(4);
        }
        const phoneWithPrefix = '+225' + cleanPhone;
        
        // Comparer avec et sans +225
        if (contrat.telephone1 === cleanPhone || contrat.telephone1 === phoneWithPrefix ||
            contrat.telephone2 === cleanPhone || contrat.telephone2 === phoneWithPrefix) {
          hasAccess = true;
        }
      }
    }
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce contrat'
      });
    }
    
    console.log('✅ Contrat trouvé et accès autorisé');
    
    res.json({
      success: true,
      contrat: result.rows[0]
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération détails contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
};

/**
 * Récupère les contrats de l'utilisateur connecté
 * Route: GET /api/contrats/mes-contrats
 */
exports.getMesContrats = async (req, res) => {
  try {
    console.log('=== RÉCUPÉRATION MES CONTRATS ===');
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    console.log('📞 Code apporteur:', req.user.code_apporteur);
    
    let query, params;
    
    if (req.user.role === 'commercial') {
      // Commercial: récupérer via code_apporteur
      query = `
        SELECT 
          id,
          codeprod,
          codeinte,
          codeappo,
          numepoli,
          duree,
          dateeffet,
          dateeche,
          periodicite,
          domiciliation,
          capital,
          rente,
          prime,
          montant_encaisse,
          impaye,
          etat,
          telephone1,
          telephone2,
          nom_prenom,
          datenaissance
        FROM contrats
        WHERE codeappo = $1
        ORDER BY dateeffet DESC
      `;
      params = [req.user.code_apporteur];
    } else {
      // Client: récupérer via téléphone
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      
      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Utilisateur non trouvé'
        });
      }
      
      const telephone = userResult.rows[0].telephone;
      
      // Nettoyer le numéro: enlever +225 s'il existe
      let cleanPhone = telephone;
      if (telephone.startsWith('+225')) {
        cleanPhone = telephone.substring(4);
      }
      const phoneWithPrefix = '+225' + cleanPhone;
      
      console.log('📞 Téléphone nettoyé:', cleanPhone);
      console.log('📞 Avec préfixe:', phoneWithPrefix);
      
      query = `
        SELECT 
          id,
          codeprod,
          codeinte,
          codeappo,
          numepoli,
          duree,
          dateeffet,
          dateeche,
          periodicite,
          domiciliation,
          capital,
          rente,
          prime,
          montant_encaisse,
          impaye,
          etat,
          telephone1,
          telephone2,
          nom_prenom,
          datenaissance
        FROM contrats
        WHERE telephone1 = $1 OR telephone1 = $2
           OR telephone2 = $1 OR telephone2 = $2
        ORDER BY dateeffet DESC
      `;
      params = [cleanPhone, phoneWithPrefix];
    }
    
    const result = await pool.query(query, params);
    
    console.log(`✅ ${result.rows.length} contrat(s) trouvé(s)`);
    
    res.json({
      success: true,
      count: result.rows.length,
      contrats: result.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération mes contrats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

/**
 * Génère le PDF d'un contrat
 * Route: GET /api/contrats/pdf/:numepoli
 */
exports.generateContratPdf = async (req, res) => {
  try {
    const { numepoli } = req.params;
    
    console.log('=== GÉNÉRATION PDF CONTRAT ===');
    console.log('📋 Numéro police:', numepoli);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Récupérer les détails du contrat
    const query = `
      SELECT *
      FROM contrats
      WHERE numepoli = $1
    `;
    
    const result = await pool.query(query, [numepoli]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }
    
    const contrat = result.rows[0];
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    if (req.user.role === 'admin') {
      hasAccess = true;
    } else if (req.user.role === 'commercial' && req.user.code_apporteur === contrat.codeappo) {
      hasAccess = true;
    } else if (req.user.role === 'client') {
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      if (userResult.rows.length > 0) {
        const userPhone = userResult.rows[0].telephone;
        let cleanPhone = userPhone;
        if (userPhone.startsWith('+225')) {
          cleanPhone = userPhone.substring(4);
        }
        const phoneWithPrefix = '+225' + cleanPhone;
        
        if (contrat.telephone1 === cleanPhone || contrat.telephone1 === phoneWithPrefix ||
            contrat.telephone2 === cleanPhone || contrat.telephone2 === phoneWithPrefix) {
          hasAccess = true;
        }
      }
    }
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce contrat'
      });
    }
    
    // Récupérer les bénéficiaires
    const benefQuery = `
      SELECT * FROM beneficiaires
      WHERE numepoli = $1
    `;
    const benefResult = await pool.query(benefQuery, [numepoli]);
    
    // Pour l'instant, retourner une réponse JSON
    // TODO: Implémenter la génération PDF réelle avec une bibliothèque comme PDFKit
    console.log('✅ PDF prêt (simulation)');
    
    res.json({
      success: true,
      message: 'PDF généré avec succès (simulation)',
      contrat: contrat,
      beneficiaires: benefResult.rows,
      note: 'Pour générer un vrai PDF, installer PDFKit ou utiliser un service externe'
    });
    
  } catch (error) {
    console.error('❌ Erreur génération PDF contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération du PDF',
      error: error.message
    });
  }
};
