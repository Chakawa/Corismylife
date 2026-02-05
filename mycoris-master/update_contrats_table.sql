-- =====================================================
-- Mise à jour de la table CONTRATS
-- Ajout des colonnes pour gestion des paiements et notifications
-- =====================================================

-- Vérifier les colonnes existantes
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'contrats';

-- Ajouter les colonnes si elles n'existent pas
ALTER TABLE contrats 
ADD COLUMN IF NOT EXISTS next_payment_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS last_payment_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50),
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'a_jour',
ADD COLUMN IF NOT EXISTS total_paid DECIMAL(15, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS subscription_id INTEGER REFERENCES subscriptions(id),
ADD COLUMN IF NOT EXISTS contract_number VARCHAR(100),
ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS last_notification_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_contrats_next_payment ON contrats(next_payment_date);
CREATE INDEX IF NOT EXISTS idx_contrats_payment_status ON contrats(payment_status);
CREATE INDEX IF NOT EXISTS idx_contrats_subscription_id ON contrats(subscription_id);
CREATE INDEX IF NOT EXISTS idx_contrats_etat ON contrats(etat);

-- Commentaires sur les nouvelles colonnes
COMMENT ON COLUMN contrats.next_payment_date IS 'Date de la prochaine échéance de paiement (NULL si paiement unique)';
COMMENT ON COLUMN contrats.last_payment_date IS 'Date du dernier paiement effectué';
COMMENT ON COLUMN contrats.payment_method IS 'Méthode de paiement utilisée (CorisMoney, Orange Money, Wave, etc.)';
COMMENT ON COLUMN contrats.payment_status IS 'Statut du paiement: a_jour, en_retard, echeance_proche (5 jours)';
COMMENT ON COLUMN contrats.total_paid IS 'Montant total payé depuis le début du contrat';
COMMENT ON COLUMN contrats.subscription_id IS 'Lien vers la souscription d\'origine';
COMMENT ON COLUMN contrats.contract_number IS 'Numéro unique du contrat (pour nouveau système)';
COMMENT ON COLUMN contrats.notification_sent IS 'Indique si une notification a été envoyée pour le prochain paiement';
COMMENT ON COLUMN contrats.last_notification_date IS 'Date de la dernière notification envoyée';

-- =====================================================
-- Fonction pour calculer la prochaine date de paiement
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_next_payment_date(
  current_date TIMESTAMP,
  periodicite VARCHAR
) RETURNS TIMESTAMP AS $$
BEGIN
  CASE LOWER(periodicite)
    WHEN 'mensuelle', 'mensuel' THEN
      RETURN current_date + INTERVAL '1 month';
    WHEN 'trimestrielle', 'trimestriel' THEN
      RETURN current_date + INTERVAL '3 months';
    WHEN 'semestrielle', 'semestriel' THEN
      RETURN current_date + INTERVAL '6 months';
    WHEN 'annuelle', 'annuel' THEN
      RETURN current_date + INTERVAL '1 year';
    ELSE
      -- Paiement unique
      RETURN NULL;
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Fonction pour mettre à jour le statut de paiement
-- =====================================================
CREATE OR REPLACE FUNCTION update_payment_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Si pas de prochaine échéance, statut = a_jour
  IF NEW.next_payment_date IS NULL THEN
    NEW.payment_status = 'a_jour';
    RETURN NEW;
  END IF;

  -- Vérifier le nombre de jours avant l'échéance
  DECLARE
    days_until_payment INTEGER;
  BEGIN
    days_until_payment := EXTRACT(DAY FROM (NEW.next_payment_date - CURRENT_DATE));
    
    IF days_until_payment < 0 THEN
      -- En retard
      NEW.payment_status = 'en_retard';
    ELSIF days_until_payment <= 5 THEN
      -- Échéance proche (5 jours ou moins)
      NEW.payment_status = 'echeance_proche';
    ELSE
      -- À jour
      NEW.payment_status = 'a_jour';
    END IF;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement le payment_status
DROP TRIGGER IF EXISTS trigger_update_payment_status ON contrats;
CREATE TRIGGER trigger_update_payment_status
  BEFORE INSERT OR UPDATE ON contrats
  FOR EACH ROW
  EXECUTE FUNCTION update_payment_status();

-- =====================================================
-- Trigger pour updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION update_contrats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_contrats_timestamp ON contrats;
CREATE TRIGGER trigger_update_contrats_timestamp
  BEFORE UPDATE ON contrats
  FOR EACH ROW
  EXECUTE FUNCTION update_contrats_updated_at();

-- =====================================================
-- Initialiser next_payment_date pour les contrats existants
-- =====================================================
UPDATE contrats
SET next_payment_date = calculate_next_payment_date(
  COALESCE(last_payment_date, dateeffet, NOW()),
  periodicite
)
WHERE next_payment_date IS NULL
  AND etat IN ('actif', 'en cours', 'valide', 'active')
  AND periodicite IS NOT NULL
  AND periodicite != 'unique';

-- =====================================================
-- Vue pour les contrats nécessitant une notification
-- =====================================================
CREATE OR REPLACE VIEW contrats_notification_needed AS
SELECT 
  c.id,
  c.numepoli,
  c.nom_prenom,
  c.telephone1,
  c.telephone2,
  c.next_payment_date,
  c.prime,
  c.codeprod,
  c.payment_status,
  c.notification_sent,
  c.last_notification_date,
  EXTRACT(DAY FROM (c.next_payment_date - CURRENT_DATE))::INTEGER as jours_restants
FROM contrats c
WHERE c.etat IN ('actif', 'en cours', 'valide', 'active')
  AND c.next_payment_date IS NOT NULL
  AND c.payment_status = 'echeance_proche'
  AND (
    c.notification_sent = false 
    OR c.last_notification_date IS NULL
    OR c.last_notification_date < CURRENT_DATE - INTERVAL '2 days'
  )
ORDER BY c.next_payment_date;

-- =====================================================
-- Vue pour statistiques des paiements
-- =====================================================
CREATE OR REPLACE VIEW contrats_payment_stats AS
SELECT 
  COUNT(*) as total_contrats,
  COUNT(CASE WHEN payment_status = 'a_jour' THEN 1 END) as a_jour,
  COUNT(CASE WHEN payment_status = 'echeance_proche' THEN 1 END) as echeance_proche,
  COUNT(CASE WHEN payment_status = 'en_retard' THEN 1 END) as en_retard,
  SUM(prime) as total_prime_mensuelle,
  SUM(total_paid) as total_encaisse,
  AVG(prime) as prime_moyenne
FROM contrats
WHERE etat IN ('actif', 'en cours', 'valide', 'active');

-- =====================================================
-- Fonction pour obtenir les contrats d'un utilisateur avec statut de paiement
-- =====================================================
CREATE OR REPLACE FUNCTION get_contrats_with_payment_info(
  user_telephone VARCHAR
) RETURNS TABLE (
  id INTEGER,
  numepoli VARCHAR,
  codeprod VARCHAR,
  nom_prenom VARCHAR,
  prime DECIMAL,
  periodicite VARCHAR,
  dateeffet TIMESTAMP,
  dateeche TIMESTAMP,
  etat VARCHAR,
  next_payment_date TIMESTAMP,
  payment_status VARCHAR,
  jours_restants INTEGER,
  total_paid DECIMAL,
  payment_method VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.numepoli,
    c.codeprod,
    c.nom_prenom,
    c.prime,
    c.periodicite,
    c.dateeffet,
    c.dateeche,
    c.etat,
    c.next_payment_date,
    c.payment_status,
    CASE 
      WHEN c.next_payment_date IS NULL THEN NULL
      ELSE EXTRACT(DAY FROM (c.next_payment_date - CURRENT_DATE))::INTEGER
    END as jours_restants,
    c.total_paid,
    c.payment_method
  FROM contrats c
  WHERE (c.telephone1 = user_telephone OR c.telephone2 = user_telephone)
  ORDER BY 
    CASE c.payment_status
      WHEN 'en_retard' THEN 1
      WHEN 'echeance_proche' THEN 2
      WHEN 'a_jour' THEN 3
      ELSE 4
    END,
    c.next_payment_date NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Exemples de requêtes utiles
-- =====================================================

-- Voir tous les contrats nécessitant une notification
-- SELECT * FROM contrats_notification_needed;

-- Voir les statistiques de paiement
-- SELECT * FROM contrats_payment_stats;

-- Obtenir les contrats d'un utilisateur avec info de paiement
-- SELECT * FROM get_contrats_with_payment_info('0707070707');

-- Marquer une notification comme envoyée
-- UPDATE contrats 
-- SET notification_sent = true, last_notification_date = NOW()
-- WHERE id = 123;

-- Enregistrer un paiement
-- UPDATE contrats
-- SET last_payment_date = NOW(),
--     total_paid = total_paid + prime,
--     next_payment_date = calculate_next_payment_date(NOW(), periodicite),
--     notification_sent = false
-- WHERE id = 123;
