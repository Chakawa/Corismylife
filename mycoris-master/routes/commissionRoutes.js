/**
 * ===============================================
 * ROUTES DES COMMISSIONS (SIMPLIFIÉES)
 * ===============================================
 * 
 * Définit les routes pour la gestion simple des commissions:
 * - Ajout direct d'une commission
 * - Récupération des commissions d'un commercial
 * - Résumé rapide
 * - Récupération/Suppression par ID
 */

const express = require('express');
const router = express.Router();
const commissionController = require('../controllers/commissionController');
const { verifyToken } = require('../middleware/auth');

// ✅ Toutes les routes nécessitent une authentification
router.use(verifyToken);

// Ajouter une commission
// POST /api/commissions/ajouter
router.post('/ajouter', commissionController.ajouterCommission);

// Récupérer toutes les commissions d'un commercial
// GET /api/commissions/commercial/:code_apporteur
router.get('/commercial/:code_apporteur', commissionController.getCommissionsCommercial);

// Récupérer le résumé d'un commercial
// GET /api/commissions/resume/:code_apporteur
router.get('/resume/:code_apporteur', commissionController.getResumeCommissions);

// Récupérer une commission par ID
// GET /api/commissions/:commission_id
router.get('/:commission_id', commissionController.getCommissionById);

// Supprimer une commission
// DELETE /api/commissions/:commission_id
router.delete('/:commission_id', commissionController.deleteCommission);

module.exports = router;
