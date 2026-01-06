/**
 * Script pour créer un compte administrateur
 * Utilisation: node create_admin_account.js
 */

const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

// Configuration de la connexion
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: false
});

async function createAdminAccount() {
    console.log('\n========================================');
    console.log('  Création du Compte Administrateur');
    console.log('========================================\n');
    
    const adminData = {
        nom: 'Admin',
        prenom: 'CORIS',
        email: 'admin@coris.ci',
        password: 'Admin@2024',  // Changez ce mot de passe si nécessaire
        telephone: '0700000000',
        role: 'admin',
        civilite: 'M',
        date_naissance: '1990-01-01',
        lieu_naissance: 'Abidjan',
        adresse: 'Plateau, Abidjan',
        pays: 'Côte d\'Ivoire'
    };
    
    try {
        console.log('📡 Connexion à la base de données...');
        
        // Vérifier si l'admin existe déjà
        const checkQuery = 'SELECT id, email FROM users WHERE email = $1';
        const checkResult = await pool.query(checkQuery, [adminData.email]);
        
        if (checkResult.rows.length > 0) {
            console.log(`\n⚠️  Un compte existe déjà avec l'email ${adminData.email}`);
            console.log('   Voulez-vous le mettre à jour ? (Oui/Non)');
            console.log('\n   Pour mettre à jour, exécutez:');
            console.log(`   UPDATE users SET role = 'admin' WHERE email = '${adminData.email}';`);
            console.log('\n   Ou supprimez-le d\'abord:');
            console.log(`   DELETE FROM users WHERE email = '${adminData.email}';`);
            console.log('   Puis relancez ce script.\n');
            await pool.end();
            return;
        }
        
        console.log('🔐 Hashage du mot de passe...');
        const hashedPassword = await bcrypt.hash(adminData.password, 10);
        
        console.log('💾 Insertion du compte admin...');
        const insertQuery = `
            INSERT INTO users (
                email, password_hash, role, nom, prenom, civilite,
                date_naissance, lieu_naissance, telephone, adresse, pays
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            RETURNING id, nom, prenom, email, role
        `;
        
        const result = await pool.query(insertQuery, [
            adminData.email,
            hashedPassword,
            adminData.role,
            adminData.nom,
            adminData.prenom,
            adminData.civilite,
            adminData.date_naissance,
            adminData.lieu_naissance,
            adminData.telephone,
            adminData.adresse,
            adminData.pays
        ]);
        
        console.log('\n✅ Compte administrateur créé avec succès !\n');
        console.log('========================================');
        console.log('  Informations de Connexion');
        console.log('========================================\n');
        console.log('Email:', adminData.email);
        console.log('Mot de passe:', adminData.password);
        console.log('Rôle:', result.rows[0].role);
        console.log('\n========================================');
        console.log('  Accès au Dashboard');
        console.log('========================================\n');
        console.log('URL: http://localhost:3000');
        console.log('\n⚠️  IMPORTANT: Changez ce mot de passe en production !\n');
        
        await pool.end();
        
    } catch (error) {
        console.error('\n❌ Erreur lors de la création du compte:', error.message);
        console.error('\nDétails:', error);
        await pool.end();
        process.exit(1);
    }
}

// Exécuter la fonction
createAdminAccount();
