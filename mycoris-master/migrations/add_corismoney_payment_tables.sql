-- Migration pour l'intégration CorisMoney
-- Créer les tables pour gérer les paiements et transactions

-- Table pour les demandes d'OTP
CREATE TABLE IF NOT EXISTS payment_otp_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    code_pays VARCHAR(10) NOT NULL,
    telephone VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table pour les transactions de paiement
CREATE TABLE IF NOT EXISTS payment_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    subscription_id INTEGER REFERENCES subscriptions(id) ON DELETE SET NULL,
    transaction_id VARCHAR(100) UNIQUE,
    code_pays VARCHAR(10) NOT NULL,
    telephone VARCHAR(20) NOT NULL,
    montant DECIMAL(15, 2) NOT NULL,
    statut VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    description TEXT,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_transaction_id ON payment_transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_statut ON payment_transactions(statut);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_subscription_id ON payment_transactions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payment_otp_requests_user_id ON payment_otp_requests(user_id);

-- Commentaires sur les tables
COMMENT ON TABLE payment_otp_requests IS 'Historique des demandes d''OTP pour les paiements CorisMoney';
COMMENT ON TABLE payment_transactions IS 'Historique des transactions de paiement via CorisMoney';

-- Commentaires sur les colonnes importantes
COMMENT ON COLUMN payment_transactions.statut IS 'Statut de la transaction: PENDING, SUCCESS, FAILED, VERIFIED';
COMMENT ON COLUMN payment_transactions.transaction_id IS 'ID de transaction retourné par CorisMoney';
