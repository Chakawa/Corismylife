const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'dashboard-admin/src/pages/SubscriptionsPage.jsx');
let content = fs.readFileSync(filePath, 'utf8');

const replacements = [
  // Statuts
  [/'en_attente'/g, "'proposition'"],
  [/'approuvé'/g, "'contrat'"],
  [/'rejeté'/g, "'annulé'"],
  [/"approuve"/g, '"contrat"'],
  [/"rejete"/g, '"annulé"'],
  
  // Colonnes dans la table
  [/{sub\.nom_client} {sub\.prenom_client}/g, '{sub.creator_prenom} {sub.creator_nom}'],
  [/{sub\.email}/g, '{sub.creator_email}'],
  [/{sub\.produit}/g, '{sub.produit_nom}'],
  [/sub\.email/g, 'sub.creator_email'],
  [/sub\.nom_client/g, 'sub.creator_prenom'],
  [/sub\.prenom_client/g, 'sub.creator_nom'],
  [/sub\.produit/g, 'sub.produit_nom'],
  
  // Stats
  ['Approuvées', 'Contrats'],
  ['Rejetées', 'Annulées'],
  ['En attente', 'Propositions'],
];

replacements.forEach(([from, to]) => {
  content = content.replace(from, to);
});

fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ SubscriptionsPage.jsx corrigé');
