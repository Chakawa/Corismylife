/**
 * ========================================
 * SCRIPT DE VÉRIFICATION DES TABLES CORISMONEY
 * ========================================
 * 
 * Ce script vérifie que les tables de paiement CorisMoney
 * ont été correctement créées dans la base de données PostgreSQL.
 * 
 * Tables vérifiées:
 * - payment_otp_requests: Stocke les demandes d'OTP
 * - payment_transactions: Stocke l'historique des transactions
 * 
 * Commande: node scripts/verify_corismoney_tables.js
 */

require('dotenv').config();
const { Pool } = require('pg');

// Configuration de la connexion PostgreSQL
// Utilise DATABASE_URL du fichier .env
const connectionString = process.env.DATABASE_URL || 'postgresql://db_admin:Corisvie2025@185.98.138.168:5432/mycorisdb';
const pool = new Pool({
  connectionString: connectionString
});

/**
 * Vérifie l'existence d'une table et affiche ses colonnes
 */
async function verifyTable(tableName) {
  console.log(`\n📋 Vérification de la table: ${tableName}`);
  console.log('='.repeat(60));

  try {
    // Vérifier l'existence de la table
    const existsQuery = `
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = $1
      );
    `;
    
    const existsResult = await pool.query(existsQuery, [tableName]);
    const tableExists = existsResult.rows[0].exists;

    if (!tableExists) {
      console.log(`❌ ERREUR: La table "${tableName}" n'existe pas !`);
      return false;
    }

    console.log(`✅ La table "${tableName}" existe`);

    // Récupérer les colonnes de la table
    const columnsQuery = `
      SELECT 
        column_name, 
        data_type, 
        character_maximum_length,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = $1
      ORDER BY ordinal_position;
    `;

    const columnsResult = await pool.query(columnsQuery, [tableName]);
    
    console.log('\n📊 Colonnes:');
    columnsResult.rows.forEach(col => {
      const nullable = col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL';
      const defaultVal = col.column_default ? ` DEFAULT ${col.column_default}` : '';
      const maxLength = col.character_maximum_length ? `(${col.character_maximum_length})` : '';
      
      console.log(`  - ${col.column_name}: ${col.data_type}${maxLength} ${nullable}${defaultVal}`);
    });

    // Compter les enregistrements
    const countQuery = `SELECT COUNT(*) FROM ${tableName}`;
    const countResult = await pool.query(countQuery);
    console.log(`\n📈 Nombre d'enregistrements: ${countResult.rows[0].count}`);

    return true;

  } catch (error) {
    console.log(`❌ ERREUR lors de la vérification: ${error.message}`);
    return false;
  }
}

/**
 * Fonction principale
 */
async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║   VÉRIFICATION DES TABLES CORISMONEY                       ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  try {
    // Test de connexion
    console.log('\n🔌 Test de connexion à la base de données...');
    await pool.query('SELECT NOW()');
    console.log('✅ Connexion réussie !');

    // Vérifier les tables
    const table1 = await verifyTable('payment_otp_requests');
    const table2 = await verifyTable('payment_transactions');

    // Résumé
    console.log('\n' + '='.repeat(60));
    console.log('📝 RÉSUMÉ');
    console.log('='.repeat(60));
    console.log(`payment_otp_requests: ${table1 ? '✅ OK' : '❌ MANQUANTE'}`);
    console.log(`payment_transactions: ${table2 ? '✅ OK' : '❌ MANQUANTE'}`);

    if (table1 && table2) {
      console.log('\n🎉 Toutes les tables CorisMoney sont correctement créées !');
    } else {
      console.log('\n⚠️  Certaines tables sont manquantes. Exécutez la migration:');
      console.log('   node scripts/run_corismoney_migration.js');
    }

  } catch (error) {
    console.error('\n❌ ERREUR:', error.message);
  } finally {
    await pool.end();
    console.log('\n👋 Déconnexion de la base de données\n');
  }
}

// Exécuter le script
main();
