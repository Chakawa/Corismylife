const express = require('express');
const path = require('path');
const fs = require('fs');
const router = express.Router();

// Servir les fichiers statiques du dossier uploads
router.use('/', express.static(path.join(__dirname, '../uploads')));

module.exports = router;