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
 * GET /api/admin/stats/connexions-mensuelles
 * Statistiques des connexions clients par mois (derniers 12 mois)
 */
router.get('/stats/connexions-mensuelles', async (req, res) => {
  try {
    const { months = 12 } = req.query;
    
    // Récupérer les connexions des clients (role='client') groupées par mois
    const result = await pool.query(`
      WITH monthly_stats AS (
        SELECT 
          DATE_TRUNC('month', ual.created_at) AS mois,
          COUNT(DISTINCT ual.user_id) AS utilisateurs_uniques,
          COUNT(*) AS total_connexions
        FROM user_activity_logs ual
        INNER JOIN users u ON u.id = ual.user_id
        WHERE 
          ual.type = 'login'
          AND u.role = 'client'
          AND ual.created_at >= NOW() - INTERVAL '${parseInt(months)} months'
        GROUP BY DATE_TRUNC('month', ual.created_at)
        ORDER BY mois DESC
      )
      SELECT 
        TO_CHAR(mois, 'YYYY-MM') AS mois,
        TO_CHAR(mois, 'Month YYYY') AS mois_label,
        EXTRACT(MONTH FROM mois)::int AS mois_num,
        EXTRACT(YEAR FROM mois)::int AS annee,
        utilisateurs_uniques::int,
        total_connexions::int
      FROM monthly_stats
      ORDER BY mois ASC
    `);

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur stats connexions mensuelles:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques de connexion'
    });
  }
});

/**
 * POST /api/admin/users
 * Créer un nouvel utilisateur
 */
router.post('/users', async (req, res) => {
  const client = await pool.connect();
  let transactionActive = false;
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
    transactionActive = true;

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

    await client.query('COMMIT');
    transactionActive = false;

    // Créer une notification pour tous les admins (hors transaction principale)
    // IMPORTANT: ne jamais impacter la persistance du compte utilisateur.
    try {
      const adminUsers = await pool.query(
        "SELECT id FROM users WHERE role IN ('super_admin', 'admin', 'moderation')"
      );

      if (adminUsers.rows.length > 0) {
        const notificationMessage = `Nouvel utilisateur ${role} enregistré: ${prenom} ${nom} (${email})`;

        for (const admin of adminUsers.rows) {
          await pool.query(`
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
      console.error('Erreur création notification (non bloquante):', notifError.message);
    }

    res.status(201).json({
      success: true,
      message: `Utilisateur créé avec succès: ${prenom} ${nom}`,
      user: newUser
    });
  } catch (error) {
    if (transactionActive) {
      await client.query('ROLLBACK');
    }
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

    let query = `
      SELECT 
        u.*,
        suspendeur.nom as suspendeur_nom,
        suspendeur.prenom as suspendeur_prenom,
        (SELECT MAX(created_at) FROM user_activity_logs WHERE user_id = u.id AND type = 'login') as derniere_connexion,
        (SELECT MAX(created_at) FROM user_activity_logs WHERE user_id = u.id AND type = 'logout') as derniere_deconnexion
      FROM users u
      LEFT JOIN users suspendeur ON u.suspendu_par = suspendeur.id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;

    if (role) {
      query += ` AND u.role = $${paramCount}`;
      params.push(role);
      paramCount++;
    }

    if (search) {
      query += ` AND (u.nom ILIKE $${paramCount} OR u.prenom ILIKE $${paramCount} OR u.email ILIKE $${paramCount} OR u.telephone ILIKE $${paramCount})`;
      params.push(`%${search}%`);
      paramCount++;
    }

    query += ` ORDER BY u.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
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
    const { prenom, nom, email, telephone, adresse, role, password, code_apporteur } = req.body;

    // Construire la requête dynamiquement selon les champs fournis
    const updateFields = [];
    const params = [];
    let paramCount = 1;

    if (prenom !== undefined) {
      updateFields.push(`prenom = $${paramCount}`);
      params.push(prenom);
      paramCount++;
    }
    if (nom !== undefined) {
      updateFields.push(`nom = $${paramCount}`);
      params.push(nom);
      paramCount++;
    }
    if (email !== undefined) {
      updateFields.push(`email = $${paramCount}`);
      params.push(email);
      paramCount++;
    }
    if (telephone !== undefined) {
      updateFields.push(`telephone = $${paramCount}`);
      params.push(telephone);
      paramCount++;
    }
    if (adresse !== undefined) {
      updateFields.push(`adresse = $${paramCount}`);
      params.push(adresse);
      paramCount++;
    }
    if (role !== undefined) {
      updateFields.push(`role = $${paramCount}`);
      params.push(role);
      paramCount++;
    }
    if (code_apporteur !== undefined) {
      updateFields.push(`code_apporteur = $${paramCount}`);
      params.push(code_apporteur);
      paramCount++;
    }

    // Si un nouveau mot de passe est fourni, le hasher avant mise à jour
    if (password && password.trim() !== '') {
      const bcrypt = require('bcryptjs');
      const hashedPassword = await bcrypt.hash(password, 10);
      updateFields.push(`password_hash = $${paramCount}`);
      params.push(hashedPassword);
      paramCount++;
      console.log(`🔐 Admin modifying password for user ${id}`);
    }

    // Toujours mettre à jour updated_at
    updateFields.push(`updated_at = NOW()`);

    if (updateFields.length === 1) {
      // Seulement updated_at, aucune modification réelle
      return res.status(400).json({ success: false, message: 'Aucune donnée à modifier' });
    }

    const query = `
      UPDATE users 
      SET ${updateFields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, prenom, nom, email, telephone, adresse, role, code_apporteur, created_at, updated_at
    `;

    params.push(id);

    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    console.log(`✅ User ${id} updated successfully by admin`);
    res.json({ success: true, user: result.rows[0] });
  } catch (error) {
    console.error('Erreur modification utilisateur:', error);
    
    // Gestion des erreurs d'unicité (email ou téléphone déjà existant)
    if (error.code === '23505') {
      if (error.constraint === 'users_email_key') {
        return res.status(400).json({ success: false, message: 'Cet email est déjà utilisé' });
      }
      if (error.constraint === 'users_telephone_key') {
        return res.status(400).json({ success: false, message: 'Ce numéro de téléphone est déjà utilisé' });
      }
    }
    
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

    let query = `
      SELECT c.*,
             s.id AS subscription_id,
             s.produit_nom,
             s.souscriptiondata
      FROM contrats c
      LEFT JOIN subscriptions s ON s.numero_police = c.numepoli
      WHERE 1=1`;
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
    const byStatusResult = await pool.query('SELECT etat, COUNT(*) as count FROM contrats GROUP BY etat');

    const byStatus = {};
    for (const row of byStatusResult.rows) {
      byStatus[row.etat] = parseInt(row.count, 10);
    }

    res.json({
      success: true,
      contracts: result.rows,
      total: parseInt(countResult.rows[0].count, 10),
      stats: {
        by_status: byStatus
      }
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
 * GET /api/admin/contracts/:id
 * Détails d'un contrat
 */
router.get('/contracts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM contrats WHERE id = $1', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Contrat introuvable' });
    }

    res.json({ success: true, contract: result.rows[0] });
  } catch (error) {
    console.error('Erreur détails contrat:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * DELETE /api/admin/contracts/:id
 * Supprimer un contrat
 */
router.delete('/contracts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM contrats WHERE id = $1 RETURNING *', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Contrat introuvable' });
    }

    res.json({ success: true, message: 'Contrat supprimé avec succès', contract: result.rows[0] });
  } catch (error) {
    console.error('Erreur suppression contrat:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression' });
  }
});

/**
 * PATCH /api/admin/contracts/:id/status
 * Mettre à jour le statut d'un contrat
 */
router.patch('/contracts/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const allowed = ['actif', 'suspendu', 'en_attente', 'resilie'];
    if (!allowed.includes((status || '').toLowerCase())) {
      return res.status(400).json({ success: false, message: 'Statut invalide' });
    }

    const result = await pool.query(
      'UPDATE contrats SET etat = $1 WHERE id = $2 RETURNING *',
      [status, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Contrat introuvable' });
    }

    res.json({ success: true, contract: result.rows[0] });
  } catch (error) {
    console.error('Erreur mise à jour statut contrat:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * POST /api/admin/contracts
 * Créer un nouveau contrat
 */
router.post('/contracts', async (req, res) => {
  try {
    const {
      numepoli,
      nom_prenom,
      codeprod,
      dateeffet,
      etat,
      email,
      telephone
    } = req.body;

    if (!numepoli || !nom_prenom || !codeprod || !dateeffet) {
      return res.status(400).json({
        success: false,
        message: 'Champs requis manquants: numepoli, nom_prenom, codeprod, dateeffet'
      });
    }

    const result = await pool.query(
      `INSERT INTO contrats (numepoli, nom_prenom, codeprod, dateeffet, etat, email, telephone)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [numepoli, nom_prenom, codeprod, dateeffet, etat || 'en_attente', email, telephone]
    );

    res.json({
      success: true,
      message: 'Contrat créé avec succès',
      contract: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur création contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du contrat',
      error: error.message
    });
  }
});

/**
 * ROUTE : GET /api/admin/subscriptions
 * Liste toutes les souscriptions avec informations de création et origine.
 * 
 * FONCTIONNEMENT :
 * 1. Récupère les souscriptions de la table subscriptions
 * 2. JOIN avec users pour obtenir nom/prénom/email du créateur
 * 3. Extrait souscriptiondata (JSONB) pour déterminer l'origine :
 *    - Si client_info existe => Commercial pour un client
 *    - Si code_apporteur existe => Commercial direct
 *    - Sinon => Client direct
 * 4. Retourne aussi :
 *    - total : nombre total de souscriptions (table subscriptions)
 *    - stats.by_status : décompte par statut (proposition, payé, contrat, activé, annulé)
 *    - stats.total_contrats : nombre total de contrats réels (table contrats)
 * 
 * QUERY PARAMS :
 * - statut (optionnel) : filtre par statut
 * - limit (défaut: 50) : nombre de résultats par page
 * - offset (défaut: 0) : pagination
 */
router.get('/subscriptions', async (req, res) => {
  try {
    const { statut, limit = 50, offset = 0 } = req.query;

    let query = `
      SELECT 
        s.id,
        s.user_id,
        s.numero_police,
        s.produit_nom,
        s.statut,
        s.date_creation as created_at,
        s.date_validation,
        s.souscriptiondata,
        s.code_apporteur,
        s.updated_at,
        u.nom as creator_nom,
        u.prenom as creator_prenom,
        u.role as creator_role,
        u.email as creator_email
      FROM subscriptions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE 1=1
    `;
    const params = [];
    let paramCount = 1;

    if (statut) {
      query += ` AND s.statut = $${paramCount}`;
      params.push(statut);
      paramCount++;
    }

    query += ` ORDER BY s.date_creation DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
        // Compter le total de souscriptions (table subscriptions)
        const countResult = await pool.query('SELECT COUNT(*) FROM subscriptions');
        // Compter par statut dans subscriptions
        const byStatusResult = await pool.query('SELECT statut, COUNT(*) as count FROM subscriptions GROUP BY statut');
        // Compter le total de contrats réels (table contrats)
        const contratsCountResult = await pool.query('SELECT COUNT(*) as total FROM contrats');

    const byStatus = {};
    for (const row of byStatusResult.rows) {
      byStatus[row.statut] = parseInt(row.count, 10);
    }

    // Enrichir avec infos d'origine depuis souscriptiondata et user_id
    const subscriptions = result.rows.map(r => {
      let origin = 'Client';
      let client_name = null;
      
      // Si la souscription a des infos client dans souscriptiondata, c'est un commercial
      const data = r.souscriptiondata || {};
      if (data.client_info) {
        // Commercial a créé pour un client
        const client = data.client_info;
        client_name = `${client.prenom || ''} ${client.nom || ''}`.trim();
        const commercial_name = `${r.creator_prenom || ''} ${r.creator_nom || ''}`.trim();
        origin = `Commercial (${commercial_name}) pour ${client_name}`;
      } else if (r.code_apporteur) {
        // C'est un commercial (code_apporteur indique un commercial)
        origin = `Commercial: ${r.creator_prenom || ''} ${r.creator_nom || ''}`.trim();
      }
      
      return {
        id: r.id,
        numero_police: r.numero_police,
        produit_nom: r.produit_nom,
        statut: r.statut,
        created_at: r.created_at,
        date_validation: r.date_validation,
        code_apporteur: r.code_apporteur,
        creator_nom: r.creator_nom,
        creator_prenom: r.creator_prenom,
        creator_role: r.creator_role,
        creator_email: r.creator_email,
        origin,
        client_info: data.client_info || null,
        souscriptiondata: r.souscriptiondata
      };
    });

    res.json({
      success: true,
      subscriptions,
      total: parseInt(countResult.rows[0].count, 10),
      stats: {
        by_status: byStatus,
        total_contrats: parseInt(contratsCountResult.rows[0].total, 10)
      }
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
    const { limit = 50, offset = 0 } = req.query;

    const result = await pool.query(`
      SELECT 
        ci.*,
        u.nom,
        u.prenom,
        u.email
      FROM commission_instance ci
      LEFT JOIN users u ON u.code_apporteur = ci.code_apporteur
      ORDER BY ci.date_calcul DESC
      LIMIT $1 OFFSET $2
    `, [limit, offset]);

    const countResult = await pool.query('SELECT COUNT(*) FROM commission_instance');

    res.json({
      success: true,
      commissions: result.rows,
      total: parseInt(countResult.rows[0].count, 10)
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
 * ROUTE : GET /api/admin/subscriptions/:id
 * Récupère les détails complets d'une souscription spécifique.
 * 
 * FONCTIONNEMENT :
 * 1. JOIN avec users pour obtenir creator_nom, creator_prenom, creator_role
 * 2. Retourne toutes les colonnes de subscriptions + infos créateur
 * 
 * PARAM :
 * - id (route param) : ID de la souscription
 * 
 * RETOUR :
 * - subscription : objet avec tous les champs + creator_nom, creator_prenom, creator_role
 */
router.get('/subscriptions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(`
      SELECT s.*, u.nom as creator_nom, u.prenom as creator_prenom, u.role as creator_role
      FROM subscriptions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE s.id = $1
    `, [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Souscription introuvable' });
    }

    res.json({ success: true, subscription: result.rows[0] });
  } catch (error) {
    console.error('Erreur détails souscription:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * ROUTE : GET /api/admin/subscriptions/:id/documents/download
 * Télécharge tous les documents d'identité d'une souscription sous forme de ZIP.
 * 
 * FONCTIONNEMENT :
 * 1. Récupère la souscription (user_id + souscriptiondata)
 * 2. Extrait les documents depuis souscriptiondata.piece_identite_documents (uploads/identity-cards/)
 * 3. Extrait la signature depuis souscriptiondata.signature_path (uploads/signatures/)
 * 4. Récupère les documents KYC depuis kyc_documents table (uploads/kyc/) comme fallback
 * 5. Archive tous les fichiers trouvés et stream le ZIP en réponse
 * 
 * PARAM :
 * - id (route param) : ID de la souscription
 * 
 * RETOUR :
 * - Fichier ZIP contenant tous les documents disponibles
 */
router.get('/subscriptions/:id/documents/download', verifyToken, requireAdmin, async (req, res) => {
  const archiver = require('archiver');
  const fs = require('fs');
  const path = require('path');

  try {
    const { id } = req.params;

    // 1. Récupérer la souscription
    const subResult = await pool.query(
      'SELECT user_id, souscriptiondata, numero_police FROM subscriptions WHERE id = $1',
      [id]
    );

    if (subResult.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Souscription introuvable' });
    }

    const { user_id, souscriptiondata, numero_police } = subResult.rows[0];
    const subscriptionData = souscriptiondata || {};
    const numeroRef = numero_police || `SUB-${id}`;

    // 2. Collecter les fichiers à archiver
    const filesToArchive = [];
    const addedPaths = new Set(); // éviter les doublons

    const tryAddFile = (absPath, archiveName) => {
      if (absPath && !addedPaths.has(absPath) && fs.existsSync(absPath)) {
        addedPaths.add(absPath);
        filesToArchive.push({ filePath: absPath, archiveName });
      }
    };

    // --- Source 1 : piece_identite_documents dans souscriptiondata (principal)
    // Fichiers dans uploads/identity-cards/
    const pieceDocuments = subscriptionData.piece_identite_documents;
    if (Array.isArray(pieceDocuments) && pieceDocuments.length > 0) {
      pieceDocuments.forEach((doc, index) => {
        if (doc && doc.url) {
          const relPath = doc.url.replace(/^\//, '');
          const absPath = path.join(__dirname, '..', relPath);
          const ext = path.extname(absPath) || '';
          const label = (doc.label || `document_${index + 1}`).replace(/[/\\?%*:|"<>]/g, '-');
          tryAddFile(absPath, `piece_identite_${index + 1}_${label}${ext.includes('.') ? '' : ext}`);
        }
      });
    } else if (subscriptionData.piece_identite_url) {
      // Fallback : champ single piece_identite_url
      const relPath = subscriptionData.piece_identite_url.replace(/^\//, '');
      const absPath = path.join(__dirname, '..', relPath);
      const ext = path.extname(absPath) || '';
      tryAddFile(absPath, `piece_identite${ext}`);
    } else if (subscriptionData.piece_identite) {
      // Fallback : champ piece_identite = nom de fichier seul (anciens comptes mobile)
      const fname = subscriptionData.piece_identite;
      const ext = path.extname(fname) || '';
      // Essayer dans identity-cards d'abord, puis à la racine uploads
      const candidates = [
        path.join(__dirname, '..', 'uploads', 'identity-cards', fname),
        path.join(__dirname, '..', 'uploads', fname),
      ];
      for (const absPath of candidates) {
        if (fs.existsSync(absPath)) {
          tryAddFile(absPath, `piece_identite${ext}`);
          break;
        }
      }
    }

    // --- Source 2 : signature — exclue du téléchargement (usage interne uniquement)

    // --- Source 3 : documents KYC (table kyc_documents) - fallback si la table existe
    if (user_id) {
      try {
        const kycResult = await pool.query(
          'SELECT doc_key, url FROM kyc_documents WHERE user_id = $1 ORDER BY created_at DESC',
          [user_id]
        );
        const seenKeys = new Set();
        for (const row of kycResult.rows) {
          if (seenKeys.has(row.doc_key)) continue;
          seenKeys.add(row.doc_key);
          const relPath = row.url.replace(/^\//, '');
          const absPath = path.join(__dirname, '..', relPath);
          const ext = path.extname(absPath) || '';
          const docLabel = row.doc_key.replace(/_/g, '-');
          tryAddFile(absPath, `kyc_${docLabel}${ext}`);
        }
      } catch (kycErr) {
        // La table kyc_documents n'existe pas ou autre erreur non bloquante
        console.warn('⚠️ kyc_documents non disponible:', kycErr.message);
      }
    }

    if (filesToArchive.length === 0) {
      return res.status(404).json({ success: false, message: 'Aucun document d\'identité disponible pour cette souscription' });
    }

    // 3. Créer et streamer l'archive ZIP
    const zipName = `documents_${numeroRef}.zip`;
    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', `attachment; filename="${zipName}"`);

    const archive = archiver('zip', { zlib: { level: 6 } });
    archive.on('error', (err) => {
      console.error('Erreur archiver:', err);
      if (!res.headersSent) {
        res.status(500).json({ success: false, message: 'Erreur lors de la création de l\'archive' });
      }
    });

    archive.pipe(res);
    for (const { filePath, archiveName } of filesToArchive) {
      archive.file(filePath, { name: archiveName });
    }
    await archive.finalize();

  } catch (error) {
    console.error('❌ Erreur téléchargement documents:', error);
    console.error('❌ Stack:', error.stack);
    if (!res.headersSent) {
      res.status(500).json({ success: false, message: 'Erreur lors du téléchargement des documents' });
    }
  }
});

/**
 * ROUTE : GET /api/admin/subscriptions/:id/questionnaire-medical/print
 * Retourne une page HTML imprimable du questionnaire médical d'une souscription.
 */
router.get('/subscriptions/:id/questionnaire-medical/print', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Récupérer les infos de la souscription
    const subResult = await pool.query(
      `SELECT s.id, s.numero_police, s.produit_nom, s.souscriptiondata, s.date_creation, s.code_apporteur,
              u.nom, u.prenom, u.email, u.telephone, u.date_naissance
       FROM subscriptions s
       LEFT JOIN users u ON u.id = s.user_id
       WHERE s.id = $1`,
      [id]
    );

    if (subResult.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Souscription introuvable' });
    }

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

    // Formater produit lisiblement
    const produitLabel = (sub.produit_nom || 'N/A')
      .replace(/_/g, ' ')
      .split(' ')
      .map(w => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ');

    // Récupérer les réponses au questionnaire médical
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

    // Générer les lignes HTML du questionnaire
    const lignesHtml = reponses.length === 0
      ? `<tr><td colspan="3" style="text-align:center;color:#888;padding:20px;font-style:italic;">
           Aucune réponse enregistrée pour cette souscription.
         </td></tr>`
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

    /* Logo CORIS */
    .logo-container { display: flex; align-items: center; gap: 10px; }
    .logo-shield {
      width: 48px; height: 48px;
      background: linear-gradient(135deg, #1a4b8c 0%, #0d3275 100%);
      border-radius: 10px;
      display: flex; align-items: center; justify-content: center;
      box-shadow: 0 3px 10px rgba(26,75,140,0.35);
    }
    .logo-shield svg { width: 28px; height: 28px; fill: white; }
    .logo-text { line-height: 1; }
    .logo-text .brand { font-size: 22px; font-weight: 900; color: #1a4b8c; letter-spacing: 1px; }
    .logo-text .sub { font-size: 11px; color: #e67e22; font-weight: 600; letter-spacing: 2px; text-transform: uppercase; }

    /* Header */
    .header { display: flex; align-items: center; justify-content: space-between; border-bottom: 3px solid #1a4b8c; padding-bottom: 16px; margin-bottom: 24px; }
    .header-right { text-align: right; }
    .header-right h1 { font-size: 17px; color: #1a4b8c; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; }
    .header-right h2 { font-size: 12px; color: #666; font-weight: normal; margin-top: 3px; }
    .header-right .date { font-size: 11px; color: #999; margin-top: 6px; }

    /* Bandeau titre */
    .section-title {
      background: linear-gradient(90deg, #1a4b8c 0%, #2563eb 100%);
      color: white;
      padding: 8px 14px;
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      border-radius: 5px;
      margin-bottom: 12px;
      margin-top: 20px;
    }

    /* Info client */
    .info-grid {
      display: grid; grid-template-columns: 1fr 1fr;
      gap: 0;
      border: 1px solid #d0d8e8;
      border-radius: 6px;
      overflow: hidden;
      margin-bottom: 4px;
    }
    .info-item {
      padding: 9px 14px;
      border-bottom: 1px solid #e8edf5;
      border-right: 1px solid #e8edf5;
    }
    .info-item:nth-child(even) { border-right: none; }
    .info-item label { font-size: 10px; color: #888; display: block; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 2px; }
    .info-item span { font-weight: 600; color: #1a2a4a; font-size: 13px; }

    /* Questionnaire table */
    table { width: 100%; border-collapse: collapse; }
    thead tr { background: linear-gradient(90deg, #1a4b8c 0%, #2563eb 100%); }
    thead th { padding: 10px 12px; color: white; text-align: left; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; border: none; }
    tbody tr:last-child td { border-bottom: 1px solid #d0d8e8; }

    /* RÉSUMÉ */
    .summary-box {
      display: flex; gap: 12px; margin-bottom: 4px; margin-top: 8px;
    }
    .stat-box {
      flex: 1;
      background: #f0f4ff;
      border: 1px solid #c3cfee;
      border-radius: 8px;
      padding: 10px 14px;
      text-align: center;
    }
    .stat-box .val { font-size: 22px; font-weight: 900; color: #1a4b8c; }
    .stat-box .lbl { font-size: 11px; color: #666; margin-top: 2px; }

    /* Signatures */
    .signature-block {
      display: grid; grid-template-columns: 1fr 1fr; gap: 30px;
      margin-top: 28px;
      border-top: 1px solid #d0d8e8;
      padding-top: 16px;
    }
    .sig-box { }
    .sig-box .sig-title { font-size: 12px; font-weight: 600; color: #1a4b8c; margin-bottom: 8px; }
    .sig-box .sig-line { border-top: 1px solid #555; margin-top: 55px; }
    .sig-box .sig-sub { font-size: 10px; color: #888; margin-top: 4px; }

    /* Pied de page */
    .footer {
      margin-top: 20px;
      padding-top: 10px;
      border-top: 1px solid #e0e0e0;
      display: flex; justify-content: space-between;
      font-size: 10px; color: #aaa;
    }

    /* Bouton impression (écran seulement) */
    .no-print { margin-bottom: 20px; }
    .btn-print {
      background: #1a4b8c; color: white; border: none;
      padding: 10px 24px; font-size: 14px; border-radius: 8px;
      cursor: pointer; font-weight: 600;
      box-shadow: 0 3px 8px rgba(26,75,140,0.3);
    }
    .btn-print:hover { background: #0d3275; }

    @media print {
      body { background: white; }
      .page { padding: 0; max-width: 100%; box-shadow: none; }
      .no-print { display: none !important; }
      @page { margin: 1.5cm 1.8cm; size: A4 portrait; }
      .logo-shield { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      thead tr { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      .section-title { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
<div class="page">

  <!-- Boutons action (masqués à l'impression) -->
  <div class="no-print">
    <button class="btn-print" onclick="window.print()">🖨️&nbsp; Imprimer</button>
    <a class="btn-print" style="text-decoration:none;margin-left:10px;background:#27ae60;" href="?download=1" download="questionnaire-medical-${String(numeroRef).replace(/[^a-zA-Z0-9-_]/g,'_')}.html">⬇️&nbsp; Télécharger</a>
    <span style="margin-left:14px;color:#888;font-size:12px;">Ctrl+P pour imprimer directement</span>
  </div>

  <!-- En-tête -->
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

  <!-- Informations souscription -->
  <div class="section-title">📋 Informations de la souscription</div>
  <div class="info-grid">
    <div class="info-item"><label>N° Police / Référence</label><span>${numeroRef}</span></div>
    <div class="info-item"><label>Produit</label><span>${produitLabel}</span></div>
    <div class="info-item"><label>Date de souscription</label><span>${dateSouscription}</span></div>
    <div class="info-item"><label>Statut réponses</label><span>${reponses.length > 0 ? `${reponses.length} réponse(s) enregistrée(s)` : 'Aucune réponse'}</span></div>
  </div>

  <!-- Informations client -->
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

  <!-- Questionnaire médical -->
  <div class="section-title">🏥 Formulaire Médical — Questions &amp; Réponses</div>
  <table>
    <thead>
      <tr>
        <th style="width:50px;text-align:center;">N°</th>
        <th>Question médicale</th>
        <th style="width:160px;">Réponse</th>
      </tr>
    </thead>
    <tbody>
      ${lignesHtml}
    </tbody>
  </table>

  <!-- Bloc signatures -->
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

  <!-- Pied de page -->
  <div class="footer">
    <span>CORIS Assurance Vie — Questionnaire médical — Réf. ${numeroRef}</span>
    <span>Document confidentiel — Usage interne uniquement</span>
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
});

/**
 * ROUTE : DELETE /api/admin/subscriptions/:id
 * Supprime une souscription de la base de données.
 * 
 * ATTENTION : Cette action est irréversible.
 * 
 * PARAM :
 * - id (route param) : ID de la souscription à supprimer
 * 
 * RETOUR :
 * - subscription : objet de la souscription supprimée (RETURNING *)
 */
router.delete('/subscriptions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM subscriptions WHERE id = $1 RETURNING *', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Souscription introuvable' });
    }

    res.json({ success: true, message: 'Souscription supprimée avec succès', subscription: result.rows[0] });
  } catch (error) {
    console.error('Erreur suppression souscription:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression' });
  }
});

/**
 * ROUTE : POST /api/admin/subscriptions
 * Crée une nouvelle souscription dans la table subscriptions.
 * 
 * FONCTIONNEMENT :
 * 1. Valide les champs requis (user_id, produit_nom, souscriptiondata)
 * 2. Insère une nouvelle ligne avec statut = 'proposition' par défaut
 * 3. Retourne la souscription créée
 * 
 * BODY PARAMS :
 * - user_id (requis) : ID de l'utilisateur créateur (client ou commercial)
 * - produit_nom (requis) : Nom du produit souscrit
 * - souscriptiondata (requis) : JSONB contenant toutes les données du formulaire
 *   (infos client si commercial, montant, durée, options, etc.)
 * - code_apporteur (optionnel) : Code du commercial apporteur
 * 
 * RETOUR :
 * - subscription : objet nouvellement créé (id, user_id, produit_nom, statut='proposition', etc.)
 */
router.post('/subscriptions', async (req, res) => {
  try {
    const {
      user_id,
      produit_nom,
      souscriptiondata,
      code_apporteur
    } = req.body;

  if (!user_id || !produit_nom || !souscriptiondata) {
      return res.status(400).json({
        success: false,
        message: 'Champs requis manquants: user_id, produit_nom, souscriptiondata'
      });
    }

    const result = await pool.query(
      `INSERT INTO subscriptions (user_id, produit_nom, souscriptiondata, code_apporteur, statut)
       VALUES ($1, $2, $3, $4, 'proposition')
       RETURNING *`,
      [user_id, produit_nom, souscriptiondata, code_apporteur || null]
    );

    res.json({
      success: true,
      message: 'Souscription créée avec succès',
      subscription: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur création souscription:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la souscription',
      error: error.message
    });
  }
});

/**
 * ROUTE : PATCH /api/admin/subscriptions/:id/status
 * Met à jour le statut d'une souscription.
 * 
 * FLUX DE STATUTS :
 * - proposition : souscription initiale (non payée)
 * - payé : paiement reçu (Wave, Orange Money, Virement, Espèce)
 * - contrat : validé et enregistré comme contrat (peut être stocké dans table contrats aussi)
 * - activé : contrat actif et en cours
 * - annulé : souscription annulée/rejetée
 * 
 * PARAM :
 * - id (route param) : ID de la souscription
 * 
 * BODY PARAMS :
 * - status (requis) : Nouveau statut (énum: proposition, payé, contrat, activé, annulé)
 * 
 * RETOUR :
 * - subscription : objet mis à jour avec nouveau statut et updated_at
 */
router.patch('/subscriptions/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

  const validStatuses = ['proposition', 'contrat', 'annulé', 'payé', 'activé'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Statut invalide' });
    }

    const result = await pool.query(
      'UPDATE subscriptions SET statut = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [status, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Souscription introuvable' });
    }

    res.json({ success: true, message: 'Statut mis à jour', subscription: result.rows[0] });
  } catch (error) {
    console.error('Erreur mise à jour statut:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * GET /api/admin/commissions/:id
 * Détails d'une commission
 */
router.get('/commissions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT 
        ci.*,
        u.nom,
        u.prenom,
        u.email
      FROM commission_instance ci
      LEFT JOIN users u ON u.code_apporteur = ci.code_apporteur
      WHERE ci.id = $1`,
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Commission introuvable' });
    }

    res.json({ success: true, commission: result.rows[0] });
  } catch (error) {
    console.error('Erreur détails commission:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * DELETE /api/admin/commissions/:id
 * Supprimer une commission
 */
router.delete('/commissions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM commission_instance WHERE id = $1 RETURNING *', [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Commission introuvable' });
    }

    res.json({ success: true, message: 'Commission supprimée avec succès', commission: result.rows[0] });
  } catch (error) {
    console.error('Erreur suppression commission:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression' });
  }
});

/**
 * POST /api/admin/commissions
 * Créer une nouvelle commission
 */
router.post('/commissions', async (req, res) => {
  try {
    const {
      code_apporteur,
      montant_commission,
      date_calcul
    } = req.body;

    if (!code_apporteur || montant_commission === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Champs requis manquants: code_apporteur, montant_commission'
      });
    }

    const result = await pool.query(
      `INSERT INTO commission_instance (code_apporteur, montant_commission, date_calcul)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [code_apporteur, montant_commission, date_calcul || new Date()]
    );

    res.json({
      success: true,
      message: 'Commission créée avec succès',
      commission: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur création commission:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création de la commission',
      error: error.message
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
 * Par défaut: affiche uniquement les non-lues
 */
router.get('/notifications', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
    const offset = Math.max(parseInt(req.query.offset || '0', 10), 0);
    // Par défaut, afficher seulement les non-lues (unread_only=true par défaut)
    const unread_only = req.query.show_all === 'true' ? false : true;

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
      offset,
      showing_all: !unread_only
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
 * DELETE /api/admin/notifications/:id
 * Supprimer une notification de l'admin connecté
 */
router.delete('/notifications/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'DELETE FROM notifications WHERE id = $1 AND admin_id = $2 RETURNING *',
      [id, req.user.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, message: 'Notification introuvable' });
    }

    res.json({ success: true, message: 'Notification supprimée', notification: result.rows[0] });
  } catch (error) {
    console.error('Erreur suppression notification:', error);
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

/**
 * POST /api/admin/users/:id/suspend
 * Suspendre un compte utilisateur
 */
router.post('/users/:id/suspend', async (req, res) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { raison } = req.body;
    const adminId = req.user.id;

    await client.query('BEGIN');

    // Récupérer les infos de l'utilisateur suspendu
    const userResult = await client.query('SELECT prenom, nom, email FROM users WHERE id = $1', [id]);
    const user = userResult.rows[0];

    // Suspendre le compte
    await client.query(
      `UPDATE users 
       SET est_suspendu = true, date_suspension = NOW(), raison_suspension = $1, suspendu_par = $2
       WHERE id = $3`,
      [raison || 'Aucune raison spécifiée', adminId, id]
    );

    // Créer notification pour tous les admins
    const admins = await client.query("SELECT id FROM users WHERE role IN ('super_admin', 'admin', 'moderation')");
    
    for (const admin of admins.rows) {
      await client.query(
        `INSERT INTO notifications (admin_id, type, title, message, reference_id, reference_type, action_url, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
        [
          admin.id,
          'user_action',
          'Compte suspendu',
          `Le compte de ${user.prenom} ${user.nom} (${user.email}) a été suspendu. Raison: ${raison || 'Non spécifiée'}`,
          id,
          'user',
          `/utilisateurs?user=${id}`
        ]
      );
    }

    await client.query('COMMIT');

    res.json({ success: true, message: 'Compte suspendu avec succès' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Erreur suspension compte:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suspension', error: error.message });
  } finally {
    client.release();
  }
});

/**
 * POST /api/admin/users/:id/unsuspend
 * Réactiver un compte utilisateur
 */
router.post('/users/:id/unsuspend', async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query(
      `UPDATE users 
       SET est_suspendu = false, date_suspension = NULL, raison_suspension = NULL, suspendu_par = NULL
       WHERE id = $1`,
      [id]
    );

    res.json({ success: true, message: 'Compte réactivé avec succès' });
  } catch (error) {
    console.error('Erreur réactivation compte:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la réactivation' });
  }
});

/**
 * GET /api/admin/users/stats/suspended
 * Obtenir le nombre de comptes suspendus
 */
router.get('/users/stats/suspended', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT COUNT(*) as count FROM users WHERE est_suspendu = true'
    );

    res.json({ 
      success: true, 
      count: parseInt(result.rows[0].count) 
    });
  } catch (error) {
    console.error('Erreur stats suspendus:', error);
    res.status(500).json({ success: false, message: 'Erreur' });
  }
});

/**
 * GET /api/admin/activity-stats
 * Obtenir les statistiques d'utilisation de l'application
 */
router.get('/activity-stats', async (req, res) => {
  try {
    const { days = 30 } = req.query;

    // Statistiques quotidiennes sur X jours
    const dailyStats = await pool.query(
      `SELECT * FROM user_activity_stats 
       WHERE date >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'
       ORDER BY date DESC`
    );

    // Total de connexions par utilisateur (top 10)
    const topUsers = await pool.query(
      `SELECT 
        u.id, u.nom, u.prenom, u.email, u.role,
        COUNT(*) FILTER (WHERE ual.type = 'login') as total_connexions,
        MAX(ual.created_at) as derniere_connexion
       FROM users u
       LEFT JOIN user_activity_logs ual ON u.id = ual.user_id
       WHERE ual.created_at >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'
       GROUP BY u.id, u.nom, u.prenom, u.email, u.role
       ORDER BY total_connexions DESC
       LIMIT 10`
    );

    // Stats globales
    const globalStats = await pool.query(
      `SELECT 
        COUNT(DISTINCT user_id) as utilisateurs_actifs,
        COUNT(*) FILTER (WHERE type = 'login') as total_connexions,
        COUNT(*) FILTER (WHERE type = 'logout') as total_deconnexions
       FROM user_activity_logs
       WHERE created_at >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'`
    );

    res.json({
      success: true,
      daily: dailyStats.rows,
      topUsers: topUsers.rows,
      global: globalStats.rows[0]
    });
  } catch (error) {
    console.error('Erreur stats activité:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des statistiques' });
  }
});

/**
 * GET /api/admin/products
 * Liste de tous les produits
 */
router.get('/products', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM produit ORDER BY libelle');
    res.json({ success: true, products: result.rows });
  } catch (error) {
    console.error('Erreur liste produits:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des produits' });
  }
});

/**
 * GET /api/admin/products/:id/tarifs
 * Liste des tarifs d'un produit
 */
router.get('/products/:id/tarifs', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'SELECT * FROM tarif_produit WHERE produit_id = $1 ORDER BY age, duree_contrat, periodicite',
      [id]
    );
    res.json({ success: true, tarifs: result.rows });
  } catch (error) {
    console.error('Erreur liste tarifs:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des tarifs' });
  }
});

/**
 * POST /api/admin/products/:id/tarifs/import
 * Importer des tarifs depuis un fichier Excel (à implémenter côté frontend)
 */
router.post('/products/:id/tarifs/import', async (req, res) => {
  try {
    const { id } = req.params;
    const { tarifs } = req.body; // Array de tarifs depuis Excel

    if (!tarifs || !Array.isArray(tarifs)) {
      return res.status(400).json({ success: false, message: 'Format invalide' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (const tarif of tarifs) {
        await client.query(
          `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, capital, age, categorie)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT DO NOTHING`,
          [id, tarif.duree_contrat, tarif.periodicite, tarif.prime, tarif.capital, tarif.age, tarif.categorie]
        );
      }

      await client.query('COMMIT');
      res.json({ success: true, message: `${tarifs.length} tarifs importés avec succès` });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Erreur import tarifs:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'import des tarifs' });
  }
});

/**
 * GET /api/admin/tarifs/export
 * Exporter tous les tarifs de tous les produits au format Excel
 */
router.get('/tarifs/export', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        p.libelle as produit,
        t.age,
        t.duree_contrat as duree,
        t.periodicite,
        t.prime,
        t.capital,
        t.categorie
      FROM tarif_produit t
      JOIN produit p ON p.id = t.produit_id
      ORDER BY p.libelle, t.age, t.duree_contrat, t.periodicite
    `);

    // Créer un CSV simple (peut être ouvert dans Excel)
    const header = 'Produit,Âge,Durée,Périodicité,Prime,Capital,Catégorie\n';
    const rows = result.rows.map(r => 
      `"${r.produit}",${r.age},${r.duree},"${r.periodicite}",${r.prime},${r.capital || ''},"${r.categorie || ''}"`
    ).join('\n');
    
    const csv = header + rows;
    
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename=tarifs_coris_${new Date().toISOString().split('T')[0]}.csv`);
    res.send('\uFEFF' + csv); // BOM pour Excel
  } catch (error) {
    console.error('Erreur export tarifs:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'export' });
  }
});

/**
 * POST /api/admin/tarifs/import
 * Importer des tarifs depuis un fichier Excel/CSV
 */
router.post('/tarifs/import', async (req, res) => {
  try {
    // Note: Pour parser Excel, installer 'xlsx' package: npm install xlsx
    // Pour l'instant, retourner un message
    res.json({ 
      success: true, 
      message: 'Fonctionnalité d\'import en cours de développement. Utilisez l\'export pour voir le format attendu.',
      imported: 0
    });
  } catch (error) {
    console.error('Erreur import tarifs:', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'import' });
  }
});

/**
 * PUT /api/admin/update-profile
 * Met à jour le profil de l'admin connecté
 */
router.put('/update-profile', async (req, res) => {
  try {
    const userId = req.user.id;
    const { email, telephone, address, city, country } = req.body;

    console.log('📝 Mise à jour profil admin:', { userId, email, telephone, address, city, country });

    // Mettre à jour les informations de l'utilisateur (utiliser les noms de colonnes français)
    const updateQuery = `
      UPDATE users 
      SET 
        email = COALESCE($1, email),
        telephone = COALESCE($2, telephone),
        adresse = $3,
        pays = $4,
        updated_at = NOW()
      WHERE id = $5
      RETURNING id, nom, prenom, email, telephone, adresse, pays, role
    `;

    const result = await pool.query(updateQuery, [
      email,
      telephone,
      address,
      country,
      userId
    ]);

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        message: 'Utilisateur non trouvé' 
      });
    }

    console.log('✅ Profil admin mis à jour:', result.rows[0]);

    res.json({
      success: true,
      message: 'Profil mis à jour avec succès',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour profil admin:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la mise à jour du profil' 
    });
  }
});

module.exports = router;
