/**
 * SCRIPT DE TEST - SIGNATURE
 * 
 * Ce script teste la fonctionnalité de signature:
 * 1. Décode une signature base64
 * 2. Sauvegarde l'image
 * 3. Vérifie que le fichier existe
 */

const fs = require('fs');
const path = require('path');

// Signature de test en base64 (petit carré noir)
const testSignatureBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC';

function testSignatureSave() {
  console.log('🧪 Test de sauvegarde de signature...\n');

  try {
    // 1. Créer le dossier si nécessaire
    const signaturesDir = path.join(process.cwd(), 'uploads', 'signatures');
    if (!fs.existsSync(signaturesDir)) {
      fs.mkdirSync(signaturesDir, { recursive: true });
      console.log('✅ Dossier créé:', signaturesDir);
    } else {
      console.log('✅ Dossier existe:', signaturesDir);
    }

    // 2. Décoder la signature
    const signatureBuffer = Buffer.from(testSignatureBase64, 'base64');
    console.log('✅ Signature décodée:', signatureBuffer.length, 'bytes');

    // 3. Sauvegarder
    const testFilename = `signature_TEST-2026-00001_${Date.now()}.png`;
    const testPath = path.join(signaturesDir, testFilename);
    fs.writeFileSync(testPath, signatureBuffer);
    console.log('✅ Signature sauvegardée:', testPath);

    // 4. Vérifier existence
    if (fs.existsSync(testPath)) {
      const stats = fs.statSync(testPath);
      console.log('✅ Fichier vérifié:', stats.size, 'bytes');
      console.log('\n🎉 TEST RÉUSSI!\n');
      
      // Nettoyer le fichier de test
      fs.unlinkSync(testPath);
      console.log('🧹 Fichier de test supprimé');
    } else {
      console.log('❌ Fichier introuvable!');
    }

  } catch (error) {
    console.error('❌ ERREUR:', error.message);
    console.error(error.stack);
  }
}

// Exécuter le test
testSignatureSave();
