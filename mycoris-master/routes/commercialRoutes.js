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

/**
 * GET /api/commercial/mes_contrats_commercial
 * Récupère tous les contrats du commercial
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, contrats: [...] }
 */
router.get('/mes_contrats_commercial', verifyToken, commercialController.getMesContratsCommercial);

/**
 * GET /api/commercial/liste_clients
 * Récupère la liste des clients du commercial
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, clients: [...] }
 */
router.get('/liste_clients', verifyToken, commercialController.getListeClients);

/**
 * GET /api/commercial/contrats_actifs
 * Récupère les contrats actifs du commercial
 * Headers : Authorization: Bearer <token>
 * Retour : { success: true, contrats: [...] }
 */
router.get('/contrats_actifs', verifyToken, commercialController.getContratsActifs);

/**
 * GET /api/commercial/details_client/:clientId
 * Récupère les détails d'un client
 * Headers : Authorization: Bearer <token>
 * Params : clientId (int)
 * Retour : { success: true, client: {...}, contrats: [...] }
 */
router.get('/details_client/:clientId', verifyToken, commercialController.getDetailsClient);

/**
 * GET /api/commercial/contrat_details/:numepoli
 * Récupère les détails d'un contrat
 * Headers : Authorization: Bearer <token>
 * Params : numepoli (string)
 * Retour : { success: true, contrat: {...} }
 */
router.get('/contrat_details/:numepoli', verifyToken, commercialController.getContratDetails);

module.exports = router;


