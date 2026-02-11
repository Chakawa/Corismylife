const crypto = require('crypto');
const axios = require('axios');
const https = require('https');

class CorisMoneyService {
  constructor() {
    // Configuration - À mettre dans .env en production
    this.baseURL = process.env.CORIS_MONEY_BASE_URL || 'https://testbed.corismoney.com/external/v1/api';
    this.clientId = process.env.CORIS_MONEY_CLIENT_ID || '';
    this.clientSecret = process.env.CORIS_MONEY_CLIENT_SECRET || '';
    this.codePv = process.env.CORIS_MONEY_CODE_PV || '';
    
    // Mode développement - Simule les réponses sans appeler l'API
    this.devMode = process.env.CORIS_MONEY_DEV_MODE === 'true';
    this.devOTP = process.env.CORIS_MONEY_DEV_OTP || '123456';
    
    // Agent HTTPS - En production, vérifie les certificats SSL
    // ⚠️ ATTENTION: L'API testbed CorisMoney a un certificat SSL expiré
    // En production réelle, il faudra changer l'URL vers l'API production et activer la vérification SSL
    const isTestbedAPI = this.baseURL.includes('testbed');
    this.httpsAgent = new https.Agent({
      rejectUnauthorized: isTestbedAPI ? false : (process.env.NODE_ENV === 'production')
    });
    
    if (isTestbedAPI) {
      console.warn('⚠️  Utilisation de l\'API testbed CorisMoney avec certificat SSL désactivé');
    }

    if (this.devMode) {
      console.log('🧪 ═══════════════════════════════════════════════════════════');
      console.log('🧪 MODE DÉVELOPPEMENT CORISMONEY ACTIVÉ');
      console.log('🧪 Les paiements seront SIMULÉS (aucun appel API réel)');
      console.log('🧪 Code OTP de test: ' + this.devOTP);
      console.log('🧪 Pour activer l\'API réelle: CORIS_MONEY_DEV_MODE=false dans .env');
      console.log('🧪 ═══════════════════════════════════════════════════════════');
    } else {
      console.log('💰 ═══════════════════════════════════════════════════════════');
      console.log('💰 MODE PRODUCTION CORISMONEY ACTIVÉ');
      console.log('💰 API CorisMoney: ' + this.baseURL);
      console.log('💰 Client ID: ' + this.clientId);
      console.log('💰 Code PV: ' + this.codePv);
      console.log('💰 Les paiements seront RÉELS');
      console.log('💰 ═══════════════════════════════════════════════════════════');
    }
  }

  /**
   * Génère un hash SHA256 d'une chaîne de caractères
   * @param {string} originalString - La chaîne à hacher
   * @returns {string} Le hash SHA256
   */
  getHash256(originalString) {
    return crypto
      .createHash('sha256')
      .update(originalString, 'utf8')
      .digest('hex');
  }

  /**
   * Vérifie que les identifiants marchands sont configurés
   * @throws {Error} Si les identifiants ne sont pas configurés
   */
  checkCredentials() {
    // En mode dev, on n'a pas besoin des vrais identifiants
    if (this.devMode) {
      return true;
    }
    
    if (!this.clientId || !this.clientSecret || !this.codePv) {
      throw new Error('Identifiants CorisMoney non configurés. Veuillez configurer CORIS_MONEY_CLIENT_ID, CORIS_MONEY_CLIENT_SECRET et CORIS_MONEY_CODE_PV dans le fichier .env');
    }
  }

  /**
   * Étape 1 : Envoie un code OTP au client
   * @param {string} codePays - Code téléphonique du pays (ex: "225" pour CI)
   * @param {string} telephone - Numéro de téléphone AVEC le 0 initial (ex: "0799283976")
   *                             Format complet attendu: 225 + 0799283976 = 2250799283976
   * @returns {Promise<Object>} Réponse de l'API
   */
  async sendOTP(codePays, telephone) {
    this.checkCredentials();

    console.log('📱 ===== ENVOI CODE OTP CORISMONEY =====');
    console.log('Code Pays:', codePays);
    console.log('Téléphone:', telephone);
    console.log('Numéro complet:', codePays + telephone);

    // MODE DÉVELOPPEMENT - Simulation
    if (this.devMode) {
      console.log('🧪 MODE DEV: Simulation d\'envoi OTP');
      console.log('🔐 ═══════════════════════════════════════');
      console.log('🔐 CODE OTP DE TEST: ' + this.devOTP);
      console.log('🔐 ═══════════════════════════════════════');
      console.log('✅ Simulation réussie');
      
      return {
        success: true,
        data: {
          msg: "Code OTP envoyé avec succès (MODE DEV)",
          codeOTP: this.devOTP,
          transactionId: 'DEV-' + Date.now(),
          text: "Code envoyé (simulation)"
        },
        message: 'Code OTP envoyé avec succès (MODE DEV)'
      };
    }

    // MODE PRODUCTION - Appel API réel
    const hashString = `${codePays}${telephone}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    console.log('Hash généré:', hashParam.substring(0, 20) + '...');
    console.log('URL:', `${this.baseURL}/send-code-otp`);

    try {
      const response = await axios.post(
        `${this.baseURL}/send-code-otp`,
        null,
        {
          params: {
            codePays,
            telephone
          },
          headers: {
            'Content-Type': 'application/json',
            'clientId': this.clientId,
            'hashParam': hashParam
          },
          httpsAgent: this.httpsAgent
        }
      );

      console.log('📦 Réponse reçue de CorisMoney:');
      console.log(JSON.stringify(response.data, null, 2));

      // Vérifier si la réponse contient une erreur
      if (response.data.msg && response.data.msg.toLowerCase().includes('erroné')) {
        console.error('❌ ERREUR CORISMONEY: Paramètres erronés !');
        console.error('💡 SOLUTION: Vérifiez que:');
        console.error('   - Le numéro DOIT commencer par 0 (ex: 0799283976 et non 799283976)');
        console.error('   - Le format complet: codePays + telephone (ex: 225 + 0799283976 = 2250799283976)');
        console.error('   - Le code pays est correct (225 pour Côte d\'Ivoire)');
        console.error('   - Les identifiants CLIENT_ID et CLIENT_SECRET sont valides');
        return {
          success: false,
          error: response.data.msg,
          message: 'Paramètres erronés. Vérifiez le format du numéro de téléphone (avec le 0 initial).'
        };
      }

      // Si le code OTP est présent dans la réponse (mode développement)
      if (response.data.codeOTP) {
        console.log('🔐 ═══════════════════════════════════════');
        console.log('🔐 CODE OTP REÇU: ' + response.data.codeOTP);
        console.log('🔐 ═══════════════════════════════════════');
      }

      // Si un transactionId est présent
      if (response.data.transactionId) {
        console.log('📝 Transaction ID:', response.data.transactionId);
      }

      console.log('✅ Code OTP envoyé avec succès');

      return {
        success: true,
        data: response.data,
        message: 'Code OTP envoyé avec succès'
      };
    } catch (error) {
      console.error('❌ Erreur lors de l\'envoi du code OTP');
      console.error('   Message:', error.message);
      console.error('   Code HTTP:', error.response?.status);
      console.error('   Réponse API:', error.response?.data);
      console.error('   Cause:', error.code || 'Inconnue');
      
      // Afficher des suggestions selon le type d'erreur
      if (error.message.includes('certificate')) {
        console.error('   💡 PROBLÈME SSL DÉTECTÉ: Vérifiez le certificat SSL du serveur');
      }
      
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de l\'envoi du code OTP',
        errorCode: error.code
      };
    }
  }

  /**
   * Étape 2 : Effectue le paiement de bien
   * @param {string} codePays - Code téléphonique du pays (ex: "225" pour CI)
   * @param {string} telephone - Numéro de téléphone AVEC le 0 initial (ex: "0799283976")
   * @param {number} montant - Montant à débiter en FCFA
   * @param {string} codeOTP - Code OTP reçu par le client
   * @returns {Promise<Object>} Réponse de l'API avec transactionId
   */
  async paiementBien(codePays, telephone, montant, codeOTP) {
    this.checkCredentials();

    console.log('💳 ===== PAIEMENT CORISMONEY =====');
    console.log('Numéro complet:', codePays + telephone);
    console.log('Montant:', montant, 'FCFA');
    console.log('Code OTP fourni:', codeOTP);

    // MODE DÉVELOPPEMENT - Simulation
    if (this.devMode) {
      console.log('🧪 MODE DEV: Simulation de paiement');
      
      // Vérifier que le code OTP est correct
      if (codeOTP !== this.devOTP) {
        console.log('❌ Code OTP incorrect');
        console.log('   Attendu:', this.devOTP);
        console.log('   Reçu:', codeOTP);
        return {
          success: false,
          error: 'Code OTP incorrect',
          message: 'Code OTP invalide'
        };
      }

      console.log('✅ Code OTP validé');
      console.log('💰 Paiement simulé de', montant, 'FCFA');
      console.log('🎉 Simulation de paiement réussie !');

      return {
        success: true,
        data: {
          msg: "Paiement effectué avec succès (MODE DEV)",
          transactionId: 'DEV-PAY-' + Date.now(),
          montant: montant,
          statut: 'SUCCESS'
        },
        message: 'Paiement effectué avec succès (MODE DEV)'
      };
    }

    // MODE PRODUCTION - Appel API réel
    const hashString = `${codePays}${telephone}${this.codePv}${montant}${codeOTP}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    console.log('Hash généré:', hashParam.substring(0, 20) + '...');

    try {
      const response = await axios.post(
        `${this.baseURL}/operations/paiement-bien`,
        null,
        {
          params: {
            codePays,
            telephone,
            codePv: this.codePv,
            montant,
            codeOTP
          },
          headers: {
            'Content-Type': 'application/json',
            'clientId': this.clientId,
            'hashParam': hashParam
          },
          httpsAgent: this.httpsAgent
        }
      );

      return {
        success: true,
        data: response.data,
        transactionId: response.data.transactionId,
        message: response.data.message || 'Paiement effectué avec succès'
      };
    } catch (error) {
      console.error('❌ Erreur lors du paiement');
      console.error('   Message:', error.message);
      console.error('   Code HTTP:', error.response?.status);
      console.error('   Réponse API:', error.response?.data);
      console.error('   Cause:', error.code || 'Inconnue');
      
      // Afficher des suggestions selon le type d'erreur
      if (error.message.includes('certificate')) {
        console.error('   💡 PROBLÈME SSL DÉTECTÉ: Vérifiez le certificat SSL du serveur');
      }
      
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors du paiement',
        errorCode: error.code
      };
    }
  }

  /**
   * Récupère les informations d'un client CorisMoney
   * @param {string} codePays - Code téléphonique du pays
   * @param {string} telephone - Numéro de téléphone du client
   * @returns {Promise<Object>} Informations du client
   */
  async getClientInfo(codePays, telephone) {
    this.checkCredentials();

    // Hachage: codePays+telephone+clientSecret
    const hashString = `${codePays}${telephone}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    try {
      const response = await axios.get(
        `${this.baseURL}/infos-client`,
        {
          params: {
            codePays,
            telephone
          },
          headers: {
            'Content-Type': 'application/json',
            'clientId': this.clientId,
            'hashParam': hashParam
          },
          httpsAgent: this.httpsAgent
        }
      );

      return {
        success: true,
        data: response.data,
        message: 'Informations client récupérées avec succès'
      };
    } catch (error) {
      console.error('❌ Erreur lors de la récupération des infos client');
      console.error('   Message:', error.message);
      console.error('   Code HTTP:', error.response?.status);
      console.error('   Réponse API:', error.response?.data);
      console.error('   Cause:', error.code || 'Inconnue');
      
      // Afficher des suggestions selon le type d'erreur
      if (error.message.includes('certificate')) {
        console.error('   💡 PROBLÈME SSL DÉTECTÉ: Vérifiez le certificat SSL du serveur');
        console.error('   💡 SOLUTION: Assurez-vous que httsAgent est bien configuré');
      }
      
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de la récupération des informations client',
        errorCode: error.code
      };
    }
  }

  /**
   * Vérifie le statut d'une transaction
   * @param {string} codeOperation - Code de la transaction
   * @returns {Promise<Object>} Statut de la transaction
   */
  async getTransactionStatus(codeOperation) {
    this.checkCredentials();

    // Hachage: codeOperation+clientSecret
    const hashString = `${codeOperation}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    try {
      const response = await axios.get(
        `${this.baseURL}/operations/transaction-status`,
        {
          params: {
            codeOperation
          },
          headers: {
            'Content-Type': 'application/json',
            'clientId': this.clientId,
            'hashParam': hashParam
          },
          httpsAgent: this.httpsAgent
        }
      );

      return {
        success: true,
        data: response.data,
        message: 'Statut de la transaction récupéré avec succès'
      };
    } catch (error) {
      console.error('❌ Erreur lors de la vérification du statut');
      console.error('   Message:', error.message);
      console.error('   Code HTTP:', error.response?.status);
      console.error('   Réponse API:', error.response?.data);
      console.error('   Cause:', error.code || 'Inconnue');
      
      // Afficher des suggestions selon le type d'erreur
      if (error.message.includes('certificate')) {
        console.error('   💡 PROBLÈME SSL DÉTECTÉ: Vérifiez le certificat SSL du serveur');
      }
      
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de la vérification du statut de la transaction',
        errorCode: error.code
      };
    }
  }
}

module.exports = new CorisMoneyService();
