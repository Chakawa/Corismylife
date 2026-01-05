const db = require('./db');

async function runMigration() {
  try {
    // Migration 1: Vider la table
    console.log('🗑️ Vidage de la table...');
    await db.query('TRUNCATE TABLE commission_instance');
    console.log('✅ Table vidée');

    // Migration 2: Supprimer les colonnes non nécessaires
    console.log('🔄 Suppression des colonnes non nécessaires...');
    
    const columnsToDelete = [
      'numepoli',
      'montant_encaisse_reference',
      'numero_police',
      'statut_reception',
      'date_reception',
      'notes',
      'comments'
    ];

    for (const col of columnsToDelete) {
      try {
        const sql = `ALTER TABLE commission_instance DROP COLUMN IF EXISTS ${col} CASCADE`;
        await db.query(sql);
        console.log(`  ✅ Colonne ${col} supprimée`);
      } catch (e) {
        console.log(`  ⚠️ Colonne ${col} n'existe pas ou erreur`);
      }
    }

    // Migration 3: Vérifier la structure finale
    console.log('📊 Vérification de la structure finale...');
    const result = await db.query('SELECT * FROM commission_instance LIMIT 1');
    const columns = result.fields.map(f => f.name);
    console.log('✅ Colonnes finales:', columns);

    // Migration 4: Ajouter les index
    console.log('📑 Création des index...');
    await db.query(`CREATE INDEX IF NOT EXISTS idx_commission_instance_code_apporteur 
      ON commission_instance(code_apporteur)`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_commission_instance_date_calcul 
      ON commission_instance(date_calcul DESC)`);
    console.log('✅ Index créés');

    console.log('\n✅✅✅ MIGRATION RÉUSSIE ✅✅✅');
  } catch (error) {
    console.error('❌ Erreur migration:', error.message);
  } finally {
    process.exit(0);
  }
}

runMigration();
