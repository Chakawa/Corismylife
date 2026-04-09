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
    // Déterminer le sous-dossier selon le type de fichier
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
    // Générer un nom unique avec préfixe selon le type
    const userId = req.user?.id || 'unknown';
    const timestamp = Date.now();
    const random = Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    
    let prefix = 'doc';
    if (file.fieldname === 'profile_photo' || req.path.includes('upload-photo')) {
      prefix = `profile_${userId}`;
    } else if (file.fieldname === 'piece_identite' || file.fieldname === 'identity_card' || file.fieldname === 'document') {
      prefix = `identity_${userId}`;
    } else if (file.fieldname.startsWith('kyc_')) {
      prefix = `kyc_${userId}`;
    }
    
    const filename = `${prefix}_${timestamp}_${random}${ext}`;
    console.log('✅ Nom de fichier généré:', filename);
    cb(null, filename);
  }
});

const fileFilter = (req, file, cb) => {
  // Accepter seulement les images et PDF
  const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'application/pdf'];
  
  console.log('🔍 FileFilter - Fichier reçu:', file.originalname);
  console.log('🔍 FileFilter - MIME type reçu:', file.mimetype);
  console.log('🔍 FileFilter - MIME types autorisés:', allowedMimes);
  
  // Normaliser les MIME types alternatifs (HEIC/HEIF iPhone, WEBP)
  const normalizedMime = file.mimetype
    .replace('image/heif-sequence', 'image/heic')
    .replace('image/heif', 'image/heic')
    .replace('image/heic', 'image/jpeg'); // Accepter HEIC comme JPEG

  const extendedAllowedMimes = [...allowedMimes, 'image/heic', 'image/heif', 'image/heif-sequence', 'image/webp'];

  if (extendedAllowedMimes.includes(file.mimetype) || extendedAllowedMimes.includes(normalizedMime)) {
    console.log('✅ FileFilter - Fichier accepté');
    cb(null, true);
  } else {
    console.log('❌ FileFilter - Fichier rejeté, MIME type non autorisé:', file.mimetype);
    cb(new Error('Format non autorisé. Seuls les images (JPEG, PNG, GIF, HEIC, WEBP) et PDF sont acceptés.'), false);
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