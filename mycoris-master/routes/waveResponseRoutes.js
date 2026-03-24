const express = require('express');
const router = express.Router();
const { Pool } = require('pg');

// 🔥 CONFIG DB (adapte)
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'mycorisdb',
  password: 'password',
  port: 5432,
});

/**
 * 🔁 REDIRECT DEPUIS WAVE (comme ton ancien système)
 */
router.get('/wave-success', (req, res) => {
  const queryString = new URLSearchParams(req.query || {}).toString();
  const target = queryString
    ? `/api/payment/wave-success?${queryString}`
    : `/api/payment/wave-success`;

  return res.redirect(302, target);
});

router.get('/wave-error', (req, res) => {
  const queryString = new URLSearchParams(req.query || {}).toString();
  const target = queryString
    ? `/api/payment/wave-error?${queryString}`
    : `/api/payment/wave-error`;

  return res.redirect(302, target);
});

/**
 * ✅ SUCCESS (DESIGN ORIGINAL + FALLBACK INTELLIGENT)
 */
router.get('/api/payment/wave-success', async (req, res) => {
  try {
    let { sessionId, status, montant, reference } = req.query;

    // 🔥 FALLBACK DB si données manquantes
    if (!montant || !reference || !status) {
      if (sessionId) {
        const result = await pool.query(
          `SELECT montant, statut, transaction_id 
           FROM payment_transactions 
           WHERE session_id = $1 
           ORDER BY created_at DESC 
           LIMIT 1`,
          [sessionId]
        );

        const transaction = result.rows[0];

        if (transaction) {
          montant = montant || transaction.montant;
          status = status || transaction.statut;
          reference = reference || transaction.transaction_id;
        }
      }
    }

    const htmlContent = `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Paiement Réussi - CORIS Assurance</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
        }
        
        .container {
          background: white;
          border-radius: 10px;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
          padding: 40px;
          text-align: center;
          max-width: 500px;
          width: 100%;
        }
        
        .icon {
          font-size: 80px;
          margin-bottom: 20px;
          animation: pulse 0.5s ease-in-out;
        }
        
        @keyframes pulse {
          0% { transform: scale(0.8); opacity: 0; }
          50% { transform: scale(1.1); }
          100% { transform: scale(1); opacity: 1; }
        }
        
        h1 {
          color: #27ae60;
          font-size: 28px;
          margin-bottom: 15px;
        }
        
        p {
          color: #555;
          font-size: 16px;
          line-height: 1.6;
          margin-bottom: 10px;
        }
        
        .info-box {
          background: #f0f8ff;
          border-left: 4px solid #667eea;
          padding: 15px;
          margin: 25px 0;
          border-radius: 5px;
          text-align: left;
        }
        
        .info-box strong {
          color: #667eea;
        }
        
        .timer {
          color: #999;
          font-size: 14px;
          margin-top: 20px;
        }
        
        .btn {
          background: #667eea;
          color: white;
          border: none;
          padding: 12px 30px;
          border-radius: 5px;
          cursor: pointer;
          font-size: 16px;
          margin-top: 20px;
          text-decoration: none;
          display: inline-block;
        }
        
        .btn:hover {
          background: #764ba2;
        }
        
        .logo {
          color: #667eea;
          font-weight: bold;
          font-size: 20px;
          margin-bottom: 20px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo">🏢 CORIS Assurances Vie</div>
        
        <div class="icon">✅</div>
        
        <h1>Paiement Réussi!</h1>
        
        <p>Votre souscription a été activée avec succès.</p>
        <p>Votre contrat d'assurance est maintenant en vigueur.</p>
        
        <div class="info-box">
          <strong>💰 Montant:</strong> ${montant || 'Non disponible'} FCFA<br>
          <strong>📋 Référence:</strong> ${reference || 'Non disponible'}<br>
          <strong>🔔 Statut:</strong> ${status || 'SUCCÈS'}
        </div>
        
        <p>Un message de confirmation vous sera envoyé par SMS.</p>
        
        <button class="btn" onclick="closeWindow()">Fermer</button>
        
        <div class="timer">
          <p>Cette fenêtre se fermera automatiquement dans <span id="countdown">5</span> secondes...</p>
        </div>
      </div>
      
      <script>
        let count = 5;
        const timer = setInterval(() => {
          count--;
          document.getElementById('countdown').textContent = count;
          if (count <= 0) {
            clearInterval(timer);
            closeWindow();
          }
        }, 1000);
        
        function closeWindow() {
          if (window.opener) {
            window.close();
          } else {
            console.log('Redirection après paiement');
          }
        }
      </script>
    </body>
    </html>
    `;

    res.set('Content-Type', 'text/html; charset=utf-8');
    res.send(htmlContent);

  } catch (error) {
    console.error('Erreur wave-success:', error);
    res.status(500).send('Erreur serveur');
  }
});

/**
 * ❌ ERROR (design aussi conservé)
 */
router.get('/api/payment/wave-error', (req, res) => {
  const { status, reason } = req.query;

  const htmlContent = `
  <!DOCTYPE html>
  <html lang="fr">
  <head>
    <meta charset="UTF-8">
    <title>Paiement Échoué</title>
  </head>
  <body style="text-align:center; font-family:Arial;">
    <h1 style="color:red;">❌ Paiement Échoué</h1>
    <p><strong>Statut:</strong> ${status || 'ÉCHOUÉ'}</p>
    <p><strong>Raison:</strong> ${reason || 'Erreur lors du paiement'}</p>
  </body>
  </html>
  `;

  res.send(htmlContent);
});

module.exports = router;