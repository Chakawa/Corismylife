const pool = require('./db');

async function testPrecision() {
  try {
    console.log('\n🧪 TEST: Cast ::TEXT pour préserver la précision décimale\n');
    
    // Test 1: Sans cast (comportement actuel - perte de précision)
    console.log('📊 Test 1: Sans cast ::TEXT');
    const result1 = await pool.query(`
      SELECT prime, capital 
      FROM tarif_produit 
      WHERE produit_id = (SELECT id FROM produit WHERE libelle = 'CORIS RETRAITE' LIMIT 1) 
        AND periodicite = 'mensuel' 
        AND duree_contrat = 12 
      LIMIT 1
    `);
    console.log('Résultat sans cast:');
    console.log('  - prime (type ' + typeof result1.rows[0].prime + '):', result1.rows[0].prime);
    console.log('  - capital (type ' + typeof result1.rows[0].capital + '):', result1.rows[0].capital);
    
    // Test 2: Avec cast ::TEXT (nouvelle méthode - préserve précision)
    console.log('\n📊 Test 2: Avec cast ::TEXT');
    const result2 = await pool.query(`
      SELECT prime::TEXT as prime, capital::TEXT as capital 
      FROM tarif_produit 
      WHERE produit_id = (SELECT id FROM produit WHERE libelle = 'CORIS RETRAITE' LIMIT 1) 
        AND periodicite = 'mensuel' 
        AND duree_contrat = 12 
      LIMIT 1
    `);
    console.log('Résultat avec cast ::TEXT:');
    console.log('  - prime (type ' + typeof result2.rows[0].prime + '):', result2.rows[0].prime);
    console.log('  - capital (type ' + typeof result2.rows[0].capital + '):', result2.rows[0].capital);
    
    // Test 3: Conversion en double côté Flutter
    console.log('\n📊 Test 3: Conversion double (comme Flutter)');
    const primeAsDouble = parseFloat(result2.rows[0].prime);
    const capitalAsDouble = parseFloat(result2.rows[0].capital);
    console.log('  - prime converti:', primeAsDouble);
    console.log('  - capital converti:', capitalAsDouble);
    
    // Vérification
    console.log('\n✅ Conclusion:');
    if (result2.rows[0].prime.includes('.')) {
      console.log('  ✅ La précision décimale est PRÉSERVÉE avec ::TEXT');
      console.log('  ✅ Valeur précise: ' + result2.rows[0].prime);
    } else {
      console.log('  ⚠️  La valeur est un entier: ' + result2.rows[0].prime);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

testPrecision();
