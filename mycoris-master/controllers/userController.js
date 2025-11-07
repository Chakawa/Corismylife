const pool = require('../db');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

/// ============================================
/// CONTRÔLEUR UTILISATEUR
/// ============================================
/// Gère toutes les opérations liées au profil utilisateur :
/// - Récupération du profil
/// - Modification du profil
/// - Upload de photo
/// - Changement de mot de passe

/**
 * Récupère le profil de l'utilisateur connecté
 */
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log('📋 Récupération du profil pour l\'utilisateur:', userId);
    
    // Requête améliorée avec gestion explicite des valeurs NULL
    const query = `
      SELECT 
        id, 
        civilite, 
        nom, 
        prenom, 
        email, 
        telephone, 
        date_naissance,
        lieu_naissance,
        adresse, 
        pays,
        photo_url, 
        role, 
        code_apporteur,
        created_at, 
        updated_at,
        CASE 
          WHEN date_naissance IS NULL THEN 'NULL'
          ELSE date_naissance::text
        END as date_naissance_str,
        CASE 
          WHEN lieu_naissance IS NULL THEN 'NULL'
          ELSE lieu_naissance
        END as lieu_naissance_str
      FROM users 
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    const user = result.rows[0];
    
    // Formater date_naissance si elle existe
    if (user.date_naissance) {
      if (user.date_naissance instanceof Date) {
        user.date_naissance = user.date_naissance.toISOString().split('T')[0];
      } else if (typeof user.date_naissance === 'string') {
        // Garder tel quel si c'est déjà une string
        user.date_naissance = user.date_naissance.split('T')[0];
      }
    } else {
      user.date_naissance = null;
    }
    
    // S'assurer que lieu_naissance est une string
    if (!user.lieu_naissance) {
      user.lieu_naissance = null;
    }
    
    // Ne pas retourner les informations sensibles
    delete user.password_hash;
    delete user.date_naissance_str;
    delete user.lieu_naissance_str;
    
    console.log('✅ Profil récupéré avec succès pour:', user.email);
    console.log('📋 Date de naissance:', user.date_naissance, 'Type:', typeof user.date_naissance);
    console.log('📋 Lieu de naissance:', user.lieu_naissance, 'Type:', typeof user.lieu_naissance);
    
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('❌ Erreur récupération profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du profil'
    });
  }
};

/**
 * Met à jour le profil de l'utilisateur
 */
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { civilite, nom, prenom, telephone, adresse, date_naissance, lieu_naissance, pays } = req.body;
    
    console.log('📝 Mise à jour du profil pour:', userId);
    
    const query = `
      UPDATE users 
      SET civilite = $1,
          nom = $2,
          prenom = $3,
          telephone = $4,
          adresse = $5,
          date_naissance = $6,
          lieu_naissance = $7,
          pays = $8,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $9
      RETURNING id, civilite, nom, prenom, email, telephone, 
                date_naissance, lieu_naissance, adresse, pays,
                photo_url, role, code_apporteur
    `;
    
    const values = [civilite, nom, prenom, telephone, adresse, date_naissance, lieu_naissance, pays, userId];
    
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    console.log('✅ Profil mis à jour avec succès');
    
    res.json({
      success: true,
      message: 'Profil mis à jour avec succès',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour profil:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la mise à jour du profil'
    });
  }
};

/**
 * Vérifie et retourne les données utilisateur (notamment date_naissance et lieu_naissance)
 * Utile pour déboguer les problèmes de récupération de données
 */
exports.checkUserData = async (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log('🔍 Vérification des données utilisateur pour ID:', userId);
    
    // Requête SQL pour vérifier toutes les données, y compris les valeurs NULL
    const query = `
      SELECT 
        id,
        email,
        nom,
        prenom,
        date_naissance,
        lieu_naissance,
        telephone,
        adresse,
        -- Vérifier si les champs sont NULL
        date_naissance IS NULL as date_naissance_is_null,
        lieu_naissance IS NULL as lieu_naissance_is_null,
        -- Convertir en différents formats pour test
        date_naissance::text as date_naissance_text,
        date_naissance::date as date_naissance_date,
        TO_CHAR(date_naissance, 'YYYY-MM-DD') as date_naissance_formatted
      FROM users 
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    const userData = result.rows[0];
    
    console.log('📋 Données récupérées:', {
      id: userData.id,
      email: userData.email,
      date_naissance: userData.date_naissance,
      date_naissance_is_null: userData.date_naissance_is_null,
      date_naissance_text: userData.date_naissance_text,
      date_naissance_formatted: userData.date_naissance_formatted,
      lieu_naissance: userData.lieu_naissance,
      lieu_naissance_is_null: userData.lieu_naissance_is_null
    });
    
    res.json({
      success: true,
      message: 'Données utilisateur récupérées',
      data: {
        id: userData.id,
        email: userData.email,
        nom: userData.nom,
        prenom: userData.prenom,
        date_naissance: userData.date_naissance,
        date_naissance_is_null: userData.date_naissance_is_null,
        date_naissance_text: userData.date_naissance_text,
        date_naissance_formatted: userData.date_naissance_formatted,
        lieu_naissance: userData.lieu_naissance,
        lieu_naissance_is_null: userData.lieu_naissance_is_null,
        telephone: userData.telephone,
        adresse: userData.adresse
      }
    });
  } catch (error) {
    console.error('❌ Erreur vérification données utilisateur:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification des données',
      error: error.message
    });
  }
};

/**
 * Change le mot de passe de l'utilisateur
 */
exports.changePassword = async (req, res) => {
  try {
    const userId = req.user.id;
    const { oldPassword, newPassword } = req.body;
    
    console.log('🔐 Changement de mot de passe pour:', userId);
    
    // Validation
    if (!oldPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Ancien et nouveau mot de passe requis'
      });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le nouveau mot de passe doit contenir au moins 6 caractères'
      });
    }
    
    // Récupérer le hash actuel
    const userQuery = 'SELECT password_hash FROM users WHERE id = $1';
    const userResult = await pool.query(userQuery, [userId]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }
    
    const user = userResult.rows[0];
    
    // Vérifier l'ancien mot de passe
    const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
    
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Ancien mot de passe incorrect'
      });
    }
    
    // Hasher le nouveau mot de passe
    const newHashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Mettre à jour
    const updateQuery = `
      UPDATE users 
      SET password_hash = $1, updated_at = CURRENT_TIMESTAMP 
      WHERE id = $2
    `;
    
    await pool.query(updateQuery, [newHashedPassword, userId]);
    
    console.log('✅ Mot de passe changé avec succès');
    
    res.json({
      success: true,
      message: 'Mot de passe changé avec succès'
    });
  } catch (error) {
    console.error('❌ Erreur changement mot de passe:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors du changement de mot de passe'
    });
  }
};

/**
 * Configuration de multer pour l'upload de photos
 */
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/profiles';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + req.user.id + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB max
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Seules les images (jpeg, jpg, png, gif) sont autorisées'));
    }
  }
}).single('photo');

/**
 * Upload de la photo de profil
 */
exports.uploadPhoto = (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      console.error('❌ Erreur upload:', err);
      return res.status(400).json({
        success: false,
        message: err.message || 'Erreur lors de l\'upload'
      });
    }
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier fourni'
      });
    }
    
    try {
      const userId = req.user.id;
      const photoUrl = '/uploads/profiles/' + req.file.filename;
      
      console.log('📸 Upload photo pour utilisateur:', userId);
      console.log('📁 Fichier:', req.file.filename);
      
      // Récupérer l'ancienne photo pour la supprimer
      const oldPhotoQuery = 'SELECT photo_url FROM users WHERE id = $1';
      const oldPhotoResult = await pool.query(oldPhotoQuery, [userId]);
      
      if (oldPhotoResult.rows.length > 0 && oldPhotoResult.rows[0].photo_url) {
        const oldPhotoPath = '.' + oldPhotoResult.rows[0].photo_url;
        if (fs.existsSync(oldPhotoPath)) {
          fs.unlinkSync(oldPhotoPath);
          console.log('🗑️ Ancienne photo supprimée');
        }
      }
      
      // Mettre à jour l'URL de la photo
      const updateQuery = `
        UPDATE users 
        SET photo_url = $1, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $2
        RETURNING photo_url
      `;
      
      const result = await pool.query(updateQuery, [photoUrl, userId]);
      
      console.log('✅ Photo uploadée avec succès');
      
      res.json({
        success: true,
        message: 'Photo uploadée avec succès',
        data: {
          photo_url: result.rows[0].photo_url
        }
      });
    } catch (error) {
      console.error('❌ Erreur lors de l\'enregistrement de la photo:', error);
      
      // Supprimer le fichier uploadé en cas d'erreur
      if (req.file) {
        fs.unlinkSync(req.file.path);
      }
      
      res.status(500).json({
        success: false,
        message: 'Erreur lors de l\'enregistrement de la photo'
      });
    }
  });
};

