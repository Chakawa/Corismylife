-- =====================================================
-- Table CONTRACTS - Gestion des contrats d'assurance
-- =====================================================
-- Cette table stocke les contrats activés après paiement
-- Une proposition devient un contrat après paiement réussi

CREATE TABLE IF NOT EXISTS contracts (
  id SERIAL PRIMARY KEY,
  subscription_id INTEGER UNIQUE REFERENCES subscriptions(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  contract_number VARCHAR(100) UNIQUE NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  amount DECIMAL(15, 2) NOT NULL,
  periodicite VARCHAR(50),
  start_date TIMESTAMP NOT NULL,
  next_payment_date TIMESTAMP,
  end_date TIMESTAMP,
  duration_years INTEGER,
  payment_method VARCHAR(50),
  last_payment_date TIMESTAMP,
  total_paid DECIMAL(15, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_contracts_user_id ON contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_contracts_subscription_id ON contracts(subscription_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_contracts_next_payment ON contracts(next_payment_date);

-- Commentaires sur les colonnes
COMMENT ON TABLE contracts IS 'Contrats d''assurance activés après paiement';
COMMENT ON COLUMN contracts.subscription_id IS 'Référence vers la souscription (proposition)';
COMMENT ON COLUMN contracts.contract_number IS 'Numéro unique du contrat (ex: CORIS-SER-1738732800000)';
COMMENT ON COLUMN contracts.status IS 'Statut du contrat: active, suspended, expired, cancelled';
COMMENT ON COLUMN contracts.next_payment_date IS 'Date de la prochaine échéance (NULL si paiement unique)';
COMMENT ON COLUMN contracts.duration_years IS 'Durée du contrat en années';
COMMENT ON COLUMN contracts.total_paid IS 'Montant total payé depuis le début du contrat';

-- =====================================================
-- Mise à jour automatique de updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION update_contracts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_contracts_timestamp ON contracts;
CREATE TRIGGER trigger_update_contracts_timestamp
  BEFORE UPDATE ON contracts
  FOR EACH ROW
  EXECUTE FUNCTION update_contracts_updated_at();

-- =====================================================
-- Calcul de la date de fin de contrat
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_contract_end_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.duration_years IS NOT NULL AND NEW.start_date IS NOT NULL THEN
    NEW.end_date = NEW.start_date + (NEW.duration_years || ' years')::INTERVAL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_calculate_end_date ON contracts;
CREATE TRIGGER trigger_calculate_end_date
  BEFORE INSERT OR UPDATE ON contracts
  FOR EACH ROW
  EXECUTE FUNCTION calculate_contract_end_date();

-- =====================================================
-- Vue pour les contrats actifs avec détails
-- =====================================================
CREATE OR REPLACE VIEW active_contracts_details AS
SELECT 
  c.id,
  c.contract_number,
  c.product_name,
  c.status,
  c.amount,
  c.periodicite,
  c.start_date,
  c.next_payment_date,
  c.end_date,
  c.duration_years,
  c.payment_method,
  c.total_paid,
  c.created_at,
  u.nom_prenom as client_name,
  u.email as client_email,
  u.telephone as client_phone,
  s.id as subscription_id,
  s.statut as subscription_status,
  -- Calcul du nombre de paiements restants
  CASE 
    WHEN c.periodicite = 'unique' THEN 0
    WHEN c.periodicite = 'mensuelle' THEN 
      EXTRACT(MONTH FROM AGE(c.end_date, CURRENT_DATE))::INTEGER
    WHEN c.periodicite = 'trimestrielle' THEN 
      (EXTRACT(MONTH FROM AGE(c.end_date, CURRENT_DATE)) / 3)::INTEGER
    WHEN c.periodicite = 'semestrielle' THEN 
      (EXTRACT(MONTH FROM AGE(c.end_date, CURRENT_DATE)) / 6)::INTEGER
    WHEN c.periodicite = 'annuelle' THEN 
      EXTRACT(YEAR FROM AGE(c.end_date, CURRENT_DATE))::INTEGER
    ELSE 0
  END as payments_remaining,
  -- Statut du prochain paiement
  CASE 
    WHEN c.next_payment_date IS NULL THEN 'Paiement unique effectué'
    WHEN c.next_payment_date < CURRENT_DATE THEN 'En retard'
    WHEN c.next_payment_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'Échéance proche'
    ELSE 'À jour'
  END as payment_status
FROM contracts c
LEFT JOIN users u ON c.user_id = u.id
LEFT JOIN subscriptions s ON c.subscription_id = s.id
WHERE c.status = 'active';

-- =====================================================
-- Statistiques des contrats
-- =====================================================
CREATE OR REPLACE VIEW contracts_statistics AS
SELECT 
  product_name,
  COUNT(*) as total_contracts,
  SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_contracts,
  SUM(CASE WHEN status = 'suspended' THEN 1 ELSE 0 END) as suspended_contracts,
  SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) as expired_contracts,
  SUM(total_paid) as total_revenue,
  AVG(amount) as average_premium,
  COUNT(CASE WHEN next_payment_date < CURRENT_DATE THEN 1 END) as late_payments
FROM contracts
GROUP BY product_name;

-- =====================================================
-- Données de test (optionnel)
-- =====================================================
-- Exemple de contrat après paiement réussi
-- INSERT INTO contracts (
--   subscription_id, user_id, contract_number, product_name,
--   status, amount, periodicite, start_date, next_payment_date,
--   duration_years, payment_method
-- ) VALUES (
--   1, 1, 'CORIS-SER-1738732800000', 'Coris Sérénité',
--   'active', 50000, 'mensuelle', NOW(), NOW() + INTERVAL '1 month',
--   5, 'CorisMoney'
-- );

-- =====================================================
-- Requêtes utiles
-- =====================================================

-- Voir tous les contrats actifs d'un utilisateur
-- SELECT * FROM active_contracts_details WHERE user_id = 1;

-- Voir les contrats avec échéance proche (7 jours)
-- SELECT contract_number, client_name, next_payment_date, amount
-- FROM active_contracts_details
-- WHERE payment_status = 'Échéance proche'
-- ORDER BY next_payment_date;

-- Voir les paiements en retard
-- SELECT contract_number, client_name, next_payment_date, amount
-- FROM active_contracts_details
-- WHERE payment_status = 'En retard'
-- ORDER BY next_payment_date;

-- Statistiques par produit
-- SELECT * FROM contracts_statistics ORDER BY total_revenue DESC;
