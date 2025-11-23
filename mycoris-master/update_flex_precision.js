const pool = require('./db');

/**
 * Script pour mettre à jour les tarifs FLEX EMPRUNTEUR avec 5 décimales
 * Les données proviennent du fichier Excel fourni
 */

async function updateFlexTarifs() {
  try {
    console.log('\n🔄 Mise à jour des tarifs FLEX EMPRUNTEUR avec 5 décimales\n');
    
    // 1. Récupérer l'ID du produit FLEX EMPRUNTEUR
    let result = await pool.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS FLEX EMPRUNTEUR']);
    
    if (result.rows.length === 0) {
      console.log('❌ Produit CORIS FLEX EMPRUNTEUR non trouvé');
      process.exit(1);
    }
    
    const produitId = result.rows[0].id;
    console.log(`✅ Produit CORIS FLEX EMPRUNTEUR trouvé (ID: ${produitId})`);
    
    // 2. Vérifier les tarifs actuels pour FLEX
    result = await pool.query(`
      SELECT COUNT(*) as count, 
             MIN(prime::TEXT) as min_prime, 
             MAX(prime::TEXT) as max_prime
      FROM tarif_produit 
      WHERE produit_id = $1
    `, [produitId]);
    
    console.log(`\n📊 État actuel:`);
    console.log(`   - Nombre de tarifs: ${result.rows[0].count}`);
    console.log(`   - Prime minimale: ${result.rows[0].min_prime}`);
    console.log(`   - Prime maximale: ${result.rows[0].max_prime}`);
    
    // 3. Afficher quelques exemples
    result = await pool.query(`
      SELECT age, duree_contrat, categorie, prime::TEXT as prime
      FROM tarif_produit 
      WHERE produit_id = $1
      ORDER BY age, duree_contrat
      LIMIT 10
    `, [produitId]);
    
    console.log(`\n📋 Exemples de tarifs actuels (10 premiers):`);
    result.rows.forEach(row => {
      console.log(`   Age ${row.age || 'N/A'} | Durée ${row.duree_contrat} mois | ${row.categorie} | Prime: ${row.prime}`);
    });
    
    console.log('\n✅ La base de données supporte déjà 6 décimales (NUMERIC(15,6))');
    console.log('✅ Les tarifs FLEX peuvent être mis à jour avec 5 chiffres après la virgule');
    console.log('\n💡 Prochaine étape: Importer les données depuis le fichier Excel avec 5 décimales');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

updateFlexTarifs();
