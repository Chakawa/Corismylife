const pool = require('./db');

async function addProducts() {
  try {
    const query = `
      INSERT INTO produit (libelle)
      VALUES 
        ('ASSUR PRESTIGE'),
        ('MON BON PLAN CORIS'),
        ('PRET SCOLAIRE')
      RETURNING *;
    `;
    
    const result = await pool.query(query);
    console.log('✅ Produits ajoutés:', result.rows.length);
    result.rows.forEach(p => console.log(`  - ${p.libelle} (ID: ${p.id})`));
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    process.exit();
  }
}

addProducts();
