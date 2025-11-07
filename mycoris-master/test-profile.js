const pool = require('./db');
const jwt = require('jsonwebtoken');
require('dotenv').config();

async function testProfile() {
  try {
    console.log('🔍 Test de la base de données...');
    
    // 1. Vérifier la connexion
    const connTest = await pool.query('SELECT NOW()');
    console.log('✅ Connexion DB OK');
    
    // 2. Vérifier la structure de la table users
    const structure = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);
    console.log('📋 Structure table users:');
    structure.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type}`);
    });
    
    // 3. Vérifier qu'il y a des utilisateurs
    const users = await pool.query('SELECT id, email, nom, prenom FROM users LIMIT 3');
    console.log(`👥 Nombre d'utilisateurs: ${users.rows.length}`);
    
    if (users.rows.length > 0) {
      console.log('Premiers utilisateurs:');
      users.rows.forEach(user => {
        console.log(`  - ID ${user.id}: ${user.email} (${user.nom} ${user.prenom})`);
      });
      
      // 4. Test de création/vérification du token
      const testUser = users.rows[0];
      const token = jwt.sign(
        { id: testUser.id, email: testUser.email, role: 'client' },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
      );
      
      console.log('🎫 Token de test généré pour ID', testUser.id);
      console.log('Token (début):', token.substring(0, 50) + '...');
      
      // 5. Test de la requête profile
      const profileQuery = `
        SELECT 
          id, email, 
          COALESCE(nom, '') as nom, 
          COALESCE(prenom, '') as prenom,
          COALESCE(civilite, '') as civilite,
          date_naissance, 
          COALESCE(lieu_naissance, '') as lieu_naissance,
          COALESCE(telephone, '') as telephone,
          COALESCE(adresse, '') as adresse,
          COALESCE(pays, '') as pays,
          created_at
        FROM users 
        WHERE id = $1
      `;
      
      const profileResult = await pool.query(profileQuery, [testUser.id]);
      console.log('✅ Test requête profile OK');
      console.log('Données récupérées:', profileResult.rows[0]);
      
    } else {
      console.log('⚠️ Aucun utilisateur trouvé - créez un compte d\'abord');
    }
    
  } catch (error) {
    console.error('❌ Erreur test:', error);
  }
  
  pool.end();
}

testProfile();