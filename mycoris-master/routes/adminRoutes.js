const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verifyToken } = require('../middlewares/authMiddleware');

// Middleware pour vérifier que l'utilisateur est admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Accès refusé. Seuls les administrateurs peuvent accéder à cette ressource.'
    });
  }
  next();
};

// Toutes les routes nécessitent une authentification admin
router.use(verifyToken);
router.use(requireAdmin);

/**
 * GET /api/admin/stats
 * Statistiques globales du dashboard
 */
router.get('/stats', async (req, res) => {
  try {
    // Nombre d'utilisateurs par rôle
    const usersStats = await pool.query(`
      SELECT role, COUNT(*)::int AS count
      FROM users
      GROUP BY role
    `);

    const totalUsers = usersStats.rows.reduce((sum, r) => sum + Number(r.count || 0), 0);

    // Statistiques des contrats + revenus
    const contractsStats = await pool.query(`
      SELECT 
        etat,
        COUNT(*)::int AS count,
        SUM(COALESCE(montant_encaisse, 0))::numeric AS montant_total
      FROM contrats
      GROUP BY etat
    `);

    const totalContracts = contractsStats.rows.reduce((sum, r) => sum + Number(r.count || 0), 0);
    const totalRevenue = contractsStats.rows.reduce((sum, r) => sum + Number(r.montant_total || 0), 0);

    // Statistiques des souscriptions
    const subscriptionsStats = await pool.query(`
      SELECT 
        statut,
        COUNT(*)::int AS count
      FROM subscriptions
      GROUP BY statut
    `);
    const totalSubscriptions = subscriptionsStats.rows.reduce((sum, r) => sum + Number(r.count || 0), 0);

    // Revenus mensuels (12 derniers mois)
    const revenusStats = await pool.query(`
      SELECT 
        EXTRACT(MONTH FROM dateeffet)::int AS mois_num,
        EXTRACT(YEAR FROM dateeffet)::int AS annee,
        SUM(COALESCE(montant_encaisse, 0))::numeric AS total
      FROM contrats
      WHERE dateeffet >= NOW() - INTERVAL '12 months'
      GROUP BY annee, mois_num
      ORDER BY annee, mois_num
    `);

    // Répartition par produit (basée sur les contrats saisis)
    const produitsStats = await pool.query(`
      SELECT 
        COALESCE(codeprod, 'Non défini') AS produit,
        COUNT(*)::int AS count,
        SUM(COALESCE(montant_encaisse, 0))::numeric AS montant_total
      FROM contrats
      GROUP BY COALESCE(codeprod, 'Non défini')
      ORDER BY count DESC
    `);

    res.json({
      success: true,
      stats: {
        users: usersStats.rows,
        contracts: contractsStats.rows,
        subscriptions: subscriptionsStats.rows,
        revenus: revenusStats.rows,
        produits: produitsStats.rows,
        totals: {
          users: totalUsers,
          contracts: totalContracts,
          subscriptions: totalSubscriptions,
          revenue: totalRevenue
        }
      }
    });
  } catch (error) {
    console.error('Erreur stats admin:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
});

/**
 * GET /api/admin/users
 * Liste de tous les utilisateurs avec filtres
 */
router.get('/users', async (req, res) => {
  try {
    const { role, search, limit = 50, offset = 0 } = req.query;

    let query = 'SELECT * FROM users WHERE 1=1';
    const params = [];
    let paramCount = 1;

    if (role) {
      query += ` AND role = $${paramCount}`;
      params.push(role);
      paramCount++;
    }

    if (search) {
      query += ` AND (nom ILIKE $${paramCount} OR prenom ILIKE $${paramCount} OR email ILIKE $${paramCount} OR telephone ILIKE $${paramCount})`;
      params.push(`%${search}%`);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    
    // Compter le total
    const countResult = await pool.query('SELECT COUNT(*) FROM users');

    res.json({
      success: true,
      users: result.rows,
      total: parseInt(countResult.rows[0].count),
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    console.error('Erreur liste utilisateurs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des utilisateurs'
    });
  }
});

/**
 * GET /api/admin/users/:id
 * Détails d'un utilisateur
 */
router.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    res.json({
      success: true,
      user: userResult.rows[0]
    });
  } catch (error) {
    console.error('Erreur détails utilisateur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de l\'utilisateur'
    });
  }
});

/**
 * DELETE /api/admin/users/:id
 * Supprimer un utilisateur
 */
router.delete('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier que l'utilisateur existe et n'est pas admin
    const userCheck = await pool.query('SELECT role FROM users WHERE id = $1', [id]);
    
    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    if (userCheck.rows[0].role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Impossible de supprimer un administrateur'
      });
    }

    await pool.query('DELETE FROM users WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'Utilisateur supprimé avec succès'
    });
  } catch (error) {
    console.error('Erreur suppression utilisateur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la suppression de l\'utilisateur'
    });
  }
});

/**
 * GET /api/admin/contracts
 * Liste de tous les contrats
 */
router.get('/contracts', async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;

    let query = 'SELECT * FROM contrats WHERE 1=1';
    const params = [];
    let paramCount = 1;

    if (status) {
      query += ` AND etat = $${paramCount}`;
      params.push(status);
      paramCount++;
    }

    query += ` ORDER BY dateeffet DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    const countResult = await pool.query('SELECT COUNT(*) FROM contrats');

    res.json({
      success: true,
      contracts: result.rows,
      total: parseInt(countResult.rows[0].count)
    });
  } catch (error) {
    console.error('Erreur liste contrats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats'
    });
  }
});

/**
 * GET /api/admin/subscriptions
 * Liste de toutes les souscriptions
 */
router.get('/subscriptions', async (req, res) => {
  try {
    const { statut, limit = 50, offset = 0 } = req.query;

    let query = 'SELECT * FROM souscriptions WHERE 1=1';
    const params = [];
    let paramCount = 1;

    if (statut) {
      query += ` AND statut = $${paramCount}`;
      params.push(statut);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    const countResult = await pool.query('SELECT COUNT(*) FROM souscriptions');

    res.json({
      success: true,
      subscriptions: result.rows,
      total: parseInt(countResult.rows[0].count)
    });
  } catch (error) {
    console.error('Erreur liste souscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des souscriptions'
    });
  }
});

/**
 * GET /api/admin/commissions
 * Liste de toutes les commissions
 */
router.get('/commissions', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        ci.*,
        u.nom,
        u.prenom,
        u.email
      FROM commission_instance ci
      LEFT JOIN users u ON u.code_apporteur = ci.code_apporteur
      ORDER BY ci.date_calcul DESC
      LIMIT 100
    `);

    res.json({
      success: true,
      commissions: result.rows
    });
  } catch (error) {
    console.error('Erreur liste commissions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des commissions'
    });
  }
});

/**
 * GET /api/admin/commissions/stats
 * Statistiques des commissions
 */
router.get('/commissions/stats', async (req, res) => {
  try {
    const stats = await pool.query(`
      SELECT 
        COUNT(*) as total_commissions,
        SUM(CAST(montant_commission AS NUMERIC)) as total_montant,
        COUNT(DISTINCT code_apporteur) as total_commerciaux
      FROM commission_instance
    `);

    res.json({
      success: true,
      stats: stats.rows[0]
    });
  } catch (error) {
    console.error('Erreur stats commissions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
});

/**
 * GET /api/admin/activities
 * Activités récentes
 */
router.get('/activities', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '100', 10), 200)
    const offset = Math.max(parseInt(req.query.offset || '0', 10), 0)
    const q = (req.query.q || '').toString().trim()

    // Construction dynamique avec filtre texte optionnel
    let baseQuery = `
      FROM subscriptions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE 1=1
    `
    const params = []
    let idx = 1

    if (q) {
      baseQuery += ` AND (
        u.nom ILIKE $${idx} OR u.prenom ILIKE $${idx} OR u.email ILIKE $${idx} OR
        s.produit_nom ILIKE $${idx} OR s.statut ILIKE $${idx} OR COALESCE(s.reference, '') ILIKE $${idx} OR COALESCE(s.numero_contrat, '') ILIKE $${idx}
      )`
      params.push(`%${q}%`)
      idx++
    }

    const listQuery = `
      SELECT s.id, s.date_creation AS created_at, s.statut, u.nom AS nom_client, u.prenom AS prenom_client, s.produit_nom AS produit
      ${baseQuery}
      ORDER BY s.date_creation DESC
      LIMIT $${idx} OFFSET $${idx + 1}
    `
    const listParams = params.concat([limit, offset])
    const activities = await pool.query(listQuery, listParams)

    const countQuery = `SELECT COUNT(*)::int AS total ${baseQuery}`
    const totalResult = await pool.query(countQuery, params)

    res.json({
      success: true,
      activities: activities.rows,
      total: totalResult.rows[0].total,
      limit,
      offset
    });
  } catch (error) {
    console.error('Erreur activités:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des activités'
    });
  }
});

module.exports = router;
