const pool = require('./db');

/**
 * Script de mise à jour FLEX EMPRUNTEUR avec 5 décimales
 * 
 * INSTRUCTIONS:
 * 1. Ouvrir le fichier Excel "TARIF FLEX ET FAMILIS CACI VIE_13062025.xlsx"
 * 2. Copier les valeurs FLEX et remplacer les données ci-dessous
 * 3. Exécuter: node import_flex_5decimales.js
 */

// ============================================================
// DONNÉES FLEX EMPRUNTEUR - À REMPLACER PAR LES VRAIES VALEURS
// ============================================================

// Tarifs Prêt Amortissable (Age × Durée en mois)
const tarifsAmortissable = {
  // Format: 'age_dureeMois': taux (5 décimales)
  // EXEMPLE À REMPLACER:
  '18_12': 0.15000,  // Remplacer par la vraie valeur à 5 décimales
  '18_24': 0.29500,
  '18_36': 0.44600,
  '34_60': 1.07965,  // Exemple avec 5 décimales
  // ... AJOUTER TOUTES LES AUTRES VALEURS ICI
};

// Tarifs Prêt Découvert (Age × Durée en mois)
const tarifsDecouvert = {
  // Format: 'age_dureeMois': taux (5 décimales)
  '18_12': 0.27200,  // Remplacer par la vraie valeur à 5 décimales
  '18_24': 0.56200,
  '34_60': 1.96800,  // Exemple avec 5 décimales
  // ... AJOUTER TOUTES LES AUTRES VALEURS ICI
};

// Tarifs Perte d'Emploi (Durée en années)
const tarifsPerteEmploi = {
  // Format: 'dureeAnnees': montant (5 décimales)
  '1': 19.20000,
  '2': 38.40000,
  '3': 57.60000,
  '4': 76.80000,
  '5': 96.00000,
  '6': 115.20000
};

// ============================================================
// FONCTIONS D'IMPORT
// ============================================================

async function importFlexTarifs() {
  const client = await pool.connect();
  
  try {
    console.log('\n🔄 Début de l\'import des tarifs FLEX avec 5 décimales\n');
    
    // 1. Récupérer l'ID du produit
    const result = await client.query('SELECT id FROM produit WHERE libelle = $1', ['CORIS FLEX EMPRUNTEUR']);
    if (result.rows.length === 0) {
      throw new Error('Produit CORIS FLEX EMPRUNTEUR non trouvé');
    }
    const produitId = result.rows[0].id;
    console.log(`✅ Produit CORIS FLEX EMPRUNTEUR (ID: ${produitId})\n`);
    
    await client.query('BEGIN');
    
    let updated = 0;
    let inserted = 0;
    
    // 2. Importer les tarifs Amortissable
    console.log('📊 Import des tarifs Prêt Amortissable...');
    for (const [key, prime] of Object.entries(tarifsAmortissable)) {
      const [age, duree] = key.split('_');
      
      // Vérifier si le tarif existe déjà
      const check = await client.query(
        'SELECT id FROM tarif_produit WHERE produit_id = $1 AND age = $2 AND duree_contrat = $3 AND categorie = $4',
        [produitId, parseInt(age), parseInt(duree), 'amortissable']
      );
      
      if (check.rows.length > 0) {
        // Mettre à jour
        await client.query(
          'UPDATE tarif_produit SET prime = $1 WHERE id = $2',
          [prime, check.rows[0].id]
        );
        updated++;
      } else {
        // Insérer
        await client.query(
          'INSERT INTO tarif_produit (produit_id, age, duree_contrat, periodicite, prime, categorie) VALUES ($1, $2, $3, $4, $5, $6)',
          [produitId, parseInt(age), parseInt(duree), 'unique', prime, 'amortissable']
        );
        inserted++;
      }
    }
    console.log(`   ✅ ${updated} tarifs mis à jour, ${inserted} nouveaux tarifs`);
    
    updated = 0;
    inserted = 0;
    
    // 3. Importer les tarifs Découvert
    console.log('📊 Import des tarifs Prêt Découvert...');
    for (const [key, prime] of Object.entries(tarifsDecouvert)) {
      const [age, duree] = key.split('_');
      
      const check = await client.query(
        'SELECT id FROM tarif_produit WHERE produit_id = $1 AND age = $2 AND duree_contrat = $3 AND categorie = $4',
        [produitId, parseInt(age), parseInt(duree), 'decouvert']
      );
      
      if (check.rows.length > 0) {
        await client.query(
          'UPDATE tarif_produit SET prime = $1 WHERE id = $2',
          [prime, check.rows[0].id]
        );
        updated++;
      } else {
        await client.query(
          'INSERT INTO tarif_produit (produit_id, age, duree_contrat, periodicite, prime, categorie) VALUES ($1, $2, $3, $4, $5, $6)',
          [produitId, parseInt(age), parseInt(duree), 'unique', prime, 'decouvert']
        );
        inserted++;
      }
    }
    console.log(`   ✅ ${updated} tarifs mis à jour, ${inserted} nouveaux tarifs`);
    
    updated = 0;
    inserted = 0;
    
    // 4. Importer les tarifs Perte d'Emploi
    console.log('📊 Import des tarifs Perte d\'Emploi...');
    for (const [duree, prime] of Object.entries(tarifsPerteEmploi)) {
      const check = await client.query(
        'SELECT id FROM tarif_produit WHERE produit_id = $1 AND age IS NULL AND duree_contrat = $2 AND categorie = $3',
        [produitId, parseInt(duree), 'perte_emploi']
      );
      
      if (check.rows.length > 0) {
        await client.query(
          'UPDATE tarif_produit SET prime = $1 WHERE id = $2',
          [prime, check.rows[0].id]
        );
        updated++;
      } else {
        await client.query(
          'INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, categorie) VALUES ($1, $2, $3, $4, $5)',
          [produitId, parseInt(duree), 'unique', prime, 'perte_emploi']
        );
        inserted++;
      }
    }
    console.log(`   ✅ ${updated} tarifs mis à jour, ${inserted} nouveaux tarifs`);
    
    await client.query('COMMIT');
    
    console.log('\n✅ Import terminé avec succès !');
    console.log('\n📋 Vérification des données importées...');
    
    // 5. Vérifier quelques valeurs
    const verify = await client.query(`
      SELECT age, duree_contrat, categorie, prime::TEXT as prime
      FROM tarif_produit
      WHERE produit_id = $1
      ORDER BY RANDOM()
      LIMIT 5
    `, [produitId]);
    
    console.log('\nExemples de tarifs (5 aléatoires):');
    verify.rows.forEach(row => {
      console.log(`   Age ${row.age || 'N/A'} | Durée ${row.duree_contrat} | ${row.categorie} | Prime: ${row.prime}`);
    });
    
    process.exit(0);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Erreur lors de l\'import:', error.message);
    process.exit(1);
  } finally {
    client.release();
  }
}

// ============================================================
// EXÉCUTION
// ============================================================

console.log('');
console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║  IMPORT TARIFS FLEX EMPRUNTEUR - 5 DÉCIMALES              ║');
console.log('╚════════════════════════════════════════════════════════════╝');
console.log('');
console.log('⚠️  ATTENTION: Vérifiez que les données ci-dessus sont correctes');
console.log('    avant d\'exécuter cet import !');
console.log('');

// Attendre 3 secondes avant de commencer
setTimeout(() => {
  importFlexTarifs();
}, 3000);
