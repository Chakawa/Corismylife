const express = require('express');
const router = express.Router();

/**
 * @route   GET /wave-success
 * @desc    Page de succès après paiement Wave
 * @access  Public (redirection depuis Wave)
 */
router.get('/wave-success', (req, res) => {
  const queryString = new URLSearchParams(req.query || {}).toString();
  const target = queryString
    ? `/api/payment/wave-success?${queryString}`
    : '/api/payment/wave-success';
  return res.redirect(302, target);

  const { sessionId, status, reference } = req.query;
  
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
        <div class="logo">🏢 CORIS Assurance Vie</div>
        
        <div class="icon">✅</div>
        
        <h1>Paiement Réussi!</h1>
        
        <p>Votre souscription a été activée avec succès.</p>
        <p>Votre contrat d'assurance est maintenant en vigueur.</p>
        
        <div class="info-box">
          <strong>📋 Référence:</strong> ${reference || sessionId || 'N/A'}<br>
          <strong>🔔 Statut:</strong> ${status || 'SUCCÈS'}
        </div>
        
        <p>Vous recevrez bientôt un email de confirmation avec les détails de votre contrat.</p>
        
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
          // Essayer de fermer la fenêtre (fonctionne si ouverte par JS)
          if (window.opener) {
            window.close();
          } else {
            // Sinon rediriger vers l'app (si c'est possible)
            console.log('Redirection après paiement');
          }
        }
      </script>
    </body>
    </html>
  `;
  
  res.set('Content-Type', 'text/html; charset=utf-8');
  res.send(htmlContent);
});

/**
 * @route   GET /wave-error
 * @desc    Page d'erreur après paiement Wave échoué
 * @access  Public (redirection depuis Wave)
 */
router.get('/wave-error', (req, res) => {
  const queryString = new URLSearchParams(req.query || {}).toString();
  const target = queryString
    ? `/api/payment/wave-error?${queryString}`
    : '/api/payment/wave-error';
  return res.redirect(302, target);

  const { sessionId, status, reason, reference } = req.query;
  
  const htmlContent = `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Paiement Échoué - CORIS Assurance</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
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
          animation: shake 0.5s ease-in-out;
        }
        
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-10px); }
          75% { transform: translateX(10px); }
        }
        
        h1 {
          color: #e74c3c;
          font-size: 28px;
          margin-bottom: 15px;
        }
        
        p {
          color: #555;
          font-size: 16px;
          line-height: 1.6;
          margin-bottom: 10px;
        }
        
        .error-box {
          background: #fff3cd;
          border-left: 4px solid #ffc107;
          padding: 15px;
          margin: 25px 0;
          border-radius: 5px;
          text-align: left;
        }
        
        .error-box strong {
          color: #e74c3c;
        }
        
        .btn {
          background: #e74c3c;
          color: white;
          border: none;
          padding: 12px 30px;
          border-radius: 5px;
          cursor: pointer;
          font-size: 16px;
          margin-top: 20px;
          margin-right: 10px;
          text-decoration: none;
          display: inline-block;
        }
        
        .btn:hover {
          background: #c0392b;
        }
        
        .btn-secondary {
          background: #95a5a6;
        }
        
        .btn-secondary:hover {
          background: #7f8c8d;
        }
        
        .logo {
          color: #e74c3c;
          font-weight: bold;
          font-size: 20px;
          margin-bottom: 20px;
        }
        
        .actions {
          margin-top: 30px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo">🏢 CORIS Assurance Vie</div>
        
        <div class="icon">❌</div>
        
        <h1>Paiement Échoué</h1>
        
        <p>Nous n'avons pas pu traiter votre paiement.</p>
        
        <div class="error-box">
          <strong>🔍 Raison:</strong> ${reason || 'Erreur lors du traitement du paiement'}<br>
          <strong>📋 Référence:</strong> ${reference || sessionId || 'N/A'}<br>
          <strong>🔔 Statut:</strong> ${status || 'ÉCHOUÉ'}
        </div>
        
        <p>Veuillez vérifier vos informations et réessayer.</p>
        
        <div class="actions">
          <button class="btn" onclick="retryPayment()">🔄 Réessayer</button>
          <button class="btn btn-secondary" onclick="closeWindow()">Fermer</button>
        </div>
        
        <p style="margin-top: 20px; color: #999; font-size: 13px;">
          Si le problème persiste, contactez notre support: contact@coris-assurance.ci
        </p>
      </div>
      
      <script>
        function retryPayment() {
          // Retourner à l'app pour réessayer
          if (window.opener) {
            window.close();
          } else {
            history.back();
          }
        }
        
        function closeWindow() {
          if (window.opener) {
            window.close();
          } else {
            history.back();
          }
        }
      </script>
    </body>
    </html>
  `;
  
  res.set('Content-Type', 'text/html; charset=utf-8');
  res.send(htmlContent);
});

module.exports = router;
