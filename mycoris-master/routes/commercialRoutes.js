/// ============================================
/// ROUTES COMMERCIAL
/// ============================================
/// Définit toutes les routes relatives aux commerciaux :
/// - GET /api/commercial/stats : Statistiques du commercial
/// - GET /api/commercial/clients : Liste des clients
/// - POST /api/commercial/clients : Créer un client
/// - GET /api/commercial/subscriptions : Souscriptions des clients
/// - GET /api/commercial/commissions : Commissions du commercial
/// ============================================

const express = require('express');
const router = express.Router();
const commercialController = require('../controllers/commercialController');
const { verifyToken } = require('../middleware/auth');

/// ============================================
/// ROUTES PROTÉGÉES (NÉCESSITENT UN TOKEN)
/// ============================================

/**
 * GET /api/commercial/stats
 * Récupère les statistiques du commercial connecté
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: { nbClients, nbContrats, nbPropositions, codeApporteur } }
 */
router.get('/stats', verifyToken, commercialController.getCommercialStats);

/**
 * GET /api/commercial/clients
 * Récupère la liste des clients du commercial
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: [{ id, nom, prenom, email, ... }] }
 */
router.get('/clients', verifyToken, commercialController.getCommercialClients);

/**
 * POST /api/commercial/clients
 * Crée un nouveau client avec le code apporteur du commercial
 * Headers : Authorization: Bearer <token>
 * Body : { email, password, nom, prenom, civilite, telephone, date_naissance, lieu_naissance, adresse, pays }
 * Retour : { success: true, message: "Client créé avec succès", data: {...} }
 */
router.post('/clients', verifyToken, commercialController.createClient);

/**
 * GET /api/commercial/subscriptions
 * Récupère les souscriptions des clients du commercial
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: [{ id, numero_police, produit_nom, statut, ... }] }
 */
router.get('/subscriptions', verifyToken, commercialController.getCommercialSubscriptions);

/**
 * GET /api/commercial/clients-with-subscriptions
 * Récupère la liste unique des clients qui ont des souscriptions
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: [{ nom, prenom, email, telephone, ... }] }
 */
router.get('/clients-with-subscriptions', verifyToken, commercialController.getClientsWithSubscriptions);

/**
 * GET /api/commercial/commissions
 * Récupère les commissions du commercial
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, data: [{ id, numero_police, commission, ... }] }
 */
router.get('/commissions', verifyToken, commercialController.getCommercialCommissions);

module.exports = router;


