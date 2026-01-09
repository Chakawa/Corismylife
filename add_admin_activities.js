/**
 * SCRIPT DE CORRECTION : Ajouter les activités des administrateurs à la page d'activités
 * 
 * MODIFICATIONS :
 * 1. La route GET /api/admin/activities récupère maintenant :
 *    - Les activités des souscriptions (création, statut)
 *    - Les actions des administrateurs (changements de statut, validation, rejet)
 * 
 * 2. Utilise UNION ALL pour combiner :
 *    - Souscriptions avec statut et user info
 *    - Actions admin (mise à jour de statut, validation, rejet)
 * 
 * 3. Les deux sources fusionnées et triées par date décroissante
 */

const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'mycoris-master', 'routes', 'adminRoutes.js');
let content = fs.readFileSync(filePath, 'utf8');

// Remplacer la route GET /api/admin/activities pour inclure activités admin
const oldRoute = `router.get('/activities', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '100', 10), 200)
    const offset = Math.max(parseInt(req.query.offset || '0', 10), 0)
    const q = (req.query.q || '').toString().trim()

    // Construction dynamique avec filtre texte optionnel
    let baseQuery = \`
      FROM subscriptions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE 1=1
    \`
    const params = []
    let idx = 1

    if (q) {
      baseQuery += \` AND (
        u.nom ILIKE $\${idx} OR u.prenom ILIKE $\${idx} OR u.email ILIKE $\${idx} OR
        s.produit_nom ILIKE $\${idx} OR s.statut ILIKE $\${idx} OR COALESCE(s.reference, '') ILIKE $\${idx} OR COALESCE(s.numero_contrat, '') ILIKE $\${idx}
      )\`
      params.push(\`%\${q}%\`)
      idx++
    }

    const listQuery = \`
      SELECT s.id, s.date_creation AS created_at, s.statut, u.nom AS nom_client, u.prenom AS prenom_client, s.produit_nom AS produit
      \${baseQuery}
      ORDER BY s.date_creation DESC
      LIMIT $\${idx} OFFSET $\${idx + 1}
    \`
    const listParams = params.concat([limit, offset])
    const activities = await pool.query(listQuery, listParams)

    const countQuery = \`SELECT COUNT(*)::int AS total \${baseQuery}\`
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
});`;

const newRoute = `/**
 * ROUTE : GET /api/admin/activities
 * Récupère toutes les activités : souscriptions ET actions des administrateurs.
 * 
 * FONCTIONNEMENT :
 * 1. UNION ALL de deux sources :
 *    a) Souscriptions : date_creation, statut, client info, produit
 *    b) Notifications d'admin : actions sur les souscriptions (statut changé, etc.)
 * 2. Filtrage par recherche texte (nom client, produit, statut)
 * 3. Tri par date décroissante
 * 4. Pagination
 * 
 * RETOUR :
 * - activities : liste des activités combinées (souscriptions + actions admin)
 * - total : nombre total d'activités
 */
router.get('/activities', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit || '100', 10), 200)
    const offset = Math.max(parseInt(req.query.offset || '0', 10), 0)
    const q = (req.query.q || '').toString().trim()

    // Base pour les souscriptions
    let baseQuery = \`
      FROM subscriptions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE 1=1
    \`
    const params = []
    let idx = 1

    // Filtre recherche pour souscriptions
    if (q) {
      baseQuery += \` AND (
        u.nom ILIKE $\${idx} OR u.prenom ILIKE $\${idx} OR u.email ILIKE $\${idx} OR
        s.produit_nom ILIKE $\${idx} OR s.statut ILIKE $\${idx} OR COALESCE(s.reference, '') ILIKE $\${idx} OR COALESCE(s.numero_contrat, '') ILIKE $\${idx}
      )\`
      params.push(\`%\${q}%\`)
      idx++
    }

    // UNION : Souscriptions + Notifications admin
    const listQuery = \`
      SELECT 
        s.id, s.date_creation AS created_at, s.statut, 
        u.nom AS nom_client, u.prenom AS prenom_client, 
        s.produit_nom AS produit,
        'subscription' AS activity_type
      FROM subscriptions s
      LEFT JOIN users u ON u.id = s.user_id
      WHERE 1=1
      \${q ? \`AND (
        u.nom ILIKE $\${idx} OR u.prenom ILIKE $\${idx} OR u.email ILIKE $\${idx} OR
        s.produit_nom ILIKE $\${idx} OR s.statut ILIKE $\${idx} OR COALESCE(s.reference, '') ILIKE $\${idx} OR COALESCE(s.numero_contrat, '') ILIKE $\${idx}
      )\` : ''}
      
      UNION ALL
      
      SELECT 
        reference_id AS id, created_at, title AS statut,
        message AS nom_client, '' AS prenom_client,
        type AS produit,
        'admin_action' AS activity_type
      FROM notifications
      WHERE reference_type = 'subscription'
      \${q ? \`AND (
        message ILIKE $\${idx} OR title ILIKE $\${idx} OR type ILIKE $\${idx}
      )\` : ''}
      
      ORDER BY created_at DESC
      LIMIT $\${idx + (q ? 1 : 0)} OFFSET $\${idx + (q ? 2 : 1)}
    \`
    
    const listParams = q ? [params[0], params[0], params[0], params[0], params[0], params[0], params[0], limit, offset] : [limit, offset]
    const activities = await pool.query(listQuery, listParams)

    // Compter total activités (UNION)
    const countQuery = \`
      SELECT COUNT(*) as total FROM (
        SELECT s.id
        FROM subscriptions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE 1=1
        \${q ? \`AND (
          u.nom ILIKE $1 OR u.prenom ILIKE $1 OR u.email ILIKE $1 OR
          s.produit_nom ILIKE $1 OR s.statut ILIKE $1
        )\` : ''}
        
        UNION ALL
        
        SELECT reference_id
        FROM notifications
        WHERE reference_type = 'subscription'
        \${q ? \`AND (message ILIKE $1 OR title ILIKE $1 OR type ILIKE $1)\` : ''}
      ) t
    \`
    const countParams = q ? [\`%\${q}%\`] : []
    const totalResult = await pool.query(countQuery, countParams)

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
});`;

content = content.replace(oldRoute, newRoute);
fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ Route GET /api/admin/activities - activités admin ajoutées');
