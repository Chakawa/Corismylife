const pool = require('./db');

async function simpleCheck() {
  const client = await pool.connect();
  try {
    const result = await client.query(`
      SELECT DISTINCT duree_contrat 
      FROM tarif_produit 
      WHERE produit_id = 2
      ORDER BY duree_contrat 
      LIMIT 10
    `);
    
    console.log('=== FAMILIS - Durées ===');
    result.rows.forEach(r => console.log(r.duree_contrat));
  } catch (e) {
    console.error('Erreur:', e.message);
  } finally {
    client.release();
    process.exit();
  }
}

simpleCheck();
