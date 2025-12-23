import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:mycorislife/services/subscription_service.dart';

// Couleurs globales
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color blanc = Colors.white;
const Color fondGris = Color(0xFFF5F7FA);
const Color texteGris = Color(0xFF666666);
const Color grisClair = Color(0xFFE0E0E0);
const Color bleuSecondaire = Color(0xFF1E4A8C);
const Color fondCarte = Color(0xFFF8FAFC);
const Color grisTexte = Color(0xFF64748B);
const Color vertSucces = Color(0xFF10B981);
const Color orangeWarning = Color(0xFFF59E0B);
const Color grisLeger = Color(0xFFF1F5F9);

class Membre {
  String nomPrenom;
  DateTime dateNaissance;

  Membre({required this.nomPrenom, required this.dateNaissance});
}

/// Page de souscription pour le produit CORIS SOLIDARITÉ
/// Permet de souscrire à une assurance famille avec conjoints, enfants et ascendants
///
/// [capital] : Capital garanti
/// [periodicite] : Périodicité de paiement (Mensuel, Trimestriel, etc.)
/// [nbConjoints] : Nombre de conjoints
/// [nbEnfants] : Nombre d'enfants
/// [nbAscendants] : Nombre d'ascendants
/// [clientId] : ID du client si souscription par commercial (optionnel)
/// [clientData] : Données du client si souscription par commercial (optionnel)
/// [subscriptionId] : ID de la souscription si modification (optionnel)
/// [existingData] : Données existantes si modification (optionnel)
class SouscriptionSolidaritePage extends StatefulWidget {
  final int? capital;
  final String? periodicite;
  final int? nbConjoints;
  final int? nbEnfants;
  final int? nbAscendants;
  final String? clientId; // ID du client si souscription par commercial
  final Map<String, dynamic>?
      clientData; // Données du client si souscription par commercial
  final int? subscriptionId; // ID de la souscription si modification
  final Map<String, dynamic>?
      existingData; // Données existantes si modification

  const SouscriptionSolidaritePage({
    super.key,
    this.capital,
    this.periodicite,
    this.nbConjoints,
    this.nbEnfants,
    this.nbAscendants,
    this.clientId,
    this.clientData,
    this.subscriptionId,
    this.existingData,
  });

  @override
  State<SouscriptionSolidaritePage> createState() =>
      _SouscriptionSolidaritePageState();
}

class _SouscriptionSolidaritePageState
    extends State<SouscriptionSolidaritePage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Données de simulation
  int? selectedCapital;
  String selectedPeriodicite = 'Mensuel';
  int nbConjoints = 1;
  int nbEnfants = 1;
  int nbAscendants = 0;
  double primeTotaleResult = 0.0;

  // Date d'effet du contrat
  DateTime? _dateEffetContrat;
  final TextEditingController _dateEffetController = TextEditingController();

  // Données des membres
  List<Membre> conjoints = [];
  List<Membre> enfants = [];
  List<Membre> ascendants = [];

  // Données utilisateur
  Map<String, dynamic> _userData = {};
  final storage = FlutterSecureStorage();
  bool _isLoading = true;

  // Variables pour le mode modification
  bool _isModification = false; // Indique si on est en mode modification

  /**
   * ============================================
   * NOUVELLES VARIABLES POUR LE MODE COMMERCIAL
   * ============================================
   * 
   * Ces variables permettent à un commercial de créer une souscription pour un client
   * sans que le client ait besoin d'avoir un compte dans le système.
   * 
   * FONCTIONNEMENT:
   * 1. _isCommercial : Indique si la souscription est créée par un commercial
   * 2. _clientDateNaissance, _clientAge : Stockent les informations de date de naissance et âge du client
   * 3. Les TextEditingController : Contrôlent les champs de saisie pour les informations du client
   * 4. _selectedClientCivilite : Civilité sélectionnée (Monsieur, Madame, Mademoiselle)
   * 5. _selectedClientIndicatif : Indicatif téléphonique sélectionné (+225, +226, etc.)
   */
  bool _isCommercial =
      false; // Indique si c'est un commercial qui fait la souscription
  DateTime?
      _clientDateNaissance; // Date de naissance du client (pour validation d'âge)
  int _clientAge =
      0; // Âge calculé du client (utilisé pour les validations et calculs)

  // Contrôleurs pour les informations client (si commercial)
  // Ces contrôleurs gèrent la saisie des informations du client dans le formulaire
  final TextEditingController _clientNomController = TextEditingController();
  final TextEditingController _clientPrenomController = TextEditingController();
  final TextEditingController _clientDateNaissanceController =
      TextEditingController();
  final TextEditingController _clientLieuNaissanceController =
      TextEditingController();
  final TextEditingController _clientTelephoneController =
      TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientAdresseController =
      TextEditingController();
  final TextEditingController _clientNumeroPieceController =
      TextEditingController();
  String _selectedClientCivilite = 'Monsieur'; // Civilité par défaut
  String _selectedClientIndicatif =
      '+225'; // Indicatif par défaut (Côte d'Ivoire)

  // Contrôleurs pour l'étape 2 (bénéficiaire et contact d'urgence)
  final TextEditingController _beneficiaireNomController =
      TextEditingController();
  final TextEditingController _beneficiaireContactController =
      TextEditingController();
  final TextEditingController _personneContactNomController =
      TextEditingController();
  final TextEditingController _personneContactTelController =
      TextEditingController();
  String _selectedLienParente = 'Conjoint(e)';
  String _selectedLienParenteUrgence = 'Conjoint(e)';
  String _selectedBeneficiaireIndicatif = '+221';
  String _selectedContactIndicatif = '+221';
  File? _pieceIdentite;

  // 💳 Variables Mode de Paiement
  String? _selectedModePaiement;
  String? _selectedBanque;
  final TextEditingController _banqueController = TextEditingController();
  final List<String> _banques = [
    'CORIS BANK',
    'SGCI',
    'BICICI',
    'Ecobank',
    'BOA',
    'UBA',
    'Société Générale',
    'BNI',
    'Banque Atlantique',
    'Autre',
  ];
  final TextEditingController _numeroCompteController = TextEditingController();
  final TextEditingController _numeroMobileMoneyController =
      TextEditingController();
  final List<String> _modePaiementOptions = [
    'Virement',
    'Wave',
    'Orange Money'
  ];

  final List<String> _lienParenteOptions = [
    'Conjoint(e)',
    'Enfant',
    'Parent',
    'Frère/Soeur',
    'Autre'
  ];

  final List<String> _indicatifs = [
    '+221',
    '+223',
    '+224',
    '+226',
    '+227',
    '+228',
    '+229',
    '+225'
  ];

  final periodicites = ['Mensuel', 'Trimestriel', 'Semestriel', 'Annuel'];
  final capitalOptions = [500000, 1000000, 1500000, 2000000];

  final Map<int, Map<String, double>> primeTotaleFamilleBase = {
    500000: {
      'mensuel': 2699,
      'trimestriel': 8019,
      'semestriel': 15882,
      'annuelle': 31141
    },
    1000000: {
      'mensuel': 5398,
      'trimestriel': 16038,
      'semestriel': 31764,
      'annuelle': 62283
    },
    1500000: {
      'mensuel': 8097,
      'trimestriel': 24057,
      'semestriel': 47646,
      'annuelle': 93424
    },
    2000000: {
      'mensuel': 10796,
      'trimestriel': 32076,
      'semestriel': 63529,
      'annuelle': 124566
    },
  };
  final Map<int, Map<String, int>> surprimesConjointsSupplementaires = {
    500000: {
      'mensuel': 860,
      'trimestriel': 2555,
      'semestriel': 5061,
      'annuelle': 9924
    },
    1000000: {
      'mensuel': 1720,
      'trimestriel': 5111,
      'semestriel': 10123,
      'annuelle': 19848
    },
    1500000: {
      'mensuel': 2580,
      'trimestriel': 7666,
      'semestriel': 15184,
      'annuelle': 29773
    },
    2000000: {
      'mensuel': 3440,
      'trimestriel': 10222,
      'semestriel': 20245,
      'annuelle': 39697
    },
  };
  final Map<int, Map<String, int>> surprimesEnfantsSupplementaires = {
    500000: {
      'mensuel': 124,
      'trimestriel': 370,
      'semestriel': 732,
      'annuelle': 1435
    },
    1000000: {
      'mensuel': 249,
      'trimestriel': 739,
      'semestriel': 1464,
      'annuelle': 2870
    },
    1500000: {
      'mensuel': 373,
      'trimestriel': 1109,
      'semestriel': 2196,
      'annuelle': 4306
    },
    2000000: {
      'mensuel': 498,
      'trimestriel': 1478,
      'semestriel': 2928,
      'annuelle': 5741
    },
  };
  final Map<int, Map<String, int>> surprimesAscendants = {
    500000: {
      'mensuel': 1547,
      'trimestriel': 4596,
      'semestriel': 9104,
      'annuelle': 17850
    },
    1000000: {
      'mensuel': 3094,
      'trimestriel': 9193,
      'semestriel': 18207,
      'annuelle': 35700
    },
    1500000: {
      'mensuel': 4641,
      'trimestriel': 13789,
      'semestriel': 27311,
      'annuelle': 53550
    },
    2000000: {
      'mensuel': 6188,
      'trimestriel': 18386,
      'semestriel': 36414,
      'annuelle': 71400
    },
  };

  Future<void> _loadUserData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map) {
          // 1) Cas standard: { success: true, user: { ... } }
          if (data['success'] == true &&
              data['user'] != null &&
              data['user'] is Map) {
            final userData = Map<String, dynamic>.from(data['user']);
            if (mounted) {
              setState(() {
                _userData = userData;
                _isLoading = false;
              });
            }
            return;
          }

          // 2) Cas nested: { success: true, data: { id, civilite, nom, ... } }
          if (data['success'] == true &&
              data['data'] != null &&
              data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('id') && dataObj.containsKey('email')) {
              final userData = Map<String, dynamic>.from(dataObj);
              if (mounted) {
                setState(() {
                  _userData = userData;
                  _isLoading = false;
                });
              }
              return;
            }
          }

          // 3) Cas nested avec user object: { data: { user: { ... } } }
          if (data['data'] != null &&
              data['data'] is Map &&
              data['data']['user'] != null &&
              data['data']['user'] is Map) {
            final userData = Map<String, dynamic>.from(data['data']['user']);
            if (mounted) {
              setState(() {
                _userData = userData;
                _isLoading = false;
              });
            }
            return;
          }

          // 4) Direct user object: { id, civilite, nom, ... }
          if (data.containsKey('id') && data.containsKey('email')) {
            final userData = Map<String, dynamic>.from(data);
            if (mounted) {
              setState(() {
                _userData = userData;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }

      // Fallback : Erreur ou format inattendu
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Toujours initialiser selectedCapital avec une valeur valide pour éviter l'erreur dropdown
    selectedCapital = 500000;

    // Vérifier si on est en mode modification
    _isModification =
        widget.subscriptionId != null && widget.existingData != null;

    if (_isModification) {
      // Mode modification : préremplir avec les données existantes
      _prefillExistingData();
    } else {
      // Mode création : initialiser avec les valeurs par défaut
      selectedCapital = widget.capital ?? 500000;
      selectedPeriodicite = widget.periodicite ?? 'Mensuel';
      nbConjoints = widget.nbConjoints ?? 1;
      nbEnfants = widget.nbEnfants ?? 1;
      nbAscendants = widget.nbAscendants ?? 0;

      // Initialiser les listes de membres
      conjoints = List.generate(nbConjoints,
          (index) => Membre(nomPrenom: '', dateNaissance: DateTime.now()));
      enfants = List.generate(nbEnfants,
          (index) => Membre(nomPrenom: '', dateNaissance: DateTime.now()));
      ascendants = List.generate(nbAscendants,
          (index) => Membre(nomPrenom: '', dateNaissance: DateTime.now()));

      // Initialiser la date d'effet (aujourd'hui par défaut)
      _dateEffetContrat = DateTime.now();
      _dateEffetController.text = _formatDate(_dateEffetContrat);

      // Calculer la prime initiale
      _calculerPrime();
    }

    // Charger les données utilisateur seulement si ce n'est pas un commercial
    // Pour les commerciaux, on chargera les données dans didChangeDependencies
  }

  /**
   * ============================================
   * MÉTHODE didChangeDependencies
   * ============================================
   * 
   * Cette méthode est appelée automatiquement par Flutter lorsque les dépendances du widget changent.
   * Elle est utilisée ici pour:
   * 1. Détecter si c'est un commercial qui accède à la page
   * 2. Pré-remplir les champs avec les informations d'un client existant (si sélectionné)
   * 3. Initialiser le mode commercial si nécessaire
   * 
   * ARGUMENTS ATTENDUS (via ModalRoute):
   * - isCommercial: true si c'est un commercial qui fait la souscription
   * - clientInfo: Map contenant les informations du client (si un client existant est sélectionné)
   * 
   * FLUX:
   * - Si isCommercial = true : Active le mode commercial et affiche les champs client
   * - Si clientInfo existe : Pré-remplit tous les champs avec les données du client
   * - Si isCommercial = false : Charge les données de l'utilisateur connecté (mode client normal)
   */
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Récupérer les arguments passés lors de la navigation vers cette page
    // Ces arguments peuvent contenir isCommercial et clientInfo
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Vérifier si c'est un commercial qui fait la souscription
    if (args != null && args['isCommercial'] == true) {
      // Activer le mode commercial si ce n'est pas déjà fait
      if (!_isCommercial) {
        setState(() {
          _isCommercial = true;
        });
      }

      /**
       * PRÉ-REMPLISSAGE AUTOMATIQUE DES CHAMPS CLIENT
       * 
       * Si un client existant a été sélectionné (depuis select_client_screen),
       * on pré-remplit automatiquement tous les champs avec ses informations.
       * Cela permet au commercial de gagner du temps lors de la création d'une nouvelle souscription
       * pour un client pour lequel il a déjà créé des souscriptions.
       */
      if (args['clientInfo'] != null) {
        // Extraire les informations du client depuis les arguments
        final clientInfo = args['clientInfo'] as Map<String, dynamic>;

        // Pré-remplir tous les champs texte avec les informations du client
        // L'opérateur ?? permet d'utiliser une chaîne vide si la valeur est null
        _clientNomController.text = clientInfo['nom'] ?? '';
        _clientPrenomController.text = clientInfo['prenom'] ?? '';
        _clientEmailController.text = clientInfo['email'] ?? '';
        _clientTelephoneController.text = clientInfo['telephone'] ?? '';
        _clientLieuNaissanceController.text =
            clientInfo['lieu_naissance'] ?? '';
        _clientAdresseController.text = clientInfo['adresse'] ?? '';
        _clientNumeroPieceController.text =
            clientInfo['numero_piece_identite'] ?? '';

        // Pré-remplir la civilité si disponible
        if (clientInfo['civilite'] != null) {
          _selectedClientCivilite = clientInfo['civilite'];
        }

        /**
         * GESTION DE LA DATE DE NAISSANCE
         * 
         * La date peut être reçue sous deux formats:
         * 1. String (format ISO 8601, ex: "1995-11-19")
         * 2. DateTime (objet DateTime directement)
         * 
         * On convertit toujours en DateTime pour faciliter les calculs d'âge.
         * On formate ensuite la date au format français (JJ/MM/AAAA) pour l'affichage.
         * On calcule aussi l'âge du client pour les validations ultérieures.
         */
        if (clientInfo['date_naissance'] != null) {
          try {
            DateTime? dateNaissance;
            // Vérifier le type de la date et la convertir en DateTime si nécessaire
            if (clientInfo['date_naissance'] is String) {
              // Si c'est une String, utiliser DateTime.parse pour la convertir
              dateNaissance = DateTime.parse(clientInfo['date_naissance']);
            } else if (clientInfo['date_naissance'] is DateTime) {
              // Si c'est déjà un DateTime, l'utiliser directement
              dateNaissance = clientInfo['date_naissance'];
            }

            if (dateNaissance != null) {
              final finalDate = dateNaissance;
              setState(() {
                // Stocker la date de naissance
                _clientDateNaissance = finalDate;

                // Formater la date au format français (JJ/MM/AAAA)
                // padLeft(2, '0') assure que les jours et mois ont toujours 2 chiffres
                _clientDateNaissanceController.text =
                    '${finalDate.day.toString().padLeft(2, '0')}/${finalDate.month.toString().padLeft(2, '0')}/${finalDate.year}';

                // Calculer l'âge du client
                final now = DateTime.now();
                _clientAge = now.year - finalDate.year;
                // Ajuster l'âge si l'anniversaire n'a pas encore eu lieu cette année
                if (now.month < finalDate.month ||
                    (now.month == finalDate.month && now.day < finalDate.day)) {
                  _clientAge--;
                }
              });
            }
          } catch (e) {
            // En cas d'erreur de parsing, afficher un message dans la console
            print('Erreur parsing date de naissance: $e');
          }
        }

        /**
         * EXTRACTION DE L'INDICATIF TÉLÉPHONIQUE
         * 
         * Si le numéro de téléphone commence par un indicatif (ex: +225),
         * on sépare l'indicatif du reste du numéro pour un affichage correct
         * dans les champs séparés (indicatif + numéro).
         */
        final telephone = clientInfo['telephone'] ?? '';
        if (telephone.isNotEmpty && telephone.startsWith('+')) {
          // Séparer l'indicatif du numéro (ex: "+225 0707889919" -> ["+225", "0707889919"])
          final parts = telephone.split(' ');
          if (parts.isNotEmpty) {
            // Le premier élément est l'indicatif
            _selectedClientIndicatif = parts[0];
            // Le reste est le numéro de téléphone
            if (parts.length > 1) {
              _clientTelephoneController.text = parts.sublist(1).join(' ');
            }
          }
        }
      }
    }

    /**
     * CHARGEMENT DES DONNÉES UTILISATEUR
     * 
     * - Si c'est un client normal : Charger ses données depuis le serveur
     * - Si c'est un commercial : Ne pas charger les données utilisateur car on utilise les infos client saisies
     *   et mettre _isLoading à false pour permettre l'affichage de la page
     */
    if (!_isCommercial) {
      // Mode client : Charger les données de l'utilisateur connecté
      _loadUserData();
    } else {
      /**
       * MODE COMMERCIAL : Pas besoin de charger les données utilisateur
       * 
       * CORRECTION DU BUG DE CHARGEMENT:
       * - Avant: _isLoading restait à true pour les commerciaux, ce qui bloquait l'affichage
       * - Maintenant: On met _isLoading à false immédiatement pour permettre l'affichage
       * - Les données client seront saisies manuellement ou pré-remplies depuis clientInfo
       */
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Préremplir les champs avec les données existantes pour la modification
  void _prefillExistingData() {
    if (widget.existingData == null) return;

    final data = widget.existingData!;

    // Détecter si c'est une souscription par commercial (présence de client_info)
    if (data['client_info'] != null) {
      _isCommercial = true;
      final clientInfo = data['client_info'] as Map<String, dynamic>;
      _clientNomController.text = clientInfo['nom'] ?? '';
      _clientPrenomController.text = clientInfo['prenom'] ?? '';
      _clientEmailController.text = clientInfo['email'] ?? '';
      _clientTelephoneController.text = clientInfo['telephone'] ?? '';
      _clientLieuNaissanceController.text = clientInfo['lieu_naissance'] ?? '';
      _clientAdresseController.text = clientInfo['adresse'] ?? '';
      if (clientInfo['civilite'] != null)
        _selectedClientCivilite = clientInfo['civilite'];
      if (clientInfo['date_naissance'] != null) {
        try {
          DateTime? dateNaissance;
          if (clientInfo['date_naissance'] is String) {
            dateNaissance = DateTime.parse(clientInfo['date_naissance']);
          } else if (clientInfo['date_naissance'] is DateTime) {
            dateNaissance = clientInfo['date_naissance'];
          }
          if (dateNaissance != null) {
            _clientDateNaissance = dateNaissance;
            _clientDateNaissanceController.text =
                '${dateNaissance.day.toString().padLeft(2, '0')}/${dateNaissance.month.toString().padLeft(2, '0')}/${dateNaissance.year}';
            final maintenant = DateTime.now();
            _clientAge = maintenant.year - dateNaissance.year;
            if (maintenant.month < dateNaissance.month ||
                (maintenant.month == dateNaissance.month &&
                    maintenant.day < dateNaissance.day)) {
              _clientAge = _clientAge - 1;
            }
          }
        } catch (e) {
          debugPrint('Erreur parsing date de naissance client: $e');
        }
      }
      final telephone = clientInfo['telephone'] ?? '';
      if (telephone.isNotEmpty && telephone.startsWith('+')) {
        final parts = telephone.split(' ');
        if (parts.isNotEmpty) {
          _selectedClientIndicatif = parts[0];
          if (parts.length > 1)
            _clientTelephoneController.text = parts.sublist(1).join(' ');
        }
      }
    }

    // Préremplir les données de base
    selectedCapital = data['capital'] ?? 500000;
    selectedPeriodicite = data['periodicite'] ?? 'Mensuel';

    // Préremplir la date d'effet
    if (data['date_effet'] != null) {
      try {
        _dateEffetContrat = DateTime.parse(data['date_effet']);
        _dateEffetController.text = _formatDate(_dateEffetContrat);
      } catch (e) {
        _dateEffetContrat = DateTime.now();
        _dateEffetController.text = _formatDate(_dateEffetContrat);
      }
    }

    // Préremplir les membres - Conjoints
    if (data['conjoints'] != null && data['conjoints'] is List) {
      final conjointsData = List<Map<String, dynamic>>.from(data['conjoints']);
      nbConjoints = conjointsData.length;
      conjoints = conjointsData.map((c) {
        DateTime dateNaissance = DateTime.now();
        try {
          dateNaissance = DateTime.parse(c['date_naissance'] ?? '');
        } catch (e) {
          // Garder la date par défaut
        }
        return Membre(
          nomPrenom: c['nom_prenom'] ?? '',
          dateNaissance: dateNaissance,
        );
      }).toList();
    } else {
      nbConjoints = 1;
      conjoints = [Membre(nomPrenom: '', dateNaissance: DateTime.now())];
    }

    // Préremplir les membres - Enfants
    if (data['enfants'] != null && data['enfants'] is List) {
      final enfantsData = List<Map<String, dynamic>>.from(data['enfants']);
      nbEnfants = enfantsData.length;
      enfants = enfantsData.map((e) {
        DateTime dateNaissance = DateTime.now();
        try {
          dateNaissance = DateTime.parse(e['date_naissance'] ?? '');
        } catch (e) {
          // Garder la date par défaut
        }
        return Membre(
          nomPrenom: e['nom_prenom'] ?? '',
          dateNaissance: dateNaissance,
        );
      }).toList();
    } else {
      nbEnfants = 1;
      enfants = [Membre(nomPrenom: '', dateNaissance: DateTime.now())];
    }

    // Préremplir les membres - Ascendants
    if (data['ascendants'] != null && data['ascendants'] is List) {
      final ascendantsData =
          List<Map<String, dynamic>>.from(data['ascendants']);
      nbAscendants = ascendantsData.length;
      ascendants = ascendantsData.map((a) {
        DateTime dateNaissance = DateTime.now();
        try {
          dateNaissance = DateTime.parse(a['date_naissance'] ?? '');
        } catch (e) {
          // Garder la date par défaut
        }
        return Membre(
          nomPrenom: a['nom_prenom'] ?? '',
          dateNaissance: dateNaissance,
        );
      }).toList();
    } else {
      nbAscendants = 0;
      ascendants = [];
    }

    // Préremplir bénéficiaire et contact d'urgence
    _beneficiaireNomController.text = data['beneficiaire_nom'] ?? '';
    _beneficiaireContactController.text = data['beneficiaire_contact'] ?? '';
    _personneContactNomController.text = data['contact_urgence_nom'] ?? '';
    _personneContactTelController.text = data['contact_urgence_tel'] ?? '';

    // Calculer la prime avec les données préremplies
    _calculerPrime();
  }

  void _calculerPrime() {
    if (selectedCapital == null) return;

    // Détermine la clé de la périodicité pour les maps de tarifs
    String key = selectedPeriodicite.toLowerCase() == 'annuel'
        ? 'annuelle'
        : selectedPeriodicite.toLowerCase();

    // Calcul de la prime de base et des surprimes
    final double base = primeTotaleFamilleBase[selectedCapital]?[key] ?? 0;
    final int conjointSuppl =
        (surprimesConjointsSupplementaires[selectedCapital]?[key] ?? 0) *
            (nbConjoints > 1 ? nbConjoints - 1 : 0);
    final int enfantsSuppl =
        (surprimesEnfantsSupplementaires[selectedCapital]?[key] ?? 0) *
            (nbEnfants > 6 ? nbEnfants - 6 : 0);
    final int ascendantsSuppl =
        (surprimesAscendants[selectedCapital]?[key] ?? 0) * nbAscendants;

    setState(() {
      primeTotaleResult = base + conjointSuppl + enfantsSuppl + ascendantsSuppl;
    });
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Sélectionner une date';
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  // MÉTHODES CRITIQUES POUR LE STATUT DE PAIEMENT
  Future<int> _saveSubscriptionData() async {
    try {
      final subscriptionService = SubscriptionService();

      // Convertir les listes de membres en format JSON
      final conjointsData = conjoints
          .map((membre) => {
                'nom_prenom': membre.nomPrenom,
                'date_naissance': membre.dateNaissance.toIso8601String(),
              })
          .toList();

      final enfantsData = enfants
          .map((membre) => {
                'nom_prenom': membre.nomPrenom,
                'date_naissance': membre.dateNaissance.toIso8601String(),
              })
          .toList();

      final ascendantsData = ascendants
          .map((membre) => {
                'nom_prenom': membre.nomPrenom,
                'date_naissance': membre.dateNaissance.toIso8601String(),
              })
          .toList();

      final subscriptionData = {
        'product_type': 'coris_solidarite',
        'capital': selectedCapital,
        'periodicite': selectedPeriodicite.toLowerCase(),
        'prime': primeTotaleResult, // Prime pour PDF
        'prime_totale': primeTotaleResult,
        'date_effet': _dateEffetContrat?.toIso8601String(),
        'nombre_conjoints': nbConjoints,
        'nombre_enfants': nbEnfants,
        'nombre_ascendants': nbAscendants,
        'conjoints': conjointsData,
        'enfants': enfantsData,
        'ascendants': ascendantsData,
        'beneficiaire': {
          'nom': _beneficiaireNomController.text.trim(),
          'contact':
              '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text.trim()}',
          'lien_parente': _selectedLienParente,
        },
        'contact_urgence': {
          'nom': _personneContactNomController.text.trim(),
          'contact':
              '$_selectedContactIndicatif ${_personneContactTelController.text.trim()}',
          'lien_parente': _selectedLienParenteUrgence,
        },
        'piece_identite': _pieceIdentite?.path.split('/').last ?? '',
        // NE PAS inclure 'status' ici - il sera 'proposition' par défaut dans la base
      };

      http.Response response;
      Map<String, dynamic> responseData;

      if (_isModification && widget.subscriptionId != null) {
        // Mode modification : UPDATE
        debugPrint('🔄 Mode MODIFICATION - ID: ${widget.subscriptionId}');
        response = await subscriptionService.updateSubscription(
          widget.subscriptionId!,
          subscriptionData,
        );
        responseData = jsonDecode(response.body);

        if (response.statusCode != 200 || !responseData['success']) {
          throw Exception(
              responseData['message'] ?? 'Erreur lors de la modification');
        }

        // Retourner l'ID existant
        return widget.subscriptionId!;
      } else {
        // Mode création : INSERT
        debugPrint('➕ Mode CRÉATION');
        response =
            await subscriptionService.createSubscription(subscriptionData);
        responseData = jsonDecode(response.body);

        if (response.statusCode != 201 || !responseData['success']) {
          throw Exception(
              responseData['message'] ?? 'Erreur lors de la sauvegarde');
        }

        // RETOURNER l'ID de la souscription créée
        return responseData['data']['id'];
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde souscription: $e');
      rethrow;
    }
  }

  Future<void> _updatePaymentStatus(int subscriptionId, bool paymentSuccess,
      {String? paymentMethod}) async {
    try {
      final subscriptionService = SubscriptionService();
      final response = await subscriptionService.updatePaymentStatus(
        subscriptionId,
        paymentSuccess,
        paymentMethod: paymentMethod,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200 || !responseData['success']) {
        throw Exception(responseData['message'] ??
            'Erreur lors de la mise à jour du statut');
      }

      debugPrint(
          'Statut mis à jour: ${paymentSuccess ? 'contrat' : 'proposition'}');
    } catch (e) {
      debugPrint('Erreur mise à jour statut: $e');
      rethrow;
    }
  }

  Future<bool> _simulatePayment(String paymentMethod) async {
    // Simulation d'un délai de paiement
    await Future.delayed(const Duration(seconds: 2));

    // Pour la démo, retournez true pour succès, false pour échec
    return true; // Changez en false pour tester l'échec
  }

  void _processPayment(String paymentMethod) async {
    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _LoadingDialog(paymentMethod: paymentMethod));

    try {
      // ÉTAPE 1: Sauvegarder la souscription (statut: 'proposition' par défaut)
      final subscriptionId = await _saveSubscriptionData();

      // ÉTAPE 1.5: Upload du document pièce d'identité si présent
      if (_pieceIdentite != null) {
        await _uploadDocument(subscriptionId);
      }

      // ÉTAPE 2: Simuler le paiement
      final paymentSuccess = await _simulatePayment(paymentMethod);

      // ÉTAPE 3: Mettre à jour le statut selon le résultat du paiement
      await _updatePaymentStatus(subscriptionId, paymentSuccess,
          paymentMethod: paymentMethod);

      if (mounted) {
        Navigator.pop(context); // Fermer le loading

        if (paymentSuccess) {
          _showSuccessDialog(true); // Contrat activé
        } else {
          _showErrorSnackBar(
              'Paiement échoué. Votre proposition a été sauvegardée.');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erreur lors du traitement: $e');
      }
    }
  }

  void _saveAsProposition() async {
    try {
      // Sauvegarde avec statut 'proposition' par défaut
      final subscriptionId = await _saveSubscriptionData();

      // Upload du document pièce d'identité si présent
      if (_pieceIdentite != null) {
        await _uploadDocument(subscriptionId);
      }

      if (mounted) {
        _showSuccessDialog(false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
      }
    }
  }

  /// Upload du document pièce d'identité vers le serveur
  Future<void> _uploadDocument(int subscriptionId) async {
    try {
      debugPrint('📤 Upload document pour souscription $subscriptionId');
      final subscriptionService = SubscriptionService();
      final response = await subscriptionService.uploadDocument(
        subscriptionId,
        _pieceIdentite!.path,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200 || !responseData['success']) {
        debugPrint('❌ Erreur upload: ${responseData['message']}');
        throw Exception(
            responseData['message'] ?? 'Erreur lors de l\'upload du document');
      }

      debugPrint('✅ Document uploadé avec succès');
    } catch (e) {
      debugPrint('❌ Exception upload document: $e');
      // Ne pas bloquer la souscription si l'upload échoue
      // On log juste l'erreur
    }
  }

  // FIN DES MÉTHODES CRITIQUES

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bleuCoris, bleuCoris.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.group, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isModification
                      ? "MODIFICATION CORIS SOLIDARITÉ"
                      : "SOUSCRIPTION CORIS SOLIDARITÉ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Déterminer le nombre d'étapes en fonction des membres
    int totalSteps = 6; // Paramètres + Récapitulatif
    if (nbConjoints == 0) totalSteps--;
    if (nbEnfants == 0) totalSteps--;
    if (nbAscendants == 0) totalSteps--;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: blanc,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(totalSteps, (index) {
          bool isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? bleuCoris : grisLeger,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? blanc : grisTexte,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (index < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isActive ? bleuCoris : grisLeger,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Page séparée pour les informations client (uniquement pour les commerciaux)
  Widget _buildStepClientInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormSection(
            'Informations du Client',
            Icons.person,
            [
              _buildDropdownField(
                value: _selectedClientCivilite,
                label: 'Civilité',
                icon: Icons.person_outline,
                items: ['Monsieur', 'Madame', 'Mademoiselle'],
                onChanged: (value) {
                  setState(() {
                    _selectedClientCivilite = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _clientNomController,
                label: 'Nom du client',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _clientPrenomController,
                label: 'Prénom du client',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildDateField(
                controller: _clientDateNaissanceController,
                label: 'Date de naissance',
                icon: Icons.calendar_today,
                onDateSelected: (date) {
                  setState(() {
                    _clientDateNaissance = date;
                    _clientDateNaissanceController.text =
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    final maintenant = DateTime.now();
                    _clientAge = maintenant.year - date.year;
                    if (maintenant.month < date.month ||
                        (maintenant.month == date.month &&
                            maintenant.day < date.day)) {
                      _clientAge = _clientAge - 1;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _clientLieuNaissanceController,
                label: 'Lieu de naissance',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildPhoneFieldWithIndicatif(
                controller: _clientTelephoneController,
                label: 'Téléphone du client',
                selectedIndicatif: _selectedClientIndicatif,
                onIndicatifChanged: (value) {
                  setState(() {
                    _selectedClientIndicatif = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _clientEmailController,
                label: 'Email du client',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _clientAdresseController,
                label: 'Adresse du client',
                icon: Icons.home,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _clientNumeroPieceController,
                label: 'Numéro de pièce d\'identité',
                icon: Icons.badge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de capital
          _buildCapitalDropdown(),
          const SizedBox(height: 16),

          // Sélecteur de périodicité
          _buildPeriodiciteDropdown(),
          const SizedBox(height: 16),

          // Date d'effet du contrat
          _buildDateEffetField(),
          const SizedBox(height: 25),

          // Séparateur
          const Divider(color: grisClair, height: 1, thickness: 1),
          const SizedBox(height: 25),

          // Steppers pour les membres de la famille
          _buildStepper("Nombre de conjoints", nbConjoints, 0, 10, (val) {
            setState(() {
              nbConjoints = val;
              conjoints = List.generate(
                  nbConjoints,
                  (index) => index < conjoints.length
                      ? conjoints[index]
                      : Membre(nomPrenom: '', dateNaissance: DateTime.now()));
            });
            _calculerPrime();
          }),
          const SizedBox(height: 16),

          _buildStepper("Nombre d'enfants", nbEnfants, 0, 20, (val) {
            setState(() {
              nbEnfants = val;
              enfants = List.generate(
                  nbEnfants,
                  (index) => index < enfants.length
                      ? enfants[index]
                      : Membre(nomPrenom: '', dateNaissance: DateTime.now()));
            });
            _calculerPrime();
          }),
          const SizedBox(height: 16),

          _buildStepper("Nombre d'ascendants", nbAscendants, 0, 4, (val) {
            setState(() {
              nbAscendants = val;
              ascendants = List.generate(
                  nbAscendants,
                  (index) => index < ascendants.length
                      ? ascendants[index]
                      : Membre(nomPrenom: '', dateNaissance: DateTime.now()));
            });
            _calculerPrime();
          }),
        ],
      ),
    );
  }

  Widget _buildCapitalDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<int>(
          value: selectedCapital,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.attach_money, color: Color(0xFF002B6B)),
            labelText: 'Capital à garantir',
          ),
          items: capitalOptions
              .map((val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      '${_formatNumber(val)} FCFA',
                      style: const TextStyle(
                          color: Color(0xFF002B6B),
                          fontWeight: FontWeight.w500),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() => selectedCapital = val);
            _calculerPrime();
          },
        ),
      ),
    );
  }

  Widget _buildPeriodiciteDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: selectedPeriodicite,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF002B6B)),
            labelText: 'Périodicité',
          ),
          items: periodicites
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p,
                      style: const TextStyle(
                          color: Color(0xFF002B6B),
                          fontWeight: FontWeight.w500),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() => selectedPeriodicite = val!);
            _calculerPrime();
          },
        ),
      ),
    );
  }

  Widget _buildDateEffetField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextFormField(
          controller: _dateEffetController,
          readOnly: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.event, color: Color(0xFF002B6B)),
            labelText: 'Date d\'effet du contrat',
          ),
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _dateEffetContrat ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF002B6B),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF002B6B),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              setState(() {
                _dateEffetContrat = pickedDate;
                _dateEffetController.text = _formatDate(pickedDate);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStepper(
      String label, int value, int min, int max, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF002B6B),
                  fontWeight: FontWeight.w500)),
          Row(
            children: [
              _buildStepperButton(Icons.remove,
                  () => onChanged((value - 1).clamp(min, max)), value > min),
              SizedBox(
                width: 40,
                child: Text(
                  "$value",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B6B)),
                ),
              ),
              _buildStepperButton(Icons.add,
                  () => onChanged((value + 1).clamp(min, max)), value < max),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStepperButton(
      IconData icon, VoidCallback onPressed, bool isEnabled) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isEnabled ? bleuCoris : grisClair,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon, size: 18, color: isEnabled ? blanc : texteGris),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStepConjoints() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(nbConjoints, (index) {
          return _buildMembreForm(
            titre: 'Conjoint ${index + 1}',
            membre: conjoints[index],
            onChanged: (membre) {
              setState(() {
                conjoints[index] = membre;
              });
            },
          );
        }),
      ),
    );
  }

  Widget _buildStepEnfants() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(nbEnfants, (index) {
          return _buildMembreForm(
            titre: 'Enfant ${index + 1}',
            membre: enfants[index],
            onChanged: (membre) {
              setState(() {
                enfants[index] = membre;
              });
            },
          );
        }),
      ),
    );
  }

  Widget _buildStepAscendants() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(nbAscendants, (index) {
          return _buildMembreForm(
            titre: 'Ascendant ${index + 1}',
            membre: ascendants[index],
            onChanged: (membre) {
              setState(() {
                ascendants[index] = membre;
              });
            },
          );
        }),
      ),
    );
  }

  Widget _buildMembreForm(
      {required String titre,
      required Membre membre,
      required Function(Membre) onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B6B),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: membre.nomPrenom,
            decoration: InputDecoration(
              labelText: 'Nom et prénom',
              labelStyle: TextStyle(color: bleuCoris.withValues(alpha: 0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: grisClair, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: bleuCoris, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(color: bleuCoris, fontSize: 16),
            onChanged: (value) {
              onChanged(Membre(
                  nomPrenom: value, dateNaissance: membre.dateNaissance));
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Date de naissance',
              labelStyle: TextStyle(color: bleuCoris.withValues(alpha: 0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: grisClair, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: bleuCoris, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: Icon(Icons.calendar_today, color: bleuCoris),
            ),
            controller: TextEditingController(
                text: membre.dateNaissance != DateTime.now()
                    ? "${membre.dateNaissance.day.toString().padLeft(2, '0')}/${membre.dateNaissance.month.toString().padLeft(2, '0')}/${membre.dateNaissance.year}"
                    : ""),
            style: TextStyle(color: bleuCoris, fontSize: 16),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: membre.dateNaissance,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: bleuCoris,
                        onPrimary: Colors.white,
                      ),
                      dialogTheme: DialogThemeData(
                        // Remplace dialogBackgroundColor
                        backgroundColor: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != membre.dateNaissance) {
                // Validation en temps réel de l'âge selon le type de membre
                final now = DateTime.now();
                final age = now.year - picked.year;

                // Déterminer le type de membre basé sur le titre de la section
                bool isValid = true;
                String errorMessage = '';

                if (titre.contains('enfant') || titre.contains('Enfant')) {
                  if (age < 12 || age > 21) {
                    isValid = false;
                    errorMessage =
                        "L'âge des enfants doit être compris entre 12 et 21 ans. Âge sélectionné: $age ans.";
                  }
                } else if (titre.contains('conjoint') ||
                    titre.contains('Conjoint') ||
                    titre.contains('ascendant') ||
                    titre.contains('Ascendant') ||
                    titre.contains('parent') ||
                    titre.contains('Parent')) {
                  if (age < 18) {
                    isValid = false;
                    errorMessage =
                        "L'âge doit être d'au moins 18 ans. Âge sélectionné: $age ans.";
                  }
                }

                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return; // Ne pas changer la date si invalide
                }

                onChanged(
                    Membre(nomPrenom: membre.nomPrenom, dateNaissance: picked));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildFormSection(
              'Bénéficiaire et Contact d\'urgence',
              Icons.contacts,
              [
                _buildSubSectionTitle('Bénéficiaire en cas de décès'),
                _buildModernTextField(
                  controller: _beneficiaireNomController,
                  label: 'Nom complet du bénéficiaire',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                // Champ avec indicatif
                _buildPhoneFieldWithIndicatif(
                  controller: _beneficiaireContactController,
                  label: 'Contact du bénéficiaire',
                  selectedIndicatif: _selectedBeneficiaireIndicatif,
                  onIndicatifChanged: (value) {
                    setState(() {
                      _selectedBeneficiaireIndicatif = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  value: _selectedLienParente,
                  label: 'Lien de parenté',
                  icon: Icons.link,
                  items: _lienParenteOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedLienParente = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildSubSectionTitle('Contact d\'urgence'),
                _buildModernTextField(
                  controller: _personneContactNomController,
                  label: 'Nom complet',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                // Champ avec indicatif
                _buildPhoneFieldWithIndicatif(
                  controller: _personneContactTelController,
                  label: 'Contact téléphonique',
                  selectedIndicatif: _selectedContactIndicatif,
                  onIndicatifChanged: (value) {
                    setState(() {
                      _selectedContactIndicatif = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  value: _selectedLienParenteUrgence,
                  label: 'Lien de parenté',
                  icon: Icons.link,
                  items: _lienParenteOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedLienParenteUrgence = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDocumentUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: bleuCoris,
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: blanc,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: bleuCoris, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris))
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: bleuCoris.withValues(alpha: 0.7)),
        prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bleuCoris.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: bleuCoris, size: 20)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: grisLeger)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: grisLeger)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: bleuCoris, width: 2)),
        filled: true,
        fillColor: fondCarte,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Ce champ est obligatoire'
          : null,
    );
  }

  /**
   * ============================================
   * WIDGET _buildDateField
   * ============================================
   * 
   * Crée un champ de saisie de date avec un sélecteur de date intégré.
   * 
   * PARAMÈTRES:
   * - controller: TextEditingController pour gérer le texte affiché dans le champ
   * - label: Label affiché au-dessus du champ
   * - icon: Icône affichée dans le champ (généralement Icons.calendar_today)
   * - onDateSelected: Callback appelé quand une date est sélectionnée
   * 
   * FONCTIONNEMENT:
   * 1. Affiche un TextFormField en lecture seule (AbsorbPointer)
   * 2. Quand l'utilisateur tape sur le champ, ouvre un DatePicker
   * 3. Le DatePicker utilise un Theme personnalisé pour éviter les erreurs MaterialLocalizations
   * 4. Une fois la date sélectionnée, appelle onDateSelected avec la date choisie
   * 
   * CORRECTION DU BUG:
   * - Avant: Utilisation de ThemeData.light() causait des erreurs MaterialLocalizations
   * - Maintenant: Utilisation de Theme.of(context).copyWith() pour hériter du contexte parent
   */
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _clientDateNaissance ??
                  DateTime.now().subtract(const Duration(days: 365 * 30)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: bleuCoris,
                      onPrimary: blanc,
                      surface: blanc,
                      onSurface: bleuCoris,
                    ),
                    dialogBackgroundColor: blanc,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                hintText: 'JJ/MM/AAAA',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: bleuCoris.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: bleuCoris, size: 20)),
                filled: true,
                fillColor: fondCarte,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: bleuCoris, width: 1.5),
                ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ce champ est obligatoire'
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneFieldWithIndicatif({
    required TextEditingController controller,
    required String label,
    required String selectedIndicatif,
    required Function(String?) onIndicatifChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris)),
        const SizedBox(height: 6),
        Row(
          children: [
            // Dropdown pour l'indicatif
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: fondCarte,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: grisLeger),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedIndicatif,
                  isExpanded: true,
                  items: _indicatifs.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child:
                            Text(value, style: const TextStyle(fontSize: 14)),
                      ),
                    );
                  }).toList(),
                  onChanged: onIndicatifChanged,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Champ de téléphone
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: '00 00 00 00',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.phone_outlined,
                      size: 20, color: bleuCoris.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: fondCarte,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bleuCoris, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (!RegExp(r'^[0-9]{8,15}$')
                      .hasMatch(value.replaceAll(' ', ''))) {
                    return 'Numéro de téléphone invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: bleuCoris.withValues(alpha: 0.7)),
        prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bleuCoris.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: bleuCoris, size: 20)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: grisLeger)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: grisLeger)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: bleuCoris, width: 2)),
        filled: true,
        fillColor: fondCarte,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      items: items
          .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
    );
  }

  Widget _buildDocumentUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: blanc,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.document_scanner, color: bleuCoris, size: 20),
          const SizedBox(width: 12),
          Text('Pièce d\'identité',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris))
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDocument,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _pieceIdentite != null
                  ? vertSucces.withValues(alpha: 0.1)
                  : bleuCoris.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _pieceIdentite != null
                      ? vertSucces
                      : bleuCoris.withValues(alpha: 0.3),
                  width: 2),
            ),
            child: Column(children: [
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                      _pieceIdentite != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      size: 40,
                      color: _pieceIdentite != null ? vertSucces : bleuCoris,
                      key: ValueKey(_pieceIdentite != null))),
              const SizedBox(height: 10),
              Text(
                  _pieceIdentite != null
                      ? 'Document ajouté avec succès'
                      : 'Télécharger votre pièce d\'identité',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _pieceIdentite != null ? vertSucces : bleuCoris)),
              const SizedBox(height: 6),
              Text(
                  _pieceIdentite != null
                      ? _pieceIdentite!.path.split('/').last
                      : 'Formats acceptés: PDF, JPG, PNG (Max: 5MB)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: grisTexte, fontSize: 11)),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        if (mounted) {
          setState(() => _pieceIdentite = File(result.files.single.path!));
          _showSuccessSnackBar('Document ajouté avec succès');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sélection du fichier');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: blanc),
          const SizedBox(width: 12),
          Expanded(child: Text(message))
        ]),
        backgroundColor: rougeCoris,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: blanc),
          const SizedBox(width: 12),
          Expanded(child: Text(message))
        ]),
        backgroundColor: vertSucces,
      ),
    );
  }

  // Méthode pour déterminer les étapes actives en fonction des membres
  List<Widget> _getActiveSteps() {
    List<Widget> steps = [];

    // Si commercial, ajouter la page d'informations client en premier
    if (_isCommercial) {
      steps.add(_buildStepClientInfo());
    }

    steps.add(_buildStep1());

    if (nbConjoints > 0) {
      steps.add(_buildStepConjoints());
    }

    if (nbEnfants > 0) {
      steps.add(_buildStepEnfants());
    }

    if (nbAscendants > 0) {
      steps.add(_buildStepAscendants());
    }

    steps.add(_buildStep2());
    steps.add(_buildStepModePaiement()); // 💳 Étape mode de paiement
    steps.add(_buildStepRecap());

    return steps;
  }

  // Méthode pour obtenir le nombre total d'étapes
  int _getTotalSteps() {
    int total = 2; // Étape 1 et étape finale (bénéficiaire/contact)
    if (_isCommercial) total++; // Page client pour commercial
    if (nbConjoints > 0) total++;
    if (nbEnfants > 0) total++;
    if (nbAscendants > 0) total++;
    total++; // 💳 Mode de paiement
    total++; // Récapitulatif
    return total;
  }

  /// Charge les données utilisateur pour le récapitulatif (uniquement pour les clients)
  /// Cette méthode est appelée dans le FutureBuilder pour charger les données à la volée
  /// si elles ne sont pas déjà disponibles dans _userData
  Future<Map<String, dynamic>> _loadUserDataForRecap() async {
    try {
      // Si _userData est déjà chargé et non vide, l'utiliser directement
      if (_userData.isNotEmpty) {
        debugPrint('✅ Utilisation des données utilisateur déjà chargées');
        return _userData;
      }

      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('❌ Token non trouvé');
        // Retourner un map vide au lieu de lever une exception
        return <String, dynamic>{};
      }

      debugPrint('🔄 Chargement des données utilisateur depuis l\'API...');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Timeout lors de la requête API');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map) {
          // 1) Cas standard: { success: true, user: { ... } }
          if (data['success'] == true &&
              data['user'] != null &&
              data['user'] is Map) {
            final userData = Map<String, dynamic>.from(data['user']);
            debugPrint(
                '✅ Données utilisateur: ${userData['nom']} ${userData['prenom']}');
            if (mounted) {
              setState(() {
                _userData = userData;
              });
            }
            return userData;
          }

          // 2) Cas nested: { success: true, data: { id, civilite, nom, ... } }
          if (data['success'] == true &&
              data['data'] != null &&
              data['data'] is Map) {
            final dataObj = data['data'] as Map<String, dynamic>;
            if (dataObj.containsKey('id') && dataObj.containsKey('email')) {
              final userData = Map<String, dynamic>.from(dataObj);
              debugPrint(
                  '✅ Données utilisateur depuis data: ${userData['nom']} ${userData['prenom']}');
              if (mounted) {
                setState(() {
                  _userData = userData;
                });
              }
              return userData;
            }
          }

          // 3) Cas nested avec user object: { data: { user: { ... } } }
          if (data['data'] != null &&
              data['data'] is Map &&
              data['data']['user'] != null &&
              data['data']['user'] is Map) {
            final userData = Map<String, dynamic>.from(data['data']['user']);
            debugPrint(
                '✅ Données utilisateur depuis data.user: ${userData['nom']} ${userData['prenom']}');
            if (mounted) {
              setState(() {
                _userData = userData;
              });
            }
            return userData;
          }

          // 4) Direct user object: { id, civilite, nom, ... }
          if (data.containsKey('id') && data.containsKey('email')) {
            final userData = Map<String, dynamic>.from(data);
            debugPrint(
                '✅ Données utilisateur directes: ${userData['nom']} ${userData['prenom']}');
            if (mounted) {
              setState(() {
                _userData = userData;
              });
            }
            return userData;
          }

          debugPrint(
              '⚠️ Réponse API inattendue (${response.statusCode}): ${response.body}');
        } else {
          debugPrint('⚠️ Format invalide (non-Map): ${response.body}');
        }
      } else {
        debugPrint('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
      }

      // Fallback vers _userData si la requête échoue - GARANTIR non-null
      final result = _userData.isNotEmpty ? _userData : <String, dynamic>{};
      return result;
    } catch (e) {
      debugPrint(
          '❌ Erreur chargement données utilisateur pour récapitulatif: $e');
      // Fallback vers _userData en cas d'erreur - GARANTIR non-null
      final result = _userData.isNotEmpty ? _userData : <String, dynamic>{};
      return result;
    }
  }

  /// 💳 ÉTAPE MODE DE PAIEMENT
  Widget _buildStepModePaiement() {
    const Color bleuCoris = Color(0xFF002B6B);
    const Color blanc = Colors.white;
    const Color fondCarte = Color(0xFFF8FAFC);
    const Color grisTexte = Color(0xFF64748B);
    const Color orangeCoris = Color(0xFFFF6B00);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            'Choisissez votre mode de paiement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: bleuCoris,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez comment vous souhaitez effectuer vos paiements',
            style: TextStyle(
              fontSize: 14,
              color: grisTexte,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Sélection du mode de paiement
          Container(
            decoration: BoxDecoration(
              color: blanc,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Mode de paiement *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: bleuCoris,
                    ),
                  ),
                ),
                ..._modePaiementOptions.map((mode) {
                  final isSelected = _selectedModePaiement == mode;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedModePaiement = mode;
                      // Réinitialiser les champs selon le mode
                      if (mode != 'Virement') {
                        _banqueController.clear();
                        _numeroCompteController.clear();
                      }
                      if (mode == 'Virement') {
                        _numeroMobileMoneyController.clear();
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? bleuCoris.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mode == 'Virement'
                                ? Icons.account_balance
                                : mode == 'Wave'
                                    ? Icons.water_drop
                                    : Icons.phone_android,
                            color: isSelected ? bleuCoris : grisTexte,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              mode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? bleuCoris : grisTexte,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: bleuCoris, size: 24),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Champs conditionnels selon le mode
          if (_selectedModePaiement == 'Virement') ...[
            DropdownButtonFormField<String>(
              value: _selectedBanque,
              decoration: InputDecoration(
                labelText: 'Nom de la banque',
                prefixIcon: Container(
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bleuCoris.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.account_balance, color: bleuCoris, size: 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: grisLeger),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: grisLeger),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: bleuCoris, width: 2),
                ),
                filled: true,
                fillColor: fondCarte,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              hint: Text('Sélectionnez votre banque'),
              items: _banques.map((String banque) {
                return DropdownMenuItem<String>(
                  value: banque,
                  child: Text(banque),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBanque = newValue;
                  if (newValue != null && newValue != 'Autre') {
                    _banqueController.text = newValue;
                  } else if (newValue == 'Autre') {
                    _banqueController.text = '';
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une banque';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ texte personnalisé si "Autre" est sélectionné
            if (_selectedBanque == 'Autre') ...[
              _buildModernTextField(
                controller: _banqueController,
                label: 'Nom de votre banque',
                icon: Icons.edit,
              ),
              const SizedBox(height: 16),
            ],
            _buildModernTextField(
              controller: _numeroCompteController,
              label: 'Numéro de compte',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
            ),
          ] else if (_selectedModePaiement == 'Wave' ||
              _selectedModePaiement == 'Orange Money') ...[
            _buildModernTextField(
              controller: _numeroMobileMoneyController,
              label: 'Numéro de téléphone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
          ],

          const SizedBox(height: 24),

          // Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: orangeCoris.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: orangeCoris.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: orangeCoris, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ces informations seront utilisées pour vos paiements de primes. Assurez-vous qu\'elles sont correctes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: grisTexte,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRecap() {
    /**
     * MODIFICATION IMPORTANTE:
     * 
     * Pour les CLIENTS (plateforme client):
     * - Les informations sont déjà pré-enregistrées dans la base de données lors de l'inscription
     * - On doit TOUJOURS charger les données depuis _loadUserDataForRecap() qui récupère le profil de l'utilisateur connecté
     * 
     * Pour les COMMERCIAUX (plateforme commercial):
     * - Le commercial saisit les informations du client dans les champs du formulaire
     * - On utilise les valeurs des contrôleurs (_clientNomController, etc.)
     */
    return _isCommercial
        ? _buildRecapContent()
        : FutureBuilder<Map<String, dynamic>>(
            future: _loadUserDataForRecap(),
            builder: (context, snapshot) {
              // Pour les clients, attendre le chargement des données
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: bleuCoris),
                );
              }

              if (snapshot.hasError) {
                debugPrint(
                    'Erreur chargement données récapitulatif: ${snapshot.error}');
                // En cas d'erreur, essayer d'utiliser _userData si disponible
                if (_userData.isNotEmpty) {
                  return _buildRecapContent(userData: _userData);
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: rougeCoris),
                      SizedBox(height: 16),
                      Text('Erreur lors du chargement des données'),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              // Utiliser les données chargées ou _userData en fallback
              final userData = snapshot.data ?? _userData;

              // Si userData est vide, recharger les données
              if (userData.isEmpty && !_isCommercial) {
                // Recharger les données utilisateur
                _loadUserDataForRecap().then((data) {
                  if (mounted && data.isNotEmpty) {
                    setState(() {
                      _userData = data;
                    });
                  }
                });
                return Center(
                    child: CircularProgressIndicator(color: bleuCoris));
              }

              return _buildRecapContent(userData: userData);
            },
          );
  }

  Widget _buildRecapContent({Map<String, dynamic>? userData}) {
    /**
     * CONSTRUCTION DU RÉCAPITULATIF:
     * 
     * - Si _isCommercial = true: Utiliser les données des contrôleurs (infos client saisies par le commercial)
     * - Si _isCommercial = false: Utiliser userData (infos du client connecté depuis la base de données)
     */
    Map<String, dynamic>? raw = _isCommercial ? null : (userData ?? _userData);

    String pick(List<String> keys) {
      if (raw == null) return '';
      for (final k in keys) {
        if (raw.containsKey(k) && raw[k] != null) {
          final v = raw[k];
          if (v is String && v.trim().isNotEmpty) return v;
          if (v is int || v is double) return v.toString();
          if (v is DateTime) return v.toIso8601String();
        }
      }
      return '';
    }

    // Ajout de variantes pour chaque champ afin de couvrir tous les cas
    final displayData = _isCommercial
        ? {
            'civilite': _selectedClientCivilite,
            'nom': _clientNomController.text,
            'prenom': _clientPrenomController.text,
            'email': _clientEmailController.text,
            'telephone':
                '$_selectedClientIndicatif ${_clientTelephoneController.text}',
            'date_naissance': _clientDateNaissance?.toIso8601String(),
            'lieu_naissance': _clientLieuNaissanceController.text,
            'adresse': _clientAdresseController.text,
          }
        : {
            'civilite': pick(['civilite', 'title', 'gender', 'genre']),
            'nom': pick([
              'nom',
              'last_name',
              'name',
              'full_name',
              'surname',
              'family_name'
            ]),
            'prenom':
                pick(['prenom', 'first_name', 'given_name', 'middle_name']),
            'email': pick(['email', 'mail', 'email_address']),
            'telephone':
                pick(['telephone', 'phone', 'phone_number', 'tel', 'mobile']),
            'date_naissance': pick(
                ['date_naissance', 'birth_date', 'dob', 'dateDeNaissance']),
            'lieu_naissance': pick([
              'lieu_naissance',
              'place_of_birth',
              'birth_place',
              'lieuDeNaissance'
            ]),
            'adresse': pick(['adresse', 'address', 'adresse_postale']),
          };

    // S'assurer que la prime est bien calculée avant affichage
    if (primeTotaleResult == 0) {
      _calculerPrime();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations personnelles
          _buildRecapSection(
              'Informations Personnelles', Icons.person, bleuCoris, [
            _buildCombinedRecapRow(
                'Civilité',
                displayData['civilite'] ?? 'Non renseigné',
                'Nom',
                displayData['nom'] ?? 'Non renseigné'),
            _buildCombinedRecapRow(
                'Prénom',
                displayData['prenom'] ?? 'Non renseigné',
                'Email',
                displayData['email'] ?? 'Non renseigné'),
            _buildCombinedRecapRow(
                'Téléphone',
                displayData['telephone'] ?? 'Non renseigné',
                'Date de naissance',
                displayData['date_naissance'] ?? 'Non renseigné'),
            _buildCombinedRecapRow(
                'Lieu de naissance',
                displayData['lieu_naissance'] ?? 'Non renseigné',
                'Adresse',
                displayData['adresse'] ?? 'Non renseigné'),
          ]),
          const SizedBox(height: 12),

          // Produit souscrit
          _buildRecapSection(
              'Produit Souscrit', Icons.emoji_people_outlined, vertSucces, [
            _buildCombinedRecapRow('Produit', 'CORIS SOLIDARITÉ', 'Périodicité',
                selectedPeriodicite),
            _buildCombinedRecapRow(
                'Capital garanti',
                '${_formatNumber(selectedCapital!)} FCFA',
                'Prime totale',
                '${_formatNumber(primeTotaleResult.toInt())} FCFA'),
            _buildCombinedRecapRow(
                'Date d\'effet',
                _formatDate(_dateEffetContrat),
                'Prime',
                '${_formatNumber(primeTotaleResult.toInt())} FCFA'),
            _buildCombinedRecapRow(
                'Nombre de conjoints',
                conjoints.length.toString(),
                'Nombre d\'enfants',
                enfants.length.toString()),
            _buildRecapRow(
                'Nombre d\'ascendants', ascendants.length.toString()),
          ]),
          const SizedBox(height: 12),

          // Conjoints
          if (conjoints.isNotEmpty) ...[
            _buildRecapSection(
                'Conjoint(s)',
                Icons.people,
                bleuCoris,
                conjoints
                    .map((conjoint) => _buildMembreRecap(conjoint))
                    .toList()),
            const SizedBox(height: 12),
          ],

          // Enfants
          if (enfants.isNotEmpty) ...[
            _buildRecapSection('Enfant(s)', Icons.child_care, bleuCoris,
                enfants.map((enfant) => _buildMembreRecap(enfant)).toList()),
            const SizedBox(height: 12),
          ],

          // Ascendants
          if (ascendants.isNotEmpty) ...[
            _buildRecapSection(
                'Ascendant(s)',
                Icons.elderly,
                bleuCoris,
                ascendants
                    .map((ascendant) => _buildMembreRecap(ascendant))
                    .toList()),
            const SizedBox(height: 12),
          ],

          // Bénéficiaire et Contact d'urgence dans une seule carte
          _buildRecapSection('Bénéficiaire et Contact d\'urgence',
              Icons.contacts, bleuSecondaire, [
            _buildSubsectionTitle('Bénéficiaire'),
            _buildRecapRow(
                'Nom complet',
                _beneficiaireNomController.text.isEmpty
                    ? 'Non renseigné'
                    : _beneficiaireNomController.text),
            _buildRecapRow('Contact',
                '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text.isEmpty ? 'Non renseigné' : _beneficiaireContactController.text}'),
            _buildRecapRow('Lien de parenté', _selectedLienParente),
            const SizedBox(height: 8),
            _buildSubsectionTitle('Contact d\'urgence'),
            _buildRecapRow(
                'Nom complet',
                _personneContactNomController.text.isEmpty
                    ? 'Non renseigné'
                    : _personneContactNomController.text),
            _buildRecapRow('Contact',
                '$_selectedContactIndicatif ${_personneContactTelController.text.isEmpty ? 'Non renseigné' : _personneContactTelController.text}'),
            _buildRecapRow('Lien de parenté', _selectedLienParenteUrgence),
          ]),
          const SizedBox(height: 12),

          // 💳 Mode de Paiement
          if (_selectedModePaiement != null)
            _buildRecapSection(
              'Mode de Paiement',
              Icons.payment,
              _selectedModePaiement == 'Virement'
                  ? bleuCoris
                  : _selectedModePaiement == 'Wave'
                      ? Color(0xFF00BFFF)
                      : Color(0xFFFF6B00),
              [
                _buildRecapRow('Mode choisi', _selectedModePaiement!),
                const SizedBox(height: 8),
                if (_selectedModePaiement == 'Virement') ...[
                  _buildRecapRow(
                      'Banque',
                      _banqueController.text.isNotEmpty
                          ? _banqueController.text
                          : 'Non renseigné'),
                  _buildRecapRow(
                      'Numéro de compte',
                      _numeroCompteController.text.isNotEmpty
                          ? _numeroCompteController.text
                          : 'Non renseigné'),
                ] else if (_selectedModePaiement == 'Wave' ||
                    _selectedModePaiement == 'Orange Money') ...[
                  _buildRecapRow(
                      'Numéro ${_selectedModePaiement}',
                      _numeroMobileMoneyController.text.isNotEmpty
                          ? _numeroMobileMoneyController.text
                          : 'Non renseigné'),
                ],
              ],
            ),
          if (_selectedModePaiement != null) const SizedBox(height: 12),

          // Documents
          _buildRecapSection('Documents', Icons.description, bleuSecondaire, [
            _buildRecapRow('Pièce d\'identité',
                _pieceIdentite?.path.split('/').last ?? 'Non téléchargée'),
          ]),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: orangeWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: orangeWarning.withValues(alpha: 0.3))),
            child: Column(children: [
              Icon(Icons.info_outline, color: orangeWarning, size: 24),
              const SizedBox(height: 8),
              Text('Vérification Importante',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: orangeWarning,
                      fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                  'Vérifiez attentivement toutes les informations ci-dessus. Une fois la souscription validée, certaines modifications ne seront plus possibles.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: grisTexte, fontSize: 10, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 110,
            child: Text('$label :',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grisTexte,
                    fontSize: 12))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? vertSucces : bleuCoris,
                    fontSize: isHighlighted ? 13 : 12))),
      ]),
    );
  }

  Widget _buildRecapSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: blanc,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontWeight: FontWeight.w600, color: bleuCoris, fontSize: 14));
  }

  Widget _buildCombinedRecapRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label1 :',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: grisTexte, fontSize: 12)),
          Text(value1,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: bleuCoris, fontSize: 12)),
        ])),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label2 :',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: grisTexte, fontSize: 12)),
          Text(value2,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: bleuCoris, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildMembreRecap(Membre membre) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(membre.nomPrenom,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: bleuCoris, fontSize: 12)),
        Text(
            'Date de naissance: ${membre.dateNaissance.day.toString().padLeft(2, '0')}/${membre.dateNaissance.month.toString().padLeft(2, '0')}/${membre.dateNaissance.year}',
            style: TextStyle(color: grisTexte, fontSize: 11)),
      ]),
    );
  }

  void _showPaymentOptions() {
    if (mounted) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _PaymentBottomSheet(
              onPayNow: _processPayment, onPayLater: _saveAsProposition));
    }
  }

  void _showSuccessDialog(bool isPaid) {
    if (mounted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _SuccessDialog(isPaid: isPaid));
    }
  }

  bool _validateStepClientInfo() {
    if (_clientNomController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le nom du client');
      return false;
    }
    if (_clientPrenomController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le prénom du client');
      return false;
    }
    if (_clientDateNaissance == null) {
      _showErrorSnackBar('Veuillez saisir la date de naissance du client');
      return false;
    }
    final maintenant = DateTime.now();
    _clientAge = maintenant.year - _clientDateNaissance!.year;
    if (maintenant.month < _clientDateNaissance!.month ||
        (maintenant.month == _clientDateNaissance!.month &&
            maintenant.day < _clientDateNaissance!.day)) {
      _clientAge = _clientAge - 1;
    }
    if (_clientAge < 18 || _clientAge > 65) {
      _showErrorSnackBar(
          'Âge du client non valide (18-65 ans requis). Âge calculé: $_clientAge ans');
      return false;
    }
    // Email non obligatoire pour le commercial
    if (_clientTelephoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le téléphone du client');
      return false;
    }
    return true;
  }

  /// Valide les âges de tous les membres de la famille
  /// Enfants: 12-21 ans
  /// Conjoints: 18+ ans
  /// Ascendants: 18+ ans
  bool _validateMembresAges() {
    final maintenant = DateTime.now();

    // Vérifier les enfants (12-21 ans)
    for (var i = 0; i < enfants.length; i++) {
      final enfant = enfants[i];
      int age = maintenant.year - enfant.dateNaissance.year;
      if (maintenant.month < enfant.dateNaissance.month ||
          (maintenant.month == enfant.dateNaissance.month &&
              maintenant.day < enfant.dateNaissance.day)) {
        age--;
      }

      if (age < 12 || age > 21) {
        _showErrorSnackBar(
            'Enfant ${i + 1}: Âge non valide (12-21 ans requis). Âge calculé: $age ans');
        return false;
      }
    }

    // Vérifier les conjoints (18+ ans)
    for (var i = 0; i < conjoints.length; i++) {
      final conjoint = conjoints[i];
      int age = maintenant.year - conjoint.dateNaissance.year;
      if (maintenant.month < conjoint.dateNaissance.month ||
          (maintenant.month == conjoint.dateNaissance.month &&
              maintenant.day < conjoint.dateNaissance.day)) {
        age--;
      }

      if (age < 18) {
        _showErrorSnackBar(
            'Conjoint ${i + 1}: Âge non valide (18 ans minimum requis). Âge calculé: $age ans');
        return false;
      }
    }

    // Vérifier les ascendants (18+ ans)
    for (var i = 0; i < ascendants.length; i++) {
      final ascendant = ascendants[i];
      int age = maintenant.year - ascendant.dateNaissance.year;
      if (maintenant.month < ascendant.dateNaissance.month ||
          (maintenant.month == ascendant.dateNaissance.month &&
              maintenant.day < ascendant.dateNaissance.day)) {
        age--;
      }

      if (age < 18) {
        _showErrorSnackBar(
            'Ascendant ${i + 1}: Âge non valide (18 ans minimum requis). Âge calculé: $age ans');
        return false;
      }
    }

    return true;
  }

  /// 💳 VALIDATION MODE DE PAIEMENT
  bool _validateStepModePaiement() {
    if (_selectedModePaiement == null) {
      _showErrorSnackBar('Veuillez sélectionner un mode de paiement.');
      return false;
    }

    if (_selectedModePaiement == 'Virement') {
      if (_banqueController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer le nom de votre banque.');
        return false;
      }
      if (_numeroCompteController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer votre numéro de compte bancaire.');
        return false;
      }
    } else if (_selectedModePaiement == 'Wave' ||
        _selectedModePaiement == 'Orange Money') {
      if (_numeroMobileMoneyController.text.trim().isEmpty) {
        _showErrorSnackBar(
            'Veuillez entrer votre numéro de téléphone ${_selectedModePaiement}.');
        return false;
      }
      if (!RegExp(r'^[0-9]{8,10}$')
          .hasMatch(_numeroMobileMoneyController.text.trim())) {
        _showErrorSnackBar(
            'Le numéro de téléphone semble invalide (8 à 10 chiffres attendus).');
        return false;
      }
      // Validation spécifique pour Orange Money : doit commencer par 07
      if (_selectedModePaiement == 'Orange Money') {
        if (!_numeroMobileMoneyController.text.trim().startsWith('07')) {
          _showErrorSnackBar('Le numéro Orange Money doit commencer par 07.');
          return false;
        }
      }
    }

    return true;
  }

  void _nextStep() {
    // Valider la page client si c'est un commercial et qu'on est à l'étape 0
    if (_isCommercial && _currentStep == 0) {
      if (!_validateStepClientInfo()) {
        return; // Ne pas passer à l'étape suivante si la validation échoue
      }
    }

    // Valider le mode de paiement si on est sur cette étape (avant-dernière étape avant récap)
    final modePaiementStep = _getTotalSteps() - 2;
    if (_currentStep == modePaiementStep) {
      if (!_validateStepModePaiement()) {
        return; // Ne pas passer au récap si le mode de paiement n'est pas validé
      }
    }

    if (_currentStep < _getTotalSteps() - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      // Dernière étape (récap), aller à la page de paiement
      if (!_validateMembresAges()) {
        return; // Valider les âges avant le paiement
      }
      _showPaymentOptions();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondGris,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: bleuCoris))
          : Column(
              children: [
                _buildModernHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _getActiveSteps(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: blanc, boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -4))
                  ]),
                  child: SafeArea(
                    child: Row(children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: bleuCoris, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back,
                                      color: bleuCoris, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Précédent',
                                      style: TextStyle(
                                          color: bleuCoris,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                ]),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentStep == _getTotalSteps() - 1
                                      ? bleuCoris
                                      : rougeCoris,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                              shadowColor: (_currentStep == _getTotalSteps() - 1
                                      ? bleuCoris
                                      : rougeCoris)
                                  .withValues(alpha: 0.3)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    _currentStep == _getTotalSteps() - 1
                                        ? 'Finaliser'
                                        : 'Suivant',
                                    style: TextStyle(
                                        color: blanc,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(width: 8),
                                Icon(
                                    _currentStep == _getTotalSteps() - 1
                                        ? Icons.check
                                        : Icons.arrow_forward,
                                    color: blanc,
                                    size: 20),
                              ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// Classes pour les dialogues
class _LoadingDialog extends StatelessWidget {
  final String paymentMethod;
  const _LoadingDialog({required this.paymentMethod});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                  color: Color(0xFF002B6B), strokeWidth: 3)),
          const SizedBox(height: 20),
          const Text('Traitement en cours',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF002B6B))),
          const SizedBox(height: 8),
          Text('Paiement via $paymentMethod...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        ]),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final bool isPaid;
  const _SuccessDialog({required this.isPaid});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: isPaid
                      ? vertSucces.withValues(alpha: 0.1)
                      : orangeWarning.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(isPaid ? Icons.check_circle : Icons.schedule,
                  color: isPaid ? vertSucces : orangeWarning, size: 40)),
          const SizedBox(height: 20),
          Text(
            isPaid ? 'Souscription Réussie!' : 'Proposition Enregistrée!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF002B6B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
              isPaid
                  ? 'Félicitations! Votre contrat CORIS SOLIDARITÉ est maintenant actif. Vous recevrez un message de confirmation sous peu.'
                  : 'Votre proposition a été enregistrée avec succès. Vous pouvez effectuer le paiement plus tard depuis votre espace client.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 14, height: 1.4)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  // Retour à la page d'accueil client
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/client_home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF002B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Retour à l\'accueil',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600))),
          ),
        ]),
      ),
    );
  }
}

class _PaymentBottomSheet extends StatelessWidget {
  final Function(String) onPayNow;
  final VoidCallback onPayLater;
  const _PaymentBottomSheet({required this.onPayNow, required this.onPayLater});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4))
            ]),
        child: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Row(children: [
                    Icon(Icons.payment, color: Color(0xFF002B6B), size: 28),
                    const SizedBox(width: 12),
                    const Text('Options de Paiement',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF002B6B)))
                  ]),
                  const SizedBox(height: 24),
                  _buildPaymentOption('Wave', Icons.waves, Colors.blue,
                      'Paiement mobile sécurisé', () => onPayNow('Wave')),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                      'Orange Money',
                      Icons.phone_android,
                      Colors.orange,
                      'Paiement mobile Orange',
                      () => onPayNow('Orange Money')),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OU',
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500))),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: onPayLater,
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Color(0xFF002B6B), width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule,
                                    color: Color(0xFF002B6B), size: 20),
                                const SizedBox(width: 8),
                                const Text('Payer plus tard',
                                    style: TextStyle(
                                        color: Color(0xFF002B6B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16))
                              ]))),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ]))));
  }

  Widget _buildPaymentOption(String title, IconData icon, Color color,
      String subtitle, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF002B6B),
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 12))
                  ])),
              Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 16),
            ])));
  }
}
