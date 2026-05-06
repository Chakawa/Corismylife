const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Créer les dossiers uploads s'ils n'existent pas
const baseUploadDir = path.join(__dirname, '../uploads');
const uploadDirs = {
  profiles: path.join(baseUploadDir, 'profiles'),
  identityCards: path.join(baseUploadDir, 'identity-cards'),
  kyc: path.join(baseUploadDir, 'kyc')
};

// Extensions acceptees pour tous les flux documents/images pilotes par Multer.
// Le frontend normalise ensuite les photos sensibles en JPEG pour eviter les
// differences de format entre Android, iPhone et fichiers importes.
const allowedDocumentExtensions = new Set([
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.heic',
  '.heif',
  '.bmp',
  '.pdf'
]);

function sanitizeFileComponent(value) {
  const normalized = String(value || '')
    .trim()
    .replace(/[^a-zA-Z0-9_-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');

  return normalized || 'document';
}

// Essaie d'abord l'extension d'origine puis retombe sur le MIME si l'appareil
// n'envoie pas un nom de fichier exploitable.
function resolveExtension(file) {
  const originalExt = path.extname(file.originalname || '').toLowerCase();
  if (originalExt) {
    return originalExt;
  }

  const mime = String(file.mimetype || '').toLowerCase();
  if (mime === 'application/pdf') return '.pdf';
  if (mime === 'image/png') return '.png';
  if (mime === 'image/gif') return '.gif';
  if (mime === 'image/webp') return '.webp';
  if (mime === 'image/heic') return '.heic';
  if (mime === 'image/heif' || mime === 'image/heif-sequence') return '.heif';
  if (mime.startsWith('image/')) return '.jpg';
  return '.bin';
}

// Unifie les regles d'acceptation pour les photos de profil et les documents.
// Les iPhone envoient parfois `application/octet-stream` avec une extension
// correcte, d'ou le fallback sur l'extension.
function isAllowedDocument(file) {
  const mime = String(file.mimetype || '').toLowerCase();
  const ext = resolveExtension(file);

  if (mime === 'application/pdf' && ext === '.pdf') {
    return true;
  }

  if (mime.startsWith('image/') && allowedDocumentExtensions.has(ext)) {
    return true;
  }

  if (mime === 'application/octet-stream' && allowedDocumentExtensions.has(ext)) {
    return true;
  }

  return false;
}

// Créer tous les dossiers nécessaires
Object.values(uploadDirs).forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    console.log(`✅ Dossier créé: ${dir}`);
  }
});

// Configuration du storage avec sous-dossiers dynamiques
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Le choix du dossier depend de la route et du champ multipart afin que
    // toutes les API partagent un seul point de regle pour l'upload.
    let uploadPath = baseUploadDir;
    
    if (file.fieldname === 'profile_photo' || req.path.includes('upload-photo')) {
      uploadPath = uploadDirs.profiles;
    } else if (file.fieldname === 'piece_identite' || file.fieldname === 'identity_card' || file.fieldname === 'document' || req.path.includes('upload-document')) {
      uploadPath = uploadDirs.identityCards;
    } else if (file.fieldname.startsWith('kyc_')) {
      uploadPath = uploadDirs.kyc;
    }
    
    console.log('📂 Destination upload:', uploadPath);
    console.log('📝 Field name:', file.fieldname);
    
    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    // Le nom genere contient assez d'information pour retrouver le fichier
    // meme apres migration, reupload ou relecture differente du backend.
    const userId = req.user?.id || 'unknown';
    const subscriptionId = req.params?.id || 'unknown';
    const timestamp = Date.now();
    const random = Math.round(Math.random() * 1E9);
    const ext = resolveExtension(file);
    const safeOriginalStem = sanitizeFileComponent(path.basename(file.originalname || 'document', path.extname(file.originalname || '')));
    
    let prefix = 'doc';
    if (file.fieldname === 'profile_photo' || req.path.includes('upload-photo')) {
      prefix = `profile_${userId}`;
    } else if (file.fieldname === 'piece_identite' || file.fieldname === 'identity_card' || file.fieldname === 'document') {
      prefix = `identity_${subscriptionId}_${userId}`;
    } else if (file.fieldname.startsWith('kyc_')) {
      prefix = `kyc_${userId}`;
    }
    
    const filename = `${prefix}_${safeOriginalStem}_${timestamp}_${random}${ext}`;
    console.log('✅ Nom de fichier généré:', filename);
    cb(null, filename);
  }
});

const fileFilter = (req, file, cb) => {
  // Accepter les PDF et les formats image courants fournis par les appareils mobiles.
  const allowedMimes = ['application/pdf', 'image/*'];
  
  console.log('🔍 FileFilter - Fichier reçu:', file.originalname);
  console.log('🔍 FileFilter - MIME type reçu:', file.mimetype);
  console.log('🔍 FileFilter - MIME types autorisés:', allowedMimes);

  if (isAllowedDocument(file)) {
    console.log('✅ FileFilter - Fichier accepté');
    cb(null, true);
  } else {
    console.log('❌ FileFilter - Fichier rejeté, MIME type non autorisé:', file.mimetype);
    cb(new Error('Format non autorisé. Utilisez un PDF ou une image compatible (JPG, PNG, WEBP, HEIC).'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB max
  }
});

module.exports = upload;