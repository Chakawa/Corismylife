-- ============================================
-- MIGRATION: Fix Wave Payment Database Schema
-- ============================================
-- Ce script ajoute toutes les colonnes manquantes pour supporter
-- les paiements Wave et corriger les erreurs existantes
-- ============================================

-- ==============================================
-- 1. FIX TABLE NOTIFICATIONS
-- ==============================================
-- Ajouter user_id si manquant
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE notifications 
        ADD COLUMN user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE;
        
        CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
        CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
        
        RAISE NOTICE '✅ Colonne user_id ajoutée à la table notifications';
    ELSE
        RAISE NOTICE 'ℹ️  Colonne user_id existe déjà dans notifications';
    END IF;
END $$;

-- ==============================================
-- 2. FIX TABLE PAYMENT_TRANSACTIONS
-- ==============================================

-- Ajouter provider (pour distinguer Wave/CorisMoney/OrangeMoney)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payment_transactions' AND column_name = 'provider'
    ) THEN
        ALTER TABLE payment_transactions 
        ADD COLUMN provider VARCHAR(50) DEFAULT 'CorisMoney' CHECK (provider IN ('Wave', 'CorisMoney', 'OrangeMoney'));
        
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_provider ON payment_transactions(provider);
        
        RAISE NOTICE '✅ Colonne provider ajoutée à payment_transactions';
    ELSE
        RAISE NOTICE 'ℹ️  Colonne provider existe déjà dans payment_transactions';
    END IF;
END $$;

-- Ajouter session_id (pour Wave checkout session)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payment_transactions' AND column_name = 'session_id'
    ) THEN
        ALTER TABLE payment_transactions 
        ADD COLUMN session_id VARCHAR(255);
        
        CREATE INDEX IF NOT EXISTS idx_payment_transactions_session_id ON payment_transactions(session_id);
        
        RAISE NOTICE '✅ Colonne session_id ajoutée à payment_transactions';
    ELSE
        RAISE NOTICE 'ℹ️  Colonne session_id existe déjà dans payment_transactions';
    END IF;
END $$;

-- Ajouter api_response si manquant (certaines installations l'ont déjà)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payment_transactions' AND column_name = 'api_response'
    ) THEN
        ALTER TABLE payment_transactions 
        ADD COLUMN api_response JSONB;
        
        RAISE NOTICE '✅ Colonne api_response ajoutée à payment_transactions';
    ELSE
        RAISE NOTICE 'ℹ️  Colonne api_response existe déjà dans payment_transactions';
    END IF;
END $$;

-- ==============================================
-- 3. FIX TABLE SUBSCRIPTIONS
-- ==============================================

-- Ajouter payment_method
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'subscriptions' AND column_name = 'payment_method'
    ) THEN
        ALTER TABLE subscriptions 
        ADD COLUMN payment_method VARCHAR(50);
        
        CREATE INDEX IF NOT EXISTS idx_subscriptions_payment_method ON subscriptions(payment_method);
        
        RAISE NOTICE '✅ Colonne payment_method ajoutée à subscriptions';
    ELSE
        RAISE NOTICE 'ℹ️  Colonne payment_method existe déjà dans subscriptions';
    END IF;
END $$;

-- Ajouter payment_transaction_id
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'subscriptions' AND column_name = 'payment_transaction_id'
    ) THEN
        ALTER TABLE subscriptions 
        ADD COLUMN payment_transaction_id VARCHAR(100);
        
        CREATE INDEX IF NOT EXISTS idx_subscriptions_payment_transaction_id ON subscriptions(payment_transaction_id);
        
        RAISE NOTICE '✅ Colonne payment_transaction_id ajoutée à subscriptions';
    ELSE
        RAISE NOTICE 'ℹ️  Colonne payment_transaction_id existe déjà dans subscriptions';
    END IF;
END $$;

-- ==============================================
-- 4. COMMENTAIRES ET DOCUMENTATION
-- ==============================================

COMMENT ON COLUMN notifications.user_id IS 'Référence vers l''utilisateur destinataire de la notification';

COMMENT ON COLUMN payment_transactions.provider IS 'Fournisseur de paiement: Wave, CorisMoney, OrangeMoney';
COMMENT ON COLUMN payment_transactions.session_id IS 'ID de session Wave checkout (si provider=Wave)';
COMMENT ON COLUMN payment_transactions.api_response IS 'Réponse brute de l''API du provider (JSON)';

COMMENT ON COLUMN subscriptions.payment_method IS 'Méthode de paiement utilisée (Wave/CorisMoney/OrangeMoney)';
COMMENT ON COLUMN subscriptions.payment_transaction_id IS 'Référence vers la transaction de paiement';

-- ==============================================
-- 5. MESSAGE FINAL
-- ==============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ MIGRATION TERMINÉE AVEC SUCCÈS !';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Colonnes ajoutées:';
    RAISE NOTICE '   • notifications.user_id';
    RAISE NOTICE '   • payment_transactions.provider';
    RAISE NOTICE '   • payment_transactions.session_id';
    RAISE NOTICE '   • payment_transactions.api_response (si manquante)';
    RAISE NOTICE '   • subscriptions.payment_method';
    RAISE NOTICE '   • subscriptions.payment_transaction_id';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Votre base de données est maintenant compatible Wave !';
    RAISE NOTICE '';
END $$;
