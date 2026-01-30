/**
 * ===============================================
 * CONTRÔLEUR D'AUTHENTIFICATION
 * ===============================================
 * 
 * Ce fichier gère toutes les opérations d'authentification :
 * - Inscription des clients
 * - Inscription des commerciaux
 * - Connexion (par email OU téléphone)
 * - Détection automatique du rôle
 */

const bcrypt = require('bcrypt');  // Pour hasher les mots de passe
const jwt = require('jsonwebtoken');  // Pour créer les tokens JWT
const pool = require('../db');  // Connexion à la base de données PostgreSQL

/**
 * ===============================================
 * DÉTECTION AUTOMATIQUE DU RÔLE UTILISATEUR
 * ===============================================
 * 
 * Cette fonction détermine le rôle d'un utilisateur basé sur son email
 * 
 * @param {string} email - L'adresse email de l'utilisateur
 * @returns {string} Le rôle détecté : 'admin', 'commercial' ou 'client'
 * 
 * Règles de détection :
 * - Si l'email contient "adminvi25" → rôle = admin
 * - Si l'email contient "coriscomvi25" → rôle = commercial
 * - Sinon → rôle = client (par défaut)
 */
function detectUserRole(email) {
  // Convertir l'email en minuscules pour éviter les erreurs de casse
  email = email.toLowerCase();
  
  // Vérifier si c'est un admin
  if (email.includes('adminvi25')) return 'admin';
  
  // Vérifier si c'est un commercial
  if (email.includes('coriscomvi25')) return 'commercial';
  
  // Par défaut, c'est un client
  return 'client';
}

/**
 * ===============================================
 * VALIDATION DES DONNÉES UTILISATEUR
 * ===============================================
 * 
 * Vérifie que toutes les données requises sont présentes
 * et valides avant l'inscription
 * 
 * @param {object} userData - Les données de l'utilisateur à valider
 * @param {boolean} isCommercial - True si c'est un commercial, false sinon
 * @throws {Error} Si des données obligatoires sont manquantes
 */
function validateUserData(userData, isCommercial = false) {
  // Extraire les champs obligatoires
  const { email, password, nom, prenom, telephone } = userData;
  
  // Vérifier que tous les champs obligatoires sont remplis
  // L'email est optionnel pour les clients, obligatoire pour les commerciaux
  if (!password || !nom || !prenom || !telephone) {
    throw new Error('Tous les champs obligatoires doivent être remplis');
  }
  
  // Pour les commerciaux, l'email est obligatoire
  if (isCommercial && !email) {
    throw new Error('L\'email est obligatoire pour les commerciaux');
  }

  // Si c'est un commercial, le code apporteur est obligatoire
  if (isCommercial && !userData.code_apporteur) {
    throw new Error('Le code apporteur est obligatoire pour les commerciaux');
  }

  // Vérifier que l'email commercial contient bien "coriscomvi25"
  if (isCommercial && email) {
    const role = detectUserRole(email);
    if (role !== 'commercial') {
      throw new Error('L\'email commercial doit contenir "coriscomvi25"');
    }
  }
}

/**
 * ===============================================
 * VÉRIFICATION D'UNICITÉ DU TÉLÉPHONE
 * ===============================================
 * 
 * Vérifie si un numéro de téléphone existe déjà dans la base de données
 * 
 * @param {string} telephone - Le numéro de téléphone à vérifier
 * @returns {boolean} true si le téléphone existe déjà, false sinon
 */
async function checkPhoneExists(telephone) {
  const query = 'SELECT id FROM users WHERE telephone = $1';
  const result = await pool.query(query, [telephone]);
  return result.rows.length > 0;
}

/**
 * ===============================================
 * VÉRIFICATION D'UNICITÉ DE L'EMAIL
 * ===============================================
 * 
 * Vérifie si un email existe déjà dans la base de données
 * 
 * @param {string} email - L'email à vérifier
 * @returns {boolean} true si l'email existe déjà, false sinon
 */
async function checkEmailExists(email) {
  if (!email) return false; // Si pas d'email fourni, pas de problème
  const query = 'SELECT id FROM users WHERE email = $1';
  const result = await pool.query(query, [email]);
  return result.rows.length > 0;
}

/**
 * ===============================================
 * INSCRIPTION D'UN CLIENT
 * ===============================================
 * 
 * Crée un nouveau compte client dans la base de données
 * 
 * @param {object} userData - Les données du client
 * @param {string} userData.email - Email du client
 * @param {string} userData.password - Mot de passe du client
 * @param {string} userData.nom - Nom du client
 * @param {string} userData.prenom - Prénom du client
 * @param {string} userData.telephone - Téléphone du client
 * @param {string} userData.civilite - Civilité (M., Mme, etc.)
 * @param {string} userData.date_naissance - Date de naissance
 * @param {string} userData.lieu_naissance - Lieu de naissance
 * @param {string} userData.adresse - Adresse du client
 * @param {string} userData.pays - Pays du client
 * 
 * @returns {object} Les données du client créé (sans le mot de passe)
 * @throws {Error} Si la validation échoue, si le téléphone ou l'email existe déjà
 */
async function registerClient(userData) {
  // Valider les données avant de continuer
  validateUserData(userData);
  
  // Vérifier si le numéro de téléphone existe déjà
  const phoneExists = await checkPhoneExists(userData.telephone);
  if (phoneExists) {
    throw new Error('Ce numéro de téléphone est déjà utilisé pour un compte existant');
  }
  
  // Vérifier si l'email existe déjà (seulement si un email est fourni)
  if (userData.email) {
    const emailExists = await checkEmailExists(userData.email);
    if (emailExists) {
      throw new Error('Cet email est déjà attribué à un autre compte');
    }
  }
  
  // Détecter automatiquement le rôle basé sur l'email (ou 'client' par défaut)
  const role = userData.email ? detectUserRole(userData.email) : 'client';
  
  // Hasher le mot de passe (bcrypt avec 10 rounds de salage)
  // Ne JAMAIS stocker les mots de passe en clair !
  const passwordHash = await bcrypt.hash(userData.password, 10);
  
  // Requête SQL pour insérer le nouvel utilisateur
  const query = `
    INSERT INTO users (
      email, password_hash, role, nom, prenom, civilite, 
      date_naissance, lieu_naissance, telephone, adresse, pays
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    RETURNING id, email, nom, prenom, role
  `;
  
  // Valeurs à insérer (dans le même ordre que la requête)
  const values = [
    userData.email || null,  // $1 - Email peut être NULL
    passwordHash,            // $2 - Mot de passe hashé
    role,                    // $3 - Rôle détecté
    userData.nom,            // $4
    userData.prenom,         // $5
    userData.civilite,       // $6
    userData.date_naissance, // $7
    userData.lieu_naissance, // $8
    userData.telephone,      // $9
    userData.adresse,        // $10
    userData.pays            // $11
  ];
  
  // Exécuter la requête et récupérer le résultat
  const result = await pool.query(query, values);
  
  // Retourner les données du client créé (SANS le mot de passe)
  return result.rows[0];
}

/**
 * ===============================================
 * INSCRIPTION D'UN COMMERCIAL (ADMIN SEULEMENT)
 * ===============================================
 * 
 * Crée un nouveau compte commercial dans la base de données
 * Cette fonction doit être appelée uniquement par un administrateur
 * 
 * @param {object} userData - Les données du commercial
 * @param {string} userData.email - Email du commercial (doit contenir "coriscomvi25")
 * @param {string} userData.password - Mot de passe du commercial
 * @param {string} userData.nom - Nom du commercial
 * @param {string} userData.prenom - Prénom du commercial
 * @param {string} userData.telephone - Téléphone du commercial
 * @param {string} userData.civilite - Civilité
 * @param {string} userData.adresse - Adresse du commercial
 * @param {string} userData.pays - Pays du commercial
 * @param {string} userData.code_apporteur - Code apporteur unique
 * 
 * @returns {object} Les données du commercial créé
 * @throws {Error} Si la validation échoue
 */
async function registerCommercial(userData) {
  // Valider les données (avec vérification du code apporteur)
  validateUserData(userData, true);
  
  // Hasher le mot de passe
  const passwordHash = await bcrypt.hash(userData.password, 10);
  
  // Requête SQL pour insérer le commercial
  const query = `
    INSERT INTO users (
      email, password_hash, role, nom, prenom, civilite,
      telephone, adresse, pays, code_apporteur
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING id, email, nom, prenom, role, code_apporteur
  `;
  
  // Valeurs à insérer
  const values = [
    userData.email,          // $1
    passwordHash,            // $2
    'commercial',            // $3 - Rôle fixe pour les commerciaux
    userData.nom,            // $4
    userData.prenom,         // $5
    userData.civilite,       // $6
    userData.telephone,      // $7
    userData.adresse,        // $8
    userData.pays,           // $9
    userData.code_apporteur  // $10 - Code unique du commercial
  ];
  
  // Exécuter la requête
  const result = await pool.query(query, values);
  
  // Retourner les données du commercial créé
  return result.rows[0];
}

/**
 * ===============================================
 * CONNEXION UTILISATEUR
 * ===============================================
 * 
 * Permet à un utilisateur de se connecter avec son email OU son téléphone
 * 
 * @param {string} identifier - Email ou numéro de téléphone de l'utilisateur
 * @param {string} password - Mot de passe de l'utilisateur
 * 
 * @returns {object} Objet contenant le token JWT et les infos utilisateur
 * @returns {string} returns.token - Token JWT pour l'authentification
 * @returns {object} returns.user - Informations de l'utilisateur
 * 
 * @throws {Error} 'Utilisateur non trouvé' si l'identifiant n'existe pas
 * @throws {Error} 'Mot de passe incorrect' si le mot de passe est invalide
 * 
 * FONCTIONNEMENT :
 * 1. Détecte si l'identifiant est un email ou un téléphone
 * 2. Recherche l'utilisateur dans la base de données
 * 3. Vérifie le mot de passe
 * 4. Génère un token JWT
 * 5. Retourne le token et les informations utilisateur
 */
async function login(identifier, password) {
  console.log('🔐 Tentative de connexion avec:', identifier);
  
  // ============================================
  // ÉTAPE 1 : Déterminer le type d'identifiant
  // ============================================
  // Si l'identifiant contient "@", c'est un email
  // Sinon, c'est un numéro de téléphone
  const isEmail = identifier.includes('@');
  console.log('📧 Type d\'identifiant:', isEmail ? 'Email' : 'Téléphone');
  
  let query, searchValue;
  
  if (isEmail) {
    // Recherche par email
    query = 'SELECT * FROM users WHERE email = $1';
    searchValue = identifier;
  } else {
    // Recherche par téléphone - normaliser le numéro
    // Accepter les numéros avec ou sans +225
    const normalizedPhone = identifier.trim();
    
    // Rechercher avec le numéro exact OU avec/sans +225
    query = `SELECT * FROM users WHERE telephone = $1 
             OR telephone = $2 
             OR telephone = $3`;
    
    // Préparer les 3 variantes: original, avec +225, sans +225
    const withPrefix = normalizedPhone.startsWith('+225') ? normalizedPhone : '+225' + normalizedPhone.replace(/^\+225/, '');
    const withoutPrefix = normalizedPhone.replace(/^\+225/, '');
    
    searchValue = [normalizedPhone, withPrefix, withoutPrefix];
    console.log('📱 Recherche téléphone avec variantes:', searchValue);
  }
  
  // ============================================
  // ÉTAPE 2 : Rechercher l'utilisateur
  // ============================================
  console.log('🔍 Recherche de l\'utilisateur...');
  console.log('📝 Requête SQL:', query);
  console.log('📝 Paramètre de recherche:', isEmail ? identifier : searchValue);
  
  const result = isEmail 
    ? await pool.query(query, [searchValue])
    : await pool.query(query, searchValue);
  
  console.log('📊 Nombre de résultats trouvés:', result.rows.length);
  
  // Si aucun utilisateur trouvé, retourner une erreur
  if (result.rows.length === 0) {
    console.log('❌ Utilisateur non trouvé avec l\'identifiant:', identifier);
    throw new Error('Utilisateur non trouvé');
  }
  
  // Récupérer les données de l'utilisateur
  const user = result.rows[0];
  console.log('✅ Utilisateur trouvé:', user.email);
  
  // ============================================
  // ÉTAPE 2.5 : Vérifier si le compte est suspendu
  // ============================================
  if (user.est_suspendu) {
    console.log('❌ Compte suspendu');
    const error = new Error('Votre compte a été suspendu');
    error.reason = user.raison_suspension || 'Aucune raison spécifiée';
    error.suspended = true;
    throw error;
  }
  
  // ============================================
  // ÉTAPE 3 : Vérifier le mot de passe
  // ============================================
  // Comparer le mot de passe saisi avec le hash stocké
  // bcrypt.compare() est sécurisé et prend en compte le salt
  const passwordMatch = await bcrypt.compare(password, user.password_hash);
  
  if (!passwordMatch) {
    console.log('❌ Mot de passe incorrect');
    throw new Error('Mot de passe incorrect');
  }
  
  console.log('✅ Mot de passe correct');
  
  // ============================================
  // ÉTAPE 3.3 : Normaliser le numéro de téléphone si nécessaire
  // ============================================
  if (!isEmail && user.telephone && !user.telephone.startsWith('+225')) {
    // Mettre à jour le numéro avec +225 si pas déjà présent
    const updatedPhone = '+225' + user.telephone;
    await pool.query(
      'UPDATE users SET telephone = $1 WHERE id = $2',
      [updatedPhone, user.id]
    );
    console.log('📱 Numéro normalisé:', user.telephone, '→', updatedPhone);
    user.telephone = updatedPhone;
  }
  
  // ============================================
  // ÉTAPE 3.5 : Logger la connexion
  // ============================================
  try {
    await pool.query(
      'INSERT INTO user_activity_logs (user_id, type, ip_address) VALUES ($1, $2, $3)',
      [user.id, 'login', 'api-request'] // L'IP sera ajoutée plus tard depuis req
    );
    console.log('📝 Connexion enregistrée dans les logs');
  } catch (logError) {
    console.error('⚠️ Erreur lors de l\'enregistrement de la connexion:', logError);
    // Ne pas bloquer la connexion si le log échoue
  }
  
  // ============================================
  // ÉTAPE 4 : Créer le token JWT
  // ============================================
  // Le token contient les informations de base de l'utilisateur
  // Il est signé avec la clé secrète et expire après 30 jours
  const token = jwt.sign(
    {
      id: user.id,                    // ID de l'utilisateur
      email: user.email,              // Email de l'utilisateur
      role: user.role,                // Rôle (super_admin, admin, moderation, commercial, client)
      code_apporteur: user.code_apporteur  // Code apporteur (si commercial)
    },
    process.env.JWT_SECRET,           // Clé secrète (depuis .env)
    { expiresIn: '30d' }              // Le token expire dans 30 jours
  );
  
  console.log('🎫 Token JWT généré');
  
  // ============================================
  // ÉTAPE 5 : Retourner le résultat
  // ============================================
  // On retourne le token ET les informations utilisateur
  // IMPORTANT : Ne JAMAIS retourner le mot de passe (même hashé) !
  return {
    token,                            // Token JWT pour l'authentification
    user: {                           // Informations utilisateur (sans mot de passe)
      id: user.id,
      email: user.email,
      nom: user.nom,
      prenom: user.prenom,
      role: user.role,
      telephone: user.telephone,
      code_apporteur: user.code_apporteur
    }
  };
}

/**
 * ===============================================
 * FONCTION DE DÉCONNEXION (LOGOUT)
 * ===============================================
 * 
 * Enregistre la déconnexion d'un utilisateur dans les logs
 * 
 * @param {number} userId - ID de l'utilisateur
 * @param {string} ipAddress - Adresse IP (optionnel)
 */
async function logout(userId, ipAddress = 'api-request') {
  try {
    await pool.query(
      'INSERT INTO user_activity_logs (user_id, type, ip_address) VALUES ($1, $2, $3)',
      [userId, 'logout', ipAddress]
    );
    console.log('📝 Déconnexion enregistrée pour utilisateur:', userId);
    return { success: true, message: 'Déconnexion enregistrée' };
  } catch (error) {
    console.error('❌ Erreur lors de l\'enregistrement de la déconnexion:', error);
    throw error;
  }
}

/**
 * ===============================================
 * CHANGE PASSWORD
 * ===============================================
 * 
 * Permet à un utilisateur de changer son propre mot de passe
 * Nécessite l'ancien mot de passe pour vérification
 */
const changePassword = async (req, res) => {
  try {
    const userId = req.user.id; // From JWT token via verifyToken middleware
    const { oldPassword, newPassword } = req.body;

    // Validation
    if (!oldPassword || !newPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Ancien et nouveau mot de passe requis' 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        success: false, 
        message: 'Le nouveau mot de passe doit contenir au moins 6 caractères' 
      });
    }

    // Get user
    const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    const user = userResult.rows[0];

    // Verify old password
    const isValidPassword = await bcrypt.compare(oldPassword, user.password_hash);
    
    if (!isValidPassword) {
      return res.status(401).json({ 
        success: false, 
        message: 'Ancien mot de passe incorrect' 
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await pool.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [hashedPassword, userId]
    );

    console.log(`✅ Password changed successfully for user ${userId} (${user.email})`);

    return res.status(200).json({ 
      success: true, 
      message: 'Mot de passe modifié avec succès' 
    });

  } catch (error) {
    console.error('❌ Error changing password:', error);
    return res.status(500).json({ 
      success: false, 
      message: 'Erreur lors de la modification du mot de passe' 
    });
  }
};

/**
 * ===============================================
 * EXPORTS
 * ===============================================
 * 
 * Exporte les fonctions pour qu'elles soient utilisables
 * dans d'autres fichiers (routes, controllers, etc.)
 */
module.exports = {
  registerClient,      // Inscription d'un client
  registerCommercial,  // Inscription d'un commercial
  login,               // Connexion (email ou téléphone)
  logout,              // Déconnexion
  detectUserRole,      // Détection du rôle
  checkPhoneExists,    // Vérification d'unicité du téléphone
  checkEmailExists,    // Vérification d'unicité de l'email
  changePassword       // Changement de mot de passe
};
