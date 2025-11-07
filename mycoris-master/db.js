// Importation de la bibliothèque pg

const { Pool } = require('pg');
require('dotenv').config();

// Création de la connexion au pool PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // URL complète depuis .env
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Événement déclenché lors de la connexion
pool.on('connect', () => {
  console.log('✅ Connexion PostgreSQL établie avec succès');
});

// Gestion des erreurs globales du pool

pool.on('error', (err) => {
  console.error('❌ Erreur PostgreSQL :', err);
  process.exit(-1);
});

// Test immédiat de connexion
(async () => {
  try {
    const res = await pool.query('SELECT NOW() AS date');
    console.log('📅 Test DB - Date serveur PostgreSQL :', res.rows[0].date);
  } catch (err) {
    console.error('❌ Échec du test de connexion PostgreSQL :', err.message);
  }
})();

// Exportation du pool pour utilisation dans tout le projet
module.exports = pool;
