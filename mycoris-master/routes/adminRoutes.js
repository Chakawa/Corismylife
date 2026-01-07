const express = require('express');
const router = express.Router();
const pool = require('../db');
const { verifyToken } = require('../middlewares/authMiddleware');
const { 
  requireAdminType, 
  requireSuperAdmin, 
  requireAdminOrAbove,
  getAdminPermissions 
} = require('../middleware/adminPermissions');

// Middleware pour vérifier que l'utilisateur est admin
const requireAdmin = (req, res, next) => {
  const adminRoles = ['super_admin', 'admin', 'moderation'];
  if (!adminRoles.includes(req.user.role)) {
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
 * GET /api/admin/permissions
 * Récupère les permissions de l'admin connecté
 */
router.get('/permissions', async (req, res) => {
  try {
    const role = req.user.role;
    const permissions = getAdminPermissions(role);
    
    res.json({
      success: true,
      role,
      permissions,
      user: {
        id: req.user.id,
        email: req.user.email,
        nom: req.user.nom,
        prenom: req.user.prenom
      }
    });
  } catch (error) {
    console.error('Erreur récupération permissions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des permissions'
    });
  }
});

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
 * POST /api/admin/users
 * Créer un nouvel utilisateur
 */
router.post('/users', async (req, res) => {
  const client = await pool.connect();
  try {
    const { 
      civilite, prenom, nom, email, telephone, date_naissance, lieu_naissance, 
      adresse, pays, role, admin_type, code_apporteur, password
    } = req.body;

    // Validation des champs obligatoires
    if (!prenom || !nom || !email || !role || !password) {
      return res.status(400).json({
        success: false,
        message: 'Champs obligatoires manquants (prenom, nom, email, role, password)'
      });
    }

    // Validation de l'email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Format d\'email invalide'
      });
    }

    // Validation du mot de passe (min 6 caractères)
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe doit contenir au moins 6 caractères'
      });
    }

    await client.query('BEGIN');

    // Vérifier si l'email existe déjà
    const existingUser = await client.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        message: 'Cet email existe déjà'
      });
    }

    // Hash du mot de passe
    const bcrypt = require('bcrypt');
    const hashedPassword = await bcrypt.hash(password, 10);

    // Construction de la requête d'insertion SANS admin_type (consolidé dans role)
    const query = `
      INSERT INTO users 
        (civilite, prenom, nom, email, telephone, date_naissance, lieu_naissance, 
         adresse, pays, role, code_apporteur, password_hash, created_at)
      VALUES 
        ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())
      RETURNING id, email, role, prenom, nom, civilite, telephone, 
                date_naissance, lieu_naissance, adresse, pays, code_apporteur
    `;

    const params = [
      civilite || 'M',
      prenom,
      nom,
      email,
      telephone || null,
      date_naissance || null,
      lieu_naissance || null,
      adresse || null,
      pays || null,
      role,
      code_apporteur || null,
      hashedPassword
    ];

    const result = await client.query(query, params);
    const newUser = result.rows[0];

    // Créer une notification pour tous les admins
    try {
      const adminEmails = await client.query(
        "SELECT id FROM users WHERE role = 'admin'"
      );
      
      if (adminEmails.rows.length > 0) {
        const notificationMessage = `Nouvel utilisateur ${role} enregistré: ${prenom} ${nom} (${email})`;
        
        for (const admin of adminEmails.rows) {
          await client.query(`
            INSERT INTO notifications 
              (admin_id, type, title, message, reference_id, reference_type, action_url, created_at)
            VALUES 
              ($1, $2, $3, $4, $5, $6, $7, NOW())
          `, [
            admin.id,
            'new_user',
            `Nouvel utilisateur ${role}`,
            notificationMessage,
            newUser.id,
            'user',
            `/utilisateurs?user=${newUser.id}`
          ]);
        }
      }
    } catch (notifError) {
      console.error('Erreur création notification:', notifError.message);
      // Ne pas bloquer la création d'utilisateur si la notification échoue
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: `Utilisateur créé avec succès: ${prenom} ${nom}`,
      user: newUser
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erreur création utilisateur:', error);
    
    let errorMessage = 'Erreur lors de la création de l\'utilisateur';
    if (error.code === '23505') {
      errorMessage = 'Cet email existe déjà dans le système';
    } else if (error.code === '23502') {
      errorMessage = 'Données requises manquantes';
    }
    
    res.status(500).json({
      success: false,
      message: errorMessage,
      error: error.message
    });
  } finally {
    client.release();
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
 * PUT /api/admin/users/:id
 * Modifier un utilisateur
 */
router.put('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { prenom, nom, email, telephone, adresse, role } = req.body;

    const query = `
      UPDATE users 
      SET prenom = $1, nom = $2, email = $3, telephone = $4, adresse = $5, role = $6, updated_at = NOW()
      WHERE id = $7
      RETURNING *
    `;

    const result = await pool.query(query, [prenom, nom, email, telephone, adresse, role, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    res.json({ success: true, user: result.rows[0] });
  } catch (error) {
    console.error('Erreur modification utilisateur:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la modification' });
  }
});

/**
 * DELETE /api/admin/users/:id
 * Supprimer un utilisateur
 */
router.delete('/users/:id', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;

    await client.query('BEGIN');

    // Vérifier que l'utilisateur existe et n'est pas admin
    const userCheck = await client.query('SELECT role, prenom, nom FROM users WHERE id = $1', [id]);
    
    if (userCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    if (userCheck.rows[0].role === 'admin') {
      await client.query('ROLLBACK');
      return res.status(403).json({
        success: false,
        message: 'Impossible de supprimer un administrateur'
      });
    }

    // Supprimer d'abord les notifications liées
    await client.query('DELETE FROM notifications WHERE reference_id = $1 AND reference_type = $2', [id, 'user']);

    // Ensuite supprimer l'utilisateur
    await client.query('DELETE FROM users WHERE id = $1', [id]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: `Utilisateur ${userCheck.rows[0].prenom} ${userCheck.rows[0].nom} supprimé avec succès`
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erreur suppression utilisateur:', error);
    
    let errorMessage = 'Erreur lors de la suppression de l\'utilisateur';
    if (error.code === '23503') {
      errorMessage = 'Impossible de supprimer cet utilisateur car il est lié à d\'autres enregistrements (contrats, souscriptions, etc.)';
    }
    
    res.status(500).json({
      success: false,
      message: errorMessage,
      error: error.message
    });
  } finally {
    client.release();
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

/**
 * GET /api/admin/notifications
 * Liste des notifications pour l'admin connecté
 */
router.get('/notifications', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
    const offset = Math.max(parseInt(req.query.offset || '0', 10), 0);
    const unread_only = req.query.unread_only === 'true';

    let query = `
      SELECT id, type, title, message, reference_id, reference_type, is_read, 
             created_at, action_url
      FROM notifications
      WHERE admin_id = $1
    `;
    const params = [req.user.id];
    let idx = 2;

    if (unread_only) {
      query += ` AND is_read = false`;
    }

    query += ` ORDER BY created_at DESC LIMIT $${idx} OFFSET $${idx + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    const countResult = await pool.query('SELECT COUNT(*) FROM notifications WHERE admin_id = $1 AND is_read = false', [req.user.id]);

    res.json({
      success: true,
      notifications: result.rows,
      unread_count: parseInt(countResult.rows[0].count),
      limit,
      offset
    });
  } catch (error) {
    console.error('Erreur notifications:', error);
    res.status(500).json({ success: false, message: 'Erreur chargement notifications' });
  }
});

/**
 * PUT /api/admin/notifications/:id/mark-read
 * Marquer une notification comme lue
 */
router.put('/notifications/:id/mark-read', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'UPDATE notifications SET is_read = true, read_at = NOW() WHERE id = $1 RETURNING *',
      [id]
    );
    res.json({ success: true, notification: result.rows[0] });
  } catch (error) {
    console.error('Erreur marquer lue:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * POST /api/admin/notifications/create
 * Créer une notification (à appeler lors d'événements importants)
 */
router.post('/notifications/create', async (req, res) => {
  try {
    const { type, title, message, reference_id, reference_type, action_url } = req.body;
    
    // Récupérer tous les admins
    const admins = await pool.query('SELECT id FROM users WHERE role = $1', ['admin']);
    
    for (const admin of admins.rows) {
      await pool.query(
        `INSERT INTO notifications (admin_id, type, title, message, reference_id, reference_type, action_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [admin.id, type, title, message, reference_id, reference_type, action_url]
      );
    }

    res.json({ success: true, message: 'Notification envoyée à tous les admins' });
  } catch (error) {
    console.error('Erreur création notification:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

module.exports = router;
