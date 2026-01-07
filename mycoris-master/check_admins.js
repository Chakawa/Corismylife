const db = require('./db');

async function checkAdmins() {
  try {
    console.log('🔍 Administrateurs dans le système:\n');
    
    const result = await db.query(`
      SELECT id, email, nom, prenom, role, created_at
      FROM users 
      WHERE role IN ('super_admin', 'admin', 'moderation')
      ORDER BY created_at DESC
    `);
    
    if (result.rows.length === 0) {
      console.log('❌ Aucun administrateur trouvé!');
    } else {
      console.log(`✅ Trouvé ${result.rows.length} administrateur(s):\n`);
      result.rows.forEach((admin, index) => {
        console.log(`${index + 1}. ${admin.prenom} ${admin.nom}`);
        console.log(`   📧 Email: ${admin.email}`);
        console.log(`   🔑 Rôle: ${admin.role}`);
        console.log(`   📅 Créé: ${new Date(admin.created_at).toLocaleDateString('fr-FR')}`);
        console.log('');
      });
    }
    
    // Afficher aussi le compte utilisateur si on veut tester
    console.log('\n' + '='.repeat(60));
    console.log('🧪 COMPTES DE TEST À UTILISER');
    console.log('='.repeat(60));
    console.log('\nSuper Admin (accès complet):');
    console.log('  Email: super_admin@coris.ci');
    console.log('  Mot de passe: SuperAdmin@2024\n');
    
    console.log('Admin (accès standard):');
    console.log('  Email: admin@coris.ci');
    console.log('  Mot de passe: Admin@2024\n');
    
    console.log('Modération (accès limité):');
    console.log('  Email: moderation@coris.ci');
    console.log('  Mot de passe: Moderation@2024\n');
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await db.end();
  }
}

checkAdmins();
