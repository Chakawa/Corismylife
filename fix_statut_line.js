const fs = require('fs');
const path = require('path');

const filePath = 'mycoris-master/routes/adminRoutes.js';
let lines = fs.readFileSync(filePath, 'utf-8').split('\n');

// Trouver et supprimer la ligne "statut" à la ligne 841
const newLines = [];
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  const trimmed = line.trim();
  
  // Si c'est la ligne "statut" ET que la ligne précédente c'est code_apporteur, saute-la
  if (trimmed === 'statut' && i > 0 && newLines[newLines.length - 1].trim() === 'code_apporteur') {
    // Ne pas ajouter cette ligne
    continue;
  }
  newLines.push(line);
}

fs.writeFileSync(filePath, newLines.join('\n'), 'utf-8');
console.log('✅ Ligne statut supprimée');
