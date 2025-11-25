/**
 * ===============================================
 * MIGRATION: Création de la table contrats
 * ===============================================
 * 
 * Cette table stocke tous les contrats d'assurance
 * avec les informations complètes des clients et produits
 */

const pool = require('../db');

async function createContratsTable() {
  try {
    console.log('=== CRÉATION TABLE CONTRATS ===\n');
    
    // Créer la table contrats
    await pool.query(`
      CREATE TABLE IF NOT EXISTS contrats (
        id SERIAL PRIMARY KEY,
        codeprod VARCHAR(50),
        codeinte VARCHAR(50),
        codeappo VARCHAR(50),
        numepoli VARCHAR(100) UNIQUE,
        duree INTEGER,
        dateeffet DATE,
        dateeche DATE,
        periodicite VARCHAR(50),
        domiciliation VARCHAR(200),
        capital DECIMAL(15, 2),
        rente DECIMAL(15, 2),
        prime DECIMAL(15, 2),
        montant_encaisse DECIMAL(15, 2),
        impaye DECIMAL(15, 2),
        etat VARCHAR(50),
        telephone1 VARCHAR(20),
        telephone2 VARCHAR(20),
        nom_prenom VARCHAR(200),
        datenaissance DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    console.log('✅ Table "contrats" créée avec succès\n');
    
    // Créer les index pour améliorer les performances
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_contrats_telephone1 ON contrats(telephone1);
    `);
    console.log('✅ Index sur telephone1 créé');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_contrats_telephone2 ON contrats(telephone2);
    `);
    console.log('✅ Index sur telephone2 créé');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_contrats_codeappo ON contrats(codeappo);
    `);
    console.log('✅ Index sur codeappo créé');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_contrats_numepoli ON contrats(numepoli);
    `);
    console.log('✅ Index sur numepoli créé');
    
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_contrats_dateeffet ON contrats(dateeffet);
    `);
    console.log('✅ Index sur dateeffet créé\n');
    
    // Ajouter un trigger pour mettre à jour updated_at
    await pool.query(`
      CREATE OR REPLACE FUNCTION update_contrats_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
    
    await pool.query(`
      DROP TRIGGER IF EXISTS trigger_update_contrats_updated_at ON contrats;
    `);
    
    await pool.query(`
      CREATE TRIGGER trigger_update_contrats_updated_at
      BEFORE UPDATE ON contrats
      FOR EACH ROW
      EXECUTE FUNCTION update_contrats_updated_at();
    `);
    
    console.log('✅ Trigger de mise à jour automatique créé\n');
    
    console.log('🎉 Migration terminée avec succès !');
    
  } catch (error) {
    console.error('❌ Erreur lors de la création de la table:', error.message);
    console.error(error.stack);
  } finally {
    pool.end();
    process.exit(0);
  }
}

createContratsTable();
