-- ============================================
-- AJOUT DES COLONNES DE PAIEMENT - TABLE CONTRATS
-- Date: 5 Février 2026
-- Usage: Copier-coller dans le terminal psql
-- ============================================

-- Ajout des colonnes de paiement
ALTER TABLE contrats 
ADD COLUMN IF NOT EXISTS next_payment_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS last_payment_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'a_jour',
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50),
ADD COLUMN IF NOT EXISTS total_paid DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS last_notification_date TIMESTAMP;

-- Commentaires sur les colonnes
COMMENT ON COLUMN contrats.next_payment_date IS 'Prochaine date de paiement (calculée automatiquement)';
COMMENT ON COLUMN contrats.last_payment_date IS 'Date du dernier paiement effectué';
COMMENT ON COLUMN contrats.payment_status IS 'Statut: a_jour, echeance_proche, en_retard';
COMMENT ON COLUMN contrats.payment_method IS 'Méthode de paiement: CorisMoney, Orange Money, Wave';
COMMENT ON COLUMN contrats.total_paid IS 'Montant total payé depuis le début';
COMMENT ON COLUMN contrats.notification_sent IS 'Notification de rappel envoyée (true/false)';
COMMENT ON COLUMN contrats.last_notification_date IS 'Date du dernier rappel envoyé';

-- Fonction pour calculer la prochaine date de paiement
CREATE OR REPLACE FUNCTION calculate_next_payment_date(
  date_debut TIMESTAMP,
  periodicite_val VARCHAR
) RETURNS TIMESTAMP AS $$
BEGIN
  RETURN CASE 
    WHEN LOWER(periodicite_val) LIKE '%mens%' THEN date_debut + INTERVAL '1 month'
    WHEN LOWER(periodicite_val) LIKE '%trim%' THEN date_debut + INTERVAL '3 months'
    WHEN LOWER(periodicite_val) LIKE '%sem%' THEN date_debut + INTERVAL '6 months'
    WHEN LOWER(periodicite_val) LIKE '%ann%' THEN date_debut + INTERVAL '1 year'
    ELSE NULL
  END;
END;
$$ LANGUAGE plpgsql;

-- Initialiser next_payment_date pour les contrats existants actifs
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(
  COALESCE(dateeffet, NOW()), 
  periodicite
)
WHERE etat IN ('actif', 'en cours', 'valide', 'active', 'EN COURS', 'Actif', 'Valide')
  AND periodicite IS NOT NULL
  AND periodicite != ''
  AND next_payment_date IS NULL;

-- Mettre à jour payment_status basé sur next_payment_date
UPDATE contrats
SET payment_status = CASE
  WHEN next_payment_date IS NULL THEN 'a_jour'
  WHEN next_payment_date::date - CURRENT_DATE < 0 THEN 'en_retard'
  WHEN next_payment_date::date - CURRENT_DATE <= 5 THEN 'echeance_proche'
  ELSE 'a_jour'
END
WHERE next_payment_date IS NOT NULL;

-- Afficher résultat
SELECT 
  COUNT(*) as total_contrats,
  COUNT(*) FILTER (WHERE next_payment_date IS NOT NULL) as avec_date_paiement,
  COUNT(*) FILTER (WHERE payment_status = 'a_jour') as a_jour,
  COUNT(*) FILTER (WHERE payment_status = 'echeance_proche') as echeance_proche,
  COUNT(*) FILTER (WHERE payment_status = 'en_retard') as en_retard
FROM contrats
WHERE etat IN ('actif', 'en cours', 'valide', 'active', 'EN COURS', 'Actif', 'Valide');
