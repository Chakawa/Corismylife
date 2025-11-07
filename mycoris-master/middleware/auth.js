/// ============================================
/// MIDDLEWARE D'AUTHENTIFICATION
/// ============================================
/// Vérifie le token JWT dans les requêtes protégées
/// Utilisé pour sécuriser les routes qui nécessitent
/// une authentification (profil, notifications, etc.)
/// ============================================

const jwt = require('jsonwebtoken');

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
function verifyToken(req, res, next) {
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
    
    // Le token est valide, on ajoute les infos utilisateur à req
    req.user = {
      id: decoded.id,
      email: decoded.email,
      role: decoded.role,
      code_apporteur: decoded.code_apporteur
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
function optionalAuth(req, res, next) {
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
    req.user = {
      id: decoded.id,
      email: decoded.email,
      role: decoded.role,
      code_apporteur: decoded.code_apporteur
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













