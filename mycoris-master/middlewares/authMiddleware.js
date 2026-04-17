const jwt = require('jsonwebtoken');
const pool = require('../db');

async function verifyToken(req, res, next) {
  console.log('🔐 Vérification du token...');
  console.log('Authorization header:', req.headers.authorization);
  
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; 
  
  if (!token) {
    console.log('❌ Aucun token fourni');
    return res.status(401).json({ 
      success: false, 
      message: 'Token d\'authentification manquant' 
    });
  }

  console.log('🎫 Token reçu (début):', token.substring(0, 20) + '...');

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userResult = await pool.query(
      `SELECT id, email, role, nom, prenom, code_apporteur, est_suspendu, raison_suspension
       FROM users
       WHERE id = $1
       LIMIT 1`,
      [decoded.id]
    );

    if (userResult.rows.length === 0) {
      console.log('❌ Utilisateur introuvable pour le token:', decoded.id);
      return res.status(401).json({ 
        success: false, 
        message: 'Utilisateur introuvable ou supprimé'
      });
    }

    const user = userResult.rows[0];

    if (user.est_suspendu) {
      console.log('⛔ Compte suspendu détecté pour:', user.email);
      return res.status(403).json({
        success: false,
        suspended: true,
        forceLogout: true,
        message: 'Votre compte a été suspendu',
        reason: user.raison_suspension || 'Aucune raison spécifiée'
      });
    }

    console.log('✅ Token valide pour utilisateur:', {
      id: user.id,
      email: user.email,
      role: user.role
    });
    
    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      nom: user.nom,
      prenom: user.prenom,
      code_apporteur: user.code_apporteur
    };
    next();
  } catch (err) {
    console.error('❌ Erreur token:', err.message);
    return res.status(401).json({ 
      success: false, 
      message: 'Token invalide ou expiré'
    });
  }
}

function requireRole(role) {
  return (req, res, next) => {
    if (req.user?.role !== role) {
      return res.status(403).json({ 
        success: false, 
        message: `Accès réservé aux ${role}s` 
      });
    }
    next();
  };
}

module.exports = { verifyToken, requireRole };