-- ============================================
-- MIGRATION: Tables de gestion des paiements
-- ============================================
-- Crée les tables nécessaires pour:
-- 1. Enregistrer les transactions de paiement
-- 2. Gérer les rappels de paiements (primes mensuelles)
-- ============================================

-- ============================================
-- 1. TABLE: payment_transactions
-- ============================================
-- Enregistre toutes les transactions de paiement
-- pour les contrats et propositions
CREATE TABLE IF NOT EXISTS payment_transactions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contract_id INTEGER,
  subscription_id INTEGER,
  amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL, -- 'Wave', 'CorisMoney', 'OrangeMoney'
  premium_type VARCHAR(50) DEFAULT 'monthly', -- 'monthly', 'annual', 'initial'
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'cancelled'
  transaction_reference VARCHAR(255), -- ID fourni par le fournisseur de paiement
  payment_proof TEXT, -- JSON avec détails du paiement
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_contract ON payment_transactions(contract_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_subscription ON payment_transactions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

-- ============================================
-- 2. TABLE: premium_renewals
-- ============================================
-- Enregistre les primes renouvelables (mensuelles, annuelles)
-- pour les contrats actifs
CREATE TABLE IF NOT EXISTS premium_renewals (
  id SERIAL PRIMARY KEY,
  contract_id INTEGER NOT NULL REFERENCES contrats(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  due_date DATE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  frequency VARCHAR(50) NOT NULL, -- 'monthly', 'annual', 'quarterly'
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'paid', 'overdue', 'cancelled'
  payment_transaction_id INTEGER REFERENCES payment_transactions(id),
  reminder_sent BOOLEAN DEFAULT FALSE,
  last_payment_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_premium_renewals_contract ON premium_renewals(contract_id);
CREATE INDEX IF NOT EXISTS idx_premium_renewals_user ON premium_renewals(user_id);
CREATE INDEX IF NOT EXISTS idx_premium_renewals_due_date ON premium_renewals(due_date);
CREATE INDEX IF NOT EXISTS idx_premium_renewals_status ON premium_renewals(status);

-- ============================================
-- 3. TABLE: payment_reminders
-- ============================================
-- Enregistre les rappels envoyés pour les paiements
CREATE TABLE IF NOT EXISTS payment_reminders (
  id SERIAL PRIMARY KEY,
  premium_renewal_id INTEGER NOT NULL REFERENCES premium_renewals(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reminder_type VARCHAR(50), -- 'sms', 'email', 'push'
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  delivery_status VARCHAR(50) DEFAULT 'sent' -- 'sent', 'failed', 'bounced'
);

CREATE INDEX IF NOT EXISTS idx_payment_reminders_user ON payment_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_reminders_renewal ON payment_reminders(premium_renewal_id);

-- ============================================
-- TRIGGERS ET CONTRAINTES
-- ============================================

-- Mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_payment_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_payment_transactions_updated_at
BEFORE UPDATE ON payment_transactions
FOR EACH ROW
EXECUTE FUNCTION update_payment_transactions_updated_at();

-- Mettre à jour premium_renewals.updated_at
CREATE OR REPLACE FUNCTION update_premium_renewals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_premium_renewals_updated_at
BEFORE UPDATE ON premium_renewals
FOR EACH ROW
EXECUTE FUNCTION update_premium_renewals_updated_at();

-- ============================================
-- VERIFICATION
-- ============================================

-- Vérifier que les tables ont été créées
SELECT 
  't'::regclass,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 't') as column_count
FROM (
  VALUES 
    ('payment_transactions'::text),
    ('premium_renewals'::text),
    ('payment_reminders'::text)
) AS tables(t)
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = t);

-- Afficher un résumé
\echo '✅ Migration tables paiements complétée'
\echo '   - payment_transactions: Pour enregistrer les transactions'
\echo '   - premium_renewals: Pour gérer les primes récurrentes'
\echo '   - payment_reminders: Pour les rappels d''envoi'
