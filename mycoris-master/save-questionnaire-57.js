/**
 * Test - Sauvegarder questionnaire pour souscription 57
 * pour tester l'affichage en proposition details
 */

/**
 * Script pour sauvegarder le questionnaire de la souscription 57
 * avec des réponses réalistes et bien structurées
 */

const pool = require('./db');

const SUBSCRIPTION_ID = 57;

async function saveQuestionnaire57() {
  try {
    console.log('\n=== SAUVEGARDE QUESTIONNAIRE SOUSCRIPTION 57 ===\n');
    
    // Étape 1: Vérifier souscription
    const subCheck = await pool.query(
      'SELECT id, user_id FROM subscriptions WHERE id = $1',
      [SUBSCRIPTION_ID]
    );
    
    if (subCheck.rows.length === 0) {
      console.error(`❌ Souscription ${SUBSCRIPTION_ID} n'existe pas`);
      process.exit(1);
    }
    console.log(`✅ Souscription ${SUBSCRIPTION_ID} trouvée`);
    
    // Étape 2: Récupérer les questions
    const quesResult = await pool.query(
      'SELECT id, code, libelle FROM questionnaire_medical ORDER BY ordre ASC'
    );
    
    if (quesResult.rows.length === 0) {
      console.error('❌ Aucune question trouvée');
      process.exit(1);
    }
    console.log(`✅ ${quesResult.rows.length} questions récupérées`);
    
    // Étape 3: Préparer réponses variées
    const testResponses = [
      // Q1: Taille/Poids (type: taille_poids)
      {
        question_id: quesResult.rows[0].id,
        reponse_oui_non: null,
        reponse_text: '175 cm, 72 kg',
        reponse_detail_1: '175',
        reponse_detail_2: '72',
        reponse_detail_3: null,
      },
      // Q2: OUI/NON avec détails (type: oui_non_details)
      {
        question_id: quesResult.rows[1].id,
        reponse_oui_non: true,
        reponse_text: 'À quelles dates ?: 20/12/2025',
        reponse_detail_1: '2025-12-20T00:00:00.000',
        reponse_detail_2: 'GRIPPE',
        reponse_detail_3: null,
      },
      // Q3: OUI/NON avec détails
      {
        question_id: quesResult.rows[2].id,
        reponse_oui_non: true,
        reponse_text: 'Depuis quand ?: 10/12/2025',
        reponse_detail_1: 'Hypertension',
        reponse_detail_2: '2025-12-10T00:00:00.000',
        reponse_detail_3: null,
      },
      // Q4-Q10: NON
      ...quesResult.rows.slice(3).map(q => ({
        question_id: q.id,
        reponse_oui_non: false,
        reponse_text: null,
        reponse_detail_1: null,
        reponse_detail_2: null,
        reponse_detail_3: null,
      })),
    ];
    
    console.log(`✅ ${testResponses.length} réponses préparées\n`);
    
    // Étape 4: Sauvegarder les réponses
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      for (const resp of testResponses) {
        await client.query(
          `INSERT INTO souscription_questionnaire 
           (subscription_id, question_id, reponse_oui_non, reponse_text,
            reponse_detail_1, reponse_detail_2, reponse_detail_3, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
           ON CONFLICT (subscription_id, question_id) 
           DO UPDATE SET
             reponse_oui_non = $3, reponse_text = $4,
             reponse_detail_1 = $5, reponse_detail_2 = $6, reponse_detail_3 = $7,
             updated_at = NOW()`,
          [
            SUBSCRIPTION_ID,
            resp.question_id,
            resp.reponse_oui_non,
            resp.reponse_text,
            resp.reponse_detail_1,
            resp.reponse_detail_2,
            resp.reponse_detail_3,
          ]
        );
      }
      
      await client.query('COMMIT');
      console.log('✅ Transaction réussie\n');
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
    
    // Étape 5: Vérifier insertion
    const verify = await pool.query(
      `SELECT COUNT(*) as count FROM souscription_questionnaire WHERE subscription_id = $1`,
      [SUBSCRIPTION_ID]
    );
    
    console.log(`✅ Vérification: ${verify.rows[0].count} réponses en BD pour souscription ${SUBSCRIPTION_ID}`);
    
    // Étape 6: Afficher un aperçu
    const preview = await pool.query(
      `SELECT sq.question_id, sq.reponse_oui_non, sq.reponse_text,
              qm.libelle
       FROM souscription_questionnaire sq
       JOIN questionnaire_medical qm ON sq.question_id = qm.id
       WHERE sq.subscription_id = $1
       ORDER BY qm.ordre ASC
       LIMIT 5`,
      [SUBSCRIPTION_ID]
    );
    
    console.log('\nAperçu des réponses (5 premières):');
    preview.rows.forEach((row, idx) => {
      console.log(`  ${idx + 1}. "${row.libelle.substring(0, 50)}..." → ${row.reponse_oui_non ?? row.reponse_text}`);
    });
    
    console.log('\n🎉 Souscription 57 prête pour test!\n');
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

saveQuestionnaire57();
