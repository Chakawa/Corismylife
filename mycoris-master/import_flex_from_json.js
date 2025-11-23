const pool = require('./db');
const fs = require('fs');
const path = require('path');

// Lire le fichier JSON
const jsonPath = path.join(__dirname, 'scripts', 'data', 'flex_emprunteur_data.json');
const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

// Fonction pour formatter avec 5 décimales
function format5Decimals(value) {
  return Number(value).toFixed(5);
}

async function importFlexTarifs() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Démarrage de l\'import des tarifs FLEX EMPRUNTEUR avec 5 décimales...\n');
    
    // Récupérer l'ID du produit FLEX EMPRUNTEUR
    const produitResult = await client.query(
      "SELECT id FROM produit WHERE libelle ILIKE '%FLEX%EMPRUNTEUR%'"
    );
    
    if (produitResult.rows.length === 0) {
      throw new Error('Produit CORIS FLEX EMPRUNTEUR non trouvé !');
    }
    
    const produitId = produitResult.rows[0].id;
    console.log(`✅ Produit CORIS FLEX EMPRUNTEUR trouvé (ID: ${produitId})\n`);
    
    await client.query('BEGIN');
    
    let countInserted = 0;
    let countUpdated = 0;
    let countSkipped = 0;
    
    // 1. Importer les tarifs PRÊT AMORTISSABLE
    console.log('📊 Import des tarifs PRÊT AMORTISSABLE...');
    for (const [key, value] of Object.entries(data.tarifsPretAmortissable)) {
      const [age, dureeMois] = key.split('_').map(Number);
      const prime5Decimals = format5Decimals(value);
      
      // Vérifier si le tarif existe déjà
      const existingResult = await client.query(
        `SELECT id, prime FROM tarif_produit 
         WHERE produit_id = $1 
         AND age = $2 
         AND duree_contrat = $3 
         AND categorie = 'amortissable'`,
        [produitId, age, dureeMois]
      );
      
      if (existingResult.rows.length > 0) {
        // UPDATE si la valeur est différente
        const existingPrime = parseFloat(existingResult.rows[0].prime);
        const newPrime = parseFloat(prime5Decimals);
        
        if (Math.abs(existingPrime - newPrime) > 0.00001) {
          await client.query(
            `UPDATE tarif_produit 
             SET prime = $1::numeric(15,6), 
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $2`,
            [prime5Decimals, existingResult.rows[0].id]
          );
          countUpdated++;
          if (countUpdated <= 5) {
            console.log(`   ✏️  Mis à jour: Age ${age}, ${dureeMois} mois | ${existingPrime.toFixed(6)} → ${prime5Decimals}`);
          }
        } else {
          countSkipped++;
        }
      } else {
        // INSERT nouveau tarif
        await client.query(
          `INSERT INTO tarif_produit (produit_id, age, duree_contrat, periodicite, prime, categorie, created_at)
           VALUES ($1, $2, $3, 'mensuelle', $4::numeric(15,6), 'amortissable', CURRENT_TIMESTAMP)`,
          [produitId, age, dureeMois, prime5Decimals]
        );
        countInserted++;
        if (countInserted <= 5) {
          console.log(`   ➕ Inséré: Age ${age}, ${dureeMois} mois | Prime: ${prime5Decimals}`);
        }
      }
    }
    console.log(`   ✅ Amortissable: ${countInserted} insérés, ${countUpdated} mis à jour, ${countSkipped} inchangés\n`);
    
    // 2. Importer les tarifs PRÊT DÉCOUVERT
    console.log('📊 Import des tarifs PRÊT DÉCOUVERT...');
    countInserted = 0;
    countUpdated = 0;
    countSkipped = 0;
    
    for (const [key, value] of Object.entries(data.tarifsPretDecouvert)) {
      const [age, dureeMois] = key.split('_').map(Number);
      const prime5Decimals = format5Decimals(value);
      
      const existingResult = await client.query(
        `SELECT id, prime FROM tarif_produit 
         WHERE produit_id = $1 
         AND age = $2 
         AND duree_contrat = $3 
         AND categorie = 'decouvert'`,
        [produitId, age, dureeMois]
      );
      
      if (existingResult.rows.length > 0) {
        const existingPrime = parseFloat(existingResult.rows[0].prime);
        const newPrime = parseFloat(prime5Decimals);
        
        if (Math.abs(existingPrime - newPrime) > 0.00001) {
          await client.query(
            `UPDATE tarif_produit 
             SET prime = $1::numeric(15,6), 
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $2`,
            [prime5Decimals, existingResult.rows[0].id]
          );
          countUpdated++;
          if (countUpdated <= 5) {
            console.log(`   ✏️  Mis à jour: Age ${age}, ${dureeMois} mois | ${existingPrime.toFixed(6)} → ${prime5Decimals}`);
          }
        } else {
          countSkipped++;
        }
      } else {
        await client.query(
          `INSERT INTO tarif_produit (produit_id, age, duree_contrat, periodicite, prime, categorie, created_at)
           VALUES ($1, $2, $3, 'mensuelle', $4::numeric(15,6), 'decouvert', CURRENT_TIMESTAMP)`,
          [produitId, age, dureeMois, prime5Decimals]
        );
        countInserted++;
        if (countInserted <= 5) {
          console.log(`   ➕ Inséré: Age ${age}, ${dureeMois} mois | Prime: ${prime5Decimals}`);
        }
      }
    }
    console.log(`   ✅ Découvert: ${countInserted} insérés, ${countUpdated} mis à jour, ${countSkipped} inchangés\n`);
    
    // 3. Importer les tarifs PERTE D'EMPLOI
    console.log('📊 Import des tarifs PERTE D\'EMPLOI...');
    countInserted = 0;
    countUpdated = 0;
    countSkipped = 0;
    
    for (const [dureeAnnees, montant] of Object.entries(data.tarifsPerteEmploi)) {
      const dureeMois = parseInt(dureeAnnees) * 12;
      const montant5Decimals = format5Decimals(montant);
      
      const existingResult = await client.query(
        `SELECT id, capital FROM tarif_produit 
         WHERE produit_id = $1 
         AND duree_contrat = $2 
         AND categorie = 'perte_emploi'`,
        [produitId, dureeMois]
      );
      
      if (existingResult.rows.length > 0) {
        const existingCapital = parseFloat(existingResult.rows[0].capital);
        const newCapital = parseFloat(montant5Decimals);
        
        if (Math.abs(existingCapital - newCapital) > 0.00001) {
          await client.query(
            `UPDATE tarif_produit 
             SET capital = $1::numeric(15,6), 
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $2`,
            [montant5Decimals, existingResult.rows[0].id]
          );
          countUpdated++;
          console.log(`   ✏️  Mis à jour: ${dureeAnnees} an(s) | ${existingCapital.toFixed(2)} → ${montant5Decimals}`);
        } else {
          countSkipped++;
        }
      } else {
        await client.query(
          `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, capital, categorie, created_at)
           VALUES ($1, $2, 'annuelle', $3::numeric(15,6), 'perte_emploi', CURRENT_TIMESTAMP)`,
          [produitId, dureeMois, montant5Decimals]
        );
        countInserted++;
        console.log(`   ➕ Inséré: ${dureeAnnees} an(s) | Montant: ${montant5Decimals}`);
      }
    }
    console.log(`   ✅ Perte d'emploi: ${countInserted} insérés, ${countUpdated} mis à jour, ${countSkipped} inchangés\n`);
    
    await client.query('COMMIT');
    
    // Vérification finale avec précision
    console.log('🔍 Vérification finale de la précision...');
    const verificationResult = await client.query(
      `SELECT 
        categorie,
        COUNT(*) as total,
        COUNT(CASE WHEN LENGTH(SPLIT_PART(prime::TEXT, '.', 2)) >= 5 THEN 1 END) as avec_5_decimales
       FROM tarif_produit 
       WHERE produit_id = $1 AND prime IS NOT NULL
       GROUP BY categorie`,
      [produitId]
    );
    
    console.log('\n📊 Statistiques finales:');
    verificationResult.rows.forEach(row => {
      const pourcentage = ((row.avec_5_decimales / row.total) * 100).toFixed(1);
      console.log(`   ${row.categorie}: ${row.avec_5_decimales}/${row.total} tarifs avec ≥5 décimales (${pourcentage}%)`);
    });
    
    // Afficher quelques exemples
    console.log('\n📋 Exemples de tarifs importés:');
    const exemples = await client.query(
      `SELECT age, duree_contrat, categorie, prime::TEXT 
       FROM tarif_produit 
       WHERE produit_id = $1 
       ORDER BY categorie, age, duree_contrat 
       LIMIT 5`,
      [produitId]
    );
    
    exemples.rows.forEach(row => {
      const decimals = row.prime ? row.prime.split('.')[1]?.length || 0 : 0;
      console.log(`   Age ${row.age || 'N/A'} | ${row.duree_contrat} mois | ${row.categorie} | Prime: ${row.prime} (${decimals} décimales)`);
    });
    
    console.log('\n✅ Import terminé avec succès !');
    console.log('✅ Toutes les valeurs sont maintenant formatées avec 5 chiffres après la virgule');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur lors de l\'import:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Exécuter l'import
importFlexTarifs()
  .then(() => {
    console.log('\n🎉 Processus terminé');
    process.exit(0);
  })
  .catch(err => {
    console.error('\n❌ Échec:', err.message);
    process.exit(1);
  });
