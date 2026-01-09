const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'dashboard-admin', 'src', 'pages', 'SubscriptionsPage.jsx');
let content = fs.readFileSync(filePath, 'utf8');

// Fix 1: Ajouter max-h-[90vh] flex flex-col au container du modal
content = content.replace(
  '<div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4">',
  '<div className="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 max-h-[90vh] flex flex-col">'
);

// Fix 2: Ajouter flex-shrink-0 au header du modal
content = content.replace(
  '<div className="flex justify-between items-center p-6 border-b">',
  '<div className="flex justify-between items-center p-6 border-b flex-shrink-0">'
);

// Fix 3: Ajouter overflow-y-auto flex-1 au div contenant les champs du formulaire (payment modal)
// Chercher le div qui contient les infos de souscription et les champs de paiement
content = content.replace(
  /(<h2 className="text-lg font-semibold text-gray-900">Encaisser et passer en contrat<\/h2>[\s\S]*?<\/div>\s*<\/div>\s*)<div className="p-6 space-y-4">/,
  '$1<div className="p-6 space-y-4 overflow-y-auto flex-1">'
);

fs.writeFileSync(filePath, content, 'utf8');
console.log('✅ Modal de paiement - scroll interne ajouté (max-h-[90vh])');
