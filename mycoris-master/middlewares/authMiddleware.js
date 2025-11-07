const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
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
    console.log('✅ Token valide pour utilisateur:', {
      id: decoded.id,
      email: decoded.email,
      role: decoded.role
    });
    
    req.user = decoded;
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