const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});

async function checkQuestionnaire() {
  try {
    console.log('🔍 Vérification de la table questionnaire_medical...');
    
    // Vérifier si la table existe
    const tableExists = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'questionnaire_medical'
      )
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('❌ La table questionnaire_medical n\'existe pas!');
      console.log('💡 Exécutez la migration: migrations/add_questionnaire_medical_v2.sql');
      pool.end();
      return;
    }
    
    console.log('✅ La table questionnaire_medical existe');
    
    // Compter les questions
    const count = await pool.query('SELECT COUNT(*) FROM questionnaire_medical');
    console.log(`📊 Nombre de questions: ${count.rows[0].count}`);
    
    // Lister les questions
    const questions = await pool.query(`
      SELECT id, code, libelle, type_question, ordre, actif 
      FROM questionnaire_medical 
      ORDER BY ordre
    `);
    
    console.log('\n📋 Liste des questions:');
    questions.rows.forEach(q => {
      console.log(`  ${q.code} [${q.type_question}] ${q.actif ? '✓' : '✗'}: ${q.libelle.substring(0, 60)}...`);
    });
    
    pool.end();
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    pool.end();
  }
}

checkQuestionnaire();
