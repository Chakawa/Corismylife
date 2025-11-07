const pool = require('../db');

const generatePolicyNumber = async (productType) => {
  const prefixMap = {
    'coris_retraite': 'CRR',
    'coris_etude': 'CRE',
    'coris_serenite': 'CRS',
    'coris_familis': 'CRF',
    'coris_epargne_bonus': 'CREB',
    'flex_emprunteur': 'FLE'
  };
  
  const prefix = prefixMap[productType] || 'POL';
  const year = new Date().getFullYear();
  
  // Compter le nombre de souscriptions pour ce produit cette année
  const countQuery = `
    SELECT COUNT(*) FROM subscriptions 
    WHERE produit_nom = $1 AND EXTRACT(YEAR FROM date_creation) = $2
  `;
  
  const countResult = await pool.query(countQuery, [productType, year]);
  const count = parseInt(countResult.rows[0].count) + 1;
  
  return `${prefix}${year}${count.toString().padStart(6, '0')}`;
};

module.exports = {
  generatePolicyNumber
};