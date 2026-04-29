// Importation de la bibliothèque pg

const { Pool, types } = require('pg');
require('dotenv').config();

// Fix timezone: forcer pg à retourner les colonnes 'date' (OID 1082) comme
// chaîne 'YYYY-MM-DD' au lieu d'un objet Date JS local.
// Sans ce fix, '2025-03-01' devient new Date('2025-03-01T00:00:00') en heure
// locale (Paris UTC+1) = 2025-02-28T23:00:00Z, et getUTCDate() retourne 28.
types.setTypeParser(1082, val => val); // date → string 'YYYY-MM-DD'

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
