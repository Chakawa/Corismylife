const pool = require('./db');

async function testConnexions() {
  try {
    console.log('🔍 Test de la requête des connexions mensuelles...\n');
    
    const months = 12;
    const query = `
      SELECT 
        DATE_TRUNC('month', ual.created_at) AS mois,
        COUNT(DISTINCT ual.user_id) AS utilisateurs_uniques,
        COUNT(*) AS total_connexions
      FROM user_activity_logs ual
      INNER JOIN users u ON u.id = ual.user_id
      WHERE ual.type = 'login'
        AND u.role = 'client'
        AND ual.created_at >= NOW() - INTERVAL '${months} months'
      GROUP BY DATE_TRUNC('month', ual.created_at)
      ORDER BY mois ASC
    `;

    const result = await pool.query(query);
    
    console.log(`✅ ${result.rows.length} mois trouvés:\n`);
    
    if (result.rows.length === 0) {
      console.log('⚠️  Aucune donnée de connexion trouvée!');
      console.log('   Vérification: y a-t-il des clients qui se sont connectés?');
      
      // Vérifier s'il y a des logs
      const logsCheck = await pool.query(`
        SELECT COUNT(*) as count 
        FROM user_activity_logs 
        WHERE type = 'login'
      `);
      console.log(`   → Total de logs login: ${logsCheck.rows[0].count}`);
      
      // Vérifier s'il y a des clients
      const clientsCheck = await pool.query(`
        SELECT COUNT(*) as count 
        FROM users 
        WHERE role = 'client'
      `);
      console.log(`   → Total de clients: ${clientsCheck.rows[0].count}`);
    } else {
      result.rows.forEach((row, index) => {
        const date = new Date(row.mois);
        const monthNames = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                          'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
        const monthName = monthNames[date.getMonth()];
        const year = date.getFullYear();
        
        console.log(`${index + 1}. ${monthName} ${year}:`);
        console.log(`   - Utilisateurs uniques: ${row.utilisateurs_uniques}`);
        console.log(`   - Total connexions: ${row.total_connexions}\n`);
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error);
    process.exit(1);
  }
}

testConnexions();
