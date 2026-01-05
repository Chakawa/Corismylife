const pool = require('./db');

console.log('🚀 Exécution de la migration: Création table 2FA');

async function runMigration() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('📋 Création de la table two_factor_auth...');
    
    // Créer la table two_factor_auth
    await client.query(`
      CREATE TABLE IF NOT EXISTS two_factor_auth (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        enabled BOOLEAN DEFAULT false,
        secondary_phone VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('✅ Table two_factor_auth créée');
    
    // Créer les index
    console.log('📋 Création des index...');
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_2fa_user_id ON two_factor_auth(user_id)
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_2fa_enabled ON two_factor_auth(enabled)
    `);
    
    console.log('✅ Index créés');
    
    // Créer la fonction de mise à jour
    console.log('📋 Création de la fonction de mise à jour...');
    await client.query(`
      CREATE OR REPLACE FUNCTION update_2fa_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);
    
    console.log('✅ Fonction créée');
    
    // Créer le trigger
    console.log('📋 Création du trigger...');
    await client.query(`
      DROP TRIGGER IF EXISTS trigger_update_2fa_updated_at ON two_factor_auth
    `);
    await client.query(`
      CREATE TRIGGER trigger_update_2fa_updated_at
        BEFORE UPDATE ON two_factor_auth
        FOR EACH ROW
        EXECUTE FUNCTION update_2fa_updated_at()
    `);
    
    console.log('✅ Trigger créé');
    
    // Vérifier la structure de la table
    const tableCheck = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'two_factor_auth'
      ORDER BY ordinal_position
    `);
    
    console.log('\n📊 Structure de la table two_factor_auth:');
    tableCheck.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
    });
    
    await client.query('COMMIT');
    
    console.log('\n✅✅✅ MIGRATION RÉUSSIE ✅✅✅');
    console.log('La table two_factor_auth a été créée avec succès\n');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ ERREUR lors de la migration:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(err => {
  console.error('Échec de la migration:', err);
  process.exit(1);
});
