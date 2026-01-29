const pool = require('../db');

/**
 * Enregistrer une nouvelle simulation
 */
exports.saveSimulation = async (req, res) => {
  try {
    const {
      produit_nom,
      type_simulation,
      age,
      date_naissance,
      capital,
      prime,
      duree_mois,
      periodicite,
      resultat_prime,
      resultat_capital
    } = req.body;

    // Récupérer l'user_id si l'utilisateur est connecté
    const user_id = req.user ? req.user.id : null;
    
    // Récupérer l'IP et le user agent
    const ip_address = req.ip || req.connection.remoteAddress;
    const user_agent = req.get('user-agent');

    const query = `
      INSERT INTO simulations 
      (user_id, produit_nom, type_simulation, age, date_naissance, 
       capital, prime, duree_mois, periodicite, resultat_prime, 
       resultat_capital, ip_address, user_agent)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING id
    `;

    const result = await pool.query(query, [
      user_id,
      produit_nom,
      type_simulation,
      age,
      date_naissance,
      capital,
      prime,
      duree_mois,
      periodicite,
      resultat_prime,
      resultat_capital,
      ip_address,
      user_agent
    ]);

    res.status(201).json({
      success: true,
      message: 'Simulation enregistrée avec succès',
      simulation_id: result.rows[0].id
    });

  } catch (error) {
    console.error('❌ Erreur lors de l\'enregistrement de la simulation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'enregistrement de la simulation',
      error: error.message
    });
  }
};

/**
 * Récupérer toutes les simulations avec filtres et pagination
 */
exports.getAllSimulations = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 50,
      produit,
      type_simulation,
      date_debut,
      date_fin
    } = req.query;

    const offset = (page - 1) * limit;
    
    let whereConditions = [];
    let params = [];
    let paramIndex = 1;

    if (produit) {
      whereConditions.push(`s.produit_nom = $${paramIndex++}`);
      params.push(produit);
    }

    if (type_simulation) {
      whereConditions.push(`s.type_simulation = $${paramIndex++}`);
      params.push(type_simulation);
    }

    if (date_debut) {
      whereConditions.push(`s.created_at >= $${paramIndex++}`);
      params.push(date_debut);
    }

    if (date_fin) {
      whereConditions.push(`s.created_at <= $${paramIndex++}`);
      params.push(date_fin);
    }

    const whereClause = whereConditions.length > 0 
      ? 'WHERE ' + whereConditions.join(' AND ') 
      : '';

    // Requête pour compter le total
    const countQuery = `SELECT COUNT(*) as total FROM simulations s ${whereClause}`;
    const countResult = await pool.query(countQuery, params);
    const total = parseInt(countResult.rows[0].total);

    // Requête pour récupérer les données
    const query = `
      SELECT 
        s.*,
        CONCAT(u.nom, ' ', u.prenom) as user_name,
        u.email as user_email
      FROM simulations s
      LEFT JOIN users u ON s.user_id = u.id
      ${whereClause}
      ORDER BY s.created_at DESC
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;

    const result = await pool.query(query, [...params, parseInt(limit), parseInt(offset)]);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        current_page: parseInt(page),
        per_page: parseInt(limit),
        total: total,
        total_pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('❌ Erreur lors de la récupération des simulations:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des simulations',
      error: error.message
    });
  }
};

/**
 * Obtenir les statistiques des simulations pour le dashboard admin
 */
exports.getSimulationStats = async (req, res) => {
  try {
    const { date_debut, date_fin } = req.query;
    
    let dateFilter = '';
    let params = [];

    if (date_debut && date_fin) {
      dateFilter = 'WHERE created_at BETWEEN $1 AND $2';
      params = [date_debut, date_fin];
    } else if (date_debut) {
      dateFilter = 'WHERE created_at >= $1';
      params = [date_debut];
    } else if (date_fin) {
      dateFilter = 'WHERE created_at <= $1';
      params = [date_fin];
    }

    // Total des simulations
    const totalResult = await pool.query(
      `SELECT COUNT(*) as total FROM simulations ${dateFilter}`,
      params
    );

    // Simulations par produit
    const parProduit = await pool.query(
      `SELECT produit_nom, COUNT(*) as count 
       FROM simulations 
       ${dateFilter}
       GROUP BY produit_nom 
       ORDER BY count DESC`,
      params
    );

    // Simulations par type
    const parType = await pool.query(
      `SELECT type_simulation, COUNT(*) as count 
       FROM simulations 
       ${dateFilter}
       GROUP BY type_simulation 
       ORDER BY count DESC`,
      params
    );

    // Simulations par jour (derniers 30 jours)
    const parJour = await pool.query(
      `SELECT 
        DATE(created_at) as date, 
        COUNT(*) as count 
       FROM simulations 
       WHERE created_at >= NOW() - INTERVAL '30 days'
       GROUP BY DATE(created_at) 
       ORDER BY date ASC`
    );

    // Simulations par mois (derniers 12 mois)
    const parMois = await pool.query(
      `SELECT 
        TO_CHAR(created_at, 'YYYY-MM') as mois, 
        COUNT(*) as count 
       FROM simulations 
       WHERE created_at >= NOW() - INTERVAL '12 months'
       GROUP BY TO_CHAR(created_at, 'YYYY-MM') 
       ORDER BY mois ASC`
    );

    // Statistiques des montants
    const montants = await pool.query(
      `SELECT 
        AVG(capital) as capital_moyen,
        MAX(capital) as capital_max,
        MIN(capital) as capital_min,
        AVG(prime) as prime_moyenne,
        MAX(prime) as prime_max,
        MIN(prime) as prime_min
       FROM simulations 
       ${dateFilter}`,
      params
    );

    res.json({
      success: true,
      stats: {
        total: parseInt(totalResult.rows[0].total),
        par_produit: parProduit.rows,
        par_type: parType.rows,
        par_jour: parJour.rows,
        par_mois: parMois.rows,
        montants: montants.rows[0]
      }
    });

  } catch (error) {
    console.error('❌ Erreur lors de la récupération des statistiques:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques',
      error: error.message
    });
  }
};

/**
 * Obtenir les simulations d'un utilisateur spécifique
 */
exports.getUserSimulations = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : null;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'Utilisateur non connecté'
      });
    }

    const query = `
      SELECT * FROM simulations 
      WHERE user_id = $1 
      ORDER BY created_at DESC 
      LIMIT 50
    `;

    const result = await pool.query(query, [userId]);

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('❌ Erreur lors de la récupération des simulations utilisateur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des simulations',
      error: error.message
    });
  }
};
