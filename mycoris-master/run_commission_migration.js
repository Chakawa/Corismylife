const pool = require('./db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    console.log('=== MIGRATION: Commission Instance Table ===\n');
    
    console.log('📄 Creating commission_instance table...\n');
    
    // Create table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS commission_instance (
        id SERIAL PRIMARY KEY,
        code_apporteur VARCHAR(50) NOT NULL,
        montant_commission DECIMAL(15, 2) NOT NULL,
        date_calcul TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        montant_encaisse_reference DECIMAL(15, 2),
        numero_police VARCHAR(100),
        statut_reception VARCHAR(50) DEFAULT 'En attente',
        date_reception TIMESTAMP,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    console.log('✅ Table created\n');
    
    // Add foreign key to users
    console.log('🔗 Adding foreign key to users table...\n');
    try {
      await pool.query(`
        ALTER TABLE commission_instance
        ADD CONSTRAINT fk_commission_apporteur 
          FOREIGN KEY (code_apporteur) 
          REFERENCES users(code_apporteur) 
          ON DELETE CASCADE 
          ON UPDATE CASCADE;
      `);
      console.log('✅ Foreign key fk_commission_apporteur added\n');
    } catch (err) {
      if (err.message.includes('existe déjà') || err.message.includes('already exists')) {
        console.log('✓ Foreign key fk_commission_apporteur already exists\n');
      } else {
        throw err;
      }
    }
    
    // Add foreign key to contrats
    console.log('🔗 Adding foreign key to contrats table...\n');
    console.log('⚠️  Note: numero_police cannot be a foreign key due to duplicates in contrats.numepoli');
    console.log('✓ Using numero_police as a reference field without foreign key constraint\n');
    
    // Add check constraints
    console.log('✔️  Adding validation constraints...\n');
    
    try {
      await pool.query(`
        ALTER TABLE commission_instance
        ADD CONSTRAINT check_montant_commission_positive 
          CHECK (montant_commission >= 0);
      `);
    } catch (err) {
      if (!err.message.includes('already exists')) console.log('✓ check_montant_commission_positive constraint added');
    }
    
    try {
      await pool.query(`
        ALTER TABLE commission_instance
        ADD CONSTRAINT check_statut_reception_valide 
          CHECK (statut_reception IN ('En attente', 'Reçue', 'Rejetée'));
      `);
    } catch (err) {
      if (!err.message.includes('already exists')) console.log('✓ check_statut_reception_valide constraint added');
    }
    
    // Create indexes
    console.log('\n📊 Creating indexes...\n');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_commission_code_apporteur 
      ON commission_instance(code_apporteur);
    `);
    console.log('✅ Index idx_commission_code_apporteur created');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_commission_numero_police 
      ON commission_instance(numero_police);
    `);
    console.log('✅ Index idx_commission_numero_police created');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_commission_statut 
      ON commission_instance(statut_reception);
    `);
    console.log('✅ Index idx_commission_statut created');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_commission_apporteur_date 
      ON commission_instance(code_apporteur, date_calcul);
    `);
    console.log('✅ Index idx_commission_apporteur_date created');
    
    // Create trigger function
    console.log('\n⚙️  Creating trigger for updated_at...\n');
    
    await pool.query(`
      CREATE OR REPLACE FUNCTION update_commission_timestamp()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
    
    await pool.query(`
      DROP TRIGGER IF EXISTS update_commission_instance_timestamp ON commission_instance;
    `);
    
    await pool.query(`
      CREATE TRIGGER update_commission_instance_timestamp
      BEFORE UPDATE ON commission_instance
      FOR EACH ROW
      EXECUTE FUNCTION update_commission_timestamp();
    `);
    
    console.log('✅ Trigger created\n');
    
    console.log('✅ Table commission_instance créée avec succès!\n');
    
    // Verify the table structure
    console.log('🔍 Vérification de la structure de la table:\n');
    
    const structureResult = await pool.query(`
      SELECT 
        column_name, 
        data_type, 
        character_maximum_length,
        numeric_precision,
        numeric_scale,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_name = 'commission_instance'
      ORDER BY ordinal_position;
    `);
    
    console.log('Colonnes:');
    structureResult.rows.forEach(col => {
      const type = col.character_maximum_length 
        ? `${col.data_type}(${col.character_maximum_length})`
        : col.numeric_precision 
        ? `${col.data_type}(${col.numeric_precision},${col.numeric_scale})`
        : col.data_type;
      console.log(`  - ${col.column_name}: ${type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'}`);
    });
    
    // Verify foreign keys
    console.log('\n🔗 Vérification des clés étrangères:\n');
    
    const fkResult = await pool.query(`
      SELECT
        tc.constraint_name, 
        kcu.column_name, 
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.update_rule,
        rc.delete_rule
      FROM information_schema.table_constraints AS tc 
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
      JOIN information_schema.referential_constraints AS rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'commission_instance';
    `);
    
    if (fkResult.rows.length > 0) {
      console.log('Clés étrangères configurées:');
      fkResult.rows.forEach(fk => {
        console.log(`  - ${fk.constraint_name}:`);
        console.log(`    ${fk.column_name} → ${fk.foreign_table_name}.${fk.foreign_column_name}`);
        console.log(`    ON DELETE ${fk.delete_rule}, ON UPDATE ${fk.update_rule}`);
      });
    } else {
      console.log('⚠️  Aucune clé étrangère trouvée');
    }
    
    // Verify indexes
    console.log('\n📊 Vérification des index:\n');
    
    const indexResult = await pool.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'commission_instance'
      ORDER BY indexname;
    `);
    
    if (indexResult.rows.length > 0) {
      console.log('Index créés:');
      indexResult.rows.forEach(idx => {
        console.log(`  - ${idx.indexname}`);
      });
    }
    
    console.log('\n✅ Migration terminée avec succès!\n');
    
  } catch (error) {
    console.error('❌ Erreur lors de la migration:', error.message);
    console.error(error.stack);
  } finally {
    await pool.end();
  }
}

runMigration();
