/**
 * Test rapide de l'intégration Wave Checkout backend
 *
 * Usage (PowerShell):
 *   $env:JWT_TOKEN="<votre_jwt>"
 *   $env:SUBSCRIPTION_ID="123"
 *   $env:AMOUNT="100"
 *   node test-wave-checkout.js
 */

require('dotenv').config();
const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'http://127.0.0.1:5000/api';
const JWT_TOKEN = process.env.JWT_TOKEN || '';
const SUBSCRIPTION_ID = Number(process.env.SUBSCRIPTION_ID || 0);
const AMOUNT = Number(process.env.AMOUNT || 100);
const DESCRIPTION = process.env.DESCRIPTION || `Test Wave ${new Date().toISOString()}`;

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
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

async function createSession() {
  const payload = {
    subscriptionId: SUBSCRIPTION_ID,
    amount: AMOUNT,
    description: DESCRIPTION,
  };

  const response = await axios.post(
    `${API_BASE_URL}/payment/wave/create-session`,
    payload,
    { headers: authHeaders() }
  );

  return response.data;
}

async function getStatus(sessionId, transactionId) {
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

  return response.data;
}

async function run() {
  console.log('\n' + '='.repeat(64));
  log(colors.cyan, '🧪 TEST WAVE CHECKOUT BACKEND');
  console.log('='.repeat(64));

  if (!JWT_TOKEN) {
    log(colors.red, '❌ JWT_TOKEN manquant');
    console.log('Définissez JWT_TOKEN dans votre terminal avant de lancer le test.');
    process.exit(1);
  }

  if (!SUBSCRIPTION_ID || SUBSCRIPTION_ID <= 0) {
    log(colors.red, '❌ SUBSCRIPTION_ID invalide');
    console.log('Définissez SUBSCRIPTION_ID (id numérique d\'une souscription existante).');
    process.exit(1);
  }

  if (!Number.isFinite(AMOUNT) || AMOUNT <= 0) {
    log(colors.red, '❌ AMOUNT invalide');
    process.exit(1);
  }

  try {
    log(colors.blue, '📤 Création de session Wave...');
    const createResult = await createSession();

    console.log('Réponse create-session:', JSON.stringify(createResult, null, 2));

    const data = createResult.data || {};
    const sessionId = data.sessionId;
    const transactionId = data.transactionId;
    const launchUrl = data.launchUrl;

    if (!sessionId) {
      log(colors.red, '❌ sessionId non retourné par create-session');
      process.exit(1);
    }

    if (launchUrl) {
      log(colors.yellow, '🔗 launchUrl:', launchUrl);
      console.log('Ouvrez cette URL sur mobile ou navigateur pour finaliser le paiement.');
    }

    log(colors.blue, '⏳ Vérification du statut (poll x3)...');
    for (let i = 1; i <= 3; i++) {
      await new Promise((resolve) => setTimeout(resolve, 3000));
      const statusResult = await getStatus(sessionId, transactionId);
      const status = statusResult?.data?.status || 'UNKNOWN';

      console.log(`Tentative ${i}/3 - status: ${status}`);

      if (status === 'SUCCESS' || status === 'FAILED') {
        console.log('Réponse status finale:', JSON.stringify(statusResult, null, 2));
        break;
      }

      if (i === 3) {
        console.log('Réponse status:', JSON.stringify(statusResult, null, 2));
      }
    }

    log(colors.green, '✅ Test terminé');
    process.exit(0);
  } catch (error) {
    const payload = error.response?.data || error.message;
    log(colors.red, '❌ Échec du test Wave');
    console.error(payload);
    process.exit(1);
  }
}

run();
