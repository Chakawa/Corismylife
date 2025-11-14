const fs = require('fs');
const path = require('path');

/**
 * Script pour extraire les données FLEX EMPRUNTEUR du fichier Dart
 * et les convertir en JSON pour la migration
 */

const dartFilePath = path.join(__dirname, '../../mycorislife-master/lib/features/simulation/presentation/screens/flex_emprunteur_page.dart');
const outputPath = path.join(__dirname, 'data/flex_emprunteur_data.json');

console.log('🔍 Extraction des données FLEX EMPRUNTEUR...\n');
console.log(`📄 Fichier source: ${dartFilePath}`);
console.log(`📦 Fichier de sortie: ${outputPath}\n`);

// Lire le fichier Dart
const dartContent = fs.readFileSync(dartFilePath, 'utf-8');

// Extraire tarifsPretAmortissable
console.log('📊 Extraction de tarifsPretAmortissable...');
const amortissableMatch = dartContent.match(/final Map<String, double> tarifsPretAmortissable = \{([\s\S]*?)\};/);
if (!amortissableMatch) {
  console.error('❌ Impossible de trouver tarifsPretAmortissable');
  process.exit(1);
}

const tarifsPretAmortissable = {};
const amortissableContent = amortissableMatch[1];
// Parser les entrées au format 'age_duree': valeur
const amortissableEntries = amortissableContent.matchAll(/'(\d+)_(\d+)':\s*([\d.]+)/g);
for (const match of amortissableEntries) {
  const key = `${match[1]}_${match[2]}`;
  const value = parseFloat(match[3]);
  tarifsPretAmortissable[key] = value;
}
console.log(`   ✅ ${Object.keys(tarifsPretAmortissable).length} tarifs extraits`);

// Extraire tarifsPretDecouvert
console.log('📊 Extraction de tarifsPretDecouvert...');
const decouvertMatch = dartContent.match(/final Map<String, double> tarifsPretDecouvert = \{([\s\S]*?)\};/);
if (!decouvertMatch) {
  console.error('❌ Impossible de trouver tarifsPretDecouvert');
  process.exit(1);
}

const tarifsPretDecouvert = {};
const decouvertContent = decouvertMatch[1];
const decouvertEntries = decouvertContent.matchAll(/'(\d+)_(\d+)':\s*([\d.]+)/g);
for (const match of decouvertEntries) {
  const key = `${match[1]}_${match[2]}`;
  const value = parseFloat(match[3]);
  tarifsPretDecouvert[key] = value;
}
console.log(`   ✅ ${Object.keys(tarifsPretDecouvert).length} tarifs extraits`);

// Extraire tarifsPerteEmploi
console.log('📊 Extraction de tarifsPerteEmploi...');
const perteEmploiMatch = dartContent.match(/final Map<String, double> tarifsPerteEmploi = \{([\s\S]*?)\};/);
if (!perteEmploiMatch) {
  console.error('❌ Impossible de trouver tarifsPerteEmploi');
  process.exit(1);
}

const tarifsPerteEmploi = {};
const perteEmploiContent = perteEmploiMatch[1];
const perteEmploiEntries = perteEmploiContent.matchAll(/'(\d+)':\s*([\d.]+)/g);
for (const match of perteEmploiEntries) {
  const key = match[1];
  const value = parseFloat(match[2]);
  tarifsPerteEmploi[key] = value;
}
console.log(`   ✅ ${Object.keys(tarifsPerteEmploi).length} tarifs extraits`);

// Créer l'objet JSON final
const jsonData = {
  tarifsPretAmortissable,
  tarifsPretDecouvert,
  tarifsPerteEmploi,
};

// S'assurer que le dossier data existe
const dataDir = path.dirname(outputPath);
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Écrire le fichier JSON
fs.writeFileSync(outputPath, JSON.stringify(jsonData, null, 2), 'utf-8');

console.log('\n✅ Extraction terminée avec succès !');
console.log(`📦 Fichier créé: ${outputPath}`);
console.log(`\n📊 Résumé:`);
console.log(`   - Prêt Amortissable: ${Object.keys(tarifsPretAmortissable).length} tarifs`);
console.log(`   - Prêt Découvert: ${Object.keys(tarifsPretDecouvert).length} tarifs`);
console.log(`   - Perte d'Emploi: ${Object.keys(tarifsPerteEmploi).length} tarifs`);
console.log(`\n💡 Vous pouvez maintenant exécuter le script de migration !`);










