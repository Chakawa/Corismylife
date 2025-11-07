const express = require('express');
const router = express.Router();
// Stockage OTP en mémoire (simple, à remplacer par Redis en prod)
const otpStore = new Map(); // key: userId or identifier, value: { code, expiresAt }
const pool = require('../db'); // Import de la connexion DB
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

// Import du contrôleur (optionnel)
let authController;
try {
  authController = require('../controllers/authController');
} catch (error) {
  console.log('AuthController non trouvé, utilisation des routes directes');
}

// Route d'inscription
router.post('/register', async (req, res) => {
  try {
    if (authController) {
      const user = await authController.registerClient(req.body);
      res.status(201).json({ success: true, user });
    } else {
      // Implémentation basique si pas de contrôleur
      const { email, password, nom, prenom } = req.body;
      const bcrypt = require('bcrypt');
      const passwordHash = await bcrypt.hash(password, 10);
      
      const result = await pool.query(
        'INSERT INTO users (email, password_hash, nom, prenom, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, nom, prenom, role',
        [email, passwordHash, nom, prenom, 'client']
      );
      
      res.status(201).json({ success: true, user: result.rows[0] });
    }
  } catch (error) {
    console.error('Erreur inscription:', error);
    res.status(400).json({ success: false, message: error.message });
  }
});

/**
 * 🔐 ROUTE DE CONNEXION
 * Permet à un utilisateur de se connecter avec son téléphone OU son email
 * 
 * @route POST /auth/login
 * @param {string} email - Email ou numéro de téléphone de l'utilisateur
 * @param {string} password - Mot de passe de l'utilisateur
 * @returns {object} Token JWT et informations utilisateur
 */
router.post('/login', async (req, res) => {
  console.log('🔐 Tentative de connexion...');
  console.log('📥 Données reçues:', { email: req.body.email, password: '***' });
  
  try {
    // Si le contrôleur authController existe, l'utiliser
    if (authController) {
      // Récupérer l'identifiant (email ou téléphone) et le mot de passe
      const { email, password } = req.body;
      console.log('📞 Identifiant reçu:', email);
      console.log('🔍 Type détecté:', email.includes('@') ? 'EMAIL' : 'TÉLÉPHONE');
      
      // Appeler la fonction login du contrôleur (accepte téléphone OU email)
      const result = await authController.login(email, password);
      
      console.log('✅ Connexion réussie pour:', result.user.email);
      
      // Retourner le résultat avec succès
      res.json({ success: true, ...result });
    } else {
      // Fallback si pas de contrôleur (implémentation basique)
      const { email, password } = req.body;
      
      // Vérifier si c'est un email ou un téléphone
      const isEmail = email.includes('@');
      const query = isEmail 
        ? 'SELECT * FROM users WHERE email = $1'
        : 'SELECT * FROM users WHERE telephone = $1';
      
      // Rechercher l'utilisateur dans la base de données
      const userResult = await pool.query(query, [email]);
      
      if (userResult.rows.length === 0) {
        console.log('❌ Utilisateur non trouvé');
        return res.status(401).json({ 
          success: false, 
          message: 'Identifiant ou mot de passe incorrect' 
        });
      }
      
      const user = userResult.rows[0];
      const bcrypt = require('bcrypt');
      const jwt = require('jsonwebtoken');
      
      // Vérifier le mot de passe
      const validPassword = await bcrypt.compare(password, user.password_hash);
      if (!validPassword) {
        console.log('❌ Mot de passe incorrect');
        return res.status(401).json({ 
          success: false, 
          message: 'Identifiant ou mot de passe incorrect' 
        });
      }
      
      // Créer le token JWT
      const token = jwt.sign(
        { id: user.id, email: user.email, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      console.log('✅ Connexion réussie');
      
      // Retourner le token et les infos utilisateur
      res.json({
        success: true,
        token,
        user: { 
          id: user.id, 
          email: user.email, 
          nom: user.nom, 
          prenom: user.prenom, 
          role: user.role,
          telephone: user.telephone
        }
      });
    }
  } catch (error) {
    console.error('❌ Erreur connexion:', error);
    res.status(401).json({ success: false, message: error.message });
  }
});

// 🎯 ROUTE PROFILE AVEC GESTION D'ERREUR ROBUSTE
router.get('/profile', verifyToken, async (req, res) => {
  console.log('=== ROUTE /profile APPELÉE ===');
  console.log('Headers:', req.headers.authorization);
  console.log('User depuis middleware:', req.user);
  
  try {
    const userId = req.user.id;
    console.log('🔍 Recherche utilisateur ID:', userId);
    
    // Requête SQL sécurisée avec gestion des valeurs NULL
    const query = `
      SELECT 
        id, 
        email, 
        COALESCE(nom, '') as nom, 
        COALESCE(prenom, '') as prenom,
        COALESCE(civilite, '') as civilite,
        date_naissance, 
        COALESCE(lieu_naissance, '') as lieu_naissance,
        COALESCE(telephone, '') as telephone,
        COALESCE(adresse, '') as adresse,
        COALESCE(pays, '') as pays,
        created_at
      FROM users 
      WHERE id = $1
    `;
    
    console.log('🔄 Exécution requête SQL...');
    const result = await pool.query(query, [userId]);
    console.log('📊 Nombre de résultats:', result.rows.length);
    
    if (result.rows.length === 0) {
      console.log('❌ Aucun utilisateur trouvé');
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    const userData = result.rows[0];
    console.log('✅ Données utilisateur récupérées:', {
      id: userData.id,
      email: userData.email,
      nom: userData.nom,
      prenom: userData.prenom
    });

    // Formater la date si elle existe
    if (userData.date_naissance) {
      userData.date_naissance = userData.date_naissance.toISOString().split('T')[0];
    }

    res.json({
      success: true,
      user: userData
    });
    
  } catch (error) {
    console.error('=== ERREUR ROUTE /profile ===');
    console.error('Type d\'erreur:', error.constructor.name);
    console.error('Message:', error.message);
    console.error('Code SQL:', error.code);
    console.error('Stack complet:', error.stack);
    
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération du profil',
      error: process.env.NODE_ENV === 'development' ? {
        message: error.message,
        code: error.code,
        detail: error.detail
      } : 'Erreur interne'
    });
  }
});

// =========================
// 2FA (OTP) Endpoints
// =========================
router.post('/request-otp', async (req, res) => {
  try {
    const { identifier } = req.body; // email ou téléphone
    if (!identifier) return res.status(400).json({ success: false, message: 'identifier requis' });

    // Trouver l'utilisateur
    const isEmail = identifier.includes('@');
    const query = isEmail ? 'SELECT id, email FROM users WHERE email = $1' : 'SELECT id, telephone as email FROM users WHERE telephone = $1';
    const result = await pool.query(query, [identifier]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });

    const user = result.rows[0];
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 min
    otpStore.set(user.id, { code, expiresAt });

    console.log('📨 OTP envoyé (log dev):', code);
    // TODO: envoyer par SMS/Email
    res.json({ success: true, message: 'OTP généré et envoyé' });
  } catch (e) {
    console.error('request-otp error', e);
    res.status(500).json({ success: false, message: 'Erreur génération OTP' });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const { userId, code } = req.body;
    if (!userId || !code) return res.status(400).json({ success: false, message: 'userId et code requis' });
    const item = otpStore.get(userId);
    if (!item) return res.status(400).json({ success: false, message: 'OTP non demandé' });
    if (Date.now() > item.expiresAt) return res.status(400).json({ success: false, message: 'OTP expiré' });
    if (item.code !== code) return res.status(401).json({ success: false, message: 'OTP invalide' });
    otpStore.delete(userId);
    res.json({ success: true, message: 'OTP vérifié' });
  } catch (e) {
    console.error('verify-otp error', e);
    res.status(500).json({ success: false, message: 'Erreur vérification OTP' });
  }
});

module.exports = router;
 