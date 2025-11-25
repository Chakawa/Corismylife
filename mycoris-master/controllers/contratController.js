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
    
    // Préparer les différents formats de téléphone
    const phoneVariants = [telephone];
    
    // Si le numéro commence par +225, ajouter la version sans +225
    if (telephone.startsWith('+225')) {
      const withoutCountryCode = telephone.replace('+225', '');
      phoneVariants.push(withoutCountryCode);
      // Ajouter aussi avec 0 au début si pas déjà présent
      if (!withoutCountryCode.startsWith('0')) {
        phoneVariants.push('0' + withoutCountryCode);
      }
    }
    // Si le numéro commence par 225 (sans +), ajouter les autres versions
    else if (telephone.startsWith('225')) {
      phoneVariants.push('+' + telephone);
      phoneVariants.push(telephone.replace('225', '0'));
    }
    // Si le numéro commence par 0, ajouter les versions avec indicatif
    else if (telephone.startsWith('0')) {
      const withoutZero = telephone.substring(1);
      phoneVariants.push('+225' + withoutZero);
      phoneVariants.push('225' + withoutZero);
    }
    // Sinon, ajouter les versions avec indicatif
    else {
      phoneVariants.push('+225' + telephone);
      phoneVariants.push('225' + telephone);
      phoneVariants.push('0' + telephone);
    }
    
    console.log('🔍 Formats de recherche:', phoneVariants);
    
    // Créer la requête avec tous les variants
    const placeholders = phoneVariants.map((_, index) => `$${index + 1}`).join(', ');
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
      WHERE telephone1 IN (${placeholders}) OR telephone2 IN (${placeholders})
      ORDER BY dateeffet DESC
    `;
    
    const result = await pool.query(query, phoneVariants);
    
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
        
        // Préparer les différents formats de téléphone
        const phoneVariants = [userPhone];
        
        if (userPhone.startsWith('+225')) {
          const withoutCountryCode = userPhone.replace('+225', '');
          phoneVariants.push(withoutCountryCode);
          if (!withoutCountryCode.startsWith('0')) {
            phoneVariants.push('0' + withoutCountryCode);
          }
        } else if (userPhone.startsWith('225')) {
          phoneVariants.push('+' + userPhone);
          phoneVariants.push(userPhone.replace('225', '0'));
        } else if (userPhone.startsWith('0')) {
          const withoutZero = userPhone.substring(1);
          phoneVariants.push('+225' + withoutZero);
          phoneVariants.push('225' + withoutZero);
        } else {
          phoneVariants.push('+225' + userPhone);
          phoneVariants.push('225' + userPhone);
          phoneVariants.push('0' + userPhone);
        }
        
        // Vérifier si le téléphone du contrat correspond à l'un des variants
        if (phoneVariants.includes(contrat.telephone1) || phoneVariants.includes(contrat.telephone2)) {
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
      console.log('📞 Téléphone utilisateur:', telephone);
      
      // Préparer les différents formats de téléphone
      const phoneVariants = [telephone];
      
      if (telephone.startsWith('+225')) {
        const withoutCountryCode = telephone.replace('+225', '');
        phoneVariants.push(withoutCountryCode);
        if (!withoutCountryCode.startsWith('0')) {
          phoneVariants.push('0' + withoutCountryCode);
        }
      } else if (telephone.startsWith('225')) {
        phoneVariants.push('+' + telephone);
        phoneVariants.push(telephone.replace('225', '0'));
      } else if (telephone.startsWith('0')) {
        const withoutZero = telephone.substring(1);
        phoneVariants.push('+225' + withoutZero);
        phoneVariants.push('225' + withoutZero);
      } else {
        phoneVariants.push('+225' + telephone);
        phoneVariants.push('225' + telephone);
        phoneVariants.push('0' + telephone);
      }
      
      console.log('🔍 Formats de recherche:', phoneVariants);
      
      // Créer la requête avec tous les variants
      const placeholders = phoneVariants.map((_, index) => `$${index + 1}`).join(', ');
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
        WHERE telephone1 IN (${placeholders}) OR telephone2 IN (${placeholders})
        ORDER BY dateeffet DESC
      `;
      params = phoneVariants;
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
