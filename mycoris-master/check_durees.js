const pool = require('./db');

async function checkDurees() {
  try {
    // Vérifier les durées pour chaque produit
    const products = [
      { id: 1, name: 'SÉRÉNITÉ' },
      { id: 2, name: 'FAMILIS' },
      { id: 3, name: 'RETRAITE' },
      { id: 4, name: 'SOLIDARITÉ' },
      { id: 5, name: 'ÉTUDE' },
      { id: 6, name: 'FLEX EMPRUNTEUR' }
    ];
    
    for (const product of products) {
      const query = `
        SELECT DISTINCT duree_contrat 
        FROM tarif_produit 
        WHERE produit_id = $1 
        ORDER BY duree_contrat 
        LIMIT 10
      `;
      const result = await pool.query(query, [product.id]);
      
      console.log(`\n=== ${product.name} (ID ${product.id}) ===`);
      console.log('Valeurs de duree_contrat dans la base :');
      result.rows.forEach(r => console.log(`  - ${r.duree_contrat}`));
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    process.exit();
  }
}

checkDurees();
