const pool = require('../db');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// Dossier uploads KYC
const uploadDir = 'uploads/kyc';
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => cb(null, `kyc-${req.user.id}-${Date.now()}${path.extname(file.originalname)}`)
});

exports.uploadMiddleware = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } }).single('document');

exports.listRequired = async (req, res) => {
  // Liste statique minimale; peut venir d'une table paramétrage
  res.json({ success: true, requirements: [
    { key: 'piece_identite', label: 'Pièce d\'identité (CNI/Passeport)' },
    { key: 'justificatif_domicile', label: 'Justificatif de domicile' },
    { key: 'photo_identite', label: 'Photo d\'identité' }
  ]});
};

exports.listDocuments = async (req, res) => {
  try {
    const result = await pool.query('SELECT id, doc_key, url, created_at FROM kyc_documents WHERE user_id = $1 ORDER BY created_at DESC', [req.user.id]);
    res.json({ success: true, documents: result.rows });
  } catch (e) {
    res.status(500).json({ success: false, message: 'Erreur récupération documents' });
  }
};

exports.uploadDocument = async (req, res) => {
  try {
    const { doc_key } = req.body;
    if (!doc_key) return res.status(400).json({ success: false, message: 'doc_key requis' });
    if (!req.file) return res.status(400).json({ success: false, message: 'Fichier manquant' });
    const url = '/uploads/kyc/' + req.file.filename;
    const r = await pool.query('INSERT INTO kyc_documents (user_id, doc_key, url) VALUES ($1, $2, $3) RETURNING id, doc_key, url, created_at', [req.user.id, doc_key, url]);
    res.json({ success: true, document: r.rows[0] });
  } catch (e) {
    console.error('upload KYC error', e);
    res.status(500).json({ success: false, message: 'Erreur upload KYC' });
  }
};

