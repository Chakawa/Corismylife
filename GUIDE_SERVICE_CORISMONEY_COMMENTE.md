/**
 * ========================================
 * SERVICE DE PAIEMENT CORISMONEY - VERSION COMMENTÉE
 * ========================================
 * 
 * Ce service gère toutes les interactions avec l'API CorisMoney
 * pour effectuer des paiements via le système de portefeuille mobile.
 * 
 * Fonctionnalités:
 * - Génération de hash SHA256 pour sécuriser les requêtes
 * - Envoi de code OTP par SMS
 * - Traitement des paiements avec validation OTP
 * - Récupération du statut des transactions
 * - Consultation des informations client
 * 
 * Configuration requise dans .env:
 * - CORIS_MONEY_BASE_URL: URL de l'API (testbed ou production)
 * - CORIS_MONEY_CLIENT_ID: Identifiant marchand fourni par CorisMoney
 * - CORIS_MONEY_CLIENT_SECRET: Clé secrète fournie par CorisMoney
 * - CORIS_MONEY_CODE_PV: Code point de vente fourni par CorisMoney
 * 
 * Documentation API: CorisMoney External API v1.1.0
 */

const crypto = require('crypto');
const axios = require('axios');

class CorisMoneyService {
  constructor() {
    // Configuration - Les valeurs doivent être dans le fichier .env
    // IMPORTANT: Ne jamais mettre ces valeurs directement dans le code !
    
    // URL de base de l'API CorisMoney
    // Test: https://testbed.corismoney.com/external/v1/api
    // Production: https://corismoney.com/external/v1/api (à confirmer)
    this.baseURL = process.env.CORIS_MONEY_BASE_URL || 'https://testbed.corismoney.com/external/v1/api';
    
    // Identifiant CLIENT fourni par l'administrateur CorisMoney
    this.clientId = process.env.CORIS_MONEY_CLIENT_ID || '';
    
    // Clé secrète CLIENT fournie par l'administrateur CorisMoney
    // ATTENTION: Cette clé doit rester CONFIDENTIELLE !
    this.clientSecret = process.env.CORIS_MONEY_CLIENT_SECRET || '';
    
    // Code du point de vente (PV) fourni par l'administrateur CorisMoney
    this.codePv = process.env.CORIS_MONEY_CODE_PV || '';
  }

  /**
   * GÉNÉRATION DU HASH SHA256
   * 
   * Cette fonction génère un hash SHA256 pour sécuriser les requêtes API.
   * CorisMoney exige que chaque requête contienne un hash calculé pour vérifier
   * que la requête provient bien d'un marchand autorisé.
   * 
   * Le hash est généré en combinant :
   * 1. Les paramètres de la requête (dans un ordre spécifique)
   * 2. La clé secrète du marchand (CLIENT_SECRET)
   * 
   * Exemple:
   * - Paramètres: codePays="225", telephone="0700000000"
   * - Chaîne à hasher: "2250700000000" + CLIENT_SECRET
   * - Résultat: hash SHA256 en hexadécimal
   * 
   * @param {string} originalString - La chaîne à hasher
   * @returns {string} Le hash SHA256 en hexadécimal (64 caractères)
   */
  getHash256(originalString) {
    return crypto
      .createHash('sha256')        // Utilise l'algorithme SHA256
      .update(originalString, 'utf8') // Convertit la chaîne en bytes UTF-8
      .digest('hex');                 // Retourne le hash en hexadécimal
  }

  /**
   * VÉRIFICATION DES IDENTIFIANTS
   * 
   * Vérifie que les identifiants marchands sont bien configurés
   * avant de faire des appels API. Cela évite des erreurs difficiles à déboguer.
   * 
   * @throws {Error} Si un des identifiants n'est pas configuré
   */
  checkCredentials() {
    if (!this.clientId || !this.clientSecret || !this.codePv) {
      throw new Error(
        'Identifiants CorisMoney non configurés. ' +
        'Veuillez configurer CORIS_MONEY_CLIENT_ID, CORIS_MONEY_CLIENT_SECRET ' +
        'et CORIS_MONEY_CODE_PV dans le fichier .env'
      );
    }
  }

  /**
   * ÉTAPE 1 : ENVOI DU CODE OTP PAR SMS
   * 
   * Cette fonction envoie un code OTP (One-Time Password) au numéro de téléphone
   * du client CorisMoney. Le client doit saisir ce code pour valider le paiement.
   * 
   * Processus:
   * 1. Vérification des identifiants marchands
   * 2. Génération du hash SHA256 : codePays + telephone + CLIENT_SECRET
   * 3. Appel à l'API CorisMoney /send-code-otp
   * 4. CorisMoney envoie un SMS avec le code OTP au client
   * 
   * @param {string} codePays - Code téléphonique du pays (ex: "225" pour Côte d'Ivoire)
   * @param {string} telephone - Numéro de téléphone sans indicatif pays (ex: "0700000000")
   * @returns {Promise<Object>} Résultat de l'envoi
   * 
   * Exemple de réponse SUCCESS:
   * {
   *   success: true,
   *   data: { codeStatut: "0", message: "SUCCESS" },
   *   message: "Code OTP envoyé avec succès"
   * }
   * 
   * Exemple de réponse ERREUR:
   * {
   *   success: false,
   *   error: { codeStatut: "1", message: "COMPTE INEXISTANT" },
   *   message: "Erreur lors de l'envoi du code OTP"
   * }
   */
  async sendOTP(codePays, telephone) {
    // Vérifier que les identifiants sont configurés
    this.checkCredentials();

    // Construction du hash selon la documentation CorisMoney
    // Format: codePays + telephone + clientSecret
    const hashString = `${codePays}${telephone}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    try {
      // Appel à l'API CorisMoney
      const response = await axios.post(
        `${this.baseURL}/send-code-otp`,  // Endpoint
        null,                              // Pas de body (paramètres dans l'URL)
        {
          params: {                        // Paramètres de la requête
            codePays,                      // Code du pays (ex: "225")
            telephone                      // Numéro de téléphone
          },
          headers: {                       // En-têtes requis par CorisMoney
            'Content-Type': 'application/json',
            'clientId': this.clientId,     // ID du marchand
            'hashParam': hashParam         // Hash pour sécuriser la requête
          }
        }
      );

      // Retourner le résultat formaté
      return {
        success: true,
        data: response.data,
        message: 'Code OTP envoyé avec succès'
      };
    } catch (error) {
      // En cas d'erreur, logger et retourner le message d'erreur
      console.error('Erreur lors de l\'envoi du code OTP:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de l\'envoi du code OTP'
      };
    }
  }

  /**
   * ÉTAPE 2 : TRAITEMENT DU PAIEMENT
   * 
   * Cette fonction effectue le paiement après validation du code OTP.
   * Elle débite le compte CorisMoney du client et crédite le compte marchand.
   * 
   * Processus:
   * 1. Vérification des identifiants marchands
   * 2. Génération du hash SHA256 : codePays + telephone + codePv + montant + codeOTP + CLIENT_SECRET
   * 3. Appel à l'API CorisMoney /operations/paiement-bien
   * 4. CorisMoney traite le paiement et retourne un ID de transaction
   * 
   * @param {string} codePays - Code téléphonique du pays (ex: "225")
   * @param {string} telephone - Numéro de téléphone du client
   * @param {number} montant - Montant à payer en FCFA (ex: 50000)
   * @param {string} codeOTP - Code OTP saisi par le client (6 chiffres)
   * @returns {Promise<Object>} Résultat du paiement avec transactionId
   * 
   * Exemple de réponse SUCCESS:
   * {
   *   success: true,
   *   data: {
   *     codeStatut: "0",
   *     message: "SUCCESS",
   *     transactionId: "CM2024011523456789",
   *     montant: 50000,
   *     frais: 250
   *   },
   *   transactionId: "CM2024011523456789",
   *   message: "Paiement effectué avec succès"
   * }
   * 
   * Exemple de réponse ERREUR:
   * {
   *   success: false,
   *   error: { codeStatut: "2", message: "CODE OTP INVALIDE" },
   *   message: "Erreur lors du paiement"
   * }
   */
  async paiementBien(codePays, telephone, montant, codeOTP) {
    // Vérifier que les identifiants sont configurés
    this.checkCredentials();

    // Construction du hash selon la documentation CorisMoney
    // Format: codePays + telephone + codePv + montant + codeOTP + clientSecret
    const hashString = `${codePays}${telephone}${this.codePv}${montant}${codeOTP}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    try {
      // Appel à l'API CorisMoney pour effectuer le paiement
      const response = await axios.post(
        `${this.baseURL}/operations/paiement-bien`,  // Endpoint
        null,                                         // Pas de body (paramètres dans l'URL)
        {
          params: {                                   // Paramètres de la requête
            codePays,                                 // Code du pays (ex: "225")
            telephone,                                // Numéro de téléphone
            codePv: this.codePv,                      // Code du point de vente
            montant,                                  // Montant en FCFA
            codeOTP                                   // Code OTP du client
          },
          headers: {                                  // En-têtes requis par CorisMoney
            'Content-Type': 'application/json',
            'clientId': this.clientId,                // ID du marchand
            'hashParam': hashParam                    // Hash pour sécuriser la requête
          }
        }
      );

      // Retourner le résultat formaté avec l'ID de transaction
      return {
        success: true,
        data: response.data,
        transactionId: response.data.transactionId,  // ID unique de la transaction
        message: response.data.message || 'Paiement effectué avec succès'
      };
    } catch (error) {
      // En cas d'erreur, logger et retourner le message d'erreur
      console.error('Erreur lors du paiement:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors du paiement'
      };
    }
  }

  /**
   * RÉCUPÉRATION DES INFORMATIONS CLIENT
   * 
   * Cette fonction récupère les informations d'un compte CorisMoney
   * (nom, prénom, solde, etc.) pour vérifier que le compte existe.
   * 
   * @param {string} codePays - Code téléphonique du pays (ex: "225")
   * @param {string} telephone - Numéro de téléphone du client
   * @returns {Promise<Object>} Informations du client
   * 
   * Exemple de réponse:
   * {
   *   success: true,
   *   data: {
   *     nom: "FOFANA",
   *     prenoms: "Chaka",
   *     telephone: "0576093737",
   *     numeroCompte: "0033000148306",
   *     solde: 125000
   *   },
   *   message: "Informations récupérées avec succès"
   * }
   */
  async getClientInfo(codePays, telephone) {
    // Vérifier que les identifiants sont configurés
    this.checkCredentials();

    // Construction du hash : codePays + telephone + clientSecret
    const hashString = `${codePays}${telephone}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    try {
      // Appel à l'API CorisMoney
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
        message: 'Informations récupérées avec succès'
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des infos client:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de la récupération des informations'
      };
    }
  }

  /**
   * VÉRIFICATION DU STATUT D'UNE TRANSACTION
   * 
   * Cette fonction vérifie le statut d'une transaction CorisMoney
   * en utilisant son ID unique (transactionId).
   * 
   * Utilisé pour:
   * - Vérifier qu'un paiement a bien été traité
   * - Récupérer les détails d'une transaction passée
   * - Confirmer le montant et les frais d'une transaction
   * 
   * @param {string} transactionId - ID unique de la transaction CorisMoney
   * @returns {Promise<Object>} Détails de la transaction
   * 
   * Exemple de réponse:
   * {
   *   success: true,
   *   data: {
   *     transactionId: "CM2024011523456789",
   *     statut: "SUCCESS",
   *     montant: 50000,
   *     frais: 250,
   *     dateHeure: "2024-01-15T14:23:45Z"
   *   },
   *   message: "Statut de la transaction récupéré"
   * }
   */
  async getTransactionStatus(transactionId) {
    // Vérifier que les identifiants sont configurés
    this.checkCredentials();

    // Construction du hash : transactionId + clientSecret
    const hashString = `${transactionId}${this.clientSecret}`;
    const hashParam = this.getHash256(hashString);

    try {
      // Appel à l'API CorisMoney
      const response = await axios.get(
        `${this.baseURL}/statut-transaction/${transactionId}`,
        {
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
        message: 'Statut de la transaction récupéré'
      };
    } catch (error) {
      console.error('Erreur lors de la vérification du statut:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        message: 'Erreur lors de la vérification du statut'
      };
    }
  }
}

// Export du service pour utilisation dans les routes
module.exports = new CorisMoneyService();
