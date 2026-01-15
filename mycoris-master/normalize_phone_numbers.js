/**
 * Script de normalisation des numéros de téléphone
 * Ajoute +225 aux numéros qui n'ont pas d'indicatif
 */

const pool = require('./db');

async function normalizePhoneNumbers() {
  try {
    console.log('🔄 Début de la normalisation des numéros de téléphone...\n');

    // Récupérer tous les utilisateurs avec un numéro sans +225
    const result = await pool.query(`
      SELECT id, telephone, nom, prenom 
      FROM users 
      WHERE telephone IS NOT NULL 
        AND telephone != '' 
        AND telephone NOT LIKE '+%'
    `);

    console.log(`📊 ${result.rows.length} numéro(s) à normaliser\n`);

    if (result.rows.length === 0) {
      console.log('✅ Tous les numéros sont déjà normalisés!');
      process.exit(0);
    }

    // Normaliser chaque numéro
    for (const user of result.rows) {
      const oldPhone = user.telephone;
      const newPhone = '+225' + oldPhone;

      await pool.query(
        'UPDATE users SET telephone = $1 WHERE id = $2',
        [newPhone, user.id]
      );

      console.log(`✅ ${user.prenom} ${user.nom}: ${oldPhone} → ${newPhone}`);
    }

    console.log(`\n🎉 Normalisation terminée! ${result.rows.length} numéro(s) mis à jour.`);
    process.exit(0);

  } catch (error) {
    console.error('❌ Erreur lors de la normalisation:', error.message);
    console.error(error);
    process.exit(1);
  }
}

normalizePhoneNumbers();
