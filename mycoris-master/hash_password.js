/**
 * Script pour générer un mot de passe hashé avec bcrypt
 * Utilisation: node hash_password.js
 */

const bcrypt = require('bcrypt');

async function hashPassword() {
    // Mot de passe à hasher
    const password = 'Admin@2024';  // Changez ce mot de passe selon vos besoins
    
    console.log('\n========================================');
    console.log('  Générateur de Mot de Passe Hashé');
    console.log('========================================\n');
    
    console.log('Mot de passe en clair:', password);
    console.log('Hashage en cours...\n');
    
    try {
        // Générer le hash avec bcrypt (saltRounds = 10)
        const hash = await bcrypt.hash(password, 10);
        
        console.log('✅ Hash généré avec succès !\n');
        console.log('Mot de passe hashé:');
        console.log(hash);
        console.log('\n========================================\n');
        console.log('Utilisez ce hash dans votre requête SQL :');
        console.log('\nINSERT INTO users (');
        console.log('    nom, prenom, email, motdepasse,');
        console.log('    telephone, role, statut');
        console.log(') VALUES (');
        console.log('    \'Admin\', \'CORIS\', \'admin@coris.ci\',');
        console.log(`    '${hash}',`);
        console.log('    \'0700000000\', \'admin\', \'actif\'');
        console.log(');\n');
        console.log('========================================\n');
        
    } catch (error) {
        console.error('❌ Erreur lors du hashage:', error.message);
    }
}

// Exécuter la fonction
hashPassword();
