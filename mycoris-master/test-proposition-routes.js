/**
 * Script de test pour les routes de propositions
 * Utilisation : node test-proposition-routes.js
 */

const http = require('http');

// Configuration
const BASE_URL = 'http://localhost:3000'; // Ajustez selon votre configuration
const AUTH_TOKEN = 'YOUR_JWT_TOKEN_HERE'; // Remplacez par un vrai token

// Couleurs pour la console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
};

/**
 * Effectue une requête HTTP
 */
function makeRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port || 3000,
      path: url.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AUTH_TOKEN}`,
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            data: JSON.parse(data),
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            data: data,
          });
        }
      });
    });

    req.on('error', reject);
    
    if (body) {
      req.write(JSON.stringify(body));
    }
    
    req.end();
  });
}

/**
 * Affiche le résultat d'un test
 */
function logTest(testName, success, message = '') {
  const icon = success ? '✓' : '✗';
  const color = success ? colors.green : colors.red;
  console.log(`${color}${icon}${colors.reset} ${testName}${message ? `: ${message}` : ''}`);
}

/**
 * Tests
 */
async function runTests() {
  console.log(`\n${colors.blue}=== Tests des routes de propositions ===${colors.reset}\n`);

  try {
    // Test 1: Récupérer toutes les propositions
    console.log(`${colors.yellow}Test 1: Récupération des propositions${colors.reset}`);
    const propositionsResponse = await makeRequest('/subscriptions/user/propositions');
    
    if (propositionsResponse.statusCode === 200 && propositionsResponse.data.success) {
      logTest('GET /subscriptions/user/propositions', true, `${propositionsResponse.data.data.length} propositions trouvées`);
      
      // Si on a des propositions, tester la récupération des détails
      if (propositionsResponse.data.data.length > 0) {
        const firstProposition = propositionsResponse.data.data[0];
        const propositionId = firstProposition.id;
        
        // Test 2: Récupérer les détails d'une proposition
        console.log(`\n${colors.yellow}Test 2: Récupération des détails${colors.reset}`);
        const detailsResponse = await makeRequest(`/subscriptions/${propositionId}`);
        
        if (detailsResponse.statusCode === 200 && detailsResponse.data.success) {
          const hasSubscription = detailsResponse.data.data.subscription !== undefined;
          const hasUser = detailsResponse.data.data.user !== undefined;
          
          logTest('GET /subscriptions/:id', true);
          logTest('  - Données de souscription', hasSubscription);
          logTest('  - Données utilisateur', hasUser);
          
          if (hasSubscription && hasUser) {
            console.log(`\n${colors.blue}Aperçu des données :${colors.reset}`);
            console.log(`  Produit: ${detailsResponse.data.data.subscription.produit_nom || 'N/A'}`);
            console.log(`  Statut: ${detailsResponse.data.data.subscription.statut || 'N/A'}`);
            console.log(`  Utilisateur: ${detailsResponse.data.data.user.nom} ${detailsResponse.data.data.user.prenom}`);
          }
        } else {
          logTest('GET /subscriptions/:id', false, `Code ${detailsResponse.statusCode}`);
        }

        // Test 3: Mise à jour du statut de paiement (simulation)
        console.log(`\n${colors.yellow}Test 3: Mise à jour du statut de paiement${colors.reset}`);
        const paymentData = {
          payment_success: false, // false pour ne pas changer réellement le statut
          payment_method: 'test',
          transaction_id: 'test_' + Date.now(),
        };
        
        const paymentResponse = await makeRequest(
          `/subscriptions/${propositionId}/payment-status`,
          'PUT',
          paymentData
        );
        
        if (paymentResponse.statusCode === 200 && paymentResponse.data.success) {
          logTest('PUT /subscriptions/:id/payment-status', true);
          console.log(`  Message: ${paymentResponse.data.message}`);
        } else {
          logTest('PUT /subscriptions/:id/payment-status', false, `Code ${paymentResponse.statusCode}`);
        }
      } else {
        console.log(`${colors.yellow}Aucune proposition trouvée, tests 2 et 3 ignorés${colors.reset}`);
      }
    } else {
      logTest('GET /subscriptions/user/propositions', false, `Code ${propositionsResponse.statusCode}`);
    }

  } catch (error) {
    console.error(`${colors.red}Erreur lors des tests:${colors.reset}`, error.message);
    console.log(`\n${colors.yellow}Vérifiez que:${colors.reset}`);
    console.log('  - Le serveur backend est démarré');
    console.log('  - Le BASE_URL est correct');
    console.log('  - Le AUTH_TOKEN est valide');
  }

  console.log(`\n${colors.blue}=== Fin des tests ===${colors.reset}\n`);
}

// Vérifications préalables
if (AUTH_TOKEN === 'YOUR_JWT_TOKEN_HERE') {
  console.log(`${colors.red}❌ Erreur: Veuillez configurer AUTH_TOKEN dans le fichier${colors.reset}`);
  console.log(`${colors.yellow}Instructions:${colors.reset}`);
  console.log('1. Connectez-vous à l\'application');
  console.log('2. Récupérez votre token JWT');
  console.log('3. Remplacez AUTH_TOKEN dans ce fichier');
  console.log('4. Relancez le script\n');
  process.exit(1);
}

// Exécuter les tests
runTests();
















