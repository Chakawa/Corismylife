/// ============================================
/// MIDDLEWARE D'AUTHENTIFICATION
/// ============================================
/// Vérifie le token JWT dans les requêtes protégées
/// Utilisé pour sécuriser les routes qui nécessitent
/// une authentification (profil, notifications, etc.)
/// ============================================

const jwt = require('jsonwebtoken');
const pool = require('../db');

/**
 * Middleware de vérification du token JWT
 * Extrait le token du header Authorization
 * Vérifie sa validité et décode les informations utilisateur
 * 
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction suivante
 * @returns {void}
 */
async function verifyToken(req, res, next) {
  // ===================================
  // ÉTAPE 1 : RÉCUPÉRER LE TOKEN
  // ===================================
  
  // Le token peut être dans le header Authorization
  // Format attendu : "Bearer eyJhbGciOiJIUzI1NiIs..."
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Récupère la partie après "Bearer "
  
  // Si aucun token n'est fourni
  if (!token) {
    console.log('❌ Aucun token fourni dans la requête');
    return res.status(401).json({
      success: false,
      message: 'Authentification requise - Aucun token fourni'
    });
  }
  
  // ===================================
  // ÉTAPE 2 : VÉRIFIER LE TOKEN
  // ===================================
  
  try {
    // Vérifier et décoder le token avec la clé secrète
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userResult = await pool.query(
      `SELECT id, email, role, code_apporteur, est_suspendu, raison_suspension
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
      console.log('⛔ Compte suspendu pour utilisateur:', user.email);
      return res.status(403).json({
        success: false,
        suspended: true,
        forceLogout: true,
        message: 'Votre compte a été suspendu',
        reason: user.raison_suspension || 'Aucune raison spécifiée'
      });
    }
    
    // Le token est valide, on ajoute les infos utilisateur à req
    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      code_apporteur: user.code_apporteur
    };
    
    console.log('✅ Token valide pour utilisateur:', req.user.email);
    
    // Passer à la route suivante
    next();
    
  } catch (error) {
    // Le token est invalide ou expiré
    console.log('❌ Token invalide ou expiré:', error.message);
    
    // Différencier les types d'erreurs
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expiré - Veuillez vous reconnecter'
      });
    }
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token invalide - Authentification requise'
      });
    }
    
    // Erreur générique
    return res.status(401).json({
      success: false,
      message: 'Erreur d\'authentification'
    });
  }
}

/**
 * Middleware de vérification du rôle utilisateur
 * Vérifie que l'utilisateur a un rôle spécifique
 * Doit être utilisé APRÈS verifyToken
 * 
 * @param {string|Array<string>} roles - Rôle(s) autorisé(s)
 * @returns {Function} Middleware Express
 */
function requireRole(roles) {
  // Convertir en tableau si c'est une seule valeur
  const allowedRoles = Array.isArray(roles) ? roles : [roles];
  
  return (req, res, next) => {
    // Vérifier que l'utilisateur est bien authentifié (verifyToken a été appelé avant)
    if (!req.user) {
      console.log('❌ requireRole: Utilisateur non authentifié');
      return res.status(401).json({
        success: false,
        message: 'Authentification requise'
      });
    }
    
    // Vérifier le rôle
    if (!allowedRoles.includes(req.user.role)) {
      console.log(`❌ Accès refusé: Rôle requis ${allowedRoles.join(', ')}, rôle actuel: ${req.user.role}`);
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé - Permissions insuffisantes'
      });
    }
    
    console.log(`✅ Accès autorisé pour le rôle: ${req.user.role}`);
    next();
  };
}

/**
 * Middleware optionnel de vérification du token
 * Même fonctionnement que verifyToken mais n'échoue pas si pas de token
 * Utile pour les routes accessibles avec ou sans authentification
 * 
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction suivante
 * @returns {void}
 */
async function optionalAuth(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  // Si pas de token, on continue sans authentifier
  if (!token) {
    console.log('ℹ️ Requête sans authentification (optionnelle)');
    return next();
  }
  
  // Si token présent, on vérifie
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userResult = await pool.query(
      `SELECT id, email, role, code_apporteur, est_suspendu
       FROM users
       WHERE id = $1
       LIMIT 1`,
      [decoded.id]
    );

    if (userResult.rows.length === 0 || userResult.rows[0].est_suspendu) {
      console.log('⚠️ Auth optionnelle ignorée: utilisateur introuvable ou suspendu');
      return next();
    }

    const user = userResult.rows[0];
    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      code_apporteur: user.code_apporteur
    };
    console.log('✅ Token valide (auth optionnelle) pour:', req.user.email);
  } catch (error) {
    console.log('⚠️ Token invalide (auth optionnelle):', error.message);
    // On continue quand même sans authentifier
  }
  
  next();
}

/// ============================================
/// EXPORTS
/// ============================================

module.exports = {
  verifyToken,      // Middleware principal d'authentification
  requireRole,      // Middleware de vérification du rôle
  optionalAuth      // Middleware d'authentification optionnelle
};















