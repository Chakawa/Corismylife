const pool = require('./db');

async function checkAllProductsTarifs() {
  try {
    const query = `
      SELECT p.id, p.libelle, COUNT(t.id) as nb_tarifs
      FROM produit p
      LEFT JOIN tarif_produit t ON t.produit_id = p.id
      GROUP BY p.id, p.libelle
      ORDER BY p.id
    `;
    const result = await pool.query(query);
    
    console.log('=== TOUS LES PRODUITS ET LEURS TARIFS ===\n');
    result.rows.forEach(p => {
      const icon = p.nb_tarifs > 0 ? '✅' : '⚠️';
      console.log(`${icon} ID ${p.id}: ${p.libelle.padEnd(30)} - ${p.nb_tarifs} tarifs`);
    });
    
    // Vérifier spécifiquement Épargne Bonus
    const epargneQuery = `
      SELECT * FROM tarif_produit WHERE produit_id = 7 LIMIT 3
    `;
    const epargneResult = await pool.query(epargneQuery);
    
    console.log('\n=== TARIFS ÉPARGNE BONUS (ID 7) ===');
    if (epargneResult.rows.length > 0) {
      console.log('Exemple de tarifs:');
      epargneResult.rows.forEach((t, i) => {
        console.log(`${i+1}. Age: ${t.age}, Durée: ${t.duree_contrat} mois, Prime: ${t.prime}, Capital: ${t.capital}`);
      });
    } else {
      console.log('⚠️ Aucun tarif trouvé - c\'est normal si le produit vient d\'être créé');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    process.exit();
  }
}

checkAllProductsTarifs();
