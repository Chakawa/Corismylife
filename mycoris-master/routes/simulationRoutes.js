const express = require('express');
const router = express.Router();
const simulationController = require('../controllers/simulationController');
const { verifyToken, optionalAuth } = require('../middleware/auth');

/**
 * @route POST /api/simulations
 * @desc Enregistrer une nouvelle simulation (avec ou sans authentification)
 * @access Public
 */
router.post('/', optionalAuth, simulationController.saveSimulation);

/**
 * @route GET /api/simulations
 * @desc Récupérer toutes les simulations (Admin seulement)
 * @access Private/Admin
 */
router.get('/', verifyToken, simulationController.getAllSimulations);

/**
 * @route GET /api/simulations/stats
 * @desc Obtenir les statistiques des simulations (Admin seulement)
 * @access Private/Admin
 */
router.get('/stats', verifyToken, simulationController.getSimulationStats);

/**
 * @route GET /api/simulations/user
 * @desc Récupérer les simulations de l'utilisateur connecté
 * @access Private
 */
router.get('/user', verifyToken, simulationController.getUserSimulations);

module.exports = router;
