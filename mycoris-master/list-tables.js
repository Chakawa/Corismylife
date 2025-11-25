/**
 * Script pour lister toutes les tables de la base de données
 */

const pool = require('./db');

async function listAllTables() {
  try {
    console.log('=== LISTE DES TABLES DANS LA BASE DE DONNÉES ===\n');
    
    // Récupérer toutes les tables
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name;
    `);
    
    console.log(`📊 Nombre de tables trouvées: ${result.rows.length}\n`);
    
    if (result.rows.length === 0) {
      console.log('❌ Aucune table trouvée dans la base de données\n');
    } else {
      console.log('📋 Tables existantes:\n');
      result.rows.forEach((row, index) => {
        console.log(`${index + 1}. ${row.table_name}`);
      });
      console.log('\n');
      
      // Vérifier si la table contrats existe
      const contratsExists = result.rows.some(row => row.table_name === 'contrats');
      
      if (contratsExists) {
        console.log('✅ La table "contrats" existe bien !\n');
        
        // Compter les lignes
        const countResult = await pool.query('SELECT COUNT(*) FROM contrats');
        console.log(`📊 Nombre de contrats: ${countResult.rows[0].count}\n`);
        
        // Afficher la structure
        console.log('🔍 Structure de la table "contrats":\n');
        const structureResult = await pool.query(`
          SELECT column_name, data_type, character_maximum_length, is_nullable
          FROM information_schema.columns
          WHERE table_name = 'contrats'
          ORDER BY ordinal_position;
        `);
        
        structureResult.rows.forEach(col => {
          const type = col.character_maximum_length 
            ? `${col.data_type}(${col.character_maximum_length})`
            : col.data_type;
          console.log(`  - ${col.column_name}: ${type} ${col.is_nullable === 'NO' ? '(NOT NULL)' : ''}`);
        });
        console.log('\n');
        
        // Afficher quelques exemples de contrats
        const sampleResult = await pool.query(`
          SELECT id, telephone1, telephone2, nom_prenom, numepoli, etat 
          FROM contrats 
          LIMIT 5
        `);
        
        if (sampleResult.rows.length > 0) {
          console.log('📋 Exemples de contrats:\n');
          sampleResult.rows.forEach((contrat, index) => {
            console.log(`Contrat ${index + 1}:`);
            console.log(`  - ID: ${contrat.id}`);
            console.log(`  - Nom: ${contrat.nom_prenom}`);
            console.log(`  - Tel1: ${contrat.telephone1}`);
            console.log(`  - Tel2: ${contrat.telephone2}`);
            console.log(`  - N° Police: ${contrat.numepoli}`);
            console.log(`  - État: ${contrat.etat}\n`);
          });
        } else {
          console.log('⚠️  La table "contrats" est vide (aucun contrat enregistré)\n');
        }
        
      } else {
        console.log('❌ La table "contrats" n\'existe PAS dans la base de données\n');
      }
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error.stack);
  } finally {
    pool.end();
    process.exit(0);
  }
}

listAllTables();
