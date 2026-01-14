const http = require('http');

// Le token de test (à récupérer depuis le localStorage du navigateur)
// Pour le moment, testons sans token d'abord
const testEndpoint = async () => {
  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/admin/stats/connexions-mensuelles?months=12',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('Status:', res.statusCode);
      console.log('Response:', data);
      try {
        const json = JSON.parse(data);
        console.log('\nParsed:', JSON.stringify(json, null, 2));
      } catch (e) {
        console.log('Non-JSON response');
      }
    });
  });

  req.on('error', (error) => {
    console.error('Erreur:', error.message);
  });

  req.end();
};

testEndpoint();
