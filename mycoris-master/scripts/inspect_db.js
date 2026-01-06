/*
  Introspection de la base PostgreSQL
  - Liste les tables du schéma public
  - Affiche les colonnes (nom, type, nullabilité)
  - Donne le nombre de lignes
  - Extrait 5 lignes d'exemple

  Utilisation:
    node scripts/inspect_db.js

  Prérequis:
    - .env doit contenir DATABASE_URL valide
*/

const pool = require('../db')

async function getTables(client) {
  const { rows } = await client.query(
    `SELECT table_name
     FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
     ORDER BY table_name;`
  )
  return rows.map(r => r.table_name)
}

async function getColumns(client, table) {
  const { rows } = await client.query(
    `SELECT column_name, data_type, is_nullable
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = $1
     ORDER BY ordinal_position;`,
    [table]
  )
  return rows
}

async function getCount(client, table) {
  const { rows } = await client.query(`SELECT COUNT(*)::bigint AS count FROM ${table};`)
  return Number(rows[0].count)
}

async function getSample(client, table) {
  const { rows } = await client.query(`SELECT * FROM ${table} LIMIT 5;`)
  return rows
}

async function main() {
  const client = await pool.connect()
  try {
    console.log('🔎 Inspection du schéma public...')
    const tables = await getTables(client)
    if (!tables.length) {
      console.log('Aucune table trouvée dans le schéma public.')
      return
    }

    for (const table of tables) {
      console.log(`\n===== 🗂️  TABLE: ${table} =====`)
      const [columns, count, sample] = await Promise.all([
        getColumns(client, table),
        getCount(client, table),
        getSample(client, table)
      ])
      console.log('Colonnes:')
      columns.forEach(c => {
        console.log(` - ${c.column_name} :: ${c.data_type} ${c.is_nullable === 'NO' ? 'NOT NULL' : ''}`)
      })
      console.log(`Nombre de lignes: ${count}`)
      console.log('Exemples (jusqu\'à 5):')
      console.dir(sample, { depth: null, maxArrayLength: 5 })
    }
  } catch (err) {
    console.error('❌ Erreur inspection DB:', err.message)
  } finally {
    client.release()
    await pool.end()
  }
}

main()
