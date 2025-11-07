const pool = require('../db');

// Trouver un utilisateur par email
const findUserByEmail = async (email) => {
  const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  return result.rows[0];
};

// Créer un nouvel utilisateur
const createUser = async (userData) => {
  const {
    email, passwordHash, nom, prenom, civilite,
    date_naissance, lieu_naissance, telephone, adresse, pays, role
  } = userData;

  const result = await pool.query(
    `INSERT INTO users 
      (email, password_hash, nom, prenom, civilite, date_naissance, 
       lieu_naissance, telephone, adresse, pays, role) 
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     RETURNING id, email, nom, prenom, civilite, date_naissance, lieu_naissance, telephone, adresse, pays, role, created_at`,
    [email, passwordHash, nom, prenom, civilite, date_naissance,
     lieu_naissance, telephone, adresse, pays, role]
  );

  return result.rows[0];
};

module.exports = { findUserByEmail, createUser };
