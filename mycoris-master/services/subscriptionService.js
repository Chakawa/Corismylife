// services/subscriptionService.js
const pool = require('../db');
const { generatePolicyNumber } = require('./policyNumberService');

async function createSubscription(payload) {
  const { user_id, product_type, subscription_data, metadata = {} } = payload;
  const q = `
    INSERT INTO subscriptions (user_id, product_type, subscription_data, metadata, created_at, updated_at)
    VALUES ($1,$2,$3,$4,NOW(),NOW())
    RETURNING *;
  `;
  const { rows } = await pool.query(q, [user_id, product_type, subscription_data, metadata]);
  return rows[0];
}

async function validateSubscription(id) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query('SELECT * FROM subscriptions WHERE id=$1 FOR UPDATE', [id]);
    if (rows.length === 0) throw Object.assign(new Error('Subscription not found'), { status: 404 });
    const sub = rows[0];
    if (sub.statut === 'contrat') {
      await client.query('COMMIT');
      return sub;
    }
    const numero = await generatePolicyNumber(sub.product_type);
    const { rows: updated } = await client.query(
      `UPDATE subscriptions SET statut='contrat', date_validation=NOW(), numero_police=$2, updated_at=NOW()
       WHERE id=$1 RETURNING *`,
      [id, numero]
    );
    await client.query('COMMIT');
    return updated[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function listSubscriptions({ user_id, product_type, statut, limit = 50, offset = 0 }) {
  const where = [];
  const params = [];
  if (user_id) { params.push(user_id); where.push(`user_id=$${params.length}`); }
  if (product_type) { params.push(product_type); where.push(`product_type=$${params.length}`); }
  if (statut) { params.push(statut); where.push(`statut=$${params.length}`); }
  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  params.push(limit, offset);
  const q = `SELECT * FROM subscriptions ${clause} ORDER BY created_at DESC LIMIT $${params.length-1} OFFSET $${params.length}`;
  const { rows } = await pool.query(q, params);
  return rows;
}

module.exports = { createSubscription, validateSubscription, listSubscriptions };
