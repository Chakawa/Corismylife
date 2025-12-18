-- Migration: Système de questionnaire médical dynamique
-- Date: 2025-12-18
-- Description: Questions stockées en base, réponses liées aux souscriptions

-- ============================================
-- TABLE 1: Questions du questionnaire médical
-- ============================================
CREATE TABLE IF NOT EXISTS questionnaire_medical (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,  -- Ex: Q1, Q2, Q3...
    libelle TEXT NOT NULL,              -- Texte de la question
    type_question VARCHAR(50) NOT NULL, -- 'oui_non', 'texte', 'nombre', 'taille_poids'
    ordre INTEGER NOT NULL,             -- Ordre d'affichage (1, 2, 3...)
    actif BOOLEAN DEFAULT TRUE,         -- Permet de désactiver une question
    
    -- Champs de détails conditionnels (si réponse OUI)
    champ_detail_1_label VARCHAR(255),  -- Ex: "À quelles dates ?"
    champ_detail_1_type VARCHAR(50),    -- 'texte', 'date', 'nombre'
    champ_detail_2_label VARCHAR(255),  -- Ex: "Pour quels motifs ?"
    champ_detail_2_type VARCHAR(50),
    champ_detail_3_label VARCHAR(255),
    champ_detail_3_type VARCHAR(50),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE 2: Réponses aux questions par souscription
-- ============================================
CREATE TABLE IF NOT EXISTS souscription_questionnaire (
    id SERIAL PRIMARY KEY,
    souscription_id INTEGER NOT NULL REFERENCES souscriptions(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questionnaire_medical(id) ON DELETE CASCADE,
    
    -- Réponse principale
    reponse_oui_non BOOLEAN,            -- Pour questions OUI/NON
    reponse_texte TEXT,                 -- Pour questions texte/nombre (Q1: taille, poids)
    
    -- Détails conditionnels (si OUI)
    detail_1 TEXT,
    detail_2 TEXT,
    detail_3 TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Une seule réponse par question par souscription
    UNIQUE(souscription_id, question_id)
);

-- ============================================
-- INDEX pour optimiser les recherches
-- ============================================
CREATE INDEX IF NOT EXISTS idx_questionnaire_medical_ordre ON questionnaire_medical(ordre);
CREATE INDEX IF NOT EXISTS idx_questionnaire_medical_actif ON questionnaire_medical(actif);
CREATE INDEX IF NOT EXISTS idx_souscription_questionnaire_souscription ON souscription_questionnaire(souscription_id);
CREATE INDEX IF NOT EXISTS idx_souscription_questionnaire_question ON souscription_questionnaire(question_id);

-- ============================================
-- INSERTION des 10 questions initiales
-- ============================================
INSERT INTO questionnaire_medical (code, libelle, type_question, ordre, actif, 
    champ_detail_1_label, champ_detail_1_type, 
    champ_detail_2_label, champ_detail_2_type) VALUES

-- Question 1: Taille et Poids (type spécial)
('Q1', 'Votre taille et votre poids', 'taille_poids', 1, TRUE, 
    'Taille (cm)', 'nombre', 
    'Poids (kg)', 'nombre'),

-- Question 2: Interruption travail
('Q2', 'Au cours des 5 dernières années, avez-vous dû interrompre votre travail plus de 30 jours consécutifs par maladie ou accident ?', 
    'oui_non', 2, TRUE, 
    'À quelles dates ?', 'texte', 
    'Pour quels motifs ?', 'texte'),

-- Question 3: Traitement médical
('Q3', 'Suivez-vous actuellement un traitement médical ou un régime quelconque ?', 
    'oui_non', 3, TRUE, 
    'Lequel ?', 'texte', 
    'Depuis quand ?', 'texte'),

-- Question 4: Intervention chirurgicale
('Q4', 'Avez-vous ou devez-vous subir une intervention chirurgicale ?', 
    'oui_non', 4, TRUE, 
    'À quelle date ?', 'texte', 
    'Pour quels motifs ?', 'texte'),

-- Question 5: Infirmité/invalidité
('Q5', 'Êtes-vous atteint d''infirmité, d''une invalidité ou d''une maladie chronique quelconque ?', 
    'oui_non', 5, TRUE, 
    'Laquelle ?', 'texte', 
    'Depuis quand ?', 'texte'),

-- Question 6: Maladies connues
('Q6', 'Avez-vous des maladies quelconques dont vous avez connaissance ?', 
    'oui_non', 6, TRUE, 
    'Lesquelles ?', 'texte', 
    'Depuis quand ?', 'texte'),

-- Question 7: Infections respiratoires
('Q7', 'Avez-vous eu ces 3 dernières années des infections chroniques des voies respiratoires ?', 
    'oui_non', 7, TRUE, 
    'Depuis quand ?', 'texte', 
    NULL, NULL),

-- Question 8: Dépressions/troubles psycho
('Q8', 'Avez-vous eu au cours de ces 3 dernières années des dépressions ou autres troubles psycho neurologiques sans cause connue ?', 
    'oui_non', 8, TRUE, 
    'Combien ?', 'texte', 
    'Quand ?', 'texte'),

-- Question 9: Test VIH
('Q9', 'Avez-vous fait le test de dépistage du VIH ?', 
    'oui_non', 9, TRUE, 
    'Date du dernier test ?', 'texte', 
    'Quel est le résultat ?', 'texte'),

-- Question 10: Test hépatite
('Q10', 'Avez-vous fait le test d''hépatite B et/ou C ?', 
    'oui_non', 10, TRUE, 
    'Dates des derniers tests ?', 'texte', 
    'Quels résultats ?', 'texte');

-- ============================================
-- COMMENTAIRES
-- ============================================
COMMENT ON TABLE questionnaire_medical IS 'Questions du questionnaire médical pour Coris Sérénité, Familis et Étude';
COMMENT ON TABLE souscription_questionnaire IS 'Réponses au questionnaire médical par souscription';
COMMENT ON COLUMN questionnaire_medical.code IS 'Code unique de la question (Q1, Q2, etc.)';
COMMENT ON COLUMN questionnaire_medical.type_question IS 'Type: oui_non, texte, nombre, taille_poids';
COMMENT ON COLUMN questionnaire_medical.ordre IS 'Ordre d''affichage des questions';
COMMENT ON COLUMN souscription_questionnaire.reponse_oui_non IS 'TRUE=OUI, FALSE=NON, NULL=non répondu';

