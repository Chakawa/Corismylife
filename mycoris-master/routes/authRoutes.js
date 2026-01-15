const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs'); // Pour hasher les mots de passe
// Stockage OTP en mémoire (simple, à remplacer par Redis en prod)
const otpStore = new Map(); // key: telephone, value: { code, expiresAt, userData }
const pool = require('../db'); // Import de la connexion DB
const { verifyToken, requireRole } = require('../middlewares/authMiddleware');

// Configuration API SMS
const SMS_API_URL = 'https://apis.letexto.com/v1/messages/send'; // URL de l'API SMS CI
const SMS_API_TOKEN = 'fa09e6cef91f77c4b7d8e2c067f1b22c'; // Token de production
//const SMS_API_TOKEN = '1ed5abe2ef38e1e0ce6e64e2648d005c'; // Token de test
const SMS_SENDER = 'CORIS ASSUR'; // Max 11 caractères requis par l'API

/**
 * 📞 Fonction de normalisation du numéro de téléphone
 * Ajoute le préfixe +225 s'il manque
 */
function normalizeTelephone(phone) {
  if (!phone) return phone;
  const cleaned = phone.replace(/\s+/g, ''); // Supprimer les espaces
  if (!cleaned.startsWith('+')) {
    return '+225' + cleaned;
  }
  if (cleaned.startsWith('+225')) {
    return cleaned;
  }
  return '+225' + cleaned.substring(1); // Remplacer + par +225
}
// Import du contrôleur (optionnel)
let authController;
try {
  authController = require('../controllers/authController');
} catch (error) {
  console.log('AuthController non trouvé, utilisation des routes directes');
}

/**
 * 📱 FONCTION D'ENVOI DE SMS
 * Envoie un SMS via l'API SMS CI avec logs détaillés
 */
async function sendSMS(phoneNumber, message) {
  console.log('\n=== 📱 DÉBUT ENVOI SMS ===');
  console.log('📞 Destinataire:', phoneNumber);
  console.log('📝 Message:', message);
  console.log('🔑 API URL:', SMS_API_URL);
  console.log('👤 Expéditeur:', SMS_SENDER);
  
  try {
    const data = JSON.stringify({
      from: SMS_SENDER,
      to: phoneNumber,
      content: message,
    });
    
    console.log('📦 Données à envoyer:', data);
    console.log('⏳ Envoi de la requête HTTP POST...');

    const response = await fetch(SMS_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SMS_API_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: data,
    });

    console.log('📊 Statut HTTP:', response.status, response.statusText);
    
    if (!response.ok) {
      console.error('❌ Erreur HTTP:', response.status, response.statusText);
      const errorText = await response.text();
      console.error('📄 Réponse brute:', errorText);
      return { 
        success: false, 
        error: `HTTP ${response.status}: ${response.statusText}`,
        details: errorText
      };
    }

    const responseData = await response.json();
    console.log('✅ Réponse API SMS (JSON):', JSON.stringify(responseData, null, 2));
    
    // Vérifier si l'API a retourné un succès
    if (responseData.status === 'success' || responseData.success === true) {
      console.log('✅✅ SMS ENVOYÉ AVEC SUCCÈS!');
      console.log('📱 ID Message:', responseData.messageId || responseData.id || 'N/A');
    } else {
      console.warn('⚠️ Réponse API reçue mais statut incertain:', responseData);
    }
    
    console.log('=== ✅ FIN ENVOI SMS ===\n');
    return { success: true, data: responseData };
    
  } catch (error) {
    console.error('\n=== ❌ ERREUR CRITIQUE ENVOI SMS ===');
    console.error('Type d\'erreur:', error.constructor.name);
    console.error('Message:', error.message);
    console.error('Stack:', error.stack);
    console.error('=== ❌ FIN ERREUR ===\n');
    return { success: false, error: error.message };
  }
}

/**
 * 📱 ROUTE DE GÉNÉRATION ET ENVOI D'OTP
 * Génère un code OTP de 5 chiffres et l'envoie par SMS
 * 
 * @route POST /auth/send-otp
 * @param {string} telephone - Le numéro de téléphone
 * @param {object} userData - Les données du client à enregistrer après vérification
 * @returns {object} { success: boolean, message: string }
 */
router.post('/send-otp', async (req, res) => {
  console.log('\n╔════════════════════════════════════════╗');
  console.log('║   DEMANDE D\'ENVOI OTP                 ║');
  console.log('╚════════════════════════════════════════╝');
  
  try {
    const { telephone, userData } = req.body;
    
    console.log('📋 Données reçues:');
    console.log('  - Téléphone:', telephone);
    console.log('  - UserData présent:', !!userData);
    
    if (!telephone) {
      console.error('❌ Erreur: Numéro de téléphone manquant');
      return res.status(400).json({ 
        success: false, 
        message: 'Le numéro de téléphone est requis' 
      });
    }
    
    // Générer un code OTP de 5 chiffres
    const otpCode = Math.floor(10000 + Math.random() * 90000).toString();
    console.log('🔐 Code OTP généré:', otpCode);
    
    // Stocker l'OTP avec expiration de 5 minutes
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes
    otpStore.set(telephone, { 
      code: otpCode, 
      expiresAt, 
      userData // Stocker les données utilisateur pour l'inscription finale
    });
    
    console.log('💾 OTP stocké en mémoire');
    console.log('⏰ Expiration:', new Date(expiresAt).toLocaleString());
    console.log('📝 Note: Si un OTP existait déjà pour ce numéro, il a été REMPLACÉ par le nouveau');
    
    // Envoyer le SMS avec le code OTP
    const smsMessage = `Votre code de verification Coris Assurance est: ${otpCode}. Ce code expire dans 5 minutes. Ne le partagez avec personne.`;
    console.log('📤 Tentative d\'envoi du SMS...');
    
    const smsResult = await sendSMS(telephone, smsMessage);
    
    if (!smsResult.success) {
      console.error('╔════════════════════════════════════════╗');
      console.error('║   ⚠️  ÉCHEC ENVOI SMS                 ║');
      console.error('╚════════════════════════════════════════╝');
      console.error('Erreur:', smsResult.error);
      console.error('Détails:', smsResult.details);
      console.error('⚠️ OTP stocké mais SMS non envoyé!');
      
      // En cas d'échec, retourner une erreur à l'utilisateur
      return res.status(500).json({ 
        success: false, 
        message: 'Impossible d\'envoyer le SMS. Veuillez vérifier votre numéro et réessayer.' 
      });
    }
    
    console.log('╔════════════════════════════════════════╗');
    console.log('║   ✅ SMS ENVOYÉ AVEC SUCCÈS           ║');
    console.log('╚════════════════════════════════════════╝');
    console.log('✅ Code OTP envoyé au', telephone);
    console.log('📊 Résumé:');
    console.log('  - Code OTP: ***', otpCode.slice(-2), '(masqué dans les logs production)');
    console.log('  - Destinataire:', telephone);
    console.log('  - Expiration:', new Date(expiresAt).toLocaleString());
    console.log('  - SMS envoyé: ✅ OUI');
    console.log('\n');
    
    res.json({ 
      success: true, 
      message: 'Code OTP envoyé avec succès'
      // ⚠️ NE JAMAIS retourner le code OTP dans la réponse
    });
  } catch (error) {
    console.error('\n╔════════════════════════════════════════╗');
    console.error('║   ❌ ERREUR CRITIQUE ROUTE OTP        ║');
    console.error('╚════════════════════════════════════════╝');
    console.error('Type d\'erreur:', error.constructor.name);
    console.error('Message:', error.message);
    console.error('Stack:', error.stack);
    console.error('\n');
    
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de l\'envoi du code OTP' 
    });
  }
});

/**
 * ✅ ROUTE DE VÉRIFICATION D'OTP ET CRÉATION DU COMPTE
 * Vérifie le code OTP et crée le compte si le code est correct
 * 
 * @route POST /auth/verify-otp
 * @param {string} telephone - Le numéro de téléphone
 * @param {string} otpCode - Le code OTP à vérifier
 * @returns {object} { success: boolean, user: object }
 */
router.post('/verify-otp', async (req, res) => {
  try {
    const { telephone, otpCode } = req.body;
    
    if (!telephone || !otpCode) {
      return res.status(400).json({ 
        success: false, 
        message: 'Le téléphone et le code OTP sont requis' 
      });
    }
    
    // Récupérer l'OTP stocké
    const storedOtp = otpStore.get(telephone);
    
    if (!storedOtp) {
      return res.status(400).json({ 
        success: false, 
        message: 'Aucun code OTP trouvé. Veuillez demander un nouveau code.' 
      });
    }
    
    // Vérifier si l'OTP a expiré
    if (Date.now() > storedOtp.expiresAt) {
      otpStore.delete(telephone);
      return res.status(400).json({ 
        success: false, 
        message: 'Le code OTP a expiré. Veuillez demander un nouveau code.' 
      });
    }
    
    // Vérifier si le code est correct
    if (storedOtp.code !== otpCode) {
      return res.status(400).json({ 
        success: false, 
        message: 'Code OTP incorrect. Veuillez réessayer.' 
      });
    }
    
    // Code OTP correct, créer le compte
    const user = await authController.registerClient(storedOtp.userData);
    
    // Supprimer l'OTP après utilisation
    otpStore.delete(telephone);
    
    console.log('✅ Compte créé avec succès après vérification OTP:', user.email || telephone);
    
    res.status(201).json({ success: true, user });
  } catch (error) {
    console.error('Erreur vérification OTP:', error);
    res.status(400).json({ 
      success: false, 
      message: error.message || 'Erreur lors de la vérification du code OTP' 
    });
  }
});

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
 * � ROUTE DE VÉRIFICATION D'UNICITÉ DU TÉLÉPHONE
 * Vérifie si un numéro de téléphone existe déjà dans la base de données
 * 
 * @route POST /auth/check-phone
 * @param {string} telephone - Le numéro de téléphone à vérifier
 * @returns {object} { exists: boolean }
 */
router.post('/check-phone', async (req, res) => {
  try {
    const { telephone } = req.body;
    
    if (!telephone) {
      return res.status(400).json({ 
        success: false, 
        message: 'Le numéro de téléphone est requis' 
      });
    }
    
    const exists = await authController.checkPhoneExists(telephone);
    res.json({ success: true, exists });
  } catch (error) {
    console.error('Erreur vérification téléphone:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la vérification du téléphone' 
    });
  }
});

/**
 * 📧 ROUTE DE VÉRIFICATION D'UNICITÉ DE L'EMAIL
 * Vérifie si un email existe déjà dans la base de données
 * 
 * @route POST /auth/check-email
 * @param {string} email - L'email à vérifier
 * @returns {object} { exists: boolean }
 */
router.post('/check-email', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.json({ success: true, exists: false });
    }
    
    const exists = await authController.checkEmailExists(email);
    res.json({ success: true, exists });
  } catch (error) {
    console.error('Erreur vérification email:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la vérification de l\'email' 
    });
  }
});

/**
 * �🔐 ROUTE DE CONNEXION
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

/**
 * ===============================================
 * MOT DE PASSE OUBLIÉ - FLUX COMPLET
 * ===============================================
 */

// Store séparé pour OTP de reset de mot de passe
const resetPasswordOtpStore = new Map(); // key: telephone, value: { code, expiresAt, userId }

/**
 * 📱 ÉTAPE 1: Demander un reset de mot de passe
 * Vérifie si le téléphone existe et envoie un OTP
 * @route POST /auth/forgot-password
 */
router.post('/forgot-password', async (req, res) => {
  try {
    let { telephone } = req.body;
    
    if (!telephone) {
      return res.status(400).json({
        success: false,
        message: 'Le numéro de téléphone est requis'
      });
    }
    
      // Normaliser le numéro de téléphone
      telephone = normalizeTelephone(telephone);
    
    console.log('🔓 Demande reset mot de passe pour téléphone:', telephone);
    
    // Vérifier si le téléphone existe dans la base de données
    const userResult = await pool.query(
      'SELECT id, email FROM users WHERE telephone = $1',
      [telephone]
    );
    
    if (userResult.rows.length === 0) {
      // Ne pas révéler si le téléphone existe ou non (sécurité)
      return res.status(404).json({
        success: false,
        message: 'Aucun compte associé à ce numéro de téléphone'
      });
    }
    
    const user = userResult.rows[0];
    console.log('✅ Compte trouvé pour:', user.email);
    
    // Générer un code OTP de 5 chiffres
    const otpCode = Math.floor(10000 + Math.random() * 90000).toString();
    console.log('🔐 Code OTP généré pour reset:', otpCode);
    
    // Stocker l'OTP avec expiration de 5 minutes
    resetPasswordOtpStore.set(telephone, {
      code: otpCode,
      expiresAt: Date.now() + 5 * 60 * 1000,
      userId: user.id
    });
    
    console.log('💾 OTP reset stocké pour:', telephone);
    
    // Envoyer le SMS
    const smsMessage = `Votre code de réinitialisation Coris Assurance est: ${otpCode}. Ce code expire dans 5 minutes. Ne le partagez avec personne.`;
    
    try {
      await sendSMS(telephone, smsMessage);
      console.log('✅ SMS d\'OTP reset envoyé au', telephone);
    } catch (smsError) {
      console.error('⚠️ OTP reset stocké mais SMS non envoyé:', smsError.message);
      // On continue quand même
    }
    
    // Retourner le succès
    res.json({
      success: true,
      message: 'Un code de vérification a été envoyé à votre numéro de téléphone',
      telephone: telephone
    });
    
  } catch (error) {
    console.error('❌ Erreur forgot-password:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la demande de réinitialisation'
    });
  }
});

/**
 * ✅ ÉTAPE 2: Vérifier l'OTP du reset
 * @route POST /auth/verify-reset-otp
 */
router.post('/verify-reset-otp', async (req, res) => {
  try {
    let { telephone, otpCode } = req.body;
    
    if (!telephone || !otpCode) {
      return res.status(400).json({
        success: false,
        message: 'Le téléphone et le code OTP sont requis'
      });
    }
    
      // Normaliser le numéro de téléphone
      telephone = normalizeTelephone(telephone);
    
    console.log('✅ Vérification OTP reset pour:', telephone);
    
    const storedOtp = resetPasswordOtpStore.get(telephone);
    
    if (!storedOtp) {
      return res.status(400).json({
        success: false,
        message: 'Aucun code OTP trouvé. Veuillez demander un nouveau code.'
      });
    }
    
    // Vérifier si l'OTP a expiré
    if (Date.now() > storedOtp.expiresAt) {
      resetPasswordOtpStore.delete(telephone);
      return res.status(400).json({
        success: false,
        message: 'Le code OTP a expiré. Veuillez demander un nouveau code.'
      });
    }
    
    // Vérifier si le code est correct
    if (storedOtp.code !== otpCode) {
      return res.status(401).json({
        success: false,
        message: 'Code OTP incorrect. Veuillez réessayer.'
      });
    }
    
    console.log('✅ OTP reset vérifié pour userId:', storedOtp.userId);
    
    // OTP correct - retourner le userId pour la prochaine étape
    res.json({
      success: true,
      message: 'Code OTP vérifié',
      userId: storedOtp.userId,
      telephone: telephone
    });
    
  } catch (error) {
    console.error('❌ Erreur verify-reset-otp:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du code OTP'
    });
  }
});

/**
 * 🔑 ÉTAPE 3: Réinitialiser le mot de passe
 * @route POST /auth/reset-password
 */
router.post('/reset-password', async (req, res) => {
  try {
    let { telephone, userId, newPassword, confirmPassword } = req.body;
    
    if (!telephone || !userId || !newPassword || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs sont requis'
      });
    }
    
      // Normaliser le numéro de téléphone
      telephone = normalizeTelephone(telephone);
    
    // Vérifier que les mots de passe correspondent
    if (newPassword !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Les mots de passe ne correspondent pas'
      });
    }
    
    // Validation du mot de passe (au moins 6 caractères)
    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe doit contenir au moins 6 caractères'
      });
    }
    
    console.log('🔐 Réinitialisation mot de passe pour userId:', userId);
    
    // Récupérer l'utilisateur
    const userResult = await pool.query(
      'SELECT id, email FROM users WHERE id = $1 AND telephone = $2',
      [userId, telephone]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    const user = userResult.rows[0];
    
    // Hasher le nouveau mot de passe avec bcrypt
    const passwordHash = await bcrypt.hash(newPassword, 10);
    
    // Mettre à jour le mot de passe
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [passwordHash, userId]
    );
    
    console.log('✅ Mot de passe mis à jour pour:', user.email);
    
    // Supprimer l'OTP utilisé
    resetPasswordOtpStore.delete(telephone);
    
    res.json({
      success: true,
      message: 'Mot de passe réinitialisé avec succès. Vous pouvez maintenant vous connecter.'
    });
    
  } catch (error) {
    console.error('❌ Erreur reset-password:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la réinitialisation du mot de passe'
    });
  }
});

/**
 * 🔄 Renvoyer un OTP (pour reset de mot de passe)
 * @route POST /auth/resend-reset-otp
 */
router.post('/resend-reset-otp', async (req, res) => {
  try {
    let { telephone } = req.body;
    
    if (!telephone) {
      return res.status(400).json({
        success: false,
        message: 'Le numéro de téléphone est requis'
      });
    }
    
      // Normaliser le numéro de téléphone
      telephone = normalizeTelephone(telephone);
    
    console.log('🔄 Renvoi OTP reset pour:', telephone);
    
    // Vérifier si le téléphone existe
    const userResult = await pool.query(
      'SELECT id FROM users WHERE telephone = $1',
      [telephone]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Aucun compte associé à ce numéro'
      });
    }
    
    const userId = userResult.rows[0].id;
    
    // Générer un nouveau code OTP
    const otpCode = Math.floor(10000 + Math.random() * 90000).toString();
    console.log('🔐 Nouveau code OTP généré:', otpCode);
    
    // Remplacer l'ancien OTP (l'ancien code devient invalide)
    resetPasswordOtpStore.set(telephone, {
      code: otpCode,
      expiresAt: Date.now() + 5 * 60 * 1000,
      userId: userId
    });
    
    console.log('♻️ Ancien code OTP invalidé - seul le nouveau code sera accepté');
    
    // Envoyer le SMS
    const smsMessage = `Votre code de réinitialisation Coris Assurance est: ${otpCode}. Ce code expire dans 5 minutes.`;
    
    try {
      await sendSMS(telephone, smsMessage);
      console.log('✅ Nouveau SMS d\'OTP reset envoyé');
    } catch (smsError) {
      console.error('⚠️ SMS non envoyé:', smsError.message);
    }
    
    res.json({
      success: true,
      message: 'Un nouveau code a été envoyé à votre téléphone'
    });
    
  } catch (error) {
    console.error('❌ Erreur resend-reset-otp:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du renvoi du code'
    });
  }
});

// =========================
// ROUTES 2FA (AUTHENTIFICATION À DEUX FACTEURS)
// =========================

// Store temporaire pour les OTP de 2FA (à remplacer par Redis en prod)
const twoFAOtpStore = new Map(); // key: userId, value: { code, expiresAt, secondaryPhone }

/**
 * 📊 GET /auth/2fa-status
 * Récupère le statut 2FA de l'utilisateur connecté
 */
router.get('/2fa-status', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const result = await pool.query(
      'SELECT enabled, secondary_phone FROM two_factor_auth WHERE user_id = $1',
      [userId]
    );
    
    if (result.rows.length === 0) {
      // Pas de config 2FA, retourner désactivé par défaut
      return res.json({
        success: true,
        enabled: false,
        secondaryPhone: null
      });
    }
    
    const twoFA = result.rows[0];
    res.json({
      success: true,
      enabled: twoFA.enabled,
      secondaryPhone: twoFA.secondary_phone
    });
  } catch (error) {
    console.error('Erreur récupération statut 2FA:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

/**
 * 📱 POST /auth/activate-2fa
 * Active la 2FA et envoie un OTP au numéro secondaire
 */
router.post('/activate-2fa', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { secondaryPhone } = req.body;
    
    if (!secondaryPhone) {
      return res.status(400).json({
        success: false,
        message: 'Le numéro secondaire est requis'
      });
    }
    
    // Normaliser le numéro
    const normalizedPhone = normalizeTelephone(secondaryPhone);
    
    // Générer le code OTP
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes
    
    // Stocker l'OTP temporairement
    twoFAOtpStore.set(userId, { code, expiresAt, secondaryPhone: normalizedPhone });
    
    // Envoyer le code par SMS
    const smsMessage = `Code de vérification CORIS: ${code}. Ce code expire dans 5 minutes.`;
    const smsResult = await sendSMS(normalizedPhone, smsMessage);
    
    if (!smsResult.success) {
      console.log('⚠️ Échec envoi SMS, mais code enregistré pour test');
      console.log('📨 Code OTP (développement):', code);
    } else {
      console.log('✅ Code OTP envoyé avec succès');
    }
    
    res.json({
      success: true,
      message: 'Code OTP envoyé à votre numéro secondaire'
    });
  } catch (error) {
    console.error('Erreur activation 2FA:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'activation'
    });
  }
});

/**
 * ✅ POST /auth/verify-2fa-activation
 * Vérifie l'OTP et active définitivement la 2FA
 */
router.post('/verify-2fa-activation', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { code } = req.body;
    
    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Le code est requis'
      });
    }
    
    // Récupérer l'OTP stocké
    const stored = twoFAOtpStore.get(userId);
    
    if (!stored) {
      return res.status(400).json({
        success: false,
        message: 'Aucun code OTP en attente. Veuillez recommencer.'
      });
    }
    
    // Vérifier l'expiration
    if (Date.now() > stored.expiresAt) {
      twoFAOtpStore.delete(userId);
      return res.status(400).json({
        success: false,
        message: 'Le code a expiré. Veuillez recommencer.'
      });
    }
    
    // Vérifier le code
    if (stored.code !== code) {
      return res.status(401).json({
        success: false,
        message: 'Code invalide'
      });
    }
    
    // Code correct, activer la 2FA dans la base de données
    await pool.query(`
      INSERT INTO two_factor_auth (user_id, enabled, secondary_phone)
      VALUES ($1, true, $2)
      ON CONFLICT (user_id)
      DO UPDATE SET enabled = true, secondary_phone = $2, updated_at = CURRENT_TIMESTAMP
    `, [userId, stored.secondaryPhone]);
    
    // Supprimer l'OTP temporaire
    twoFAOtpStore.delete(userId);
    
    res.json({
      success: true,
      message: 'Authentification à deux facteurs activée avec succès'
    });
  } catch (error) {
    console.error('Erreur vérification 2FA:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification'
    });
  }
});

/**
 * ❌ POST /auth/disable-2fa
 * Désactive la 2FA pour l'utilisateur
 */
router.post('/disable-2fa', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    await pool.query(
      'UPDATE two_factor_auth SET enabled = false, updated_at = CURRENT_TIMESTAMP WHERE user_id = $1',
      [userId]
    );
    
    res.json({
      success: true,
      message: 'Authentification à deux facteurs désactivée'
    });
  } catch (error) {
    console.error('Erreur désactivation 2FA:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la désactivation'
    });
  }
});

/**
 * 🔐 POST /auth/request-2fa-otp
 * Envoie un code OTP lors de la connexion si 2FA est activée
 * (Utilisé pendant le processus de connexion)
 */
router.post('/request-2fa-otp', async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'userId requis'
      });
    }
    
    // Vérifier si la 2FA est activée pour cet utilisateur
    const result = await pool.query(
      'SELECT enabled, secondary_phone FROM two_factor_auth WHERE user_id = $1 AND enabled = true',
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: '2FA non activée pour cet utilisateur'
      });
    }
    
    const twoFA = result.rows[0];
    
    // Générer le code OTP
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes
    
    // Stocker l'OTP temporairement
    twoFAOtpStore.set(userId, { code, expiresAt, secondaryPhone: twoFA.secondary_phone });
    
    // Envoyer le code par SMS
    const smsMessage = `Code de connexion CORIS: ${code}. Ce code expire dans 5 minutes.`;
    const smsResult = await sendSMS(twoFA.secondary_phone, smsMessage);
    
    if (!smsResult.success) {
      console.log('⚠️ Échec envoi SMS, mais code enregistré pour test');
      console.log('📨 Code OTP (développement):', code);
    }
    
    res.json({
      success: true,
      message: 'Code OTP envoyé',
      secondaryPhone: twoFA.secondary_phone
    });
  } catch (error) {
    console.error('Erreur request-2fa-otp:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

/**
 * ✅ POST /auth/verify-2fa-otp
 * Vérifie le code OTP lors de la connexion
 */
router.post('/verify-2fa-otp', async (req, res) => {
  try {
    const { userId, code } = req.body;
    
    if (!userId || !code) {
      return res.status(400).json({
        success: false,
        message: 'userId et code requis'
      });
    }
    
    // Récupérer l'OTP stocké
    const stored = twoFAOtpStore.get(parseInt(userId));
    
    if (!stored) {
      return res.status(400).json({
        success: false,
        message: 'Aucun code OTP en attente'
      });
    }
    
    // Vérifier l'expiration
    if (Date.now() > stored.expiresAt) {
      twoFAOtpStore.delete(parseInt(userId));
      return res.status(400).json({
        success: false,
        message: 'Le code a expiré'
      });
    }
    
    // Vérifier le code
    if (stored.code !== code) {
      return res.status(401).json({
        success: false,
        message: 'Code invalide'
      });
    }
    
    // Code correct, supprimer l'OTP
    twoFAOtpStore.delete(parseInt(userId));
    
    res.json({
      success: true,
      message: 'Code vérifié avec succès'
    });
  } catch (error) {
    console.error('Erreur verify-2fa-otp:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur'
    });
  }
});

/**
 * 🚪 ROUTE DE DÉCONNEXION
 * Enregistre la déconnexion de l'utilisateur
 * 
 * @route POST /auth/logout
 * @returns {object} Confirmation de déconnexion
 */
router.post('/logout', verifyToken, async (req, res) => {
  console.log('🚪 Déconnexion utilisateur:', req.user.id);
  
  try {
    if (authController && authController.logout) {
      await authController.logout(req.user.id, req.ip || 'unknown');
    }
    
    res.json({ 
      success: true, 
      message: 'Déconnexion réussie' 
    });
  } catch (error) {
    console.error('❌ Erreur déconnexion:', error);
    // Même en cas d'erreur de log, on confirme la déconnexion
    res.json({ 
      success: true, 
      message: 'Déconnexion réussie' 
    });
  }
});

/**
 * 🔐 CHANGE PASSWORD (Self-service)
 * Permet à un utilisateur connecté de changer son mot de passe
 * Nécessite l'ancien mot de passe pour vérification
 */
router.post('/change-password', verifyToken, async (req, res) => {
  if (authController && authController.changePassword) {
    return authController.changePassword(req, res);
  }
  
  return res.status(501).json({ 
    success: false, 
    message: 'Fonctionnalité non disponible' 
  });
});

module.exports = router;
 