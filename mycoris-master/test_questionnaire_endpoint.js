const pool = require('./db');

async function testEndpoint() {
  try {
    console.log('🧪 Test de la requête SQL...');
    
    const result = await pool.query(
      `SELECT 
        id,
        code,
        libelle,
        type_question,
        ordre,
        champ_detail_1_label,
        champ_detail_2_label,
        champ_detail_3_label,
        obligatoire
      FROM questionnaire_medical
      WHERE actif = TRUE
      ORDER BY ordre ASC`
    );

    console.log(`✅ ${result.rows.length} questions récupérées`);
    
    const questions = result.rows.map(q => ({
      id: q.id,
      code: q.code,
      question: q.libelle,
      type: q.type_question,
      ordre: q.ordre,
      detail1Label: q.champ_detail_1_label,
      detail2Label: q.champ_detail_2_label,
      detail3Label: q.champ_detail_3_label,
      obligatoire: q.obligatoire
    }));

    console.log('\n📋 Première question:');
    console.log(JSON.stringify(questions[0], null, 2));
    
    pool.end();
    
  } catch (error) {
    console.error('❌ Erreur:', error);
    pool.end();
    process.exit(1);
  }
}

testEndpoint();
