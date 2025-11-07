const pool = require('../config/db');

(async () => {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log('✅ Test réussi:', res.rows[0]);
    pool.end(); // Fermer le pool
  } catch (err) {
    console.error('❌ Échec:', err);
  }
})();