const pool = require('../db');

const generatePolicyNumber = async (productType) => {
  const prefixMap = {
    'coris_retraite': 'CRR',
    'coris_etude': 'CRE',
    'coris_serenite': 'CRS',
    'coris_familis': 'CRF',
    'coris_solidarite': 'CRSO',
    'coris_epargne_bonus': 'CREB',
    'coris_assure_prestige': 'CAP',
    'mon_bon_plan_coris': 'MBP',
    'flex_emprunteur': 'FLE'
  };
  
  const prefix = prefixMap[productType] || 'POL';
  const year = new Date().getFullYear();
  
  // Trouver le dernier numéro utilisé pour ce produit cette année
  const lastNumberQuery = `
    SELECT numero_police FROM subscriptions 
    WHERE numero_police LIKE $1 
    ORDER BY id DESC 
    LIMIT 1
  `;
  
  const pattern = `${prefix}${year}%`;
  const lastResult = await pool.query(lastNumberQuery, [pattern]);
  
  let nextNumber = 1;
  if (lastResult.rows.length > 0) {
    // Extraire le numéro de la dernière police
    const lastPolicy = lastResult.rows[0].numero_police;
    const lastNumberStr = lastPolicy.replace(`${prefix}${year}`, '');
    nextNumber = parseInt(lastNumberStr) + 1;
  }
  
  return `${prefix}${year}${nextNumber.toString().padStart(6, '0')}`;
};

module.exports = {
  generatePolicyNumber
};