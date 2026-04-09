require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const pool = require('../db');
const fs = require('fs');
const path = require('path');

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ================================================================
    // ÉTAPE 1 : Créer la table kyc_documents
    // ================================================================
    console.log('\n[1/3] Création de la table kyc_documents...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS kyc_documents (
        id            SERIAL PRIMARY KEY,
        user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        doc_key       VARCHAR(100) NOT NULL,
        url           TEXT NOT NULL,
        label         TEXT,
        created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON kyc_documents(user_id);
      CREATE INDEX IF NOT EXISTS idx_kyc_documents_doc_key ON kyc_documents(user_id, doc_key);
    `);
    console.log('  ✅ Table kyc_documents créée');

    // ================================================================
    // ÉTAPE 2 : Migrer les piece_identite (nom de fichier brut) vers
    //           piece_identite_documents (tableau JSON structuré) +
    //           piece_identite_url (chemin complet)
    // ================================================================
    console.log('\n[2/3] Migration des données piece_identite existantes...');
    const subsRes = await client.query(`
      SELECT id, user_id, souscriptiondata
      FROM subscriptions
      WHERE souscriptiondata ? 'piece_identite'
        AND souscriptiondata->>'piece_identite' IS NOT NULL
        AND souscriptiondata->>'piece_identite' != ''
        AND (
          NOT (souscriptiondata ? 'piece_identite_documents')
          OR souscriptiondata->'piece_identite_documents' = '[]'::jsonb
          OR souscriptiondata->'piece_identite_documents' IS NULL
        )
    `);
    console.log(`  → ${subsRes.rowCount} souscription(s) à migrer`);

    let migrated = 0;
    for (const row of subsRes.rows) {
      const data = row.souscriptiondata || {};
      const fname = data.piece_identite;
      if (!fname || typeof fname !== 'string') continue;

      // Trouver le fichier physique
      const candidates = [
        require('path').join(__dirname, '../uploads', 'identity-cards', fname),
        require('path').join(__dirname, '../uploads', fname),
      ];
      let foundPath = null;
      for (const c of candidates) {
        if (fs.existsSync(c)) { foundPath = c; break; }
      }

      // Construire l'URL relative
      const ext = path.extname(fname) || '';
      let documentUrl;
      if (foundPath && foundPath.includes('identity-cards')) {
        documentUrl = `/uploads/identity-cards/${fname}`;
      } else if (foundPath) {
        documentUrl = `/uploads/${fname}`;
      } else {
        // Fichier absent localement (probablement sur serveur prod) – on garde quand même la trace
        documentUrl = `/uploads/identity-cards/${fname}`;
        console.log(`  ⚠️  Sub ${row.id}: fichier ${fname} introuvable localement (prod?)`);
      }

      const newDocument = {
        filename: fname,
        url: documentUrl,
        label: fname,
        uploaded_at: new Date().toISOString()
      };

      // Mettre à jour souscriptiondata
      await client.query(`
        UPDATE subscriptions
        SET souscriptiondata = souscriptiondata
          || jsonb_build_object('piece_identite_url', $1::text)
          || jsonb_build_object('piece_identite_documents', jsonb_build_array($2::jsonb)),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $3
      `, [documentUrl, JSON.stringify(newDocument), row.id]);

      // Insérer aussi dans kyc_documents (si user_id connu)
      if (row.user_id) {
        await client.query(`
          INSERT INTO kyc_documents (user_id, doc_key, url, label)
          VALUES ($1, 'piece_identite', $2, $3)
          ON CONFLICT DO NOTHING
        `, [row.user_id, documentUrl, fname]);
      }

      migrated++;
      console.log(`  ✅ Sub ${row.id} migré: ${fname} → ${documentUrl}`);
    }
    console.log(`  → ${migrated} souscription(s) migrée(s)`);

    // ================================================================
    // ÉTAPE 3 : Vérification finale
    // ================================================================
    console.log('\n[3/3] Vérification finale...');
    const check = await client.query(`
      SELECT COUNT(*) as total,
             SUM(CASE WHEN souscriptiondata ? 'piece_identite_documents' THEN 1 ELSE 0 END) as avec_docs,
             SUM(CASE WHEN souscriptiondata ? 'piece_identite_url' THEN 1 ELSE 0 END) as avec_url
      FROM subscriptions
    `);
    const { total, avec_docs, avec_url } = check.rows[0];
    console.log(`  Souscriptions totales    : ${total}`);
    console.log(`  Avec piece_identite_docs : ${avec_docs}`);
    console.log(`  Avec piece_identite_url  : ${avec_url}`);

    const kycCount = await client.query('SELECT COUNT(*) as c FROM kyc_documents');
    console.log(`  Entrées kyc_documents    : ${kycCount.rows[0].c}`);

    await client.query('COMMIT');
    console.log('\n✅ Migration terminée avec succès !');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('\n❌ ERREUR – rollback effectué:', err.message);
    throw err;
  } finally {
    client.release();
    pool.end();
  }
}

migrate().catch(() => process.exit(1));
