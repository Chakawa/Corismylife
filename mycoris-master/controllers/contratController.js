/**
 * ===============================================
 * CONTRÔLEUR DES CONTRATS
 * ===============================================
 * 
 * Gère les opérations liées aux contrats depuis la table `contrats` :
 * - Récupération des contrats d'un client (via telephone1)
 * - Récupération des contrats d'un commercial (via codeappo)
 * - Affichage des détails d'un contrat
 */

const pool = require('../db');

function normalizePoliceNumber(value) {
  if (!value) return '';
  return String(value).trim().toUpperCase();
}

function parseNumericValue(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;

  const normalized = String(value)
    .replace(/\s/g, '')
    .replace(/,/g, '.')
    .replace(/[^0-9.\-]/g, '');

  if (!normalized) return null;
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

function pickFirstNumeric(source, keys) {
  if (!source || typeof source !== 'object') return null;
  for (const key of keys) {
    const parsed = parseNumericValue(source[key]);
    if (parsed !== null) return parsed;
  }
  return null;
}

function enrichSubscriptionAmounts(row) {
  if (!row || (row.source || '').toLowerCase() !== 'subscription') return row;

  const details = row.souscriptiondata && typeof row.souscriptiondata === 'object'
    ? row.souscriptiondata
    : null;

  if (!details) return row;

  const primeFromDetails = pickFirstNumeric(details, [
    'prime',
    'prime_totale',
    'prime_mensuelle',
    'prime_annuelle',
    'prime_calculee',
    'montant_cotisation',
    'montant_total',
    'montant',
    'versement_initial',
  ]);

  const capitalFromDetails = pickFirstNumeric(details, [
    'capital',
    'capital_garanti',
    'capital_au_terme',
    'capital_deces',
    'capital_prevoyance',
    'capital_assure',
    'montant',
  ]);

  if (row.prime === null || row.prime === undefined) {
    row.prime = primeFromDetails;
  }

  if (row.capital === null || row.capital === undefined) {
    row.capital = capitalFromDetails;
  }

  if (!row.periodicite) {
    row.periodicite = details.periodicite || null;
  }

  return row;
}

/**
 * Récupère tous les contrats d'un client via son numéro de téléphone
 * Route: GET /api/contrats/client/:telephone
 */
exports.getContratsByTelephone = async (req, res) => {
  try {
    const { telephone } = req.params;
    
    console.log('=== RÉCUPÉRATION CONTRATS CLIENT ===');
    console.log('📞 Téléphone:', telephone);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Nettoyer le numéro: enlever +225 s'il existe
    let cleanPhone = telephone;
    if (telephone.startsWith('+225')) {
      cleanPhone = telephone.substring(4); // Enlever +225
    }
    console.log('📞 Téléphone nettoyé:', cleanPhone);
    
    // Récupérer tous les contrats du client avec informations de paiement
    // On cherche avec les deux formats: avec et sans +225
    const query = `
      SELECT 
        id,
        codeprod,
        codeinte,
        codeappo,
        numepoli,
        duree,
        dateeffet,
        dateeche,
        periodicite,
        domiciliation,
        capital,
        rente,
        prime,
        montant_encaisse,
        impaye,
        etat,
        telephone1,
        telephone2,
        nom_prenom,
        datenaissance,
        next_payment_date,
        last_payment_date,
        payment_method,
        payment_status,
        total_paid,
        CASE 
          WHEN next_payment_date IS NULL THEN NULL
          ELSE EXTRACT(DAY FROM (next_payment_date - CURRENT_DATE))::INTEGER
        END as jours_restants
      FROM contrats
      WHERE telephone1 = $1 
         OR telephone1 = $2
         OR telephone2 = $1
         OR telephone2 = $2
      ORDER BY 
        CASE payment_status
          WHEN 'en_retard' THEN 1
          WHEN 'echeance_proche' THEN 2
          WHEN 'a_jour' THEN 3
          ELSE 4
        END,
        next_payment_date NULLS LAST,
        dateeffet DESC
    `;
    
    const phoneWithPrefix = '+225' + cleanPhone;
    const result = await pool.query(query, [cleanPhone, phoneWithPrefix]);
    
    console.log(`✅ ${result.rows.length} contrat(s) trouvé(s)`);
    
    res.json({
      success: true,
      count: result.rows.length,
      contrats: result.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération contrats client:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

/**
 * Récupère tous les contrats d'un commercial via son code apporteur
 * Route: GET /api/contrats/commercial/:codeappo
 */
exports.getContratsByCodeApporteur = async (req, res) => {
  try {
    const { codeappo } = req.params;
    
    console.log('=== RÉCUPÉRATION CONTRATS COMMERCIAL ===');
    console.log('💼 Code apporteur:', codeappo);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Vérifier que l'utilisateur est un commercial
    if (req.user.role !== 'commercial') {
      return res.status(403).json({
        success: false,
        message: 'Accès réservé aux commerciaux'
      });
    }
    
    // Récupérer tous les contrats du commercial
    const query = `
      SELECT 
        id,
        codeprod,
        codeinte,
        codeappo,
        numepoli,
        duree,
        dateeffet,
        dateeche,
        periodicite,
        domiciliation,
        capital,
        rente,
        prime,
        montant_encaisse,
        impaye,
        etat,
        telephone1,
        telephone2,
        nom_prenom,
        datenaissance
      FROM contrats
      WHERE codeappo = $1
      ORDER BY dateeffet DESC
    `;
    
    const result = await pool.query(query, [codeappo]);
    
    console.log(`✅ ${result.rows.length} contrat(s) trouvé(s)`);
    
    res.json({
      success: true,
      count: result.rows.length,
      contrats: result.rows
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération contrats commercial:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

/**
 * Récupère les détails complets d'un contrat par numepoli (numéro de police)
 * Route: GET /api/commercial/contrat_details/:numepoli
 */
exports.getContratDetailsByNumepoli = async (req, res) => {
  try {
    const { numepoli } = req.params;
    
    console.log('=== RÉCUPÉRATION DÉTAILS CONTRAT PAR NUMEPOLI ===');
    console.log('📋 Numéro de police:', numepoli);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // 1) Source legacy: table contrats
    const contratQuery = `
      SELECT *, 'legacy'::text AS source
      FROM contrats
      WHERE UPPER(TRIM(numepoli)) = UPPER(TRIM($1))
    `;

    let contratResult = await pool.query(contratQuery, [numepoli]);

    // 2) Fallback source app: subscriptions (statut contrat/paid)
    if (contratResult.rows.length === 0) {
      const subscriptionQuery = `
        SELECT
          s.id,
          s.id AS subscription_id,
          'subscription'::text AS source,
          s.user_id,
          CASE
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%solidarit%' THEN '225'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%etude%' THEN '246'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%retraite%' THEN '240'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%serenite%' THEN '202'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%familis%' THEN '200'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%flex%' THEN '205'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%epargne%' THEN '242'
            ELSE '000'
          END AS codeprod,
          NULL::text AS codeinte,
          s.code_apporteur AS codeappo,
          s.code_apporteur AS code_apporteur,
          COALESCE(s.numero_police, s.payment_transaction_id, 'SUB-' || s.id::text) AS numepoli,
          NULL::int AS duree,
          s.date_creation AS datesous,
          COALESCE(s.date_validation, s.date_creation) AS dateeffet,
          NULL::timestamp AS dateeche,
          NULL::timestamp AS dateecheance,
          COALESCE(
            NULLIF(s.souscriptiondata->>'periodicite', ''),
            NULL::text
          ) AS periodicite,
          NULL::text AS domiciliation,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_garanti', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_garanti', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS capital,
          NULL::numeric AS rente,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS prime,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS montant_encaisse,
          0::numeric AS impaye,
          'actif'::text AS etat,
          u.telephone AS telephone1,
          NULL::text AS telephone2,
          TRIM(COALESCE(u.nom, '') || ' ' || COALESCE(u.prenom, '')) AS nom_prenom,
          u.date_naissance AS datenaissance,
          s.souscriptiondata
        FROM subscriptions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE (
          UPPER(TRIM(COALESCE(s.numero_police, ''))) = UPPER(TRIM($1))
          OR UPPER(TRIM(COALESCE(s.payment_transaction_id, ''))) = UPPER(TRIM($1))
          OR UPPER(TRIM('SUB-' || s.id::text)) = UPPER(TRIM($1))
        )
          AND LOWER(COALESCE(s.statut, '')) IN ('contrat', 'paid')
        ORDER BY COALESCE(s.date_validation, s.date_creation) DESC
        LIMIT 1
      `;

      contratResult = await pool.query(subscriptionQuery, [numepoli]);
    }

    if (contratResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }

    const contrat = contratResult.rows[0];
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    // 1. Admin a accès à tout
    if (req.user.role === 'admin') {
      hasAccess = true;
    }
    // 2. Commercial a accès à ses contrats
    else if (
      req.user.role === 'commercial' &&
      (req.user.code_apporteur === contrat.codeappo || req.user.code_apporteur === contrat.code_apporteur)
    ) {
      hasAccess = true;
    }
    // 3. Client a accès à ses contrats (via téléphone)
    else if (req.user.role === 'client') {
      if ((contrat.source || '').toLowerCase() === 'subscription') {
        hasAccess = String(contrat.user_id || '') === String(req.user.id || '');
      } else {
        // Récupérer le téléphone du user
        const userQuery = `SELECT telephone FROM users WHERE id = $1`;
        const userResult = await pool.query(userQuery, [req.user.id]);
        if (userResult.rows.length > 0) {
          const userPhone = userResult.rows[0].telephone;

          // Nettoyer le numéro: enlever +225 s'il existe
          let cleanPhone = userPhone;
          if (userPhone.startsWith('+225')) {
            cleanPhone = userPhone.substring(4);
          }
          const phoneWithPrefix = '+225' + cleanPhone;

          // Comparer avec et sans +225
          if (contrat.telephone1 === cleanPhone || contrat.telephone1 === phoneWithPrefix ||
              contrat.telephone2 === cleanPhone || contrat.telephone2 === phoneWithPrefix) {
            hasAccess = true;
          }
        }
      }
    }
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce contrat'
      });
    }
    
    // Récupérer les bénéficiaires selon la source
    let beneficiaires = [];

    // La souscription peut provenir d'un JSON sérialisé dans `souscriptiondata`
    let subscriptionData = contrat.souscriptiondata;
    if (typeof subscriptionData === 'string') {
      try {
        subscriptionData = JSON.parse(subscriptionData);
      } catch (e) {
        console.warn('⚠️ Impossible de parser souscriptiondata (JSON invalide).', e);
        subscriptionData = {};
      }
    }
    if (subscriptionData == null || typeof subscriptionData !== 'object') {
      subscriptionData = {};
    }

    // Assurer que le contrat expose un objet utilisable
    contrat.souscriptiondata = subscriptionData;

    if ((contrat.source || '').toLowerCase() === 'subscription') {
      const data = subscriptionData;
      const rawBenefs =
        data.beneficiaires ||
        data.beneficiaire ||
        data.beneficiaries ||
        [];

      if (Array.isArray(rawBenefs)) {
        beneficiaires = rawBenefs.map((b, index) => ({
          id: index + 1,
          nom_benef: b.nom_benef || b.nom_prenom || b.nom || b.name || 'Bénéficiaire',
          type_beneficiaires: b.type_beneficiaires || b.relation || b.lien || 'Bénéficiaire',
        }));
      }
    } else {
      const benefQuery = `
        SELECT *
        FROM beneficiaires
        WHERE numepoli = $1
        ORDER BY id
      `;

      const benefResult = await pool.query(benefQuery, [numepoli]);
      beneficiaires = benefResult.rows;
    }

    // Récupérer les informations de paiement les plus récentes (utilisé par la vue mobile)
    if ((contrat.source || '').toLowerCase() === 'subscription') {
      try {
        const paymentResult = await pool.query(
          `SELECT transaction_id, session_id, provider, montant, amount, statut, created_at, api_response
           FROM payment_transactions
           WHERE subscription_id = $1
             AND LOWER(statut) IN (
               'success', 'succeeded', 'paid', 'completed',
               'validated', 'confirmed', 'ok',
               'validé', 'validée', 'confirmé', 'confirmée'
             )
           ORDER BY created_at DESC
           LIMIT 1`,
          [contrat.id]
        );

        if (paymentResult.rows.length > 0) {
          const payment = paymentResult.rows[0];
          const paymentInfo = {
            // Identifiants de paiement
            payment_id: payment.transaction_id || payment.session_id || null,
            id: payment.transaction_id || payment.session_id || null,
            provider_payment_id: payment.transaction_id || payment.session_id || null,

            // Mode de paiement
            payment_method: payment.provider || null,
            mode_paiement: payment.provider || null,

            // Montants (pour correspondre aux différents champs attendus par l'app)
            amount: payment.montant ?? payment.amount ?? null,
            amount_paid: payment.montant ?? payment.amount ?? null,
            montant_paye: payment.montant ?? payment.amount ?? null,
            total_paid: payment.montant ?? payment.amount ?? null,

            // Dates
            payment_date: payment.created_at || null,
            date_paiement: payment.created_at || null,

            // Statuts
            provider_status: payment.statut || null,
            status: payment.statut || null,
            statut: payment.statut || null,

            raw: payment.api_response || null,
          };

          contrat.souscriptiondata = contrat.souscriptiondata || {};
          contrat.souscriptiondata.payment_info = {
            ...contrat.souscriptiondata.payment_info,
            ...paymentInfo,
          };

          // Backwards compatibility for French keys
          contrat.souscriptiondata.paiement = {
            ...contrat.souscriptiondata.paiement,
            ...paymentInfo,
          };
        }
      } catch (paymentError) {
        console.warn('⚠️ Impossible de récupérer le paiement pour la souscription', contrat.id, paymentError);
      }
    }

    delete contrat.user_id;

    console.log('✅ Contrat trouvé avec', beneficiaires.length, 'bénéficiaire(s)');
    
    res.json({
      success: true,
      contrat: contrat,
      beneficiaires
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération détails contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
};

/**
 * Récupère les détails complets d'un contrat spécifique
 * Route: GET /api/contrats/:id
 */
exports.getContratDetails = async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('=== RÉCUPÉRATION DÉTAILS CONTRAT ===');
    console.log('📋 Contrat ID:', id);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Récupérer tous les détails du contrat
    const query = `
      SELECT *
      FROM contrats
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }
    
    const contrat = result.rows[0];
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    // 1. Admin a accès à tout
    if (req.user.role === 'admin') {
      hasAccess = true;
    }
    // 2. Commercial a accès à ses contrats
    else if (req.user.role === 'commercial' && req.user.code_apporteur === contrat.codeappo) {
      hasAccess = true;
    }
    // 3. Client a accès à ses contrats (via téléphone)
    else if (req.user.role === 'client') {
      // Récupérer le téléphone du user
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      if (userResult.rows.length > 0) {
        const userPhone = userResult.rows[0].telephone;
        
        // Nettoyer le numéro: enlever +225 s'il existe
        let cleanPhone = userPhone;
        if (userPhone.startsWith('+225')) {
          cleanPhone = userPhone.substring(4);
        }
        const phoneWithPrefix = '+225' + cleanPhone;
        
        // Comparer avec et sans +225
        if (contrat.telephone1 === cleanPhone || contrat.telephone1 === phoneWithPrefix ||
            contrat.telephone2 === cleanPhone || contrat.telephone2 === phoneWithPrefix) {
          hasAccess = true;
        }
      }
    }
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce contrat'
      });
    }
    
    console.log('✅ Contrat trouvé et accès autorisé');

    // Enrichir avec paiement si contract est lié à une souscription
    // (contrat.subscription_id non-null)
    const subscriptionId = contrat.subscription_id;
    if (subscriptionId) {
      try {
        const paymentResult = await pool.query(
          `SELECT transaction_id, session_id, provider, montant, amount, statut, created_at, api_response
           FROM payment_transactions
           WHERE subscription_id = $1
             AND LOWER(statut) IN (
               'success', 'succeeded', 'paid', 'completed',
               'validated', 'confirmed', 'ok',
               'validé', 'validée', 'confirmé', 'confirmée'
             )
           ORDER BY created_at DESC
           LIMIT 1`,
          [subscriptionId]
        );

        if (paymentResult.rows.length > 0) {
          const payment = paymentResult.rows[0];

          // Ajouter les totaux cumulatifs de paiement
          const totalsResult = await pool.query(
            `SELECT COALESCE(SUM(montant), 0) AS total_paid
             FROM payment_transactions
             WHERE subscription_id = $1
               AND LOWER(statut) IN (
                 'success', 'succeeded', 'paid', 'completed',
                 'validated', 'confirmed', 'ok',
                 'validé', 'validée', 'confirmé', 'confirmée'
               )`,
            [subscriptionId]
          );

          const totalPaid = Number(totalsResult.rows[0]?.total_paid || 0);
          contrat.total_paid = totalPaid;
          contrat.montant_encaisse = totalPaid;

          if (payment.transaction_id || payment.session_id) {
            contrat.payment_transaction_id = payment.transaction_id || payment.session_id;
          }

          const paymentInfo = {
            // Identifiants de paiement
            payment_id: payment.transaction_id || payment.session_id || null,
            id: payment.transaction_id || payment.session_id || null,
            provider_payment_id: payment.transaction_id || payment.session_id || null,

            // Mode de paiement
            payment_method: payment.provider || null,
            mode_paiement: payment.provider || null,

            // Montants (pour correspondre aux différents champs attendus par l'app)
            amount: payment.montant ?? payment.amount ?? null,
            amount_paid: payment.montant ?? payment.amount ?? null,
            montant_paye: payment.montant ?? payment.amount ?? null,
            total_paid: totalPaid,

            // Dates
            payment_date: payment.created_at || null,
            date_paiement: payment.created_at || null,

            // Statuts
            provider_status: payment.statut || null,
            status: payment.statut || null,
            statut: payment.statut || null,

            raw: payment.api_response || null,
          };

          contrat.souscriptiondata = contrat.souscriptiondata || {};
          contrat.souscriptiondata.payment_info = {
            ...contrat.souscriptiondata.payment_info,
            ...paymentInfo,
          };

          contrat.souscriptiondata.paiement = {
            ...contrat.souscriptiondata.paiement,
            ...paymentInfo,
          };
        }
      } catch (paymentError) {
        console.warn('⚠️ Impossible de récupérer le paiement pour la souscription', contrat.id, paymentError);
      }
    }

    res.json({
      success: true,
      contrat: contrat
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération détails contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération du contrat',
      error: error.message
    });
  }
};

/**
 * Récupère les contrats de l'utilisateur connecté
 * Route: GET /api/contrats/mes-contrats
 */
exports.getMesContrats = async (req, res) => {
  try {
    console.log('=== RÉCUPÉRATION MES CONTRATS ===');
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    console.log('📞 Code apporteur:', req.user.code_apporteur);
    
    let query, params;
    
    if (req.user.role === 'commercial') {
      // Commercial: récupérer via code_apporteur
      query = `
        SELECT 
          id,
          NULL::int AS subscription_id,
          'legacy'::text AS source,
          codeprod,
          codeinte,
          codeappo,
          numepoli,
          duree,
          dateeffet,
          dateeche,
          periodicite,
          domiciliation,
          capital,
          rente,
          prime,
          montant_encaisse,
          impaye,
          etat,
          telephone1,
          telephone2,
          nom_prenom,
          datenaissance
        FROM contrats
        WHERE codeappo = $1
        ORDER BY dateeffet DESC
      `;
      params = [req.user.code_apporteur];
    } else {
      // Client: récupérer via téléphone
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      
      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Utilisateur non trouvé'
        });
      }
      
      const telephone = userResult.rows[0].telephone;
      
      // Nettoyer le numéro: enlever +225 s'il existe
      let cleanPhone = telephone;
      if (telephone.startsWith('+225')) {
        cleanPhone = telephone.substring(4);
      }
      const phoneWithPrefix = '+225' + cleanPhone;
      
      console.log('📞 Téléphone nettoyé:', cleanPhone);
      console.log('📞 Avec préfixe:', phoneWithPrefix);
      
      query = `
        SELECT 
          id,
          NULL::int AS subscription_id,
          'legacy'::text AS source,
          codeprod,
          codeinte,
          codeappo,
          numepoli,
          duree,
          dateeffet,
          dateeche,
          periodicite,
          domiciliation,
          capital,
          rente,
          prime,
          montant_encaisse,
          impaye,
          etat,
          telephone1,
          telephone2,
          nom_prenom,
          datenaissance
        FROM contrats
        WHERE telephone1 = $1 OR telephone1 = $2
           OR telephone2 = $1 OR telephone2 = $2
        ORDER BY dateeffet DESC
      `;
      params = [cleanPhone, phoneWithPrefix];
    }
    
    let legacyResult;
    try {
      legacyResult = await pool.query(query, params);
    } catch (dbError) {
      const errorMessage = (dbError.message || '').toLowerCase();
      if (errorMessage.includes('relation') && errorMessage.includes('contrats')) {
        console.warn('⚠️ Table legacy contrats absente, bascule sur subscriptions');
        legacyResult = { rows: [] };
      } else {
        throw dbError;
      }
    }

    let fallbackQuery;
    let fallbackParams;

    if (req.user.role === 'commercial') {
      fallbackQuery = `
        SELECT
          s.id,
          s.id AS subscription_id,
          'subscription'::text AS source,
          CASE
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%solidarit%' THEN '225'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%etude%' THEN '246'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%retraite%' THEN '240'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%serenite%' THEN '202'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%familis%' THEN '200'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%flex%' THEN '205'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%epargne%' THEN '242'
            ELSE '000'
          END AS codeprod,
          NULL::text AS codeinte,
          s.code_apporteur AS codeappo,
          COALESCE(s.numero_police, s.payment_transaction_id, 'SUB-' || s.id::text) AS numepoli,
          NULL::int AS duree,
          COALESCE(s.date_validation, s.date_creation) AS dateeffet,
          NULL::timestamp AS dateeche,
          COALESCE(
            NULLIF(s.souscriptiondata->>'periodicite', ''),
            NULL::text
          ) AS periodicite,
          NULL::text AS domiciliation,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_garanti', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_garanti', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS capital,
          NULL::numeric AS rente,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS prime,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS montant_encaisse,
          COALESCE(
            (
              SELECT SUM(pt.montant)
              FROM payment_transactions pt
              WHERE pt.subscription_id = s.id
                AND LOWER(pt.statut) IN (
                  'success', 'succeeded', 'paid', 'completed',
                  'validated', 'confirmed', 'ok',
                  'validé', 'validée', 'confirmé', 'confirmée'
                )
            ), 0
          )::numeric AS total_paid,
          COALESCE(
            (
              SELECT pt.transaction_id
              FROM payment_transactions pt
              WHERE pt.subscription_id = s.id
                AND LOWER(pt.statut) IN (
                  'success', 'succeeded', 'paid', 'completed',
                  'validated', 'confirmed', 'ok',
                  'validé', 'validée', 'confirmé', 'confirmée'
                )
              ORDER BY pt.created_at DESC
              LIMIT 1
            ),
            s.payment_transaction_id,
            NULL
          ) AS payment_transaction_id,
          0::numeric AS impaye,
          'actif'::text AS etat,
          u.telephone AS telephone1,
          NULL::text AS telephone2,
          TRIM(COALESCE(u.nom, '') || ' ' || COALESCE(u.prenom, '')) AS nom_prenom,
          u.date_naissance AS datenaissance,
          s.souscriptiondata
        FROM subscriptions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.code_apporteur = $1
          AND LOWER(COALESCE(s.statut, '')) IN ('contrat', 'paid')
        ORDER BY COALESCE(s.date_validation, s.date_creation) DESC
      `;
      fallbackParams = [req.user.code_apporteur];
    } else {
      fallbackQuery = `
        SELECT
          s.id,
          s.id AS subscription_id,
          'subscription'::text AS source,
          CASE
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%solidarit%' THEN '225'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%etude%' THEN '246'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%retraite%' THEN '240'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%serenite%' THEN '202'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%familis%' THEN '200'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%flex%' THEN '205'
            WHEN LOWER(COALESCE(s.produit_nom, '')) LIKE '%epargne%' THEN '242'
            ELSE '000'
          END AS codeprod,
          NULL::text AS codeinte,
          s.code_apporteur AS codeappo,
          COALESCE(s.numero_police, s.payment_transaction_id, 'SUB-' || s.id::text) AS numepoli,
          NULL::int AS duree,
          COALESCE(s.date_validation, s.date_creation) AS dateeffet,
          NULL::timestamp AS dateeche,
          COALESCE(
            NULLIF(s.souscriptiondata->>'periodicite', ''),
            NULL::text
          ) AS periodicite,
          NULL::text AS domiciliation,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_garanti', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_au_terme', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_garanti', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'capital_au_terme', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS capital,
          NULL::numeric AS rente,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_mensuelle', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_mensuelle', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS prime,
          CASE
            WHEN COALESCE(
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_mensuelle', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
              NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
            ) IS NOT NULL
              THEN (
                COALESCE(
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_totale', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'prime_mensuelle', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'montant_total', ''), '[^0-9.]', '', 'g'), ''),
                  NULLIF(REGEXP_REPLACE(COALESCE(s.souscriptiondata->>'versement_initial', ''), '[^0-9.]', '', 'g'), '')
                )
              )::numeric
            ELSE NULL::numeric
          END AS montant_encaisse,
          COALESCE(
            (
              SELECT SUM(pt.montant)
              FROM payment_transactions pt
              WHERE pt.subscription_id = s.id
                AND LOWER(pt.statut) IN (
                  'success', 'succeeded', 'paid', 'completed',
                  'validated', 'confirmed', 'ok',
                  'validé', 'validée', 'confirmé', 'confirmée'
                )
            ), 0
          )::numeric AS total_paid,
          COALESCE(
            (
              SELECT pt.transaction_id
              FROM payment_transactions pt
              WHERE pt.subscription_id = s.id
                AND LOWER(pt.statut) IN (
                  'success', 'succeeded', 'paid', 'completed',
                  'validated', 'confirmed', 'ok',
                  'validé', 'validée', 'confirmé', 'confirmée'
                )
              ORDER BY pt.created_at DESC
              LIMIT 1
            ),
            s.payment_transaction_id,
            NULL
          ) AS payment_transaction_id,
          0::numeric AS impaye,
          'actif'::text AS etat,
          u.telephone AS telephone1,
          NULL::text AS telephone2,
          TRIM(COALESCE(u.nom, '') || ' ' || COALESCE(u.prenom, '')) AS nom_prenom,
          u.date_naissance AS datenaissance,
          s.souscriptiondata
        FROM subscriptions s
        LEFT JOIN users u ON u.id = s.user_id
        WHERE s.user_id = $1
          AND LOWER(COALESCE(s.statut, '')) IN ('contrat', 'paid')
        ORDER BY COALESCE(s.date_validation, s.date_creation) DESC
      `;
      fallbackParams = [req.user.id];
    }

    const fallbackResult = await pool.query(fallbackQuery, fallbackParams);

    const mergedRows = [...(legacyResult.rows || []), ...(fallbackResult.rows || [])];
    const byPolice = new Map();
    const withoutPolice = [];

    for (const row of mergedRows) {
      const normalizedPolice = normalizePoliceNumber(row.numepoli);

      if (!normalizedPolice) {
        withoutPolice.push(row);
        continue;
      }

      const existing = byPolice.get(normalizedPolice);
      if (!existing) {
        byPolice.set(normalizedPolice, row);
        continue;
      }

      const existingSource = (existing.source || '').toLowerCase();
      const incomingSource = (row.source || '').toLowerCase();

      // Prioriser la source "legacy" pour masquer l'attente dès synchronisation métier
      if (existingSource !== 'legacy' && incomingSource === 'legacy') {
        byPolice.set(normalizedPolice, row);
      }
    }

    const fallbackSeen = new Set();
    const fallbackUnique = [];
    for (const row of withoutPolice) {
      const key = [
        row.subscription_id || row.id || '',
        row.codeprod || '',
        row.codeappo || '',
        row.telephone1 || '',
        row.dateeffet ? new Date(row.dateeffet).toISOString().slice(0, 10) : '',
      ].join('|');

      if (!fallbackSeen.has(key)) {
        fallbackSeen.add(key);
        fallbackUnique.push(row);
      }
    }

    const contrats = [...byPolice.values(), ...fallbackUnique].map((row) => {
      const enriched = enrichSubscriptionAmounts(row);
      if (enriched && Object.prototype.hasOwnProperty.call(enriched, 'souscriptiondata')) {
        delete enriched.souscriptiondata;
      }
      return enriched;
    });

    contrats.sort((a, b) => {
      const dateA = a.dateeffet ? new Date(a.dateeffet).getTime() : 0;
      const dateB = b.dateeffet ? new Date(b.dateeffet).getTime() : 0;
      return dateB - dateA;
    });

    console.log(`✅ ${contrats.length} contrat(s) retourné(s)`);

    res.json({
      success: true,
      count: contrats.length,
      contrats,
    });
    
  } catch (error) {
    console.error('❌ Erreur récupération mes contrats:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des contrats',
      error: error.message
    });
  }
};

/**
 * Génère le PDF d'un contrat
 * Route: GET /api/contrats/pdf/:numepoli
 */
exports.generateContratPdf = async (req, res) => {
  try {
    const { numepoli } = req.params;
    
    console.log('=== GÉNÉRATION PDF CONTRAT ===');
    console.log('📋 Numéro police:', numepoli);
    console.log('👤 User ID:', req.user.id);
    console.log('🎭 Role:', req.user.role);
    
    // Récupérer les détails du contrat
    const query = `
      SELECT *
      FROM contrats
      WHERE numepoli = $1
    `;
    
    const result = await pool.query(query, [numepoli]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contrat non trouvé'
      });
    }
    
    const contrat = result.rows[0];
    
    // Vérifier les droits d'accès
    let hasAccess = false;
    
    if (req.user.role === 'admin') {
      hasAccess = true;
    } else if (req.user.role === 'commercial' && req.user.code_apporteur === contrat.codeappo) {
      hasAccess = true;
    } else if (req.user.role === 'client') {
      const userQuery = `SELECT telephone FROM users WHERE id = $1`;
      const userResult = await pool.query(userQuery, [req.user.id]);
      if (userResult.rows.length > 0) {
        const userPhone = userResult.rows[0].telephone;
        let cleanPhone = userPhone;
        if (userPhone.startsWith('+225')) {
          cleanPhone = userPhone.substring(4);
        }
        const phoneWithPrefix = '+225' + cleanPhone;
        
        if (contrat.telephone1 === cleanPhone || contrat.telephone1 === phoneWithPrefix ||
            contrat.telephone2 === cleanPhone || contrat.telephone2 === phoneWithPrefix) {
          hasAccess = true;
        }
      }
    }
    
    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Accès non autorisé à ce contrat'
      });
    }
    
    // Récupérer les bénéficiaires
    const benefQuery = `
      SELECT * FROM beneficiaires
      WHERE numepoli = $1
    `;
    const benefResult = await pool.query(benefQuery, [numepoli]);
    
    // Pour l'instant, retourner une réponse JSON
    // TODO: Implémenter la génération PDF réelle avec une bibliothèque comme PDFKit
    console.log('✅ PDF prêt (simulation)');
    
    res.json({
      success: true,
      message: 'PDF généré avec succès (simulation)',
      contrat: contrat,
      beneficiaires: benefResult.rows,
      note: 'Pour générer un vrai PDF, installer PDFKit ou utiliser un service externe'
    });
    
  } catch (error) {
    console.error('❌ Erreur génération PDF contrat:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la génération du PDF',
      error: error.message
    });
  }
};
