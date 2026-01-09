const fs = require('fs');

const file = 'dashboard-admin/src/pages/SubscriptionsPage.jsx';
let content = fs.readFileSync(file, 'utf-8');

// Corriger l'affichage du statut et le modal
const fixes = [
  // 1. Table scrollable
  { old: 'overflow-hidden">', new: 'overflow-hidden overflow-x-auto">' },
  
  // 2. Modal scrollable
  { old: 'max-w-md w-full mx-4">', new: 'max-w-md w-full mx-4 max-h-[90vh] flex flex-col">' },
  
  // 3. Form avec scroll
  { old: 'className="p-6 space-y-4">', new: 'className="p-6 space-y-4 overflow-y-auto flex-1">' },
];

fixes.forEach(fix => {
  content = content.replace(fix.old, fix.new);
});

fs.writeFileSync(file, content, 'utf-8');
console.log('✅ SubscriptionsPage - overflow + modal scrollable corrigé');
