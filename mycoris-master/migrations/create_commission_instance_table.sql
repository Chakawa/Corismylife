/**
 * ================================================
 * MIGRATION: Création de la table commission_instance
 * ================================================
 * 
 * Cette table stocke les commissions des commerciaux.
 * Les données sont insérées directement (pas de calcul automatique).
 * 
 * STRUCTURE:
 * - id: Identifiant unique
 * - code_apporteur: Code du commercial (clé étrangère vers users.code_apporteur)
 * - montant_commission: Montant de la commission
 * - date_calcul: Date de la commission
 * - created_at: Date de création
 * - updated_at: Date de dernière modification
 * 
 * RELATIONS:
 * - commission_instance.code_apporteur → users.code_apporteur
 */

-- Supprimer la table si elle existe pour la recréer
DROP TABLE IF EXISTS commission_instance CASCADE;

-- Créer la table
CREATE TABLE commission_instance (
  id SERIAL PRIMARY KEY,
  code_apporteur VARCHAR(50) NOT NULL,
  montant_commission DECIMAL(15, 2) NOT NULL,
  date_calcul TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Contrainte de clé étrangère
  CONSTRAINT fk_commission_apporteur 
    FOREIGN KEY (code_apporteur) 
    REFERENCES users(code_apporteur) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
    
  -- Contrainte de validation
  CONSTRAINT check_montant_commission_positive 
    CHECK (montant_commission >= 0)
);

-- Index pour les recherches par code apporteur
CREATE INDEX IF NOT EXISTS idx_commission_code_apporteur 
ON commission_instance(code_apporteur);

-- Index pour les recherches par période
CREATE INDEX IF NOT EXISTS idx_commission_apporteur_date 
ON commission_instance(code_apporteur, date_calcul);

-- Trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_commission_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_commission_instance_timestamp ON commission_instance;
CREATE TRIGGER update_commission_instance_timestamp
BEFORE UPDATE ON commission_instance
FOR EACH ROW
EXECUTE FUNCTION update_commission_timestamp();
