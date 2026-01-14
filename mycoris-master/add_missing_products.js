const pool = require('./db');

async function addMissingProducts() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Vérifier et ajouter les produits manquants
    const productsToAdd = [
      { id: 250, libelle: 'ASSUR PRESTIGE' },
      { id: 260, libelle: 'MON BON PLAN CORIS' },
      { id: 270, libelle: 'PRET SCOLAIRE' }
    ];

    for (const product of productsToAdd) {
      const existing = await client.query('SELECT id FROM produit WHERE id = $1', [product.id]);
      
      if (existing.rows.length === 0) {
        await client.query(
          'INSERT INTO produit (id, libelle) VALUES ($1, $2) ON CONFLICT (id) DO NOTHING',
          [product.id, product.libelle]
        );
        console.log(`✅ Produit ajouté: ${product.libelle} (${product.id})`);
      } else {
        console.log(`⏭️  Produit existant: ${product.libelle} (${product.id})`);
      }
    }

    await client.query('COMMIT');
    console.log('\n✅ Tous les produits manquants ont été ajoutés !');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur:', error);
  } finally {
    client.release();
    process.exit();
  }
}

addMissingProducts();
