/**
 * ===============================================
 * SCRIPT DE MIGRATION - User Tracking & Suspension
 * ===============================================
 * 
 * Ce script exécute la migration pour ajouter:
 * - Tracking des connexions/déconnexions
 * - Fonctionnalité de suspension de comptes
 * 
 * Usage: node run_user_tracking_migration.js
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function runMigration() {
  console.log('\n🚀 Démarrage de la migration User Tracking & Suspension...\n');

  try {
    // Lire le fichier SQL
    const sqlPath = path.join(__dirname, 'migrations', 'add_user_tracking_suspension.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('📄 Fichier SQL chargé:', sqlPath);
    console.log('📝 Exécution de la migration...\n');

    // Exécuter la migration
    await pool.query(sql);

    console.log('✅ Migration exécutée avec succès!\n');
    console.log('📊 Modifications appliquées:');
    console.log('   - Champ "est_suspendu" ajouté à la table users');
    console.log('   - Champ "date_suspension" ajouté à la table users');
    console.log('   - Champ "raison_suspension" ajouté à la table users');
    console.log('   - Champ "suspendu_par" ajouté à la table users');
    console.log('   - Table "user_activity_logs" créée pour tracker les connexions');
    console.log('   - Vue "user_activity_stats" créée pour les statistiques\n');

    // Vérifier la structure
    const checkUsers = await pool.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND column_name IN ('est_suspendu', 'date_suspension', 'raison_suspension', 'suspendu_par')
      ORDER BY ordinal_position
    `);

    const checkLogs = await pool.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_name = 'user_activity_logs'
    `);

    console.log('🔍 Vérification:');
    console.log('   - Nouveaux champs dans users:', checkUsers.rows.length, '/ 4');
    console.log('   - Table user_activity_logs:', checkLogs.rows[0].count === '1' ? 'Créée ✅' : 'Erreur ❌');

  } catch (error) {
    console.error('\n❌ Erreur lors de la migration:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Exécuter la migration
runMigration()
  .then(() => {
    console.log('\n✅ Migration terminée avec succès!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Migration échouée:', error);
    process.exit(1);
  });
