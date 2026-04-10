-- Migration : Création des tables questionnaire médical
-- À exécuter une seule fois sur la base de données de production

-- 1. Table des questions médicales (référentiel)
CREATE TABLE IF NOT EXISTS public.questionnaire_medical (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    libelle TEXT NOT NULL,
    type_question VARCHAR(50) NOT NULL DEFAULT 'oui_non',
    ordre INTEGER NOT NULL,
    champ_detail_1_label VARCHAR(255),
    champ_detail_2_label VARCHAR(255),
    champ_detail_3_label VARCHAR(255),
    obligatoire BOOLEAN DEFAULT true,
    actif BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Table des réponses par souscription
CREATE TABLE IF NOT EXISTS public.souscription_questionnaire (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES public.questionnaire_medical(id) ON DELETE CASCADE,
    reponse_oui_non BOOLEAN,
    reponse_text TEXT,
    reponse_detail_1 TEXT,
    reponse_detail_2 TEXT,
    reponse_detail_3 TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(subscription_id, question_id)
);

-- 3. Index pour performances
CREATE INDEX IF NOT EXISTS idx_souscription_questionnaire_subscription
    ON public.souscription_questionnaire(subscription_id);

-- 4. Données initiales : questions médicales standard (insérées uniquement si la table est vide)
INSERT INTO public.questionnaire_medical
    (code, libelle, type_question, ordre, champ_detail_1_label, champ_detail_2_label, champ_detail_3_label)
SELECT * FROM (VALUES
    ('Q01', 'Êtes-vous actuellement en bonne santé ?', 'oui_non', 1, NULL, NULL, NULL),
    ('Q02', 'Avez-vous subi une intervention chirurgicale au cours des 5 dernières années ?', 'oui_non', 2, 'Type d''intervention', 'Date', 'Établissement'),
    ('Q03', 'Souffrez-vous ou avez-vous souffert d''une maladie cardiaque ou vasculaire ?', 'oui_non', 3, 'Précisez la maladie', 'Date de diagnostic', NULL),
    ('Q04', 'Souffrez-vous ou avez-vous souffert d''une maladie du système nerveux (épilepsie, AVC, etc.) ?', 'oui_non', 4, 'Précisez la maladie', 'Date de diagnostic', NULL),
    ('Q05', 'Souffrez-vous ou avez-vous souffert d''un cancer ou d''une tumeur ?', 'oui_non', 5, 'Type de cancer/tumeur', 'Date de diagnostic', 'Traitement suivi'),
    ('Q06', 'Souffrez-vous ou avez-vous souffert d''une maladie du foie ou du rein ?', 'oui_non', 6, 'Précisez la maladie', 'Date de diagnostic', NULL),
    ('Q07', 'Souffrez-vous ou avez-vous souffert de diabète ?', 'oui_non', 7, 'Type de diabète', 'Date de diagnostic', 'Traitement'),
    ('Q08', 'Souffrez-vous ou avez-vous souffert d''une maladie pulmonaire (asthme, BPCO, etc.) ?', 'oui_non', 8, 'Précisez la maladie', 'Date de diagnostic', NULL),
    ('Q09', 'Êtes-vous actuellement sous traitement médical régulier ?', 'oui_non', 9, 'Médicaments prescrits', 'Depuis quand', NULL),
    ('Q10', 'Avez-vous été en arrêt de travail de plus de 30 jours consécutifs au cours des 3 dernières années ?', 'oui_non', 10, 'Motif', 'Durée', NULL),
    ('Q11', 'Souffrez-vous d''un handicap physique ou mental reconnu ?', 'oui_non', 11, 'Nature du handicap', 'Taux d''invalidité', NULL),
    ('Q12', 'Avez-vous des antécédents familiaux de maladies graves (cancer, maladies cardiaques, etc.) ?', 'oui_non', 12, 'Lien de parenté', 'Maladie concernée', NULL)
) AS v(code, libelle, type_question, ordre, champ_detail_1_label, champ_detail_2_label, champ_detail_3_label)
WHERE NOT EXISTS (SELECT 1 FROM public.questionnaire_medical LIMIT 1);
