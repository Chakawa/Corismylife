const pool = require('./db');

async function checkStructure() {
  try {
    const result = await pool.query(`
      SELECT column_name, data_type, numeric_precision, numeric_scale 
      FROM information_schema.columns 
      WHERE table_name = 'tarif_produit' 
        AND column_name IN ('prime', 'capital')
    `);
    
    console.log('\n📊 Structure actuelle de la table tarif_produit:\n');
    result.rows.forEach(row => {
      console.log(`Colonne: ${row.column_name}`);
      console.log(`  Type: ${row.data_type}`);
      console.log(`  Précision: ${row.numeric_precision}`);
      console.log(`  Échelle (décimales): ${row.numeric_scale}\n`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

checkStructure();
