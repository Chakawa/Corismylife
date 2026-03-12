/**
 * ===============================================
 * CONTRÔLEUR COMMERCIAL
 * ===============================================
 * 
 * Ce fichier gère toutes les opérations liées aux commerciaux :
 * - Statistiques commerciales (nombre de clients, contrats, propositions)
 * - Liste des clients du commercial (avec leurs souscriptions)
 * - Création d'un client avec code apporteur (DEPRECATED: les clients s'inscrivent maintenant eux-mêmes)
 * - Récupération des souscriptions créées par le commercial
 * - Liste des clients ayant des souscriptions (pour pré-remplissage)
 * - Suivi des commissions (calcul basé sur les contrats activés)
 * 
 * WORKFLOW COMMERCIAL :
 * 1. Le commercial se connecte avec son compte (rôle: 'commercial')
 * 2. Il peut créer des souscriptions pour des clients (sans les inscrire)
 * 3. Les infos client sont stockées dans souscriptiondata.client_info
 * 4. Le code_apporteur du commercial est enregistré dans la souscription
 * 5. Le commercial peut voir toutes ses souscriptions dans "Mes Clients"
 * 
 * STATISTIQUES :
 * - Nombre de clients uniques (basé sur numéro de téléphone)
 * - Nombre de contrats (statut = 'contrat')
 * - Nombre de propositions (statut = 'proposition')
 * 
 * SÉCURITÉ :
 * - Toutes les routes nécessitent une authentification JWT
 * - Vérification du code_apporteur pour filtrer les données
 * - Les commerciaux ne peuvent voir que leurs propres souscriptions
 * 
 * ⚠️ UNIFORMISATION DES CHAMPS (IMPORTANT) :
 * ==========================================
 * CONTRATS (table 'contrats'):
 *   - Utiliser UNIQUEMENT le champ 'etat' (pas de 'statut')
 *   - Colonne en base: contrats.etat (VARCHAR)
 *   - Valeurs: 'Actif', 'Inactif', 'Suspendu'
 *   - Frontend accède via: contrat['etat']
 * 
 * SOUSCRIPTIONS (table 'subscriptions'):
 *   - Utiliser UNIQUEMENT le champ 'statut' (différent du contexte contrats)
 *   - Colonne en base: subscriptions.statut (VARCHAR)
 *   - Valeurs: 'proposition', 'contrat', 'rejeté'
 *   - Frontend accède via: subscription['statut']
 * 
 * ⚠️ Ne JAMAIS aliaser 'c.etat as statut' dans les requêtes SQL
 * ⚠️ Retourner toujours 'c.etat' directement pour éviter la confusion
 */

// ============================================
// IMPORTS ET DÉPENDANCES
// ============================================
const pool = require('../db');  // Pool de connexions PostgreSQL
const bcrypt = require('bcrypt');  // Bibliothèque pour hasher les mots de passe (utilisée pour la création de clients - DEPRECATED)
const axios = require('axios');  // Bibliothèque pour faire des requêtes HTTP vers l'API externe des bordereaux

/**
 * Récupère les statistiques du commercial connecté
 * GET /api/commercial/stats
 */
exports.getCommercialStats = async (req, res) => {
  try {
    const commercialId = req.user.id;
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé pour ce commercial'
      });
    }

    /**
     * MODIFICATION: Compter le nombre unique de clients basé sur les numéros de téléphone
     * 
     * PRINCIPE:
     * - Un client = un numéro de téléphone unique
     * - Si un même numéro apparaît dans plusieurs propositions, on ne compte qu'une seule fois
     * - On utilise DISTINCT pour éliminer les doublons basés sur le numéro de téléphone
     * 
     * LOGIQUE:
     * 1. On récupère les numéros de téléphone depuis deux sources:
     *    - s.souscriptiondata->'client_info'->>'telephone' : numéro stocké dans les infos client (pour les souscriptions créées par commercial)
     *    - u.telephone : numéro depuis la table users (pour les souscriptions créées directement par le client)
     * 2. COALESCE permet de prendre le premier non-null entre les deux sources
     * 3. COUNT(DISTINCT ...) compte uniquement les numéros uniques
     * 4. WHERE s.code_apporteur = $1 : filtre uniquement les souscriptions créées par ce commercial
     * 
     * EXEMPLE:
     * - Si le commercial a créé 3 propositions pour le numéro +225 0707889919, on compte 1 client
     * - Si le commercial a créé 2 propositions pour +225 0707889919 et 1 pour +225 0102030405, on compte 2 clients
     */
    const clientsQuery = `
      SELECT COUNT(DISTINCT 
        COALESCE(
          s.souscriptiondata->'client_info'->>'telephone',
          u.telephone
        )
      ) as count
      FROM subscriptions s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.code_apporteur = $1
        AND (
          s.souscriptiondata->'client_info'->>'telephone' IS NOT NULL
          OR u.telephone IS NOT NULL
        )
    `;
    const clientsResult = await pool.query(clientsQuery, [codeApporteur]);
    const nbClients = parseInt(clientsResult.rows[0].count) || 0;

    // Compter le nombre de contrats actifs depuis la table contrats
    const contratsQuery = `
      SELECT COUNT(*) as count
      FROM contrats c
      WHERE c.codeappo = $1 AND LOWER(c.etat) = 'actif'
    `;
    const contratsResult = await pool.query(contratsQuery, [codeApporteur]);
    const nbContrats = parseInt(contratsResult.rows[0].count) || 0;

    // Compter le nombre de propositions (souscriptions avec statut 'proposition')
    const propositionsQuery = `
      SELECT COUNT(DISTINCT s.id) as count
      FROM subscriptions s
      INNER JOIN users u ON s.user_id = u.id
      WHERE u.code_apporteur = $1 AND s.statut = 'proposition'
    `;
    const propositionsResult = await pool.query(propositionsQuery, [codeApporteur]);
    const nbPropositions = parseInt(propositionsResult.rows[0].count) || 0;

    res.json({
      success: true,
      data: {
        nbClients,
        nbContrats,
        nbPropositions,
        codeApporteur
      }
    });
  } catch (error) {
    console.error('Erreur récupération stats commercial:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques'
    });
  }
};

/**
 * Récupère la liste des clients du commercial
 * GET /api/commercial/clients
 */
exports.getCommercialClients = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    const query = `
      SELECT 
        u.id,
        u.nom,
        u.prenom,
        u.profession,
        u.email,
        u.telephone,
        u.date_naissance,
        u.lieu_naissance,
        u.adresse,
        u.created_at,
        COUNT(DISTINCT s.id) as nb_souscriptions,
        COUNT(DISTINCT CASE WHEN s.statut = 'contrat' THEN s.id END) as nb_contrats
      FROM users u
      LEFT JOIN subscriptions s ON s.user_id = u.id
      WHERE u.code_apporteur = $1 AND u.role = 'client'
      GROUP BY u.id, u.nom, u.prenom, u.profession, u.email, u.telephone, u.date_naissance, u.lieu_naissance, u.adresse, u.created_at
      ORDER BY u.created_at DESC
    `;

    const result = await pool.query(query, [codeApporteur]);

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération clients commercial:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des clients'
    });
  }
};

/**
 * Crée un nouveau client avec le code apporteur du commercial
 * POST /api/commercial/clients
 */
exports.createClient = async (req, res) => {
  try {
    const commercialId = req.user.id;
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé pour ce commercial'
      });
    }

    const {
      email,
      password,
      nom,
      prenom,
      profession,
      civilite,
      telephone,
      date_naissance,
      lieu_naissance,
      adresse,
      pays
    } = req.body;

    // Valider les champs obligatoires
    if (!email || !password || !nom || !prenom || !telephone) {
      return res.status(400).json({
        success: false,
        message: 'Tous les champs obligatoires doivent être remplis'
      });
    }

    // Vérifier si l'email existe déjà
    const emailCheckQuery = 'SELECT id FROM users WHERE email = $1';
    const emailCheckResult = await pool.query(emailCheckQuery, [email]);
    
    if (emailCheckResult.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cet email est déjà utilisé'
      });
    }

    // Hasher le mot de passe
    const passwordHash = await bcrypt.hash(password, 10);

    // Créer le client avec le code apporteur
    const insertQuery = `
      INSERT INTO users (
        email, password_hash, role, nom, prenom, civilite,
        telephone, date_naissance, lieu_naissance, adresse, pays, code_apporteur, profession
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING id, email, nom, prenom, profession, telephone, code_apporteur, created_at
    `;

    const values = [
      email,
      passwordHash,
      'client',
      nom,
      prenom,
      civilite || 'Monsieur',
      telephone,
      date_naissance || null,
      lieu_naissance || null,
      adresse || null,
      pays || "Côte d'Ivoire",
      codeApporteur,
      profession || null
    ];

    const result = await pool.query(insertQuery, values);

    // Récupérer toutes les données du client créé pour les retourner
    const clientCreated = result.rows[0];
    
    // Récupérer les données complètes du client (y compris date_naissance et lieu_naissance)
    const fullClientQuery = `
      SELECT 
        id, email, nom, prenom, civilite, telephone, 
        profession, date_naissance, lieu_naissance, adresse, pays, 
        code_apporteur, role, created_at
      FROM users 
      WHERE id = $1
    `;
    const fullClientResult = await pool.query(fullClientQuery, [clientCreated.id]);
    
    const fullClient = fullClientResult.rows[0];
    
    // Formater la date de naissance si elle existe
    if (fullClient.date_naissance) {
      if (fullClient.date_naissance instanceof Date) {
        fullClient.date_naissance = fullClient.date_naissance.toISOString().split('T')[0];
      } else if (typeof fullClient.date_naissance === 'string') {
        fullClient.date_naissance = fullClient.date_naissance.split('T')[0];
      }
    }
    
    console.log('✅ Client créé avec succès:', {
      id: fullClient.id,
      email: fullClient.email,
      code_apporteur: fullClient.code_apporteur
    });

    res.status(201).json({
      success: true,
      message: 'Client créé avec succès',
      data: fullClient
    });
  } catch (error) {
    console.error('Erreur création client:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la création du client'
    });
  }
};

/**
 * Récupère les souscriptions des clients du commercial
 * GET /api/commercial/subscriptions
 */
exports.getCommercialSubscriptions = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    // NOUVEAU: Récupérer uniquement les souscriptions avec le code_apporteur du commercial
    // Les infos client sont dans souscription_data.client_info
    const query = `
      SELECT 
        s.id,
        s.numero_police,
        s.produit_nom,
        s.statut,
        s.souscriptiondata,
        s.date_creation,
        s.updated_at,
        s.user_id,
        s.code_apporteur,
        -- Extraire les infos client depuis souscription_data si disponibles
        s.souscriptiondata->'client_info'->>'nom' as client_nom,
        s.souscriptiondata->'client_info'->>'prenom' as client_prenom,
        s.souscriptiondata->'client_info'->>'email' as client_email,
        s.souscriptiondata->'client_info'->>'telephone' as client_telephone,
        s.souscriptiondata->'client_info'->>'date_naissance' as client_date_naissance,
        s.souscriptiondata->'client_info'->>'lieu_naissance' as client_lieu_naissance,
        s.souscriptiondata->'client_info'->>'adresse' as client_adresse,
        s.souscriptiondata->'client_info'->>'civilite' as client_civilite,
        s.souscriptiondata->'client_info'->>'numero_piece_identite' as client_numero_piece_identite,
        -- Si user_id existe, récupérer aussi les infos depuis users
        u.nom as user_nom,
        u.prenom as user_prenom,
        u.email as user_email,
        u.telephone as user_telephone
      FROM subscriptions s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.code_apporteur = $1
      ORDER BY s.date_creation DESC
    `;

    const result = await pool.query(query, [codeApporteur]);

    // Formater les résultats pour utiliser les infos client depuis souscription_data en priorité
    const formattedResults = result.rows.map(row => ({
      ...row,
      nom: row.client_nom || row.user_nom || '',
      prenom: row.client_prenom || row.user_prenom || '',
      email: row.client_email || row.user_email || '',
      telephone: row.client_telephone || row.user_telephone || ''
    }));

    res.json({
      success: true,
      data: formattedResults
    });
  } catch (error) {
    console.error('Erreur récupération souscriptions commercial:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des souscriptions'
    });
  }
};

/**
 * Récupère la liste unique des clients qui ont des souscriptions
 * créées par le commercial connecté UNIQUEMENT
 * GET /api/commercial/clients-with-subscriptions
 * 
 * MODIFICATION: Retourne UNIQUEMENT les clients du commercial connecté
 * pour que chaque commercial ne voie que ses propres clients.
 */
exports.getClientsWithSubscriptions = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    // Récupérer UNIQUEMENT les clients des souscriptions du commercial connecté
    // Filtre WHERE s.code_apporteur = $1 pour ne retourner que les clients du commercial
    const query = `
      SELECT DISTINCT ON (
        COALESCE(s.souscriptiondata->'client_info'->>'telephone', u.telephone)
      )
        s.souscriptiondata->'client_info'->>'nom' as nom,
        s.souscriptiondata->'client_info'->>'prenom' as prenom,
        s.souscriptiondata->'client_info'->>'email' as email,
        s.souscriptiondata->'client_info'->>'telephone' as telephone,
        s.souscriptiondata->'client_info'->>'date_naissance' as date_naissance,
        s.souscriptiondata->'client_info'->>'lieu_naissance' as lieu_naissance,
        s.souscriptiondata->'client_info'->>'adresse' as adresse,
        s.souscriptiondata->'client_info'->>'civilite' as civilite,
        s.souscriptiondata->'client_info'->>'numero_piece_identite' as numero_piece_identite,
        s.code_apporteur as created_by_code,
        u.id as user_id,
        u.nom as user_nom,
        u.prenom as user_prenom,
        u.email as user_email,
        u.telephone as user_telephone,
        u.date_naissance as user_date_naissance,
        u.lieu_naissance as user_lieu_naissance,
        u.adresse as user_adresse,
        u.civilite as user_civilite
      FROM subscriptions s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.code_apporteur = $1
        AND (
          s.souscriptiondata->'client_info'->>'nom' IS NOT NULL
          OR u.nom IS NOT NULL
        )
      ORDER BY COALESCE(s.souscriptiondata->'client_info'->>'telephone', u.telephone), s.date_creation DESC
    `;

    const result = await pool.query(query, [codeApporteur]);

    // Formater les résultats pour utiliser les infos client depuis souscription_data en priorité
    const formattedResults = result.rows
      .map(row => ({
        nom: row.nom || row.user_nom || '',
        prenom: row.prenom || row.user_prenom || '',
        email: row.email || row.user_email || '',
        telephone: row.telephone || row.user_telephone || '',
        date_naissance: row.date_naissance || row.user_date_naissance || null,
        lieu_naissance: row.lieu_naissance || row.user_lieu_naissance || '',
        adresse: row.adresse || row.user_adresse || '',
        civilite: row.civilite || row.user_civilite || '',
        numero_piece_identite: row.numero_piece_identite || '',
        user_id: row.user_id || null,
        created_by_code: row.created_by_code || null
      }))
      .filter(client => (client.nom && client.nom.trim() !== '') || (client.prenom && client.prenom.trim() !== ''));

    res.json({
      success: true,
      data: formattedResults,
      message: `${formattedResults.length} client(s) trouvé(s)`
    });
  } catch (error) {
    console.error('Erreur récupération clients avec souscriptions:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des clients'
    });
  }
};

/**
 * ===============================================
 * RÉCUPÉRER LES BORDEREAUX DE COMMISSIONS
 * ===============================================
 * 
 * Récupère les bordereaux de commissions depuis l'API externe
 * et les formate pour l'affichage dans l'application mobile.
 * 
 * @route GET /api/commercial/commissions
 * @requires verifyToken - L'utilisateur doit être connecté et être un commercial
 * 
 * @returns {object} Liste des bordereaux de commissions avec le total
 * 
 * STRUCTURE DES DONNÉES :
 * - id : Identifiant unique du bordereau
 * - exercice : Année d'exercice (ex: "2025")
 * - numefeui : Numéro du bordereau (feuille)
 * - refefeui : Référence du bordereau (nom du commercial)
 * - datedebut : Date de début de la période (format: DD/MM/YYYY)
 * - datefin : Date de fin de la période (format: DD/MM/YYYY)
 * - etatfeuille : État du bordereau (ex: "payée")
 * - montfeui : Montant du bordereau (en FCFA)
 * - typeappo : Type d'apporteur ("A" = Commercial/Apporteur, "B" = Intermédiaire)
 * - codappin : Code apporteur interne
 * 
 * CALCUL DU TOTAL :
 * - Additionne tous les montants (montfeui) de tous les bordereaux
 * - Retourne le total dans la réponse
 */
exports.getCommercialCommissions = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    console.log(`🔄 Récupération des bordereaux pour le code apporteur: ${codeApporteur}`);

    // Requête vers la table bordereau_commissions
    const query = `
      SELECT 
        id,
        exercice,
        numefeui,
        refefeui,
        datedebut,
        datefin,
        etatfeuille,
        montfeui,
        typeappo,
        codeappin,
        datefeui
      FROM bordereau_commissions
      WHERE codeappin = $1
      ORDER BY exercice DESC, numefeui DESC
    `;

    const result = await pool.query(query, [codeApporteur]);

    if (result.rows.length === 0) {
      console.log('⚠️ Aucun bordereau trouvé pour ce code apporteur');
      return res.json({
        success: true,
        data: [],
        total: 0,
        message: 'Aucun bordereau de commission trouvé'
      });
    }

    const bordereaux = result.rows;

    // Calculer le total de toutes les commissions
    let totalCommissions = 0;
    const bordereauxFormates = bordereaux.map(bordereau => {
      // Convertir le montant en nombre
      const montant = parseFloat(bordereau.montfeui) || 0;
      totalCommissions += montant;

      // Formater les dates (déjà au format texte dans la DB)
      // ✅ RÉSULTAT DIAGNOSTIC: datedebut est toujours présent (78/78 bordereaux)
      // On utilise datedebut comme date principale, datefeui comme fallback de sécurité
      const dateDebut = bordereau.datedebut || bordereau.datefeui || '';
      const dateFin = bordereau.datefin || '';

      // Déterminer le type d'apporteur
      const typeApporteur = bordereau.typeappo || 'A';
      const typeApporteurLabel = typeApporteur === 'A' 
        ? 'Commercial (Apporteur)' 
        : typeApporteur === 'B' 
          ? 'Intermédiaire' 
          : 'Non défini';

      return {
        id: bordereau.id,
        exercice: bordereau.exercice || '',
        numeroBordereau: bordereau.numefeui || '',
        reference: bordereau.refefeui || '',
        dateDebut: dateDebut,
        dateFin: dateFin,
        etat: bordereau.etatfeuille || '',
        montant: montant,
        montantFormate: new Intl.NumberFormat('fr-FR', {
          style: 'currency',
          currency: 'XOF',
          minimumFractionDigits: 0
        }).format(montant).replace('XOF', 'FCFA'),
        typeApporteur: typeApporteur,
        typeApporteurLabel: typeApporteurLabel,
        codeApporteur: bordereau.codeappin || codeApporteur
      };
    });

    console.log(`✅ ${bordereauxFormates.length} bordereau(x) récupéré(s), total: ${totalCommissions} FCFA`);

    // Retourner les données formatées avec le total
    res.json({
      success: true,
      data: bordereauxFormates,
      total: totalCommissions,
      totalFormate: new Intl.NumberFormat('fr-FR', {
        style: 'currency',
        currency: 'XOF',
        minimumFractionDigits: 0
      }).format(totalCommissions).replace('XOF', 'FCFA'),
      count: bordereauxFormates.length
    });
  } catch (error) {
    console.error('❌ Erreur récupération bordereaux de commissions:', error.message);
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des bordereaux de commissions',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Récupère tous les contrats du commercial
 * GET /api/commercial/mes_contrats_commercial
 */
exports.getMesContratsCommercial = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    // ✅ Champ 'c.etat' retourné directement (anciennement aliasé en 'statut')
    const query = `
      SELECT 
        c.id,
        c.numepoli,
        c.codeprod,
        c.nom_prenom,
        c.etat,
        c.dateeffet as datesous,
        c.codeinte,
        c.codeappo as code_apporteur,
        c.dateeffet,
        c.dateeche as dateecheance,
        c.datenaissance,
        c.duree,
        c.periodicite,
        -- Extraire prénom et nom si possible (format: "Prénom Nom")
        TRIM(SPLIT_PART(c.nom_prenom, ' ', 1)) as prenom,
        TRIM(SUBSTRING(c.nom_prenom FROM POSITION(' ' IN c.nom_prenom) + 1)) as nom
      FROM contrats c
      WHERE c.codeappo = $1
      ORDER BY c.dateeffet DESC
    `;

    const result = await pool.query(query, [String(codeApporteur)]);

    // Ajouter le nom du produit côté serveur
    const produitsMap = {
      '225': 'CORIS SOLIDARITÉ',
      '205': 'FLEX EMPRUNTEUR',
      '242': 'CORIS ÉPARGNE BONUS',
      '240': 'CORIS RETRAITE',
      '202': 'CORIS SÉRÉNITÉ',
      '246': 'CORIS ÉTUDE',
      '200': 'CORIS FAMILIS'
    };

    const contratsAvecNomProduit = result.rows.map(contrat => ({
      ...contrat,
      nom_produit: produitsMap[contrat.codeprod] || `Produit ${contrat.codeprod}`
    }));

    res.json({
      success: true,
      contrats: contratsAvecNomProduit
    });
  } catch (error) {
    console.error('Erreur récupération contrats commercial:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats'
    });
  }
};

/**
 * Récupère la liste des clients du commercial
 * GET /api/commercial/liste_clients
 */
exports.getListeClients = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    // Récupérer UNIQUEMENT les clients des souscriptions du commercial connecté
    // Utilise client_info depuis subscriptions pour avoir les vraies données
    const query = `
      SELECT DISTINCT ON (
        COALESCE(s.souscriptiondata->'client_info'->>'telephone', u.telephone)
      )
        CAST(u.id AS TEXT) as id,
        COALESCE(s.souscriptiondata->'client_info'->>'nom', u.nom) as nom,
        COALESCE(s.souscriptiondata->'client_info'->>'prenom', u.prenom) as prenom,
        COALESCE(s.souscriptiondata->'client_info'->>'email', u.email) as email,
        COALESCE(s.souscriptiondata->'client_info'->>'telephone', u.telephone) as telephone,
        CASE 
          WHEN u.id IS NOT NULL THEN 'user'
          ELSE 'souscription'
        END as source
      FROM subscriptions s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.code_apporteur = $1
        AND (
          s.souscriptiondata->'client_info'->>'nom' IS NOT NULL
          OR u.nom IS NOT NULL
        )
      ORDER BY COALESCE(s.souscriptiondata->'client_info'->>'telephone', u.telephone), s.date_creation DESC
    `;

    const result = await pool.query(query, [String(codeApporteur)]);

    // Filtrer les clients qui ont au moins un nom ou prénom
    const formattedClients = result.rows.filter(client => 
      (client.nom && client.nom.trim() !== '') || 
      (client.prenom && client.prenom.trim() !== '')
    );

    res.json({
      success: true,
      clients: formattedClients
    });
  } catch (error) {
    console.error('Erreur récupération liste clients:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération de la liste des clients'
    });
  }
};

/**
 * Récupère les contrats actifs du commercial
 * GET /api/commercial/contrats_actifs
 */
exports.getContratsActifs = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    // ✅ Champ 'c.etat' retourné directement (anciennement aliasé en 'statut')
    const query = `
      SELECT 
        c.id,
        c.numepoli,
        c.codeprod,
        c.nom_prenom,
        c.etat,
        c.dateeffet as datesous,
        c.codeinte,
        c.codeappo as code_apporteur,
        c.dateeffet,
        c.dateeche as dateecheance,
        c.datenaissance,
        c.duree,
        c.periodicite,
        -- Extraire prénom et nom si possible (format: "Prénom Nom")
        TRIM(SPLIT_PART(c.nom_prenom, ' ', 1)) as prenom,
        TRIM(SUBSTRING(c.nom_prenom FROM POSITION(' ' IN c.nom_prenom) + 1)) as nom
      FROM contrats c
      WHERE c.codeappo = $1 AND LOWER(c.etat) = 'actif'
      ORDER BY c.dateeffet DESC
    `;

    const result = await pool.query(query, [String(codeApporteur)]);

    // Ajouter le nom du produit côté serveur
    const produitsMap = {
      '225': 'CORIS SOLIDARITÉ',
      '205': 'FLEX EMPRUNTEUR',
      '242': 'CORIS ÉPARGNE BONUS',
      '240': 'CORIS RETRAITE',
      '202': 'CORIS SÉRÉNITÉ',
      '246': 'CORIS ÉTUDE',
      '200': 'CORIS FAMILIS'
    };

    const contratsAvecNomProduit = result.rows.map(contrat => ({
      ...contrat,
      nom_produit: produitsMap[contrat.codeprod] || `Produit ${contrat.codeprod}`
    }));

    res.json({
      success: true,
      contrats: contratsAvecNomProduit
    });
  } catch (error) {
    console.error('Erreur récupération contrats actifs:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats actifs'
    });
  }
};

/**
 * Récupère les détails d'un client
 * GET /api/commercial/details_client/:clientId
 */
exports.getDetailsClient = async (req, res) => {
  try {
    const codeApporteur = req.user.code_apporteur;
    const clientId = req.params.clientId;

    if (!codeApporteur) {
      return res.status(400).json({
        success: false,
        message: 'Code apporteur non trouvé'
      });
    }

    // Récupérer les infos du client
    const clientQuery = `
      SELECT 
        u.id,
        u.nom,
        u.prenom,
        u.email,
        u.telephone,
        u.date_naissance,
        u.lieu_naissance,
        u.adresse
      FROM users u
      WHERE u.id = $1 AND u.code_apporteur = $2
    `;

    const clientResult = await pool.query(clientQuery, [clientId, String(codeApporteur)]);

    if (clientResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Client non trouvé'
      });
    }

    const client = clientResult.rows[0];

    // Récupérer les contrats du client
    // ✅ Champ 'c.etat' retourné directement (anciennement aliasé en 'statut')
    const contratsQuery = `
      SELECT 
        c.numepoli,
        c.codeprod,
        c.etat,
        c.dateeffet as datesous
      FROM contrats c
      WHERE c.nom_prenom ILIKE $1 AND c.codeappo = $2
      ORDER BY c.dateeffet DESC
    `;

    const nomComplet = `%${client.prenom} ${client.nom}%`;
    const contratsResult = await pool.query(contratsQuery, [nomComplet, String(codeApporteur)]);

    res.json({
      success: true,
      client: client,
      contrats: contratsResult.rows
    });
  } catch (error) {
    console.error('Erreur récupération détails client:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des détails du client'
    });
  }
};

/**
 * Récupère les détails d'un contrat
 * GET /api/commercial/contrat_details/:numepoli
 */
exports.getContratDetails = async (req, res) => {
  try {
    const userRole = req.user.role;
    const codeApporteur = req.user.code_apporteur;
    const userTelephone = req.user.telephone;
    const numepoli = req.params.numepoli;

    console.log('🔍 [CONTRAT DETAILS] ========== DÉBUT ==========');
    console.log('👤 [CONTRAT DETAILS] Rôle:', userRole);
    console.log('📞 [CONTRAT DETAILS] Téléphone:', userTelephone);
    console.log('💼 [CONTRAT DETAILS] Code apporteur:', codeApporteur);
    console.log('📄 [CONTRAT DETAILS] Numéro police:', numepoli);

    // Récupérer tous les détails du contrat
    // ✅ Champ 'c.etat' retourné directement (anciennement aliasé en 'statut')
    const query = `
      SELECT 
        c.id,
        c.numepoli,
        c.codeprod,
        c.nom_prenom,
        c.etat,
        c.dateeffet as datesous,
        c.codeinte,
        c.codeappo as code_apporteur,
        c.dateeffet,
        c.dateeche as dateecheance,
        c.datenaissance,
        c.duree,
        c.periodicite,
        c.domiciliation,
        c.capital,
        c.rente,
        c.prime,
        c.montant_encaisse,
        c.impaye,
        c.telephone1,
        c.telephone2,
        -- Extraire prénom et nom si possible
        TRIM(SPLIT_PART(c.nom_prenom, ' ', 1)) as prenom,
        TRIM(SUBSTRING(c.nom_prenom FROM POSITION(' ' IN c.nom_prenom) + 1)) as nom
      FROM contrats c
      WHERE c.numepoli = $1 
        AND (
          $2::text IS NULL 
          OR c.codeappo = $2 
          OR c.telephone1 = $3 
          OR c.telephone2 = $3
          OR REPLACE(c.telephone1, ' ', '') = REPLACE($3, ' ', '')
          OR REPLACE(c.telephone2, ' ', '') = REPLACE($3, ' ', '')
        )
    `;

    const result = await pool.query(query, [
      numepoli, 
      codeApporteur || null, 
      userTelephone || null
    ]);

    console.log('📊 [CONTRAT DETAILS] Résultats trouvés:', result.rows.length);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    // Ajouter le nom du produit côté serveur
    const produitsMap = {
      '225': 'CORIS SOLIDARITÉ',
      '205': 'FLEX EMPRUNTEUR',
      '242': 'CORIS ÉPARGNE BONUS',
      '240': 'CORIS RETRAITE',
      '202': 'CORIS SÉRÉNITÉ',
      '246': 'CORIS ÉTUDE',
      '200': 'CORIS FAMILIS'
    };

    const contratAvecNomProduit = {
      ...result.rows[0],
      nom_produit: produitsMap[result.rows[0].codeprod] || `Produit ${result.rows[0].codeprod}`
    };

    // Récupérer les bénéficiaires du contrat
    const benefQuery = `
      SELECT 
        b.id,
        b.type_beneficiaires,
        b.nom_benef,
        b.codeinte,
        b.numepoli
      FROM beneficiaires b
      WHERE b.numepoli = $1
      ORDER BY b.id
    `;
    
    const benefResult = await pool.query(benefQuery, [numepoli]);

    res.json({
      success: true,
      contrat: contratAvecNomProduit,
      beneficiaires: benefResult.rows
    });
  } catch (error) {
    console.error('Erreur récupération détails contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des détails du contrat'
    });
  }
};


