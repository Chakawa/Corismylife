const express = require('express');
const router = express.Router();
const produitController = require('../controllers/produitController');

// IMPORTANT : Les routes spécifiques doivent être AVANT les routes avec paramètres
// Routes pour les tarifs (doivent être avant /:id)
router.get('/tarifs', produitController.getTarifsByProduit);
router.get('/tarifs/search', produitController.searchTarifs);
router.post('/tarifs', produitController.createTarif);
router.post('/tarifs/batch', produitController.createTarifsBatch);

// Routes pour les produits
router.get('/', produitController.getAllProduits);
router.post('/', produitController.createProduit);
router.get('/:id', produitController.getProduitById);

module.exports = router;

