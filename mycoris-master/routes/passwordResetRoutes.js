const express = require('express');
const router = express.Router();
const pool = require('../db');
const bcrypt = require('bcrypt');

// Store pour les codes de vérification (en production, utiliser Redis ou la base de données)
const verificationCodes = new Map();

// Générer un code à 6 chiffres
function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * POST /api/password-reset/request
 * Demander un code de réinitialisation
 */
router.post('/request', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email requis'
      });
    }

    // Vérifier si l'utilisateur existe
    const userResult = await pool.query(
      'SELECT id, nom, prenom FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );

    if (userResult.rows.length === 0) {
      // Pour des raisons de sécurité, on ne dit pas que l'email n'existe pas
      return res.json({
        success: true,
        message: 'Si un compte existe avec cet email, un code de vérification a été envoyé.'
      });
    }

    const user = userResult.rows[0];
    const code = generateCode();
    const expiresAt = Date.now() + 15 * 60 * 1000; // Expire dans 15 minutes

    // Stocker le code
    verificationCodes.set(email.toLowerCase(), {
      code,
      userId: user.id,
      expiresAt,
      attempts: 0
    });

    // TODO: Dans un environnement de production, envoyer le code par email
    // Pour le développement, on le log
    console.log(`\n=======================================`);
    console.log(`📧 Code de réinitialisation pour ${email}`);
    console.log(`👤 Utilisateur: ${user.nom} ${user.prenom}`);
    console.log(`🔐 Code: ${code}`);
    console.log(`⏰ Expire dans 15 minutes`);
    console.log(`=======================================\n`);

    res.json({
      success: true,
      message: 'Un code de vérification a été envoyé à votre email.',
      // En développement uniquement - À RETIRER EN PRODUCTION
      ...(process.env.NODE_ENV === 'development' && { devCode: code })
    });

  } catch (error) {
    console.error('Erreur lors de la demande de réinitialisation:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la demande de réinitialisation'
    });
  }
});

/**
 * POST /api/password-reset/verify-code
 * Vérifier le code de réinitialisation
 */
router.post('/verify-code', async (req, res) => {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return res.status(400).json({
        success: false,
        message: 'Email et code requis'
      });
    }

    const storedData = verificationCodes.get(email.toLowerCase());

    if (!storedData) {
      return res.status(400).json({
        success: false,
        message: 'Code invalide ou expiré. Veuillez demander un nouveau code.'
      });
    }

    // Vérifier l'expiration
    if (Date.now() > storedData.expiresAt) {
      verificationCodes.delete(email.toLowerCase());
      return res.status(400).json({
        success: false,
        message: 'Le code a expiré. Veuillez demander un nouveau code.'
      });
    }

    // Vérifier le nombre de tentatives
    if (storedData.attempts >= 5) {
      verificationCodes.delete(email.toLowerCase());
      return res.status(400).json({
        success: false,
        message: 'Trop de tentatives. Veuillez demander un nouveau code.'
      });
    }

    // Vérifier le code
    if (storedData.code !== code) {
      storedData.attempts += 1;
      return res.status(400).json({
        success: false,
        message: 'Code incorrect. Essayez à nouveau.',
        attemptsLeft: 5 - storedData.attempts
      });
    }

    // Code valide - générer un token temporaire pour le changement de mot de passe
    const resetToken = Buffer.from(`${email}:${Date.now()}`).toString('base64');

    res.json({
      success: true,
      message: 'Code vérifié avec succès',
      resetToken
    });

  } catch (error) {
    console.error('Erreur lors de la vérification du code:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la vérification du code'
    });
  }
});

/**
 * POST /api/password-reset/reset
 * Réinitialiser le mot de passe
 */
router.post('/reset', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email, code et nouveau mot de passe requis'
      });
    }

    // Valider la force du mot de passe
    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Le mot de passe doit contenir au moins 6 caractères'
      });
    }

    const storedData = verificationCodes.get(email.toLowerCase());

    if (!storedData || storedData.code !== code || Date.now() > storedData.expiresAt) {
      return res.status(400).json({
        success: false,
        message: 'Code invalide ou expiré'
      });
    }

    // Hasher le nouveau mot de passe
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Mettre à jour le mot de passe
    await pool.query(
      'UPDATE users SET password_hash = $1 WHERE id = $2',
      [hashedPassword, storedData.userId]
    );

    // Supprimer le code utilisé
    verificationCodes.delete(email.toLowerCase());

    console.log(`✅ Mot de passe réinitialisé avec succès pour ${email}`);

    res.json({
      success: true,
      message: 'Mot de passe réinitialisé avec succès'
    });

  } catch (error) {
    console.error('Erreur lors de la réinitialisation du mot de passe:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la réinitialisation du mot de passe'
    });
  }
});

module.exports = router;
