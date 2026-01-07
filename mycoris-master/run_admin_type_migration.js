/**
 * Migration: Ajout de la colonne admin_type
 * Exécute la migration pour ajouter le type d'administrateur
 */

const pool = require('./db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Début de la migration admin_type...\n');

    // Lire le fichier SQL
    const sqlFile = path.join(__dirname, 'migrations', 'add_admin_type_column.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    // Exécuter la migration
    await client.query(sql);
    
    console.log('✅ Colonne admin_type ajoutée avec succès');
    
    // Vérifier les admins existants
    const result = await client.query(`
      SELECT id, nom, prenom, email, role, admin_type 
      FROM users 
      WHERE role = 'admin'
      ORDER BY created_at
    `);
    
    console.log('\n📊 Administrateurs dans le système:');
    console.table(result.rows);
    
    console.log('\n✅ Migration admin_type exécutée avec succès');
    
  } catch (error) {
    console.error('❌ Erreur migration:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(console.error);
