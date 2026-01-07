const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function runMigration() {
  try {
    console.log('🔄 Exécution de la migration notifications...');
    
    // Vérifie que la table users existe
    console.log('📝 Vérification de la table users...');
    const usersCheck = await pool.query(
      "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users')"
    );
    
    if (!usersCheck.rows[0].exists) {
      throw new Error('La table users n\'existe pas');
    }
    console.log('✅ Table users trouvée');
    
    // Vérifie si la table notifications existe déjà
    const notifCheck = await pool.query(
      "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications')"
    );
    
    if (notifCheck.rows[0].exists) {
      console.log('📝 Suppression de la table notifications existante...');
      await pool.query('DROP TABLE IF EXISTS notifications CASCADE');
      console.log('✅ Table notifications supprimée');
    }
    
    // Crée la table notifications
    console.log('📝 Création de la table notifications...');
    const createTableSQL = `
      CREATE TABLE notifications (
        id SERIAL PRIMARY KEY,
        admin_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT,
        reference_id INTEGER,
        reference_type VARCHAR(50),
        is_read BOOLEAN DEFAULT false,
        read_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        action_url VARCHAR(255)
      )
    `;
    
    await pool.query(createTableSQL);
    console.log('✅ Table notifications créée');
    
    // Crée les indexes
    console.log('📝 Création des indexes...');
    await pool.query('CREATE INDEX idx_notifications_admin ON notifications(admin_id)');
    await pool.query('CREATE INDEX idx_notifications_is_read ON notifications(is_read)');
    await pool.query('CREATE INDEX idx_notifications_type ON notifications(type)');
    await pool.query('CREATE INDEX idx_notifications_created_at ON notifications(created_at)');
    console.log('✅ Indexes créés');
    
    console.log('✅ Migration notifications executée avec succès');
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur migration:', error.message);
    await pool.end();
    process.exit(1);
  }
}

runMigration();
