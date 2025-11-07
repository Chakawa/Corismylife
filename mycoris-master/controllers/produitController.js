const pool = require('../db');

// ======================================================
// Cache mémoire simple (TTL) pour accélérer les lectures
// ======================================================
const cacheStore = new Map();
const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes

function makeCacheKey(base, paramsObj) {
  const sorted = Object.keys(paramsObj || {})
    .sort()
    .map((k) => `${k}=${paramsObj[k]}`)
    .join('&');
  return `${base}?${sorted}`;
}

function getFromCache(key) {
  const entry = cacheStore.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    cacheStore.delete(key);
    return null;
  }
  return entry.data;
}

function setInCache(key, data, ttlMs = DEFAULT_TTL_MS) {
  cacheStore.set(key, { data, expiresAt: Date.now() + ttlMs });
}

// Obtenir tous les produits
const getAllProduits = async (req, res) => {
  try {
    const cacheKey = makeCacheKey('getAllProduits', {});
    const cached = getFromCache(cacheKey);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    const result = await pool.query('SELECT * FROM produit ORDER BY libelle');
    setInCache(cacheKey, result.rows);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Erreur lors de la récupération des produits:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur lors de la récupération des produits' });
  }
};

// Obtenir un produit par ID
const getProduitById = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM produit WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produit non trouvé' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Erreur lors de la récupération du produit:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Obtenir les tarifs d'un produit
const getTarifsByProduit = async (req, res) => {
  try {
    const { produit_id } = req.query;
    const cacheKey = makeCacheKey('getTarifsByProduit', { produit_id: produit_id || 'all' });
    const cached = getFromCache(cacheKey);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    let query = 'SELECT * FROM tarif_produit';
    const params = [];
    if (produit_id) {
      query += ' WHERE produit_id = $1 ORDER BY age, duree_contrat';
      params.push(produit_id);
    } else {
      query += ' ORDER BY produit_id, age, duree_contrat';
    }
    const result = await pool.query(query, params);
    setInCache(cacheKey, result.rows);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Erreur lors de la récupération des tarifs:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur lors de la récupération des tarifs' });
  }
};

// Rechercher des tarifs avec filtres
const searchTarifs = async (req, res) => {
  try {
    const { produit_id, age, duree_contrat, periodicite } = req.query;
    const cacheKey = makeCacheKey('searchTarifs', { produit_id: produit_id || '', age: age || '', duree_contrat: duree_contrat || '', periodicite: periodicite || '' });
    const cached = getFromCache(cacheKey);
    if (cached) return res.json({ success: true, data: cached, cached: true });

    let query = 'SELECT * FROM tarif_produit WHERE 1=1';
    const params = [];
    let i = 1;
    if (produit_id) { query += ` AND produit_id = $${i++}`; params.push(produit_id); }
    if (age) { query += ` AND age = $${i++}`; params.push(age); }
    if (duree_contrat) { query += ` AND duree_contrat = $${i++}`; params.push(duree_contrat); }
    if (periodicite) { query += ` AND periodicite = $${i++}`; params.push(periodicite); }
    query += ' ORDER BY age, duree_contrat';
    const result = await pool.query(query, params);
    setInCache(cacheKey, result.rows);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Erreur lors de la recherche des tarifs:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur lors de la recherche' });
  }
};

// Créer un produit
const createProduit = async (req, res) => {
  try {
    const { libelle } = req.body;
    if (!libelle) return res.status(400).json({ success: false, message: 'Le libellé est requis' });
    const result = await pool.query('INSERT INTO produit (libelle) VALUES ($1) RETURNING *', [libelle]);
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({ success: false, message: 'Ce produit existe déjà' });
    }
    console.error('Erreur lors de la création du produit:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Créer un tarif
const createTarif = async (req, res) => {
  try {
    const { produit_id, duree_contrat, periodicite, prime, capital, age, categorie } = req.body;
    if (!produit_id || !periodicite) return res.status(400).json({ success: false, message: 'Les champs produit_id et periodicite sont requis' });
    const result = await pool.query(
      `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, capital, age, categorie)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [produit_id, duree_contrat, periodicite, prime, capital, age, categorie]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Erreur lors de la création du tarif:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Créer plusieurs tarifs en batch
const createTarifsBatch = async (req, res) => {
  try {
    const { tarifs } = req.body;
    if (!Array.isArray(tarifs) || tarifs.length === 0) return res.status(400).json({ success: false, message: 'Un tableau de tarifs est requis' });

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const inserted = [];
      for (const t of tarifs) {
        const { produit_id, duree_contrat, periodicite, prime, capital, age, categorie } = t;
        if (!produit_id || !periodicite) throw new Error('Les champs produit_id et periodicite sont requis pour chaque tarif');
        const r = await client.query(
          `INSERT INTO tarif_produit (produit_id, duree_contrat, periodicite, prime, capital, age, categorie)
           VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
          [produit_id, duree_contrat, periodicite, prime, capital, age, categorie]
        );
        inserted.push(r.rows[0]);
      }
      await client.query('COMMIT');
      res.status(201).json({ success: true, data: inserted, count: inserted.length });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Erreur lors de la création des tarifs:', error);
    res.status(500).json({ success: false, message: error.message || 'Erreur serveur' });
  }
};

module.exports = {
  getAllProduits,
  getProduitById,
  getTarifsByProduit,
  searchTarifs,
  createProduit,
  createTarif,
  createTarifsBatch
};
