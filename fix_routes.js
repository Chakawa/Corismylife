const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'mycoris-master/routes/adminRoutes.js');
let content = fs.readFileSync(filePath, 'utf8');

// Corriger la virgule manquante
content = content.replace(
  `const {
      user_id,
      produit_nom,
      souscriptiondata,
      code_apporteur
      statut
    } = req.body;`,
  `const {
      user_id,
      produit_nom,
      souscriptiondata,
      code_apporteur
    } = req.body;`
);

fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ adminRoutes.js - virgule corrigée et statut supprimé');
