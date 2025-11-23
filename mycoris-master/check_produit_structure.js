const pool = require('./db');

async function checkProduitStructure() {
  try {
    // Vérifier les colonnes de la table produit
    const columnsResult = await pool.query(
      "SELECT column_name FROM information_schema.columns WHERE table_name = 'produit'"
    );
    
    console.log('📊 Colonnes de la table produit:');
    columnsResult.rows.forEach(row => {
      console.log(`   - ${row.column_name}`);
    });
    
    // Récupérer quelques lignes de la table produit
    const produitsResult = await pool.query('SELECT * FROM produit LIMIT 3');
    
    console.log('\n📋 Exemples de produits:');
    produitsResult.rows.forEach(produit => {
      console.log(JSON.stringify(produit, null, 2));
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

checkProduitStructure();
