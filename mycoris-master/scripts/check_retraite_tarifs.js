const pool = require('../db');

async function main() {
  const { rows: prodRows } = await pool.query(
    "SELECT id FROM produit WHERE libelle = 'CORIS RETRAITE'"
  );
  if (prodRows.length === 0) {
    console.error('Produit CORIS RETRAITE not found');
    process.exit(1);
  }
  const produitId = prodRows[0].id;

  const res = await pool.query(
    `SELECT duree_contrat, periodicite, prime, capital, age
     FROM tarif_produit
     WHERE produit_id = $1
     ORDER BY duree_contrat, periodicite
     LIMIT 20`,
    [produitId]
  );

  console.table(res.rows);
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
