const fs = require('fs');
const path = require('path');
const pool = require('./db');

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('== Migration profession: demarrage ==');

    const sqlFile = path.join(__dirname, 'migrations', 'add_profession_to_users.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    await client.query('BEGIN');
    await client.query(sql);

    const verify = await client.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'profession'
    `);

    await client.query('COMMIT');

    if (verify.rowCount > 0) {
      console.log('OK: colonne profession presente dans users');
      console.table(verify.rows);
    } else {
      throw new Error('colonne profession non detectee apres migration');
    }

    console.log('== Migration profession: succes ==');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('ERREUR migration profession:', error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch((err) => {
  console.error('Echec migration profession:', err.message);
  process.exit(1);
});
