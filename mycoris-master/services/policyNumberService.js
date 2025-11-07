const pool = require('../db');

async function generatePolicyNumber(productType = 'GEN') {
  const prefix = (productType.split('_')[1] || productType).toUpperCase().slice(0,6);
  const year = new Date().getFullYear();
  const { rows } = await pool.query("SELECT nextval('police_seq') AS n");
  const n = String(rows[0].n).padStart(6, '0');
  return `${prefix}-${year}-${n}`; // EX: RETRAITE-2025-100123
}

module.exports = { generatePolicyNumber };