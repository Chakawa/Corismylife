const pool = require('./db');

async function checkTarifStructure() {
  try {
    // Vérifier la structure de tarif_produit
    const structQuery = `
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'tarif_produit'
      ORDER BY ordinal_position
    `;
    const structResult = await pool.query(structQuery);
    
    console.log('=== STRUCTURE TABLE tarif_produit ===');
    structResult.rows.forEach(col => {
      console.log(`${col.column_name}: ${col.data_type}`);
    });
    
    // Exemple de données
    const sampleQuery = `SELECT * FROM tarif_produit LIMIT 3`;
    const sampleResult = await pool.query(sampleQuery);
    
    console.log('\n=== EXEMPLE DE DONNÉES ===');
    sampleResult.rows.forEach((row, i) => {
      console.log(`\nLigne ${i+1}:`);
      Object.keys(row).forEach(key => {
        console.log(`  ${key}: ${row[key]}`);
      });
    });
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    process.exit();
  }
}

checkTarifStructure();
