const pool = require('./db');

async function checkEpargneBonusTarifs() {
  try {
    // Chercher le produit Épargne Bonus
    const productQuery = `SELECT * FROM produit WHERE LOWER(libelle) LIKE '%epargne%' OR LOWER(libelle) LIKE '%bonus%'`;
    const productResult = await pool.query(productQuery);
    
    console.log('=== PRODUITS ÉPARGNE/BONUS ===');
    productResult.rows.forEach(p => {
      console.log(`ID: ${p.id}, Libellé: ${p.libelle}`);
    });
    
    if (productResult.rows.length > 0) {
      const productId = productResult.rows[0].id;
      
      // Chercher les tarifs
      const tarifQuery = `SELECT * FROM tarif_produit WHERE id_produit = $1 LIMIT 5`;
      const tarifResult = await pool.query(tarifQuery, [productId]);
      
      console.log(`\n=== TARIFS POUR ${productResult.rows[0].libelle} (ID: ${productId}) ===`);
      console.log(`Nombre de tarifs: ${tarifResult.rows.length}`);
      
      if (tarifResult.rows.length > 0) {
        console.log('\nExemple de tarifs:');
        tarifResult.rows.forEach((t, i) => {
          console.log(`${i+1}. Age: ${t.age}, Durée: ${t.duree_contrat}, Prime: ${t.prime}, Capital: ${t.capital}, Catégorie: ${t.categorie}`);
        });
      } else {
        console.log('⚠️ Aucun tarif trouvé pour ce produit');
      }
    } else {
      console.log('⚠️ Aucun produit Épargne Bonus trouvé');
    }
    
    // Lister tous les produits avec leur nombre de tarifs
    const allQuery = `
      SELECT p.id, p.libelle, COUNT(t.id) as nb_tarifs
      FROM produit p
      LEFT JOIN tarif_produit t ON t.id_produit = p.id
      GROUP BY p.id, p.libelle
      ORDER BY p.id
    `;
    const allResult = await pool.query(allQuery);
    
    console.log('\n=== TOUS LES PRODUITS ===');
    allResult.rows.forEach(p => {
      console.log(`${p.id}. ${p.libelle} - ${p.nb_tarifs} tarifs`);
    });
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    process.exit();
  }
}

checkEpargneBonusTarifs();
