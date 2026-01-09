const fs = require('fs');

const file = 'mycoris-master/routes/adminRoutes.js';
let content = fs.readFileSync(file, 'utf-8');

// Corriger la destructuration manquante de virgule et statut
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

fs.writeFileSync(file, content, 'utf-8');
console.log('✅ adminRoutes.js corrigé - virgule et statut supprimé');
