-- Migration: Système de questionnaire médical flexible
-- Date: 2025-12-18
-- Description: Tables pour gérer les questions et réponses du questionnaire médical

-- Supprimer l'ancienne table si elle existe
DROP TABLE IF EXISTS questionnaire_medical CASCADE;

-- Table 1: questionnaire_medical - Stocke les questions
CREATE TABLE IF NOT EXISTS questionnaire_medical (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    libelle TEXT NOT NULL,
    type_question VARCHAR(50) NOT NULL, -- 'taille_poids', 'oui_non', 'oui_non_details'
    ordre INTEGER NOT NULL,
    champ_detail_1_label VARCHAR(255), -- Ex: "À quelles dates ?"
    champ_detail_2_label VARCHAR(255), -- Ex: "Pour quels motifs ?"
    champ_detail_3_label VARCHAR(255), -- Pour certaines questions
    obligatoire BOOLEAN DEFAULT true,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: souscription_questionnaire - Stocke les réponses du souscripteur
CREATE TABLE IF NOT EXISTS souscription_questionnaire (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questionnaire_medical(id) ON DELETE CASCADE,
    reponse_oui_non BOOLEAN,
    reponse_text TEXT,
    reponse_detail_1 TEXT,
    reponse_detail_2 TEXT,
    reponse_detail_3 TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(subscription_id, question_id)
);

-- Index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_souscription_questionnaire_subscription ON souscription_questionnaire(subscription_id);
CREATE INDEX IF NOT EXISTS idx_souscription_questionnaire_question ON souscription_questionnaire(question_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_medical_ordre ON questionnaire_medical(ordre);
CREATE INDEX IF NOT EXISTS idx_questionnaire_medical_actif ON questionnaire_medical(actif);

-- Insertion des 10 questions par défaut
INSERT INTO questionnaire_medical (code, libelle, type_question, ordre, champ_detail_1_label, champ_detail_2_label, obligatoire) VALUES
('Q001', 'Votre taille et poids', 'taille_poids', 1, 'Taille (cm)', 'Poids (kg)', true),
('Q002', 'Au cours des 5 dernières années, avez-vous dû interrompre votre travail plus de 30 jours consécutifs par maladie ou accident ?', 'oui_non_details', 2, 'À quelles dates ?', 'Pour quels motifs ?', true),
('Q003', 'Suivez-vous actuellement un traitement médical ou un régime quelconque ?', 'oui_non_details', 3, 'Lequel ?', 'Depuis quand ?', true),
('Q004', 'Avez-vous ou devez-vous subir une intervention chirurgicale ?', 'oui_non_details', 4, 'À quelle date ?', 'Pour quels motifs ?', true),
('Q005', 'Êtes-vous atteint d''infirmité, d''une invalidité ou d''une maladie chronique quelconque ?', 'oui_non_details', 5, 'Laquelle ?', 'Depuis quand ?', true),
('Q006', 'Avez-vous des maladies quelconques dont vous avez connaissance ?', 'oui_non_details', 6, 'Lesquelles ?', 'Depuis quand ?', true),
('Q007', 'Avez-vous eu ces 3 dernières années des infections chroniques des voies respiratoires ?', 'oui_non_details', 7, 'Depuis quand ?', NULL, true),
('Q008', 'Avez-vous eu au cours de ces 3 dernières années des dépressions ou autres troubles psycho neurologiques sans cause connue ?', 'oui_non_details', 8, 'Combien ?', 'Quand ?', true),
('Q009', 'Avez-vous fait le test de dépistage du VIH ?', 'oui_non_details', 9, 'Date du dernier test ?', 'Quel est le résultat ?', true),
('Q010', 'Avez-vous fait le test d''hépatite B et/ou C ?', 'oui_non_details', 10, 'Dates des derniers tests ?', 'Quels résultats ?', true);

-- Commentaires
COMMENT ON TABLE questionnaire_medical IS 'Questions du questionnaire médical - Configurable depuis la base de données';
COMMENT ON TABLE souscription_questionnaire IS 'Réponses au questionnaire médical pour chaque souscription';
COMMENT ON COLUMN questionnaire_medical.type_question IS 'Type de question: taille_poids, oui_non, oui_non_details';
COMMENT ON COLUMN questionnaire_medical.ordre IS 'Ordre d''affichage de la question';
