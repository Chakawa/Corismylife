/**
 * ===============================================
 * ROUTES DES CONTRATS
 * ===============================================
 * 
 * Définit les routes pour la gestion des contrats
 */

const express = require('express');
const router = express.Router();
const contratController = require('../controllers/contratController');
const { verifyToken } = require('../middleware/auth');

// ✅ Toutes les routes nécessitent une authentification
router.use(verifyToken);

/**
 * GET /api/contrats/mes-contrats
 * Récupère les contrats de l'utilisateur connecté
 * - Commercial: via code_apporteur
 * - Client: via numéro de téléphone
 */
router.get('/mes-contrats', contratController.getMesContrats);

/**
 * GET /api/contrats/client/:telephone
 * Récupère tous les contrats d'un client via son téléphone
 * Accessible par: Admin, Commercial (si c'est son client)
 */
router.get('/client/:telephone', contratController.getContratsByTelephone);

/**
 * GET /api/contrats/commercial/:codeappo
 * Récupère tous les contrats d'un commercial via son code apporteur
 * Accessible par: Admin, Commercial (ses propres contrats)
 */
router.get('/commercial/:codeappo', contratController.getContratsByCodeApporteur);

/**
 * GET /api/contrats/:id
 * Récupère les détails complets d'un contrat
 * Contrôle d'accès:
 * - Admin: tous les contrats
 * - Commercial: ses contrats (via codeappo)
 * - Client: ses contrats (via téléphone)
 */
router.get('/:id', contratController.getContratDetails);

module.exports = router;
