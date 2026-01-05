/**
 * ================================================
 * CONTRÔLEUR DES COMMISSIONS
 * ================================================
 * 
 * Gère les opérations liées aux commissions des commerciaux:
 * - Récupération des commissions par commercial
 * - Ajout de nouvelles commissions
 * - Les commissions sont stockées directement (pas de calcul)
 */

const pool = require('../db');

/**
 * Ajoute une commission pour un commercial
 * Les données sont fournies directement (pas de calcul automatique)
 * 
 * POST /api/commissions/ajouter
 */
exports.ajouterCommission = async (req, res) => {
  try {
    const { code_apporteur, montant_commission, date_calcul } = req.body;

    console.log('=== AJOUT COMMISSION ===');
    console.log('💼 Code apporteur:', code_apporteur);
    console.log('💰 Montant:', montant_commission);
    console.log('📅 Date:', date_calcul);

    // Vérifier que tous les champs requis sont présents
    if (!code_apporteur || !montant_commission) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur et montant commission requis'
      });
    }

    // Insérer la commission dans la base de données
    const commissionQuery = `
      INSERT INTO commission_instance 
      (code_apporteur, montant_commission, date_calcul)
      VALUES ($1, $2, $3)
      RETURNING id, code_apporteur, montant_commission, date_calcul, created_at, updated_at
    `;

    const commissionResult = await pool.query(commissionQuery, [
      code_apporteur,
      parseFloat(montant_commission).toFixed(2),
      date_calcul || new Date()
    ]);

    const commission = commissionResult.rows[0];

    console.log('✅ Commission ajoutée:', commission);

    res.json({
      success: true,
      message: 'Commission ajoutée avec succès',
      commission: {
        id: commission.id,
        code_apporteur: commission.code_apporteur,
        montant_commission: parseFloat(commission.montant_commission),
        date_calcul: commission.date_calcul
      }
    });

  } catch (error) {
    console.error('❌ Erreur ajout commission:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'ajout de la commission',
      error: error.message
    });
  }
};

/**
 * Récupère les commissions d'un commercial
 * Retourne TOUTES les commissions simples (id, code_apporteur, montant_commission, date_calcul)
 * 
 * GET /api/commissions/commercial/:code_apporteur
 */
exports.getCommissionsCommercial = async (req, res) => {
  try {
    const { code_apporteur } = req.params;

    console.log('=== RÉCUPÉRATION COMMISSIONS ===');
    console.log('💼 Code apporteur:', code_apporteur);

    // Récupérer toutes les commissions du commercial (colonnes simplifiées)
    const query = `
      SELECT 
        id,
        code_apporteur,
        montant_commission,
        date_calcul,
        created_at,
        updated_at
      FROM commission_instance
      WHERE code_apporteur = $1
      ORDER BY date_calcul DESC
    `;

    const result = await pool.query(query, [code_apporteur]);

    // Calculer le total des commissions
    const totalCommission = result.rows.reduce((sum, row) => {
      return sum + parseFloat(row.montant_commission);
    }, 0);

    console.log(`✅ ${result.rows.length} commission(s) trouvée(s)`);

    res.json({
      success: true,
      commissions: result.rows.map(row => ({
        id: row.id,
        code_apporteur: row.code_apporteur,
        montant_commission: parseFloat(row.montant_commission),
        date_calcul: row.date_calcul
      })),
      resume: {
        total_commission: parseFloat(totalCommission.toFixed(2)),
        nombre_commissions: result.rows.length
      }
    });

  } catch (error) {
    console.error('❌ Erreur récupération commissions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commissions',
      error: error.message
    });
  }
};

/**
 * Récupère le résumé des commissions
 * 
 * GET /api/commissions/resume/:code_apporteur
 */
exports.getResumeCommissions = async (req, res) => {
  try {
    const { code_apporteur } = req.params;

    console.log('=== RÉSUMÉ COMMISSIONS ===');
    console.log('💼 Code apporteur:', code_apporteur);

    const query = `
      SELECT 
        COUNT(*) as nombre_commissions,
        COALESCE(SUM(montant_commission), 0) as total_commission
      FROM commission_instance
      WHERE code_apporteur = $1
    `;

    const result = await pool.query(query, [code_apporteur]);

    const resume = {
      nombre_commissions: parseInt(result.rows[0].nombre_commissions),
      total_commission: parseFloat(result.rows[0].total_commission)
    };

    console.log('✅ Résumé récupéré:', resume);

    res.json({
      success: true,
      resume
    });

  } catch (error) {
    console.error('❌ Erreur résumé commissions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du résumé',
      error: error.message
    });
  }
};

/**
 * Récupère une commission spécifique par ID
 * 
 * GET /api/commissions/:commission_id
 */
exports.getCommissionById = async (req, res) => {
  try {
    const { commission_id } = req.params;

    console.log('=== RÉCUPÉRATION COMMISSION ===');
    console.log('🆔 Commission ID:', commission_id);

    const query = `
      SELECT 
        id,
        code_apporteur,
        montant_commission,
        date_calcul,
        created_at,
        updated_at
      FROM commission_instance
      WHERE id = $1
    `;

    const result = await pool.query(query, [commission_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commission non trouvée'
      });
    }

    const commission = result.rows[0];

    console.log('✅ Commission trouvée');

    res.json({
      success: true,
      commission: {
        id: commission.id,
        code_apporteur: commission.code_apporteur,
        montant_commission: parseFloat(commission.montant_commission),
        date_calcul: commission.date_calcul
      }
    });

  } catch (error) {
    console.error('❌ Erreur récupération commission:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la commission',
      error: error.message
    });
  }
};

/**
 * Supprime une commission (optionnel)
 * 
 * DELETE /api/commissions/:commission_id
 */
exports.deleteCommission = async (req, res) => {
  try {
    const { commission_id } = req.params;

    console.log('=== SUPPRESSION COMMISSION ===');
    console.log('🆔 Commission ID:', commission_id);

    const query = `
      DELETE FROM commission_instance
      WHERE id = $1
      RETURNING id
    `;

    const result = await pool.query(query, [commission_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Commission non trouvée'
      });
    }

    console.log('✅ Commission supprimée');

    res.json({
      success: true,
      message: 'Commission supprimée avec succès'
    });

  } catch (error) {
    console.error('❌ Erreur suppression commission:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de la commission',
      error: error.message
    });
  }
};
