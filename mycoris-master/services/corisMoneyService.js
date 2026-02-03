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
    
    // Agent HTTPS pour ignorer les erreurs de certificat en environnement de test
    // IMPORTANT: À désactiver en production !
    this.httpsAgent = new https.Agent({
      rejectUnauthorized: process.env.NODE_ENV === 'production' ? true : false
    });
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
    if (!this.clientId || !this.clientSecret || !this.codePv) {
      throw new Error('Identifiants CorisMoney non configurés. Veuillez configurer CORIS_MONEY_CLIENT_ID, CORIS_MONEY_CLIENT_SECRET et CORIS_MONEY_CODE_PV dans le fichier .env');
    }
  }

  /**
   * Étape 1 : Envoie un code OTP au client
   * @param {string} codePays - Code téléphonique du pays (ex: "225" pour CI)
   * @param {string} telephone - Numéro de téléphone du client
   * @returns {Promise<Object>} Réponse de l'API
   */
  async sendOTP(codePays, telephone) {
    this.checkCredentials();

    // Hachage: codePays+telephone+clientSecret
    const hashString = `${codePays}${telephone}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

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

      return {
        success: true,
        data: response.data,
        message: 'Code OTP envoyé avec succès'
      };
    } catch (error) {
      console.error('Erreur lors de l\'envoi du code OTP:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de l\'envoi du code OTP'
      };
    }
  }

  /**
   * Étape 2 : Effectue le paiement de bien
   * @param {string} codePays - Code téléphonique du pays
   * @param {string} telephone - Numéro de téléphone du client
   * @param {number} montant - Montant à payer
   * @param {string} codeOTP - Code OTP reçu par le client
   * @returns {Promise<Object>} Réponse de l'API avec transactionId
   */
  async paiementBien(codePays, telephone, montant, codeOTP) {
    this.checkCredentials();

    // Hachage: codePays+telephone+codePv+montant+codeOTP+clientSecret
    const hashString = `${codePays}${telephone}${this.codePv}${montant}${codeOTP}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

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
      console.error('Erreur lors du paiement:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors du paiement'
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
          }
        }
      );

      return {
        success: true,
        data: response.data,
        message: 'Informations client récupérées avec succès'
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des infos client:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de la récupération des informations client'
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
          }
        }
      );

      return {
        success: true,
        data: response.data,
        message: 'Statut de la transaction récupéré avec succès'
      };
    } catch (error) {
      console.error('Erreur lors de la vérification du statut:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de la vérification du statut de la transaction'
      };
    }
  }
}

module.exports = new CorisMoneyService();
