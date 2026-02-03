const pool = require('../db');
const fs = require('fs');
const path = require('path');

async function runCorisMoneyMigration() {
  console.log('🚀 Démarrage de la migration CorisMoney...\n');

  try {
    // Lire le fichier SQL de migration
    const migrationPath = path.join(__dirname, '../migrations/add_corismoney_payment_tables.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');

    // Exécuter la migration
    await pool.query(sql);

    console.log('✅ Tables CorisMoney créées avec succès !');
    console.log('   - payment_otp_requests');
    console.log('   - payment_transactions');
    console.log('\n📊 Vérification des tables...\n');

    // Vérifier la structure des tables
    const tablesCheck = await pool.query(`
      SELECT table_name, column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name IN ('payment_otp_requests', 'payment_transactions')
      ORDER BY table_name, ordinal_position
    `);

    console.log('Structure des tables créées :');
    console.log('═'.repeat(80));
    
    let currentTable = '';
    tablesCheck.rows.forEach(row => {
      if (row.table_name !== currentTable) {
        currentTable = row.table_name;
        console.log(`\n📋 Table: ${currentTable}`);
        console.log('─'.repeat(80));
      }
      console.log(`   ${row.column_name.padEnd(25)} | ${row.data_type.padEnd(20)} | ${row.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}`);
    });

    console.log('\n' + '═'.repeat(80));
    console.log('✅ Migration terminée avec succès !');
    console.log('\n📝 Prochaines étapes :');
    console.log('   1. Configurer les variables d\'environnement dans .env :');
    console.log('      - CORIS_MONEY_CLIENT_ID');
    console.log('      - CORIS_MONEY_CLIENT_SECRET');
    console.log('      - CORIS_MONEY_CODE_PV');
    console.log('   2. Tester l\'API avec un compte CorisMoney de test');
    console.log('   3. Vérifier les endpoints :');
    console.log('      - POST /api/payment/send-otp');
    console.log('      - POST /api/payment/process-payment');
    console.log('      - GET /api/payment/client-info');
    console.log('      - GET /api/payment/transaction-status/:transactionId');
    console.log('      - GET /api/payment/history');

  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error.message);
    console.error('\nDétails:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Exécuter la migration
runCorisMoneyMigration();
