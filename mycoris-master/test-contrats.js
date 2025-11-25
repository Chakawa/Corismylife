/**
 * Script de test pour vérifier la table contrats
 */

const pool = require('./db');

async function testContrats() {
  try {
    console.log('=== TEST TABLE CONTRATS ===\n');
    
    // 1. Vérifier si la table existe
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'contrats'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.log('❌ La table "contrats" n\'existe pas !');
      pool.end();
      return;
    }
    
    console.log('✅ La table "contrats" existe\n');
    
    // 2. Compter les contrats
    const countResult = await pool.query('SELECT COUNT(*) FROM contrats');
    const count = parseInt(countResult.rows[0].count);
    console.log(`📊 Nombre total de contrats: ${count}\n`);
    
    if (count === 0) {
      console.log('⚠️  Aucun contrat trouvé dans la table\n');
    } else {
      // 3. Afficher quelques exemples
      const sampleResult = await pool.query(`
        SELECT id, telephone1, telephone2, nom_prenom, numepoli, codeprod, etat 
        FROM contrats 
        LIMIT 5
      `);
      
      console.log('📋 Exemples de contrats:\n');
      sampleResult.rows.forEach((contrat, index) => {
        console.log(`Contrat ${index + 1}:`);
        console.log(`  - ID: ${contrat.id}`);
        console.log(`  - Nom: ${contrat.nom_prenom}`);
        console.log(`  - Téléphone 1: ${contrat.telephone1}`);
        console.log(`  - Téléphone 2: ${contrat.telephone2}`);
        console.log(`  - N° Police: ${contrat.numepoli}`);
        console.log(`  - Code produit: ${contrat.codeprod}`);
        console.log(`  - État: ${contrat.etat}\n`);
      });
      
      // 4. Vérifier les numéros de téléphone uniques
      const phonesResult = await pool.query(`
        SELECT DISTINCT telephone1 
        FROM contrats 
        WHERE telephone1 IS NOT NULL 
        ORDER BY telephone1 
        LIMIT 10
      `);
      
      console.log('📞 Numéros de téléphone dans la base:\n');
      phonesResult.rows.forEach(row => {
        console.log(`  - ${row.telephone1}`);
      });
      console.log('');
    }
    
    // 5. Vérifier le numéro spécifique de l'utilisateur
    const userPhone = '+2250576097537';
    console.log(`🔍 Recherche de contrats pour: ${userPhone}\n`);
    
    // Préparer les différents formats
    const phoneVariants = [userPhone];
    if (userPhone.startsWith('+225')) {
      const withoutCountryCode = userPhone.replace('+225', '');
      phoneVariants.push(withoutCountryCode);
      if (!withoutCountryCode.startsWith('0')) {
        phoneVariants.push('0' + withoutCountryCode);
      }
    }
    
    console.log('📞 Formats de recherche:', phoneVariants, '\n');
    
    const placeholders = phoneVariants.map((_, index) => `$${index + 1}`).join(', ');
    const userContrats = await pool.query(`
      SELECT * FROM contrats 
      WHERE telephone1 IN (${placeholders}) OR telephone2 IN (${placeholders})
    `, phoneVariants);
    
    if (userContrats.rows.length === 0) {
      console.log(`❌ Aucun contrat trouvé pour ${userPhone}\n`);
      
      // Recherche approximative
      console.log('🔍 Recherche approximative (sans +225):\n');
      const phoneWithout225 = userPhone.replace('+225', '');
      const approxResult = await pool.query(`
        SELECT telephone1, telephone2, nom_prenom 
        FROM contrats 
        WHERE telephone1 LIKE $1 OR telephone2 LIKE $1
      `, [`%${phoneWithout225}%`]);
      
      if (approxResult.rows.length > 0) {
        console.log('⚠️  Contrats trouvés avec un format différent:');
        approxResult.rows.forEach(row => {
          console.log(`  - Tel1: ${row.telephone1}, Tel2: ${row.telephone2}, Nom: ${row.nom_prenom}`);
        });
      } else {
        console.log('❌ Aucun contrat trouvé même en recherche approximative');
      }
    } else {
      console.log(`✅ ${userContrats.rows.length} contrat(s) trouvé(s) pour ${userPhone}:\n`);
      userContrats.rows.forEach((contrat, index) => {
        console.log(`Contrat ${index + 1}:`);
        console.log(JSON.stringify(contrat, null, 2));
        console.log('');
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error.stack);
  } finally {
    pool.end();
    process.exit(0);
  }
}

testContrats();
