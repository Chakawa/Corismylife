/**
 * =====================================================
 * SCRIPT DE TEST WAVE CHECKOUT - MODE POLLING
 * =====================================================
 * 
 * Ce script teste l'intégration Wave SANS webhooks.
 * Il utilise uniquement le polling (vérification périodique du statut).
 * 
 * Conformité avec API Wave Checkout:
 * https://docs.wave.com/checkout#checkout-api
 * 
 * Étapes du test:
 * 1. Créer une session de paiement
 * 2. Afficher l'URL de paiement à ouvrir
 * 3. Vérifier le statut en boucle (polling)
 * 4. Afficher le résultat final
 */

require('dotenv').config();
const axios = require('axios');
const readline = require('readline');

// =====================================================
// CONFIGURATION
// =====================================================
const API_BASE_URL = 'http://127.0.0.1:5000/api';
const JWT_TOKEN = process.env.TEST_JWT_TOKEN || 'votre-token-jwt-ici';

// Debug: vérifier si le token est chargé
console.log('🔑 Token JWT chargé:', JWT_TOKEN ? 'OUI (' + JWT_TOKEN.substring(0, 20) + '...)' : 'NON');

// Données de test
const SUBSCRIPTION_ID = 1;
const AMOUNT = 100; // 100 FCFA minimum pour Wave
const DESCRIPTION = 'Test paiement Wave - Mode Polling';

// Couleurs pour le terminal
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

function log(color, ...args) {
  console.log(color, ...args, colors.reset);
}

function authHeaders() {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${JWT_TOKEN}`,
  };
}

// =====================================================
// ÉTAPE 1 : CRÉER SESSION WAVE
// =====================================================
async function createSession() {
  log(colors.cyan, '\n📝 ÉTAPE 1 : Création de la session Wave...');
  
  const payload = {
    subscriptionId: SUBSCRIPTION_ID,
    amount: AMOUNT,
    description: DESCRIPTION,
    // ✅ Pas de webhookUrl - mode polling uniquement
  };

  try {
    const response = await axios.post(
      `${API_BASE_URL}/payment/wave/create-session`,
      payload,
      { headers: authHeaders() }
    );

    log(colors.green, '✅ Session créée avec succès !');
    console.log('Réponse:', JSON.stringify(response.data, null, 2));
    return response.data;
  } catch (error) {
    log(colors.red, '❌ Erreur lors de la création de la session');
    console.error('Détails:', error.response?.data || error.message);
    throw error;
  }
}

// =====================================================
// ÉTAPE 2 : VÉRIFIER LE STATUT (POLLING)
// =====================================================
async function pollStatus(sessionId, transactionId, maxAttempts = 10) {
  log(colors.cyan, '\n🔄 ÉTAPE 2 : Vérification du statut (polling)...');
  log(colors.yellow, `Nombre maximum de tentatives: ${maxAttempts}`);
  log(colors.yellow, `Intervalle: 3 secondes entre chaque tentative`);
  
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      log(colors.blue, `\n📊 Tentative ${attempt}/${maxAttempts}...`);
      
      const response = await axios.get(
        `${API_BASE_URL}/payment/wave/status/${encodeURIComponent(sessionId)}`,
        {
          headers: authHeaders(),
          params: {
            subscriptionId: SUBSCRIPTION_ID,
            transactionId,
          },
        }
      );

      const data = response.data;
      const status = data.data?.status || 'UNKNOWN';
      const providerStatus = data.data?.providerStatus || 'unknown';

      log(colors.magenta, `  Statut interne: ${status}`);
      log(colors.magenta, `  Statut Wave: ${providerStatus}`);

      // Statuts terminaux
      if (status === 'COMPLETED' || providerStatus === 'complete') {
        log(colors.green, '\n🎉 PAIEMENT RÉUSSI !');
        console.log('Réponse finale:', JSON.stringify(data, null, 2));
        return { success: true, data };
      }

      if (status === 'FAILED' || providerStatus === 'failed') {
        log(colors.red, '\n❌ PAIEMENT ÉCHOUÉ');
        console.log('Réponse finale:', JSON.stringify(data, null, 2));
        return { success: false, data };
      }

      if (status === 'CANCELLED' || providerStatus === 'cancelled') {
        log(colors.yellow, '\n⚠️  PAIEMENT ANNULÉ');
        console.log('Réponse finale:', JSON.stringify(data, null, 2));
        return { success: false, data };
      }

      // Statut en attente - continuer le polling
      log(colors.yellow, '  ⏳ Paiement en attente...');
      
      if (attempt < maxAttempts) {
        await new Promise((resolve) => setTimeout(resolve, 3000));
      }

    } catch (error) {
      log(colors.red, `  ⚠️  Erreur tentative ${attempt}:`, error.response?.data?.message || error.message);
      
      if (attempt < maxAttempts) {
        await new Promise((resolve) => setTimeout(resolve, 3000));
      }
    }
  }

  log(colors.yellow, '\n⏱️  Délai d\'attente dépassé');
  log(colors.yellow, 'Le paiement peut toujours être en cours.');
  log(colors.yellow, 'Vérifiez manuellement avec le sessionId ci-dessus.');
  
  return { success: false, timeout: true };
}

// =====================================================
// FONCTION INTERACTIVE : ATTENDRE LA CONFIRMATION
// =====================================================
async function waitForUserConfirmation() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(
      '\n❓ Appuyez sur ENTRÉE après avoir effectué le paiement sur Wave... ',
      () => {
        rl.close();
        resolve();
      }
    );
  });
}

// =====================================================
// FONCTION PRINCIPALE
// =====================================================
async function run() {
  console.clear();
  log(colors.cyan, '╔════════════════════════════════════════════════╗');
  log(colors.cyan, '║   TEST WAVE CHECKOUT - MODE POLLING           ║');
  log(colors.cyan, '║   (Sans webhooks)                             ║');
  log(colors.cyan, '╚════════════════════════════════════════════════╝');

  try {
    // Vérifier la configuration
    log(colors.blue, '\n🔍 Vérification de la configuration...');
    log(colors.yellow, `  API Base URL: ${API_BASE_URL}`);
    log(colors.yellow, `  JWT Token: ${JWT_TOKEN.substring(0, 20)}...`);
    log(colors.yellow, `  Montant: ${AMOUNT} FCFA`);
    log(colors.yellow, `  Description: ${DESCRIPTION}`);

    // Étape 1 : Créer la session
    const createResult = await createSession();

    if (!createResult.success) {
      log(colors.red, '\n❌ Échec de la création de session');
      process.exit(1);
    }

    const data = createResult.data || {};
    const sessionId = data.sessionId;
    const transactionId = data.transactionId;
    const launchUrl = data.launchUrl;

    if (!sessionId) {
      log(colors.red, '❌ sessionId non retourné par create-session');
      process.exit(1);
    }

    log(colors.green, '\n✅ Session créée avec succès !');
    log(colors.magenta, `  Session ID: ${sessionId}`);
    log(colors.magenta, `  Transaction ID: ${transactionId}`);

    if (launchUrl) {
      log(colors.cyan, '\n🔗 URL DE PAIEMENT WAVE:');
      log(colors.green, `  ${launchUrl}`);
      log(colors.yellow, '\n📱 Actions requises:');
      log(colors.yellow, '  1. Ouvrez cette URL sur votre téléphone');
      log(colors.yellow, '  2. Complétez le paiement dans l\'app Wave');
      log(colors.yellow, '  3. Revenez ici et appuyez sur ENTRÉE');
    }

    // Attendre la confirmation utilisateur
    await waitForUserConfirmation();

    // Étape 2 : Polling du statut
    const pollResult = await pollStatus(sessionId, transactionId, 10);

    // Résumé final
    log(colors.cyan, '\n╔════════════════════════════════════════════════╗');
    log(colors.cyan, '║           RÉSUMÉ DU TEST                      ║');
    log(colors.cyan, '╚════════════════════════════════════════════════╝');

    if (pollResult.success) {
      log(colors.green, '\n✅ TEST RÉUSSI !');
      log(colors.green, '  Le paiement Wave fonctionne correctement.');
      log(colors.green, '  Mode polling opérationnel (sans webhooks).');
    } else if (pollResult.timeout) {
      log(colors.yellow, '\n⏱️  TIMEOUT');
      log(colors.yellow, '  Le polling a expiré avant confirmation.');
      log(colors.yellow, '  Recommandations:');
      log(colors.yellow, '    - Augmentez maxAttempts dans le code');
      log(colors.yellow, '    - Vérifiez manuellement le statut plus tard');
      log(colors.yellow, `    - Session ID: ${sessionId}`);
    } else {
      log(colors.red, '\n❌ TEST ÉCHOUÉ');
      log(colors.red, '  Le paiement n\'a pas abouti.');
      log(colors.yellow, '  Vérifiez:');
      log(colors.yellow, '    - L\'API Wave est accessible');
      log(colors.yellow, '    - La clé API est valide');
      log(colors.yellow, '    - Le montant est conforme (min 100 FCFA)');
    }

    log(colors.cyan, '\n════════════════════════════════════════════════\n');

  } catch (error) {
    log(colors.red, '\n❌ ERREUR CRITIQUE');
    console.error(error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

// =====================================================
// LANCEMENT DU SCRIPT
// =====================================================
run();
