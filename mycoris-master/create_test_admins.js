/**
 * Script: Création d'administrateurs de test
 * Crée 3 administrateurs avec différents types d'accès
 * 
 * Comptes créés :
 * 1. super_admin@coris.ci - Super Administrateur (accès complet)
 * 2. admin@coris.ci - Administrateur Standard (accès standard)
 * 3. moderation@coris.ci - Modérateur (accès limité)
 */

const bcrypt = require('bcrypt');
const pool = require('./db');

const testAdmins = [
  {
    email: 'super_admin@coris.ci',
    password: 'SuperAdmin@2024',
    nom: 'Super',
    prenom: 'Admin',
    telephone: '0700000001',
    role: 'super_admin'
  },
  {
    email: 'admin@coris.ci',
    password: 'Admin@2024',
    nom: 'Admin',
    prenom: 'Standard',
    telephone: '0700000002',
    role: 'admin'
  },
  {
    email: 'moderation@coris.ci',
    password: 'Moderation@2024',
    nom: 'Modération',
    prenom: 'Admin',
    telephone: '0700000003',
    role: 'moderation'
  }
];

async function createTestAdmins() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Création des administrateurs de test...\n');

    for (const admin of testAdmins) {
      try {
        // Vérifier si l'admin existe déjà
        const existingResult = await client.query(
          'SELECT id FROM users WHERE email = $1',
          [admin.email]
        );

        if (existingResult.rows.length > 0) {
          console.log(`⏭️  Admin ${admin.email} existe déjà, mise à jour...`);
          // Mettre à jour l'admin existant
          const hashedPassword = await bcrypt.hash(admin.password, 10);
          await client.query(`
            UPDATE users 
            SET role = $1, password_hash = $2, nom = $3, prenom = $4
            WHERE email = $5
          `, [admin.role, hashedPassword, admin.nom, admin.prenom, admin.email]);
        } else {
          console.log(`➕ Création de ${admin.email}...`);
          const hashedPassword = await bcrypt.hash(admin.password, 10);
          
          await client.query(`
            INSERT INTO users 
              (email, password_hash, nom, prenom, telephone, role, created_at)
            VALUES 
              ($1, $2, $3, $4, $5, $6, NOW())
          `, [
            admin.email,
            hashedPassword,
            admin.nom,
            admin.prenom,
            admin.telephone,
            admin.role
          ]);
        }
        
        console.log(`✅ ${admin.email} (${admin.role})`);
      } catch (error) {
        console.error(`❌ Erreur pour ${admin.email}:`, error.message);
      }
    }

    console.log('\n📊 Administrateurs dans le système:');
    const result = await client.query(`
      SELECT id, email, nom, prenom, role
      FROM users 
      WHERE role IN ('super_admin', 'admin', 'moderation')
      ORDER BY created_at DESC
    `);
    
    result.rows.forEach(admin => {
      console.log(`\n  📧 Email: ${admin.email}`);
      console.log(`  👤 Nom: ${admin.prenom} ${admin.nom}`);
      console.log(`  🔑 Rôle: ${admin.role}`);
    });

    console.log('\n' + '='.repeat(60));
    console.log('🎫 IDENTIFIANTS DE TEST');
    console.log('='.repeat(60));
    
    testAdmins.forEach(admin => {
      console.log(`\n${admin.role.toUpperCase()}`);
      console.log(`Email: ${admin.email}`);
      console.log(`Mot de passe: ${admin.password}`);
    });
    
    console.log('\n' + '='.repeat(60));
    console.log('✅ Administrateurs de test créés avec succès!');
    console.log('='.repeat(60));
    
  } catch (error) {
    console.error('❌ Erreur lors de la création des admins:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

createTestAdmins().catch(console.error);
