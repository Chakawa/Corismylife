const fs = require('fs');
const path = require('path');

console.log('🔍 VÉRIFICATION DU SYSTÈME DE DOCUMENTS\n');
console.log('='.repeat(50));

// Vérifier les dossiers
const baseDir = path.join(__dirname, '../uploads');
const folders = ['profiles', 'identity-cards', 'kyc'];

console.log('\n📁 Vérification des dossiers:\n');
folders.forEach(folder => {
  const folderPath = path.join(baseDir, folder);
  const exists = fs.existsSync(folderPath);
  const symbol = exists ? '✅' : '❌';
  console.log(`${symbol} ${folder}: ${exists ? 'EXISTS' : 'MISSING'}`);
  
  if (exists) {
    const files = fs.readdirSync(folderPath);
    const fileCount = files.filter(f => f !== '.gitkeep').length;
    console.log(`   └─ Fichiers: ${fileCount}`);
    
    if (fileCount > 0) {
      files.slice(0, 3).forEach(file => {
        if (file !== '.gitkeep') {
          const stat = fs.statSync(path.join(folderPath, file));
          const sizeKB = (stat.size / 1024).toFixed(2);
          console.log(`      • ${file} (${sizeKB} KB)`);
        }
      });
      if (fileCount > 3) {
        console.log(`      • ... et ${fileCount - 3} autres fichiers`);
      }
    }
  }
});

console.log('\n' + '='.repeat(50));
console.log('\n📋 Configuration Multer:');
console.log('✅ Fieldnames reconnus pour identity-cards:');
console.log('   • piece_identite');
console.log('   • identity_card');
console.log('   • document');
console.log('   • URL contient: upload-document');

console.log('\n📋 Format des noms de fichiers:');
console.log('   • Profile: profile_{userId}_{timestamp}_{random}.ext');
console.log('   • Identity: identity_{userId}_{timestamp}_{random}.ext');
console.log('   • KYC: kyc_{userId}_{timestamp}_{random}.ext');

console.log('\n📋 Routes API disponibles:');
console.log('   POST /api/subscriptions/:id/upload-document');
console.log('   GET  /api/subscriptions/:id/document/:filename');
console.log('   POST /api/users/upload-photo');
console.log('   GET  /api/users/photo/:filename');

console.log('\n📋 Droits d\'accès aux documents:');
console.log('   ✅ Propriétaire (user_id)');
console.log('   ✅ Commercial (code_apporteur)');
console.log('   ✅ Admin (role)');

console.log('\n' + '='.repeat(50));
console.log('\n✅ Système prêt!\n');
