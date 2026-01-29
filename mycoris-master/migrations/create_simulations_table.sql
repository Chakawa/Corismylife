-- Table pour stocker les simulations effectuées par les clients
CREATE TABLE IF NOT EXISTS simulations (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NULL,
  produit_nom VARCHAR(100) NOT NULL,
  type_simulation VARCHAR(50) NOT NULL,
  age INTEGER NULL,
  date_naissance DATE NULL,
  capital DECIMAL(15, 2) NULL,
  prime DECIMAL(15, 2) NULL,
  duree_mois INTEGER NULL,
  periodicite VARCHAR(20) NULL,
  resultat_prime DECIMAL(15, 2) NULL,
  resultat_capital DECIMAL(15, 2) NULL,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Créer les index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_simulations_user_id ON simulations(user_id);
CREATE INDEX IF NOT EXISTS idx_simulations_produit ON simulations(produit_nom);
CREATE INDEX IF NOT EXISTS idx_simulations_created_at ON simulations(created_at);
CREATE INDEX IF NOT EXISTS idx_simulations_type ON simulations(type_simulation);
