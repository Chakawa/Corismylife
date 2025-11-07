/// ============================================
/// ROUTES UTILISATEUR
/// ============================================
/// Définit toutes les routes relatives aux utilisateurs :
/// - GET /api/users/profile : Récupérer le profil utilisateur
/// - PUT /api/users/profile : Modifier le profil utilisateur
/// - POST /api/users/upload-photo : Télécharger une photo de profil
/// - PUT /api/users/change-password : Changer le mot de passe
/// ============================================

const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middleware/auth');
// Upload géré dans le contrôleur (multer interne)

// (plus de configuration multer ici)

/// ============================================
/// ROUTES PROTÉGÉES (NÉCESSITENT UN TOKEN)
/// ============================================

/**
 * GET /api/users/profile
 * Récupère le profil de l'utilisateur connecté
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: { id, civilite, nom, prenom, email, ... } }
 */
router.get('/profile', verifyToken, userController.getProfile);

/**
 * PUT /api/users/profile
 * Met à jour le profil de l'utilisateur connecté
 * Headers : Authorization: Bearer <token>
 * Body : { civilite?, nom?, prenom?, telephone?, adresse? }
 * Retour : { success: true, message: "Profil mis à jour", data: {...} }
 */
router.put('/profile', verifyToken, userController.updateProfile);

/**
 * POST /api/users/upload-photo
 * Télécharge une photo de profil pour l'utilisateur connecté
 * Headers : Authorization: Bearer <token>
 * Body (multipart/form-data) : profile_photo: <File>
 * Retour : { success: true, message: "Photo uploadée", photo_url: "/uploads/profiles/..." }
 */
router.post('/upload-photo', verifyToken, userController.uploadPhoto);

/**
 * PUT /api/users/change-password
 * Change le mot de passe de l'utilisateur connecté
 * Headers : Authorization: Bearer <token>
 * Body : { currentPassword: string, newPassword: string }
 * Retour : { success: true, message: "Mot de passe changé" }
 */
router.put('/change-password', verifyToken, userController.changePassword);

/**
 * GET /api/users/check-data
 * Vérifie et retourne les données de l'utilisateur (notamment date_naissance et lieu_naissance)
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: { date_naissance, lieu_naissance, ... } }
 */
router.get('/check-data', verifyToken, userController.checkUserData);

module.exports = router;
