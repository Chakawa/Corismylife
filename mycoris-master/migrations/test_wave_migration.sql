-- ============================================
-- Script de Test Post-Migration Wave
-- ============================================
-- Ce script verifie que toutes les colonnes
-- necessaires pour Wave sont presentes
-- ============================================

\echo ''
\echo '========================================'
\echo 'VERIFICATION POST-MIGRATION WAVE'
\echo '========================================'
\echo ''

-- Test 1: Colonne user_id dans notifications
\echo 'Test 1: notifications.user_id'
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'notifications' AND column_name = 'user_id'
        ) 
        THEN '✓ OK: user_id existe'
        ELSE '✗ ERREUR: user_id manquant'
    END AS resultat;

-- Test 2: Colonnes Wave dans payment_transactions
\echo ''
\echo 'Test 2: payment_transactions (provider, session_id, api_response)'
SELECT 
    column_name,
    data_type,
    CASE 
        WHEN is_nullable = 'YES' THEN 'NULL OK'
        ELSE 'NOT NULL'
    END AS nullable
FROM information_schema.columns 
WHERE table_name = 'payment_transactions' 
  AND column_name IN ('provider', 'session_id', 'api_response')
ORDER BY column_name;

-- Test 3: Colonnes payment dans subscriptions
\echo ''
\echo 'Test 3: subscriptions (payment_method, payment_transaction_id)'
SELECT 
    column_name,
    data_type,
    CASE 
        WHEN is_nullable = 'YES' THEN 'NULL OK'
        ELSE 'NOT NULL'
    END AS nullable
FROM information_schema.columns 
WHERE table_name = 'subscriptions' 
  AND column_name IN ('payment_method', 'payment_transaction_id')
ORDER BY column_name;

-- Test 4: Index sur les nouvelles colonnes
\echo ''
\echo 'Test 4: Index crees'
SELECT 
    indexname AS nom_index,
    tablename AS table_cible
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND (
    indexname LIKE 'idx_notifications_user%' OR
    indexname LIKE 'idx_payment_transactions_provider%' OR
    indexname LIKE 'idx_payment_transactions_session%' OR
    indexname LIKE 'idx_subscriptions_payment%'
  )
ORDER BY tablename, indexname;

-- Test 5: Comptage des enregistrements
\echo ''
\echo 'Test 5: Comptage des enregistrements'
SELECT 
    'notifications' AS table_name,
    COUNT(*) AS nombre_enregistrements
FROM notifications
UNION ALL
SELECT 
    'payment_transactions',
    COUNT(*)
FROM payment_transactions
UNION ALL
SELECT 
    'subscriptions',
    COUNT(*)
FROM subscriptions;

-- Resultat final
\echo ''
\echo '========================================'
\echo 'VERIFICATION TERMINEE'
\echo '========================================'
\echo ''
\echo 'Si tous les tests affichent "OK", votre'
\echo 'base de donnees est prete pour Wave !'
\echo ''
