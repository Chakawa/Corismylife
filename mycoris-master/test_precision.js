const pool = require('./db');

async function testPrecision() {
  try {
    const result = await pool.query(`
      SELECT prime::numeric(15,6) as prime, duree_contrat, periodicite 
      FROM tarif_produit 
      WHERE produit_id = (SELECT id FROM produit WHERE libelle = 'CORIS RETRAITE') 
      AND periodicite = 'mensuel' 
      AND duree_contrat IN (12, 15) 
      ORDER BY duree_contrat
    `);
    
    console.log('Résultats de la base de données:');
    console.log('================================');
    result.rows.forEach(row => {
      console.log(`Durée: ${row.duree_contrat} ans | Périodicité: ${row.periodicite} | Prime: ${row.prime}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Erreur:', error);
    process.exit(1);
  }
}

testPrecision();
