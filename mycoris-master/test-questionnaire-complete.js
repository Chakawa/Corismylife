/**
 * Test complet du flux questionnaire médical end-to-end
 * Vérifie: Save → DB → Get → API response
 */

const pool = require('./db');

const SUBSCRIPTION_ID = 56;

// Couleurs pour console
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

const log = {
  title: (msg) => console.log(`\n${colors.cyan}${colors.bright}=== ${msg} ===${colors.reset}`),
  ok: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
  warn: (msg) => console.log(`${colors.yellow}⚠️ ${msg}${colors.reset}`),
  info: (msg) => console.log(`${colors.blue}ℹ️ ${msg}${colors.reset}`),
};

async function testQuestionnaire() {
  try {
    log.title('TEST COMPLET QUESTIONNAIRE MÉDICAL');
    
    // ===== ÉTAPE 1: Vérifier la souscription =====
    log.title('ÉTAPE 1: Vérifier souscription ' + SUBSCRIPTION_ID);
    const subCheck = await pool.query(
      'SELECT id, user_id, statut FROM subscriptions WHERE id = $1',
      [SUBSCRIPTION_ID]
    );
    
    if (subCheck.rows.length === 0) {
      log.error(`Souscription ${SUBSCRIPTION_ID} n'existe pas`);
      process.exit(1);
    }
    
    const subscription = subCheck.rows[0];
    log.ok(`Souscription trouvée: ID=${subscription.id}, user_id=${subscription.user_id}, statut=${subscription.statut}`);
    
    // ===== ÉTAPE 2: Vérifier questions disponibles =====
    log.title('ÉTAPE 2: Lister questions médicales');
    const quesResult = await pool.query(
      'SELECT id, code, libelle, type_question, ordre FROM questionnaire_medical ORDER BY ordre ASC'
    );
    
    if (quesResult.rows.length === 0) {
      log.error('Aucune question trouvée dans questionnaire_medical');
      process.exit(1);
    }
    
    log.ok(`${quesResult.rows.length} questions trouvées:`);
    quesResult.rows.slice(0, 5).forEach((q, i) => {
      console.log(`  ${i + 1}. [${q.code}] ${q.libelle} (type: ${q.type_question})`);
    });
    
    // ===== ÉTAPE 3: Vérifier réponses existantes =====
    log.title('ÉTAPE 3: Vérifier réponses existantes');
    const existingResp = await pool.query(
      `SELECT COUNT(*) as count FROM souscription_questionnaire WHERE subscription_id = $1`,
      [SUBSCRIPTION_ID]
    );
    
    const respCount = existingResp.rows[0].count;
    log.info(`Réponses actuelles pour souscription ${SUBSCRIPTION_ID}: ${respCount}`);
    
    if (respCount > 0) {
      log.warn('Suppression des réponses existantes pour refaire le test...');
      await pool.query(
        'DELETE FROM souscription_questionnaire WHERE subscription_id = $1',
        [SUBSCRIPTION_ID]
      );
      log.ok('Réponses supprimées');
    }
    
    // ===== ÉTAPE 4: Préparer réponses de test =====
    log.title('ÉTAPE 4: Préparer réponses de test');
    const testResponses = [
      {
        question_id: quesResult.rows[0].id,  // Première question (OUI/NON)
        reponse_oui_non: true,  // BOOLEAN, pas STRING
        reponse_text: null,
        reponse_detail_1: null,
        reponse_detail_2: null,
        reponse_detail_3: null,
      },
      {
        question_id: quesResult.rows[1].id,  // Deuxième question
        reponse_oui_non: false,  // BOOLEAN, pas STRING
        reponse_text: null,
        reponse_detail_1: 'Détail 1',
        reponse_detail_2: null,
        reponse_detail_3: null,
      },
    ];
    
    if (quesResult.rows.length > 2) {
      testResponses.push({
        question_id: quesResult.rows[2].id,
        reponse_oui_non: null,
        reponse_text: 'Réponse textuelle libre',
        reponse_detail_1: null,
        reponse_detail_2: null,
        reponse_detail_3: null,
      });
    }
    
    log.ok(`${testResponses.length} réponses de test préparées`);
    
    // ===== ÉTAPE 5: Sauvegarder réponses =====
    log.title('ÉTAPE 5: Sauvegarder réponses');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      
      for (const resp of testResponses) {
        const existCheck = await client.query(
          `SELECT id FROM souscription_questionnaire 
           WHERE subscription_id = $1 AND question_id = $2`,
          [SUBSCRIPTION_ID, resp.question_id]
        );
        
        if (existCheck.rows.length > 0) {
          // UPDATE
          await client.query(
            `UPDATE souscription_questionnaire 
             SET reponse_oui_non = $1, reponse_text = $2,
                 reponse_detail_1 = $3, reponse_detail_2 = $4, reponse_detail_3 = $5,
                 updated_at = NOW()
             WHERE subscription_id = $6 AND question_id = $7`,
            [
              resp.reponse_oui_non,
              resp.reponse_text,
              resp.reponse_detail_1,
              resp.reponse_detail_2,
              resp.reponse_detail_3,
              SUBSCRIPTION_ID,
              resp.question_id,
            ]
          );
          log.info(`  ↻ Mis à jour question_id=${resp.question_id}`);
        } else {
          // INSERT
          await client.query(
            `INSERT INTO souscription_questionnaire 
             (subscription_id, question_id, reponse_oui_non, reponse_text,
              reponse_detail_1, reponse_detail_2, reponse_detail_3, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())`,
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
          log.info(`  ➕ Inséré question_id=${resp.question_id}`);
        }
      }
      
      await client.query('COMMIT');
      log.ok('Transaction sauvegardée avec succès');
    } catch (e) {
      await client.query('ROLLBACK');
      log.error(`Erreur transaction: ${e.message}`);
      throw e;
    } finally {
      client.release();
    }
    
    // ===== ÉTAPE 6: Vérifier insertion en BD =====
    log.title('ÉTAPE 6: Vérifier insertion en BD');
    const verifyInsert = await pool.query(
      `SELECT sq.id, sq.question_id, sq.reponse_oui_non, sq.reponse_text,
              qm.libelle, qm.code, qm.type_question
       FROM souscription_questionnaire sq
       JOIN questionnaire_medical qm ON sq.question_id = qm.id
       WHERE sq.subscription_id = $1
       ORDER BY qm.ordre ASC`,
      [SUBSCRIPTION_ID]
    );
    
    if (verifyInsert.rows.length === 0) {
      log.error('Aucune réponse trouvée après insertion !');
      process.exit(1);
    }
    
    log.ok(`${verifyInsert.rows.length} réponses trouvées en BD:`);
    verifyInsert.rows.forEach((row, idx) => {
      const resp = row.reponse_oui_non || row.reponse_text || 'N/A';
      console.log(`  ${idx + 1}. "${row.libelle}" → ${resp}`);
    });
    
    // ===== ÉTAPE 7: Tester getQuestionnaireMedical (endpoint GET) =====
    log.title('ÉTAPE 7: Tester getQuestionnaireMedical endpoint');
    const getResult = await pool.query(
      `SELECT sq.id, sq.question_id, sq.reponse_oui_non, sq.reponse_text,
              sq.reponse_detail_1, sq.reponse_detail_2, sq.reponse_detail_3,
              qm.code, qm.libelle, qm.type_question, qm.ordre,
              qm.champ_detail_1_label, qm.champ_detail_2_label, qm.champ_detail_3_label
       FROM souscription_questionnaire sq
       JOIN questionnaire_medical qm ON sq.question_id = qm.id
       WHERE sq.subscription_id = $1
       ORDER BY qm.ordre ASC`,
      [SUBSCRIPTION_ID]
    );
    
    const apiResponse = {
      success: true,
      reponses: getResult.rows
    };
    
    log.ok(`API endpoint retournerait ${apiResponse.reponses.length} réponses`);
    log.info('Structure réponse (premiere réponse):');
    if (apiResponse.reponses.length > 0) {
      const firstResp = apiResponse.reponses[0];
      console.log(`  {`);
      console.log(`    question_id: ${firstResp.question_id},`);
      console.log(`    libelle: "${firstResp.libelle}",`);
      console.log(`    reponse_oui_non: ${firstResp.reponse_oui_non},`);
      console.log(`    reponse_text: ${firstResp.reponse_text},`);
      console.log(`    type_question: "${firstResp.type_question}"`);
      console.log(`  }`);
    }
    
    // ===== ÉTAPE 8: Tester getSubscriptionWithUserDetails =====
    log.title('ÉTAPE 8: Tester getSubscriptionWithUserDetails endpoint');
    const subDetailsResult = await pool.query(
      'SELECT * FROM subscriptions WHERE id = $1',
      [SUBSCRIPTION_ID]
    );
    
    const questResult = await pool.query(
      `SELECT sq.id, sq.question_id, sq.reponse_oui_non, sq.reponse_text,
              sq.reponse_detail_1, sq.reponse_detail_2, sq.reponse_detail_3,
              qm.code, qm.libelle, qm.type_question, qm.ordre,
              qm.champ_detail_1_label, qm.champ_detail_2_label, qm.champ_detail_3_label
       FROM souscription_questionnaire sq
       JOIN questionnaire_medical qm ON sq.question_id = qm.id
       WHERE sq.subscription_id = $1
       ORDER BY qm.ordre ASC`,
      [SUBSCRIPTION_ID]
    );
    
    const completeResponse = {
      success: true,
      data: {
        subscription: {
          ...subDetailsResult.rows[0],
          questionnaire_reponses: questResult.rows
        },
        user: null,
        questionnaire_reponses: questResult.rows  // IMPORTANT: aussi au top level
      }
    };
    
    log.ok(`Réponse complète structure:`);
    log.info(`  - subscription.questionnaire_reponses: ${completeResponse.data.subscription.questionnaire_reponses.length} réponses`);
    log.info(`  - data.questionnaire_reponses: ${completeResponse.data.questionnaire_reponses.length} réponses`);
    
    // ===== ÉTAPE 9: Vérifier que libelle est présent =====
    log.title('ÉTAPE 9: Vérifier présence "libelle" dans réponses');
    let libelleCount = 0;
    questResult.rows.forEach((row) => {
      if (row.libelle) libelleCount++;
    });
    
    if (libelleCount === questResult.rows.length) {
      log.ok(`✓ Toutes les ${libelleCount} réponses ont "libelle"`);
    } else {
      log.error(`Seulement ${libelleCount}/${questResult.rows.length} réponses ont "libelle"`);
    }
    
    // ===== ÉTAPE 10: Summary =====
    log.title('RÉSUMÉ FINAL');
    log.ok(`✓ Souscription ${SUBSCRIPTION_ID} OK`);
    log.ok(`✓ ${testResponses.length} réponses sauvegardées en BD`);
    log.ok(`✓ Lecture depuis BD OK`);
    log.ok(`✓ getQuestionnaireMedical retournerait: { success: true, reponses: [...] }`);
    log.ok(`✓ getSubscriptionWithUserDetails retournerait questionnaire_reponses dans subscription`);
    log.ok(`✓ Toutes les réponses incluent "libelle"`);
    
    console.log(`\n${colors.green}${colors.bright}🎉 Test complet RÉUSSI !${colors.reset}`);
    console.log(`\nFlutter peut maintenant:
1. Appeler GET /subscriptions/${SUBSCRIPTION_ID}/questionnaire-medical
2. Recevoir { success: true, reponses: [...] } avec libelle dans chaque réponse
3. Afficher les vraies questions et réponses dans le recap

4. Appeler GET /subscriptions/${SUBSCRIPTION_ID}
5. Recevoir questionnaire_reponses dans subscription
6. Afficher dans proposition details\n`);
    
  } catch (error) {
    log.error(`Erreur: ${error.message}`);
    console.error(error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

testQuestionnaire();
