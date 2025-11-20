#!/usr/bin/env node

/**
 * Script de configuration des dossiers d'upload
 * Crée la structure de dossiers nécessaire pour stocker les fichiers
 */

const fs = require('fs');
const path = require('path');

// Définir les dossiers à créer
const baseDir = path.join(__dirname, '../uploads');
const folders = [
  'profiles',        // Photos de profil
  'identity-cards',  // Pièces d'identité
  'kyc',            // Documents KYC
];

console.log('🚀 Configuration des dossiers d\'upload...\n');

// Créer le dossier de base
if (!fs.existsSync(baseDir)) {
  fs.mkdirSync(baseDir, { recursive: true });
  console.log('✅ Dossier de base créé:', baseDir);
} else {
  console.log('ℹ️  Dossier de base existe déjà:', baseDir);
}

// Créer tous les sous-dossiers
folders.forEach(folder => {
  const folderPath = path.join(baseDir, folder);
  if (!fs.existsSync(folderPath)) {
    fs.mkdirSync(folderPath, { recursive: true });
    console.log('✅ Dossier créé:', folderPath);
  } else {
    console.log('ℹ️  Dossier existe déjà:', folderPath);
  }
});

// Créer un fichier .gitkeep dans chaque dossier pour le versioning
folders.forEach(folder => {
  const gitkeepPath = path.join(baseDir, folder, '.gitkeep');
  if (!fs.existsSync(gitkeepPath)) {
    fs.writeFileSync(gitkeepPath, '');
    console.log('📝 .gitkeep créé dans:', folder);
  }
});

console.log('\n✅ Configuration terminée avec succès!');
console.log('\n📁 Structure créée:');
console.log('uploads/');
folders.forEach(folder => {
  console.log(`  ├── ${folder}/`);
});
