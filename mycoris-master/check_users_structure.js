const pool = require('./db');

async function checkTableStructure() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Structure de la table users:\n');
    console.table(result.rows);
    
    pool.end();
  } catch (error) {
    console.error('Erreur:', error.message);
    pool.end();
  }
}

checkTableStructure();
