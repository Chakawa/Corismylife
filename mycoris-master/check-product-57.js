const pool = require('./db');

async function checkProduct() {
  try {
    const res = await pool.query(
      'SELECT id, produit_nom FROM subscriptions WHERE id = $1',
      [57]
    );
    if (res.rows.length > 0) {
      console.log('Souscription 57:');
      console.log(JSON.stringify(res.rows[0], null, 2));
    } else {
      console.log('Souscription 57 non trouvée');
    }
  } catch (e) {
    console.error('Erreur:', e);
  } finally {
    await pool.end();
  }
}

checkProduct();
