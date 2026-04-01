--
-- PostgreSQL database dump
--

\restrict AIDbDyUqCqSRqg69Gu4TzXuieMashILhS8cxOaBjP0og2WTBWbTK3I17U6pMJ0f

-- Dumped from database version 18.1 (Debian 18.1-1.pgdg12+2)
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: calculate_next_payment_date(timestamp without time zone, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_next_payment_date(date_debut timestamp without time zone, periodicite_val character varying) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN CASE 
    WHEN LOWER(periodicite_val) LIKE '%mens%' THEN date_debut + INTERVAL '1 month'
    WHEN LOWER(periodicite_val) LIKE '%trim%' THEN date_debut + INTERVAL '3 months'
    WHEN LOWER(periodicite_val) LIKE '%sem%' THEN date_debut + INTERVAL '6 months'
    WHEN LOWER(periodicite_val) LIKE '%ann%' THEN date_debut + INTERVAL '1 year'
    ELSE NULL
  END;
END;
$$;


--
-- Name: update_2fa_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_2fa_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$;


--
-- Name: update_commission_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_commission_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$;


--
-- Name: update_notifications_admin_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_notifications_admin_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_notifications_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_notifications_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: beneficiaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficiaires (
    id integer NOT NULL,
    type_beneficiaires character varying(50) DEFAULT NULL::character varying,
    nom_benef character varying(100) NOT NULL,
    codeinte character varying(20) DEFAULT NULL::character varying,
    numepoli character varying(20) DEFAULT NULL::character varying
);


--
-- Name: beneficiaires_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beneficiaires_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beneficiaires_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beneficiaires_id_seq OWNED BY public.beneficiaires.id;


--
-- Name: bordereau_commissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bordereau_commissions (
    id integer NOT NULL,
    exercice character varying(20) NOT NULL,
    numefeui character varying(10) NOT NULL,
    refefeui character varying(100),
    datedebut date NOT NULL,
    datefin date NOT NULL,
    etatfeuille character varying(50) NOT NULL,
    montfeui numeric(10,2) NOT NULL,
    typeappo character varying(10) NOT NULL,
    codeappin character varying(20) NOT NULL,
    datefeui date NOT NULL
);


--
-- Name: bordereau_commissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bordereau_commissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bordereau_commissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bordereau_commissions_id_seq OWNED BY public.bordereau_commissions.id;


--
-- Name: commission_instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commission_instance (
    id integer NOT NULL,
    code_apporteur character varying(50) NOT NULL,
    montant_commission numeric(15,2) NOT NULL,
    date_calcul timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_montant_commission_positive CHECK ((montant_commission >= (0)::numeric))
);


--
-- Name: commission_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.commission_instance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: commission_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.commission_instance_id_seq OWNED BY public.commission_instance.id;


--
-- Name: contrats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contrats (
    id integer NOT NULL,
    codeprod character varying(20) NOT NULL,
    codeinte character varying(20) NOT NULL,
    codeappo character varying(20) DEFAULT NULL::character varying,
    numepoli character varying(20) NOT NULL,
    duree integer,
    dateeffet date NOT NULL,
    dateeche date,
    periodicite character varying(30) NOT NULL,
    domiciliation character varying(30) DEFAULT NULL::character varying,
    capital numeric(10,0) DEFAULT NULL::numeric,
    rente numeric(10,0) DEFAULT NULL::numeric,
    prime numeric(10,0) NOT NULL,
    montant_encaisse numeric(10,0) DEFAULT NULL::numeric,
    impaye numeric(10,0) DEFAULT NULL::numeric,
    etat character varying(20) DEFAULT NULL::character varying,
    telephone1 character varying(20) DEFAULT NULL::character varying,
    telephone2 character varying(20) DEFAULT NULL::character varying,
    nom_prenom character varying(100) DEFAULT NULL::character varying,
    datenaissance date,
    next_payment_date timestamp without time zone,
    last_payment_date timestamp without time zone,
    payment_status character varying(50) DEFAULT 'a_jour'::character varying,
    payment_method character varying(50),
    total_paid numeric(15,2) DEFAULT 0,
    notification_sent boolean DEFAULT false,
    last_notification_date timestamp without time zone
);


--
-- Name: contrats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contrats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contrats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contrats_id_seq OWNED BY public.contrats.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    admin_id integer NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text,
    reference_id integer,
    reference_type character varying(50),
    is_read boolean DEFAULT false,
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    action_url character varying(255),
    user_id integer NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: COLUMN notifications.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications.user_id IS 'Reference vers utilisateur destinataire';


--
-- Name: notifications_admin; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications_admin (
    id integer CONSTRAINT notifications_admin_id_not_null1 NOT NULL,
    admin_id integer NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    reference_id integer,
    reference_type character varying(50),
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    action_url character varying(255)
);


--
-- Name: TABLE notifications_admin; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.notifications_admin IS 'Notifications destinees aux administrateurs';


--
-- Name: COLUMN notifications_admin.admin_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications_admin.admin_id IS 'Reference vers admin destinataire';


--
-- Name: COLUMN notifications_admin.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.notifications_admin.type IS 'Type de notification : subscription_alert, payment_alert, document_review, etc.';


--
-- Name: notifications_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_admin_id_seq OWNED BY public.notifications_admin.id;


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: payment_otp_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_otp_requests (
    id integer NOT NULL,
    user_id integer,
    code_pays character varying(10) NOT NULL,
    telephone character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: TABLE payment_otp_requests; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.payment_otp_requests IS 'Historique des demandes d''OTP pour les paiements CorisMoney';


--
-- Name: payment_otp_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_otp_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_otp_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_otp_requests_id_seq OWNED BY public.payment_otp_requests.id;


--
-- Name: payment_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_transactions (
    id integer NOT NULL,
    user_id integer,
    subscription_id integer,
    transaction_id character varying(100),
    code_pays character varying(10) NOT NULL,
    telephone character varying(20) NOT NULL,
    montant numeric(15,2) NOT NULL,
    statut character varying(50) DEFAULT 'PENDING'::character varying NOT NULL,
    description text,
    error_message text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    api_response jsonb,
    provider character varying(50) DEFAULT 'CorisMoney'::character varying,
    session_id character varying(255),
    CONSTRAINT payment_transactions_provider_check CHECK (((provider)::text = ANY ((ARRAY['Wave'::character varying, 'CorisMoney'::character varying, 'OrangeMoney'::character varying])::text[])))
);


--
-- Name: TABLE payment_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.payment_transactions IS 'Historique des transactions de paiement via CorisMoney';


--
-- Name: COLUMN payment_transactions.transaction_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payment_transactions.transaction_id IS 'ID de transaction retourné par CorisMoney';


--
-- Name: COLUMN payment_transactions.statut; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payment_transactions.statut IS 'Statut de la transaction: PENDING, SUCCESS, FAILED, VERIFIED';


--
-- Name: COLUMN payment_transactions.api_response; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payment_transactions.api_response IS 'Reponse brute API du provider (JSON)';


--
-- Name: COLUMN payment_transactions.provider; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payment_transactions.provider IS 'Fournisseur de paiement: Wave, CorisMoney, OrangeMoney';


--
-- Name: COLUMN payment_transactions.session_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.payment_transactions.session_id IS 'ID de session Wave checkout (si provider=Wave)';


--
-- Name: payment_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_transactions_id_seq OWNED BY public.payment_transactions.id;


--
-- Name: produit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produit (
    id integer NOT NULL,
    libelle character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    codeprod character varying(20)
);


--
-- Name: produit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.produit ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.produit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: questionnaire_medical; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questionnaire_medical (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    libelle text NOT NULL,
    type_question character varying(50) NOT NULL,
    ordre integer NOT NULL,
    champ_detail_1_label character varying(255),
    champ_detail_2_label character varying(255),
    champ_detail_3_label character varying(255),
    obligatoire boolean DEFAULT true,
    actif boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: questionnaire_medical_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.questionnaire_medical_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: questionnaire_medical_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.questionnaire_medical_id_seq OWNED BY public.questionnaire_medical.id;


--
-- Name: simulations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.simulations (
    id integer NOT NULL,
    user_id integer,
    produit_nom character varying(100) NOT NULL,
    type_simulation character varying(50) NOT NULL,
    age integer,
    date_naissance date,
    capital numeric(15,2),
    prime numeric(15,2),
    duree_mois integer,
    periodicite character varying(20),
    resultat_prime numeric(15,2),
    resultat_capital numeric(15,2),
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: simulations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.simulations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simulations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.simulations_id_seq OWNED BY public.simulations.id;


--
-- Name: souscription_questionnaire; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.souscription_questionnaire (
    id integer NOT NULL,
    subscription_id integer NOT NULL,
    question_id integer NOT NULL,
    reponse_oui_non boolean,
    reponse_text text,
    reponse_detail_1 text,
    reponse_detail_2 text,
    reponse_detail_3 text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: souscription_questionnaire_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.souscription_questionnaire_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: souscription_questionnaire_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.souscription_questionnaire_id_seq OWNED BY public.souscription_questionnaire.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    numero_police character varying(50),
    produit_nom character varying(100) NOT NULL,
    statut character varying(100) DEFAULT 'proposition'::character varying NOT NULL,
    date_creation timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    date_validation timestamp with time zone,
    souscriptiondata jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    code_apporteur character(50),
    payment_method character varying(50),
    payment_transaction_id character varying(255)
);


--
-- Name: COLUMN subscriptions.payment_method; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.payment_method IS 'Methode de paiement utilisee';


--
-- Name: COLUMN subscriptions.payment_transaction_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.subscriptions.payment_transaction_id IS 'Reference vers transaction de paiement';


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tarif_produit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tarif_produit (
    id integer NOT NULL,
    produit_id integer NOT NULL,
    duree_contrat integer,
    periodicite character varying(50) NOT NULL,
    prime numeric(15,6),
    capital numeric(15,2),
    age integer,
    categorie character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: tarif_produit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.tarif_produit ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tarif_produit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: two_factor_auth; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.two_factor_auth (
    id integer NOT NULL,
    user_id integer NOT NULL,
    enabled boolean DEFAULT false,
    secondary_phone character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: two_factor_auth_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.two_factor_auth_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: two_factor_auth_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.two_factor_auth_id_seq OWNED BY public.two_factor_auth.id;


--
-- Name: user_activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_activity_logs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    type character varying(50) NOT NULL,
    ip_address character varying(50),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE user_activity_logs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_activity_logs IS 'Enregistre toutes les connexions et déconnexions des utilisateurs';


--
-- Name: COLUMN user_activity_logs.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_activity_logs.type IS 'Type d''activité: login ou logout';


--
-- Name: user_activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_activity_logs_id_seq OWNED BY public.user_activity_logs.id;


--
-- Name: user_activity_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.user_activity_stats AS
 SELECT date(created_at) AS date,
    count(*) FILTER (WHERE ((type)::text = 'login'::text)) AS total_connexions,
    count(DISTINCT user_id) FILTER (WHERE ((type)::text = 'login'::text)) AS utilisateurs_uniques,
    count(*) FILTER (WHERE ((type)::text = 'logout'::text)) AS total_deconnexions
   FROM public.user_activity_logs
  GROUP BY (date(created_at))
  ORDER BY (date(created_at)) DESC;


--
-- Name: VIEW user_activity_stats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.user_activity_stats IS 'Statistiques d''utilisation quotidiennes de l''application';


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    nom character varying(100) NOT NULL,
    prenom character varying(100) NOT NULL,
    civilite character varying(10),
    telephone character varying(20) NOT NULL,
    adresse text,
    pays character varying(100) DEFAULT 'C“te d''Ivoire'::character varying,
    date_naissance date,
    lieu_naissance character varying(100),
    numero_piece_identite character varying(50),
    code_apporteur character varying(50),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    photo_url character(200),
    est_suspendu boolean DEFAULT false,
    date_suspension timestamp without time zone,
    raison_suspension text,
    suspendu_par integer,
    profession character varying(150),
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['super_admin'::character varying, 'admin'::character varying, 'moderation'::character varying, 'commercial'::character varying, 'client'::character varying])::text[])))
);


--
-- Name: COLUMN users.est_suspendu; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.est_suspendu IS 'Indique si le compte utilisateur est suspendu';


--
-- Name: COLUMN users.raison_suspension; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.raison_suspension IS 'Raison de la suspension du compte';


--
-- Name: COLUMN users.suspendu_par; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.suspendu_par IS 'ID de l''administrateur qui a suspendu le compte';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: beneficiaires id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaires ALTER COLUMN id SET DEFAULT nextval('public.beneficiaires_id_seq'::regclass);


--
-- Name: bordereau_commissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bordereau_commissions ALTER COLUMN id SET DEFAULT nextval('public.bordereau_commissions_id_seq'::regclass);


--
-- Name: commission_instance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_instance ALTER COLUMN id SET DEFAULT nextval('public.commission_instance_id_seq'::regclass);


--
-- Name: contrats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrats ALTER COLUMN id SET DEFAULT nextval('public.contrats_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: notifications_admin id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_admin ALTER COLUMN id SET DEFAULT nextval('public.notifications_admin_id_seq'::regclass);


--
-- Name: payment_otp_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_otp_requests ALTER COLUMN id SET DEFAULT nextval('public.payment_otp_requests_id_seq'::regclass);


--
-- Name: payment_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions ALTER COLUMN id SET DEFAULT nextval('public.payment_transactions_id_seq'::regclass);


--
-- Name: questionnaire_medical id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaire_medical ALTER COLUMN id SET DEFAULT nextval('public.questionnaire_medical_id_seq'::regclass);


--
-- Name: simulations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simulations ALTER COLUMN id SET DEFAULT nextval('public.simulations_id_seq'::regclass);


--
-- Name: souscription_questionnaire id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.souscription_questionnaire ALTER COLUMN id SET DEFAULT nextval('public.souscription_questionnaire_id_seq'::regclass);


--
-- Name: two_factor_auth id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth ALTER COLUMN id SET DEFAULT nextval('public.two_factor_auth_id_seq'::regclass);


--
-- Name: user_activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_logs ALTER COLUMN id SET DEFAULT nextval('public.user_activity_logs_id_seq'::regclass);


--
-- Name: beneficiaires beneficiaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiaires
    ADD CONSTRAINT beneficiaires_pkey PRIMARY KEY (id);


--
-- Name: bordereau_commissions bordereau_commissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bordereau_commissions
    ADD CONSTRAINT bordereau_commissions_pkey PRIMARY KEY (id);


--
-- Name: commission_instance commission_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_instance
    ADD CONSTRAINT commission_instance_pkey PRIMARY KEY (id);


--
-- Name: contrats contrats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrats
    ADD CONSTRAINT contrats_pkey PRIMARY KEY (id);


--
-- Name: notifications_admin notifications_admin_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_admin
    ADD CONSTRAINT notifications_admin_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payment_otp_requests payment_otp_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_otp_requests
    ADD CONSTRAINT payment_otp_requests_pkey PRIMARY KEY (id);


--
-- Name: payment_transactions payment_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_pkey PRIMARY KEY (id);


--
-- Name: payment_transactions payment_transactions_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_transaction_id_key UNIQUE (transaction_id);


--
-- Name: produit produit_libelle_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produit
    ADD CONSTRAINT produit_libelle_key UNIQUE (libelle);


--
-- Name: produit produit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produit
    ADD CONSTRAINT produit_pkey PRIMARY KEY (id);


--
-- Name: questionnaire_medical questionnaire_medical_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaire_medical
    ADD CONSTRAINT questionnaire_medical_code_key UNIQUE (code);


--
-- Name: questionnaire_medical questionnaire_medical_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaire_medical
    ADD CONSTRAINT questionnaire_medical_pkey PRIMARY KEY (id);


--
-- Name: simulations simulations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simulations
    ADD CONSTRAINT simulations_pkey PRIMARY KEY (id);


--
-- Name: souscription_questionnaire souscription_questionnaire_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.souscription_questionnaire
    ADD CONSTRAINT souscription_questionnaire_pkey PRIMARY KEY (id);


--
-- Name: souscription_questionnaire souscription_questionnaire_subscription_id_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.souscription_questionnaire
    ADD CONSTRAINT souscription_questionnaire_subscription_id_question_id_key UNIQUE (subscription_id, question_id);


--
-- Name: subscriptions subscriptions_numero_police_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_numero_police_key UNIQUE (numero_police);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tarif_produit tarif_produit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarif_produit
    ADD CONSTRAINT tarif_produit_pkey PRIMARY KEY (id);


--
-- Name: two_factor_auth two_factor_auth_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT two_factor_auth_pkey PRIMARY KEY (id);


--
-- Name: two_factor_auth two_factor_auth_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT two_factor_auth_user_id_key UNIQUE (user_id);


--
-- Name: user_activity_logs user_activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_logs
    ADD CONSTRAINT user_activity_logs_pkey PRIMARY KEY (id);


--
-- Name: users users_code_apporteur_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_code_apporteur_key UNIQUE (code_apporteur);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_2fa_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_2fa_enabled ON public.two_factor_auth USING btree (enabled);


--
-- Name: idx_2fa_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_2fa_user_id ON public.two_factor_auth USING btree (user_id);


--
-- Name: idx_commission_apporteur_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_apporteur_date ON public.commission_instance USING btree (code_apporteur, date_calcul);


--
-- Name: idx_commission_code_apporteur; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_code_apporteur ON public.commission_instance USING btree (code_apporteur);


--
-- Name: idx_commission_instance_code_apporteur; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_instance_code_apporteur ON public.commission_instance USING btree (code_apporteur);


--
-- Name: idx_commission_instance_date_calcul; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_commission_instance_date_calcul ON public.commission_instance USING btree (date_calcul DESC);


--
-- Name: idx_notifications_admin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_admin ON public.notifications USING btree (admin_id);


--
-- Name: idx_notifications_admin_admin_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_admin_admin_id ON public.notifications_admin USING btree (admin_id);


--
-- Name: idx_notifications_admin_admin_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_admin_admin_read ON public.notifications_admin USING btree (admin_id, is_read);


--
-- Name: idx_notifications_admin_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_admin_created_at ON public.notifications_admin USING btree (created_at DESC);


--
-- Name: idx_notifications_admin_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_admin_is_read ON public.notifications_admin USING btree (is_read);


--
-- Name: idx_notifications_admin_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_admin_type ON public.notifications_admin USING btree (type);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_created_at ON public.notifications USING btree (created_at);


--
-- Name: idx_notifications_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_is_read ON public.notifications USING btree (is_read);


--
-- Name: idx_notifications_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_type ON public.notifications USING btree (type);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_notifications_user_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_read ON public.notifications USING btree (user_id, is_read);


--
-- Name: idx_payment_otp_requests_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_otp_requests_user_id ON public.payment_otp_requests USING btree (user_id);


--
-- Name: idx_payment_transactions_api_response; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_api_response ON public.payment_transactions USING gin (api_response);


--
-- Name: idx_payment_transactions_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_provider ON public.payment_transactions USING btree (provider);


--
-- Name: idx_payment_transactions_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_session_id ON public.payment_transactions USING btree (session_id);


--
-- Name: idx_payment_transactions_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_statut ON public.payment_transactions USING btree (statut);


--
-- Name: idx_payment_transactions_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_subscription_id ON public.payment_transactions USING btree (subscription_id);


--
-- Name: idx_payment_transactions_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_transaction_id ON public.payment_transactions USING btree (transaction_id);


--
-- Name: idx_payment_transactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payment_transactions_user_id ON public.payment_transactions USING btree (user_id);


--
-- Name: idx_questionnaire_medical_actif; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questionnaire_medical_actif ON public.questionnaire_medical USING btree (actif);


--
-- Name: idx_questionnaire_medical_ordre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_questionnaire_medical_ordre ON public.questionnaire_medical USING btree (ordre);


--
-- Name: idx_simulations_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_simulations_created_at ON public.simulations USING btree (created_at);


--
-- Name: idx_simulations_produit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_simulations_produit ON public.simulations USING btree (produit_nom);


--
-- Name: idx_simulations_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_simulations_type ON public.simulations USING btree (type_simulation);


--
-- Name: idx_simulations_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_simulations_user_id ON public.simulations USING btree (user_id);


--
-- Name: idx_souscription_questionnaire_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_souscription_questionnaire_question ON public.souscription_questionnaire USING btree (question_id);


--
-- Name: idx_souscription_questionnaire_subscription; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_souscription_questionnaire_subscription ON public.souscription_questionnaire USING btree (subscription_id);


--
-- Name: idx_tarif_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_age ON public.tarif_produit USING btree (age) WHERE (age IS NOT NULL);


--
-- Name: idx_tarif_capital; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_capital ON public.tarif_produit USING btree (capital) WHERE (capital IS NOT NULL);


--
-- Name: idx_tarif_capital_perio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_capital_perio ON public.tarif_produit USING btree (produit_id, capital, periodicite) WHERE (capital IS NOT NULL);


--
-- Name: idx_tarif_categorie; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_categorie ON public.tarif_produit USING btree (categorie) WHERE (categorie IS NOT NULL);


--
-- Name: idx_tarif_composite_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_composite_age ON public.tarif_produit USING btree (produit_id, age, duree_contrat, periodicite) WHERE (age IS NOT NULL);


--
-- Name: idx_tarif_duree; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_duree ON public.tarif_produit USING btree (duree_contrat) WHERE (duree_contrat IS NOT NULL);


--
-- Name: idx_tarif_periodicite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_periodicite ON public.tarif_produit USING btree (periodicite);


--
-- Name: idx_tarif_produit_age_duree; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_produit_age_duree ON public.tarif_produit USING btree (produit_id, age, duree_contrat) WHERE (age IS NOT NULL);


--
-- Name: idx_tarif_produit_duree_perio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_produit_duree_perio ON public.tarif_produit USING btree (produit_id, duree_contrat, periodicite) WHERE (age IS NULL);


--
-- Name: idx_tarif_produit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tarif_produit_id ON public.tarif_produit USING btree (produit_id);


--
-- Name: idx_user_activity_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_activity_created_at ON public.user_activity_logs USING btree (created_at);


--
-- Name: idx_user_activity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_activity_type ON public.user_activity_logs USING btree (type);


--
-- Name: idx_user_activity_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_activity_user_id ON public.user_activity_logs USING btree (user_id);


--
-- Name: two_factor_auth trigger_update_2fa_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_2fa_updated_at BEFORE UPDATE ON public.two_factor_auth FOR EACH ROW EXECUTE FUNCTION public.update_2fa_updated_at();


--
-- Name: notifications_admin trigger_update_notifications_admin_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_notifications_admin_updated_at BEFORE UPDATE ON public.notifications_admin FOR EACH ROW EXECUTE FUNCTION public.update_notifications_admin_updated_at();


--
-- Name: notifications trigger_update_notifications_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_notifications_updated_at BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.update_notifications_updated_at();


--
-- Name: commission_instance update_commission_instance_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_commission_instance_timestamp BEFORE UPDATE ON public.commission_instance FOR EACH ROW EXECUTE FUNCTION public.update_commission_timestamp();


--
-- Name: commission_instance fk_commission_apporteur; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_instance
    ADD CONSTRAINT fk_commission_apporteur FOREIGN KEY (code_apporteur) REFERENCES public.users(code_apporteur) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: simulations fk_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simulations
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: notifications_admin notifications_admin_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications_admin
    ADD CONSTRAINT notifications_admin_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payment_otp_requests payment_otp_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_otp_requests
    ADD CONSTRAINT payment_otp_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: payment_transactions payment_transactions_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE SET NULL;


--
-- Name: payment_transactions payment_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: souscription_questionnaire souscription_questionnaire_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.souscription_questionnaire
    ADD CONSTRAINT souscription_questionnaire_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questionnaire_medical(id) ON DELETE CASCADE;


--
-- Name: souscription_questionnaire souscription_questionnaire_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.souscription_questionnaire
    ADD CONSTRAINT souscription_questionnaire_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: tarif_produit tarif_produit_produit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tarif_produit
    ADD CONSTRAINT tarif_produit_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produit(id) ON DELETE CASCADE;


--
-- Name: two_factor_auth two_factor_auth_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor_auth
    ADD CONSTRAINT two_factor_auth_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_activity_logs user_activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_activity_logs
    ADD CONSTRAINT user_activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_suspendu_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_suspendu_par_fkey FOREIGN KEY (suspendu_par) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict AIDbDyUqCqSRqg69Gu4TzXuieMashILhS8cxOaBjP0og2WTBWbTK3I17U6pMJ0f

