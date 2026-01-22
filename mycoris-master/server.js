const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./db'); 
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const subscriptionRoutes = require('./routes/subscriptionRoutes'); 
// SUPPRIMEZ CETTE LIGNE : const subscriptionController = require('../controllers/subscriptionController');

const app = express();

// Middleware critiques
app.use(cors({
  origin: ['http://localhost', 'http://localhost:3000', 'http://10.0.2.2', 'http://192.168.1.32'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  credentials: true
}));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Route de base
app.get('/', (_, res) => res.json({ 
  status: 'running',
  message: 'API MyCorisLife OK',
  timestamp: new Date().toISOString()
}));

/// ============================================
/// ROUTES DE L'API
/// ============================================
/// Toutes les routes de l'application MyCorisLife
/// - /api/auth : Authentification (login, register)
/// - /api/subscriptions : Souscriptions et propositions
/// - /api/users : Profil utilisateur
/// - /api/notifications : Notifications
/// - /api/admin : Administration (Dashboard Web)
/// ============================================
app.use('/api/auth', authRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/kyc', require('./routes/kycRoutes'));
app.use('/api/commercial', require('./routes/commercialRoutes'));
app.use('/api/password-reset', require('./routes/passwordResetRoutes'));
app.use('/api/commissions', require('./routes/commissionRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.get('/api/config/support', (_, res) => {
  res.json({ success: true, phone: process.env.SUPPORT_PHONE || '+2250700000000' });
});
app.use('/api/produits', require('./routes/produitRoutes'));
app.use('/api/contrats', require('./routes/contratRoutes'));

// Servir les fichiers uploadés
app.use('/uploads', express.static('uploads'));

app.get('/health', (_,res)=>res.json({ ok:true, ts: Date.now() }));

// Route de test de la base de données
app.get('/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() AS current_time');
    res.json({ 
      status: 'success',
      dbTime: result.rows[0].current_time,
      dbVersion: (await pool.query('SELECT version()')).rows[0].version
    });
  } catch (error) {
    console.error('Database error:', error);
    res.status(503).json({ 
      status: 'error',
      message: 'Database unreachable',
      error: error.message
    });
  }
});

// 🔍 Route de diagnostic pour vérifier les colonnes de bordereau_commissions
app.get('/test-bordereau-dates', async (req, res) => {
  try {
    console.log('\n🔍 === DIAGNOSTIC COLONNES BORDEREAU_COMMISSIONS ===');
    
    // Récupérer les 10 premiers bordereaux (tous codes apporteurs confondus)
    const query = `
      SELECT 
        id,
        exercice,
        numefeui,
        codeappin,
        datedebut,
        datefin,
        datefeui,
        montfeui,
        CASE 
          WHEN datedebut IS NOT NULL AND datedebut != '' THEN 'datedebut'
          WHEN datefeui IS NOT NULL AND datefeui != '' THEN 'datefeui'
          ELSE 'AUCUNE'
        END as colonne_date_principale
      FROM bordereau_commissions
      ORDER BY exercice DESC, numefeui DESC
      LIMIT 10
    `;
    
    const result = await pool.query(query);
    
    console.log(`\n📊 Total bordereaux dans la table: ${result.rowCount}`);
    console.log('\n📋 Échantillon des 10 derniers bordereaux:\n');
    
    result.rows.forEach((row, index) => {
      console.log(`  ${index + 1}. ID=${row.id} | Exercice=${row.exercice} | Num=${row.numefeui}`);
      console.log(`     Code apporteur: ${row.codeappin}`);
      console.log(`     datedebut: "${row.datedebut}" ${row.datedebut ? '✅' : '❌'}`);
      console.log(`     datefin: "${row.datefin}" ${row.datefin ? '✅' : '❌'}`);
      console.log(`     datefeui: "${row.datefeui}" ${row.datefeui ? '✅' : '❌'}`);
      console.log(`     Colonne principale: ${row.colonne_date_principale}`);
      console.log('');
    });
    
    console.log('🔍 === FIN DIAGNOSTIC ===\n');
    
    res.json({
      status: 'success',
      message: 'Diagnostic terminé - voir la console du serveur',
      data: result.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur diagnostic:', error);
    res.status(500).json({ 
      status: 'error',
      message: error.message
    });
  }
});

// Gestion des 404
app.use((req, res) => {
  res.status(404).json({
    status: 'error',
    message: 'Endpoint not found',
    requestedUrl: req.originalUrl
  });
});

// Gestion centrale des erreurs
app.use((err, req, res, next) => {
  console.error('[ERROR]', err.stack);
  
  const statusCode = err.statusCode || 500;
  const message = statusCode === 500 ? 'Internal server error' : err.message;
  
  res.status(statusCode).json({
    status: 'error',
    message: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Configuration du serveur (TOUJOURS sur le port défini, pas de changement automatique)
const PORT = Number(process.env.PORT) || 5000;
const HOST = process.env.HOST || '0.0.0.0';

const server = app.listen(PORT, HOST, () => {
  console.log(`🚀 Server ready at http://${HOST}:${PORT}`);
  console.log(`🔗 Test endpoint: http://localhost:${PORT}/test-db`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ ERREUR: Le port ${PORT} est déjà utilisé !`);
    console.error(`💡 Arrêtez le processus qui utilise le port ${PORT} avec:`);
    console.error(`   taskkill /F /IM node.exe`);
    process.exit(1);
  } else {
    console.error('❌ Erreur lors du démarrage du serveur:', err.message);
    process.exit(1);
  }
});

// Gestion propre des arrêts
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Closing server...');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});