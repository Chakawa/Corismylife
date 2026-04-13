// ignore_for_file: unused_field, unused_element
import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/services/wave_payment_handler.dart';
import 'package:mycorislife/core/utils/identity_document_picker.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import '../widgets/signature_dialog_syncfusion.dart' as SignatureDialogFile;

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

/// Page de souscription pour le produit CORIS SOLIDARITÃ‰
/// Permet de souscrire Ã  une assurance famille avec conjoints, enfants et ascendants
///
/// [capital] : Capital garanti
/// [periodicite] : PÃ©riodicitÃ© de paiement (Mensuel, Trimestriel, etc.)
/// [nbConjoints] : Nombre de conjoints
/// [nbEnfants] : Nombre d'enfants
/// [nbAscendants] : Nombre d'ascendants
/// [clientId] : ID du client si souscription par commercial (optionnel)
/// [clientData] : DonnÃ©es du client si souscription par commercial (optionnel)
/// [subscriptionId] : ID de la souscription si modification (optionnel)
/// [existingData] : DonnÃ©es existantes si modification (optionnel)
class SouscriptionSolidaritePage extends StatefulWidget {
  final int? capital;
  final String? periodicite;
  final int? nbConjoints;
  final int? nbEnfants;
  final int? nbAscendants;
  final String? clientId; // ID du client si souscription par commercial
  final Map<String, dynamic>?
      clientData; // DonnÃ©es du client si souscription par commercial
  final int? subscriptionId; // ID de la souscription si modification
  final Map<String, dynamic>?
      existingData; // DonnÃ©es existantes si modification

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

  // DonnÃ©es de simulation
  int? selectedCapital;
  String selectedPeriodicite = 'Mensuel';
  int nbConjoints = 1;
  int nbEnfants = 1;
  int nbAscendants = 0;
  double primeTotaleResult = 0.0;

  // Date d'effet du contrat
  DateTime? _dateEffetContrat;
  final TextEditingController _dateEffetController = TextEditingController();

  // Signature du client
  Uint8List? _clientSignature;

  // DonnÃ©es des membres
  List<Membre> conjoints = [];
  List<Membre> enfants = [];
  List<Membre> ascendants = [];

  // DonnÃ©es utilisateur
  Map<String, dynamic> _userData = {};
  final storage = FlutterSecureStorage();
  bool _isLoading = true;

  // Variables pour le mode modification
  bool _isModification = false; // Indique si on est en mode modification

  /// ============================================
  /// NOUVELLES VARIABLES POUR LE MODE COMMERCIAL
  /// ============================================
  /// 
  /// Ces variables permettent Ã  un commercial de crÃ©er une souscription pour un client
  /// sans que le client ait besoin d'avoir un compte dans le systÃ¨me.
  /// 
  /// FONCTIONNEMENT:
  /// 1. _isCommercial : Indique si la souscription est crÃ©Ã©e par un commercial
  /// 2. _clientDateNaissance, _clientAge : Stockent les informations de date de naissance et Ã¢ge du client
  /// 3. Les TextEditingController : ContrÃ´lent les champs de saisie pour les informations du client
  /// 4. _selectedClientCivilite : CivilitÃ© sÃ©lectionnÃ©e (Monsieur, Madame, Mademoiselle)
  /// 5. _selectedClientIndicatif : Indicatif tÃ©lÃ©phonique sÃ©lectionnÃ© (+225, +226, etc.)
  bool _isCommercial =
      false; // Indique si c'est un commercial qui fait la souscription
  DateTime?
      _clientDateNaissance; // Date de naissance du client (pour validation d'Ã¢ge)
  int _clientAge =
      0; // Ã‚ge calculÃ© du client (utilisÃ© pour les validations et calculs)

  // ContrÃ´leurs pour les informations client (si commercial)
  // Ces contrÃ´leurs gÃ¨rent la saisie des informations du client dans le formulaire
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
  final TextEditingController _clientProfessionController = TextEditingController();
  final TextEditingController _clientSecteurActiviteController = TextEditingController();
  final TextEditingController _clientNumeroPieceController =
      TextEditingController();
  String _selectedClientCivilite = 'Monsieur'; // CivilitÃ© par dÃ©faut
  String _selectedClientIndicatif =
      '+225'; // Indicatif par dÃ©faut (CÃ´te d'Ivoire)

  // ContrÃ´leurs pour l'Ã©tape 2 (bÃ©nÃ©ficiaire et contact d'urgence)
  final TextEditingController _beneficiaireNomController =
      TextEditingController();
  final TextEditingController _beneficiaireContactController =
      TextEditingController();
  final TextEditingController _beneficiaireDateNaissanceController =
      TextEditingController();
  final TextEditingController _personneContactNomController =
      TextEditingController();
  final TextEditingController _personneContactTelController =
      TextEditingController();
  String _selectedLienParente = 'Conjoint(e)';
  String _selectedLienParenteUrgence = 'Conjoint(e)';
  String _selectedBeneficiaireIndicatif = '+221';
  final String _selectedContactIndicatif = '+221';
  DateTime? _beneficiaireDateNaissance;
  File? _pieceIdentite;
  String? _pieceIdentiteLabel;
  final List<File> _pieceIdentiteFiles = [];

  // ðŸ’³ Variables Mode de Paiement
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
    'SociÃ©tÃ© GÃ©nÃ©rale',
    'BNI',
    'Banque Atlantique',
    'Autre',
  ];
  final TextEditingController _numeroCompteController = TextEditingController();
  final TextEditingController _numeroMobileMoneyController =
      TextEditingController();
  final TextEditingController _ribUnifiedController = TextEditingController();
  final TextEditingController _nomStructureController = TextEditingController();
  final TextEditingController _numeroMatriculeController =
      TextEditingController();
  final TextEditingController _corisMoneyPhoneController =
      TextEditingController();
  bool _isAideParCommercial = false;
  final TextEditingController _commercialNomPrenomController =
      TextEditingController();
  final TextEditingController _commercialCodeApporteurController =
      TextEditingController();
  final List<String> _modePaiementOptions = [
    'Virement',
    'Wave',
    // 'Orange Money',
    'PrÃ©lÃ¨vement Ã  la source',
    // 'CORIS Money',
  ];

  final List<String> _lienParenteOptions = [
    'Conjoint(e)',
    'Enfant',
    'Parent',
    'FrÃ¨re/Soeur',
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
      debugPrint('Erreur chargement donnÃ©es utilisateur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectBeneficiaireDateNaissance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _beneficiaireDateNaissance ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _beneficiaireDateNaissance) {
      setState(() {
        _beneficiaireDateNaissance = picked;
        _beneficiaireDateNaissanceController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Toujours initialiser selectedCapital avec une valeur valide pour Ã©viter l'erreur dropdown
    selectedCapital = 500000;

    // VÃ©rifier si on est en mode modification
    _isModification =
        widget.subscriptionId != null && widget.existingData != null;

    if (_isModification) {
      // Mode modification : prÃ©remplir avec les donnÃ©es existantes
      _prefillExistingData();
    } else {
      // Mode crÃ©ation : initialiser avec les valeurs par dÃ©faut
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

      // Initialiser la date d'effet (aujourd'hui par dÃ©faut)
      _dateEffetContrat = DateTime.now();
      _dateEffetController.text = _formatDate(_dateEffetContrat);

      // Calculer la prime initiale
      _calculerPrime();
    }

    // Charger les donnÃ©es utilisateur seulement si ce n'est pas un commercial
    // Pour les commerciaux, on chargera les donnÃ©es dans didChangeDependencies
  }

  /// ============================================
  /// MÃ‰THODE didChangeDependencies
  /// ============================================
  /// 
  /// Cette mÃ©thode est appelÃ©e automatiquement par Flutter lorsque les dÃ©pendances du widget changent.
  /// Elle est utilisÃ©e ici pour:
  /// 1. DÃ©tecter si c'est un commercial qui accÃ¨de Ã  la page
  /// 2. PrÃ©-remplir les champs avec les informations d'un client existant (si sÃ©lectionnÃ©)
  /// 3. Initialiser le mode commercial si nÃ©cessaire
  /// 
  /// ARGUMENTS ATTENDUS (via ModalRoute):
  /// - isCommercial: true si c'est un commercial qui fait la souscription
  /// - clientInfo: Map contenant les informations du client (si un client existant est sÃ©lectionnÃ©)
  /// 
  /// FLUX:
  /// - Si isCommercial = true : Active le mode commercial et affiche les champs client
  /// - Si clientInfo existe : PrÃ©-remplit tous les champs avec les donnÃ©es du client
  /// - Si isCommercial = false : Charge les donnÃ©es de l'utilisateur connectÃ© (mode client normal)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // RÃ©cupÃ©rer les arguments passÃ©s lors de la navigation vers cette page
    // Ces arguments peuvent contenir isCommercial et clientInfo
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // VÃ©rifier si c'est un commercial qui fait la souscription
    if (args != null && args['isCommercial'] == true) {
      // Activer le mode commercial si ce n'est pas dÃ©jÃ  fait
      if (!_isCommercial) {
        setState(() {
          _isCommercial = true;
        });
      }

      /**
       * PRÃ‰-REMPLISSAGE AUTOMATIQUE DES CHAMPS CLIENT
       * 
       * Si un client existant a Ã©tÃ© sÃ©lectionnÃ© (depuis select_client_screen),
       * on prÃ©-remplit automatiquement tous les champs avec ses informations.
       * Cela permet au commercial de gagner du temps lors de la crÃ©ation d'une nouvelle souscription
       * pour un client pour lequel il a dÃ©jÃ  crÃ©Ã© des souscriptions.
       */
      if (args['clientInfo'] != null) {
        // Extraire les informations du client depuis les arguments
        final clientInfo = args['clientInfo'] as Map<String, dynamic>;

        // PrÃ©-remplir tous les champs texte avec les informations du client
        // L'opÃ©rateur ?? permet d'utiliser une chaÃ®ne vide si la valeur est null
        _clientNomController.text = clientInfo['nom'] ?? '';
        _clientPrenomController.text = clientInfo['prenom'] ?? '';
        _clientEmailController.text = clientInfo['email'] ?? '';
        _clientTelephoneController.text = clientInfo['telephone'] ?? '';
        _clientLieuNaissanceController.text =
            clientInfo['lieu_naissance'] ?? '';
        _clientAdresseController.text = clientInfo['adresse'] ?? '';
        _clientNumeroPieceController.text =
            clientInfo['numero_piece_identite'] ?? '';

        // PrÃ©-remplir la civilitÃ© si disponible
        if (clientInfo['civilite'] != null) {
          _selectedClientCivilite = clientInfo['civilite'];
        }

        /**
         * GESTION DE LA DATE DE NAISSANCE
         * 
         * La date peut Ãªtre reÃ§ue sous deux formats:
         * 1. String (format ISO 8601, ex: "1995-11-19")
         * 2. DateTime (objet DateTime directement)
         * 
         * On convertit toujours en DateTime pour faciliter les calculs d'Ã¢ge.
         * On formate ensuite la date au format franÃ§ais (JJ/MM/AAAA) pour l'affichage.
         * On calcule aussi l'Ã¢ge du client pour les validations ultÃ©rieures.
         */
        if (clientInfo['date_naissance'] != null) {
          try {
            DateTime? dateNaissance;
            // VÃ©rifier le type de la date et la convertir en DateTime si nÃ©cessaire
            if (clientInfo['date_naissance'] is String) {
              // Si c'est une String, utiliser DateTime.parse pour la convertir
              dateNaissance = DateTime.parse(clientInfo['date_naissance']);
            } else if (clientInfo['date_naissance'] is DateTime) {
              // Si c'est dÃ©jÃ  un DateTime, l'utiliser directement
              dateNaissance = clientInfo['date_naissance'];
            }

            if (dateNaissance != null) {
              final finalDate = dateNaissance;
              setState(() {
                // Stocker la date de naissance
                _clientDateNaissance = finalDate;

                // Formater la date au format franÃ§ais (JJ/MM/AAAA)
                // padLeft(2, '0') assure que les jours et mois ont toujours 2 chiffres
                _clientDateNaissanceController.text =
                    '${finalDate.day.toString().padLeft(2, '0')}/${finalDate.month.toString().padLeft(2, '0')}/${finalDate.year}';

                // Calculer l'Ã¢ge du client
                final now = DateTime.now();
                _clientAge = now.year - finalDate.year;
                // Ajuster l'Ã¢ge si l'anniversaire n'a pas encore eu lieu cette annÃ©e
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
         * EXTRACTION DE L'INDICATIF TÃ‰LÃ‰PHONIQUE
         * 
         * Si le numÃ©ro de tÃ©lÃ©phone commence par un indicatif (ex: +225),
         * on sÃ©pare l'indicatif du reste du numÃ©ro pour un affichage correct
         * dans les champs sÃ©parÃ©s (indicatif + numÃ©ro).
         */
        final telephone = clientInfo['telephone'] ?? '';
        if (telephone.isNotEmpty && telephone.startsWith('+')) {
          // SÃ©parer l'indicatif du numÃ©ro (ex: "+225 0707889919" -> ["+225", "0707889919"])
          final parts = telephone.split(' ');
          if (parts.isNotEmpty) {
            // Le premier Ã©lÃ©ment est l'indicatif
            _selectedClientIndicatif = parts[0];
            // Le reste est le numÃ©ro de tÃ©lÃ©phone
            if (parts.length > 1) {
              _clientTelephoneController.text = parts.sublist(1).join(' ');
            }
          }
        }
      }
    }

    /**
     * CHARGEMENT DES DONNÃ‰ES UTILISATEUR
     * 
     * - Si c'est un client normal : Charger ses donnÃ©es depuis le serveur
     * - Si c'est un commercial : Ne pas charger les donnÃ©es utilisateur car on utilise les infos client saisies
     *   et mettre _isLoading Ã  false pour permettre l'affichage de la page
     */
    if (!_isCommercial) {
      // Mode client : Charger les donnÃ©es de l'utilisateur connectÃ©
      _loadUserData();
    } else {
      /**
       * MODE COMMERCIAL : Pas besoin de charger les donnÃ©es utilisateur
       * 
       * CORRECTION DU BUG DE CHARGEMENT:
       * - Avant: _isLoading restait Ã  true pour les commerciaux, ce qui bloquait l'affichage
       * - Maintenant: On met _isLoading Ã  false immÃ©diatement pour permettre l'affichage
       * - Les donnÃ©es client seront saisies manuellement ou prÃ©-remplies depuis clientInfo
       */
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// PrÃ©remplir les champs avec les donnÃ©es existantes pour la modification
  void _prefillExistingData() {
    if (widget.existingData == null) return;

    final data = widget.existingData!;

    // DÃ©tecter si c'est une souscription par commercial (prÃ©sence de client_info)
    if (data['client_info'] != null) {
      _isCommercial = true;
      final clientInfo = data['client_info'] as Map<String, dynamic>;
      _clientNomController.text = clientInfo['nom'] ?? '';
      _clientPrenomController.text = clientInfo['prenom'] ?? '';
      _clientEmailController.text = clientInfo['email'] ?? '';
      _clientTelephoneController.text = clientInfo['telephone'] ?? '';
      _clientLieuNaissanceController.text = clientInfo['lieu_naissance'] ?? '';
      _clientAdresseController.text = clientInfo['adresse'] ?? '';
      if (clientInfo['civilite'] != null) {
        _selectedClientCivilite = clientInfo['civilite'];
      }
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
          if (parts.length > 1) {
            _clientTelephoneController.text = parts.sublist(1).join(' ');
          }
        }
      }
    }

    // PrÃ©remplir les donnÃ©es de base
    selectedCapital = data['capital'] ?? 500000;
    selectedPeriodicite = data['periodicite'] ?? 'Mensuel';

    // PrÃ©remplir la date d'effet
    if (data['date_effet'] != null) {
      try {
        _dateEffetContrat = DateTime.parse(data['date_effet']);
        _dateEffetController.text = _formatDate(_dateEffetContrat);
      } catch (e) {
        _dateEffetContrat = DateTime.now();
        _dateEffetController.text = _formatDate(_dateEffetContrat);
      }
    }

    // PrÃ©remplir les membres - Conjoints
    if (data['conjoints'] != null && data['conjoints'] is List) {
      final conjointsData = List<Map<String, dynamic>>.from(data['conjoints']);
      nbConjoints = conjointsData.length;
      conjoints = conjointsData.map((c) {
        DateTime dateNaissance = DateTime.now();
        try {
          dateNaissance = DateTime.parse(c['date_naissance'] ?? '');
        } catch (e) {
          // Garder la date par dÃ©faut
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

    // PrÃ©remplir les membres - Enfants
    if (data['enfants'] != null && data['enfants'] is List) {
      final enfantsData = List<Map<String, dynamic>>.from(data['enfants']);
      nbEnfants = enfantsData.length;
      enfants = enfantsData.map((e) {
        DateTime dateNaissance = DateTime.now();
        try {
          dateNaissance = DateTime.parse(e['date_naissance'] ?? '');
        } catch (e) {
          // Garder la date par dÃ©faut
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

    // PrÃ©remplir les membres - Ascendants
    if (data['ascendants'] != null && data['ascendants'] is List) {
      final ascendantsData =
          List<Map<String, dynamic>>.from(data['ascendants']);
      nbAscendants = ascendantsData.length;
      ascendants = ascendantsData.map((a) {
        DateTime dateNaissance = DateTime.now();
        try {
          dateNaissance = DateTime.parse(a['date_naissance'] ?? '');
        } catch (e) {
          // Garder la date par dÃ©faut
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

    // PrÃ©remplir bÃ©nÃ©ficiaire et contact d'urgence
    _beneficiaireNomController.text = data['beneficiaire_nom'] ?? '';
    _beneficiaireContactController.text = data['beneficiaire_contact'] ?? '';
    if (data['beneficiaire_date_naissance'] != null) {
      try {
        _beneficiaireDateNaissance =
            DateTime.parse(data['beneficiaire_date_naissance']);
        _beneficiaireDateNaissanceController.text =
            "${_beneficiaireDateNaissance!.day.toString().padLeft(2, '0')}/${_beneficiaireDateNaissance!.month.toString().padLeft(2, '0')}/${_beneficiaireDateNaissance!.year}";
      } catch (e) {
        // Garder la date par dÃ©faut
      }
    }
    _personneContactNomController.text = data['contact_urgence_nom'] ?? '';
    _personneContactTelController.text = data['contact_urgence_tel'] ?? '';

    if (data['assistance_commerciale'] != null &&
      data['assistance_commerciale'] is Map) {
      final assistance = data['assistance_commerciale'];
      _isAideParCommercial = assistance['is_aide_par_commercial'] == true;
      _commercialNomPrenomController.text =
        assistance['commercial_nom_prenom']?.toString() ?? '';
      _commercialCodeApporteurController.text =
        assistance['commercial_code_apporteur']?.toString() ?? '';
    }

    // Calculer la prime avec les donnÃ©es prÃ©remplies
    _calculerPrime();
  }

  void _calculerPrime() {
    if (selectedCapital == null) return;

    // DÃ©termine la clÃ© de la pÃ©riodicitÃ© pour les maps de tarifs
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
    if (dateTime == null) return 'SÃ©lectionner une date';
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  // MÃ‰THODES CRITIQUES POUR LE STATUT DE PAIEMENT
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
          'date_naissance': _beneficiaireDateNaissance?.toIso8601String(),
          'lien_parente': _selectedLienParente,
        },
        'contact_urgence': {
          'nom': _personneContactNomController.text.trim(),
          'contact': _personneContactTelController.text.trim(),
          'lien_parente': _selectedLienParenteUrgence,
        },
        'assistance_commerciale': {
          'is_aide_par_commercial': _isAideParCommercial,
          'commercial_nom_prenom': _isAideParCommercial
              ? _commercialNomPrenomController.text.trim()
              : null,
          'commercial_code_apporteur': _isAideParCommercial
              ? _commercialCodeApporteurController.text.trim()
              : null,
        },
        'piece_identite': _pieceIdentite?.path.split('/').last ?? '',
        // NE PAS inclure 'status' ici - il sera 'proposition' par dÃ©faut dans la base
      };

      // Si commercial, ajouter les infos client
      if (_isCommercial) {
        subscriptionData['client_info'] = {
          'nom': _clientNomController.text.trim(),
          'prenom': _clientPrenomController.text.trim(),
          'date_naissance': _clientDateNaissance?.toIso8601String(),
          'lieu_naissance': _clientLieuNaissanceController.text.trim(),
          'telephone': _clientTelephoneController.text.trim(),
          'email': _clientEmailController.text.trim(),
          'adresse': _clientAdresseController.text.trim(),
          'civilite': _selectedClientCivilite,
          'profession': _clientProfessionController.text.trim(),
          'secteur_activite': _clientSecteurActiviteController.text.trim(),
        };
      }

      // Ajouter la signature si elle existe
      if (_clientSignature != null) {
        subscriptionData['signature'] = base64Encode(_clientSignature!);
      }

      http.Response response;
      Map<String, dynamic> responseData;

      if (_isModification && widget.subscriptionId != null) {
        // Mode modification : UPDATE
        debugPrint('ðŸ”„ Mode MODIFICATION - ID: ${widget.subscriptionId}');
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
        // Mode crÃ©ation : INSERT
        debugPrint('âž• Mode CRÃ‰ATION');
        response =
            await subscriptionService.createSubscription(subscriptionData);
        responseData = jsonDecode(response.body);

        if (response.statusCode != 201 || !responseData['success']) {
          throw Exception(
              responseData['message'] ?? 'Erreur lors de la sauvegarde');
        }

        // RETOURNER l'ID de la souscription crÃ©Ã©e
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
            'Erreur lors de la mise Ã  jour du statut');
      }

      debugPrint(
          'Statut mis Ã  jour: ${paymentSuccess ? 'contrat' : 'proposition'}');
    } catch (e) {
      debugPrint('Erreur mise Ã  jour statut: $e');
      rethrow;
    }
  }

  Future<bool> _simulatePayment(String paymentMethod) async {
    // Simulation d'un dÃ©lai de paiement
    await Future.delayed(const Duration(seconds: 2));

    // Pour la dÃ©mo, retournez true pour succÃ¨s, false pour Ã©chec
    return true; // Changez en false pour tester l'Ã©chec
  }

  void _processPayment(String paymentMethod) async {
    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _LoadingDialog(paymentMethod: paymentMethod));

    try {
      // Ã‰TAPE 1: Sauvegarder la souscription (statut: 'proposition' par dÃ©faut)
      final subscriptionId = await _saveSubscriptionData();

      // Ã‰TAPE 1.5: Upload du document piÃ¨ce d'identitÃ© si prÃ©sent
      if (_pieceIdentite != null) {
        await _uploadDocument(subscriptionId);
      }

      if (paymentMethod == 'Wave') {
        if (mounted) {
          Navigator.pop(context);
        }

        await WavePaymentHandler.startPayment(
          context,
          subscriptionId: subscriptionId,
          amount: primeTotaleResult,
          description: 'Paiement prime CORIS SOLIDARITÃ‰',
          onSuccess: () => _showSuccessDialog(true),
        );
        return;
      }

      // Ã‰TAPE 2: Simuler le paiement
      final paymentSuccess = await _simulatePayment(paymentMethod);

      // Ã‰TAPE 3: Mettre Ã  jour le statut selon le rÃ©sultat du paiement
      await _updatePaymentStatus(subscriptionId, paymentSuccess,
          paymentMethod: paymentMethod);

      if (mounted) {
        Navigator.pop(context); // Fermer le loading

        if (paymentSuccess) {
          _showSuccessDialog(true); // Contrat activÃ©
        } else {
          _showErrorSnackBar(
              'Paiement Ã©chouÃ©. Votre proposition a Ã©tÃ© sauvegardÃ©e.');
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
      // Sauvegarde avec statut 'proposition' par dÃ©faut
      final subscriptionId = await _saveSubscriptionData();

      // Upload du document piÃ¨ce d'identitÃ© si prÃ©sent
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

  /// Upload du document piÃ¨ce d'identitÃ© vers le serveur
  Future<void> _uploadDocument(int subscriptionId) async {
    try {
      debugPrint('ðŸ“¤ Upload document pour souscription $subscriptionId');
      final subscriptionService = SubscriptionService();
      final paths = _pieceIdentiteFiles.isNotEmpty
          ? _pieceIdentiteFiles.map((f) => f.path).toList()
          : (_pieceIdentite != null
              ? <String>[_pieceIdentite!.path]
              : <String>[]);
      if (paths.isEmpty) return;

      Map<String, dynamic> responseData = {};
      for (final filePath in paths) {
        final response = await subscriptionService.uploadDocument(
          subscriptionId,
          filePath,
        );

        final localData = jsonDecode(response.body) as Map<String, dynamic>;
        responseData = localData;

        if (response.statusCode != 200 || !localData['success']) {
          debugPrint('âŒ Erreur upload: ${localData['message']}');
          throw Exception(
              localData['message'] ?? 'Erreur lors de l\'upload du document');
        }
      }

      // RÃ©cupÃ©rer le label original si prÃ©sent dans la rÃ©ponse
      try {
        final updated = responseData['data']?['subscription'];
        if (updated != null) {
          final souscriptiondata = updated['souscriptiondata'];
          if (souscriptiondata != null) {
            if (souscriptiondata is Map) {
              _pieceIdentiteLabel = souscriptiondata['piece_identite_label'];
            } else if (souscriptiondata is String) {
              try {
                final parsed = jsonDecode(souscriptiondata);
                _pieceIdentiteLabel = parsed['piece_identite_label'];
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint(
            'âš ï¸ Impossible de lire piece_identite_label depuis la rÃ©ponse: $e');
      }

      debugPrint('âœ… Document uploadÃ© avec succÃ¨s');
    } catch (e) {
      debugPrint('âŒ Exception upload document: $e');
      // Ne pas bloquer la souscription si l'upload Ã©choue
      // On log juste l'erreur
    }
  }

  // FIN DES MÃ‰THODES CRITIQUES

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
              SizedBox(width: context.r(12)),
              const Icon(Icons.group, color: Colors.white, size: 32),
              SizedBox(width: context.r(12)),
              Expanded(
                child: Text(
                  _isModification
                      ? "MODIFICATION CORIS SOLIDARITÃ‰"
                      : "SOUSCRIPTION CORIS SOLIDARITÃ‰",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.sp(20),
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
    // DÃ©terminer le nombre d'Ã©tapes en fonction des membres
    int totalSteps = 6; // ParamÃ¨tres + RÃ©capitulatif
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

  /// Page sÃ©parÃ©e pour les informations client (uniquement pour les commerciaux)
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
                label: 'CivilitÃ©',
                icon: Icons.person_outline,
                items: ['Monsieur', 'Madame', 'Mademoiselle'],
                onChanged: (value) {
                  setState(() {
                    _selectedClientCivilite = value!;
                  });
                },
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientNomController,
                label: 'Nom du client',
                icon: Icons.person_outline,
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientPrenomController,
                label: 'PrÃ©nom du client',
                icon: Icons.person_outline,
              ),
              SizedBox(height: context.r(16)),
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
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientLieuNaissanceController,
                label: 'Lieu de naissance',
                icon: Icons.location_on,
              ),
              SizedBox(height: context.r(16)),
              _buildPhoneFieldWithIndicatif(
                controller: _clientTelephoneController,
                label: 'TÃ©lÃ©phone du client',
                selectedIndicatif: _selectedClientIndicatif,
                onIndicatifChanged: (value) {
                  setState(() {
                    _selectedClientIndicatif = value!;
                  });
                },
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientEmailController,
                label: 'Email du client',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientAdresseController,
                label: 'Adresse du client',
                icon: Icons.home,
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientProfessionController,
                label: 'Profession',
                icon: Icons.work,
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientSecteurActiviteController,
                label: "Secteur d'activitÃ©",
                icon: Icons.business,
              ),
              SizedBox(height: context.r(16)),
              _buildModernTextField(
                controller: _clientNumeroPieceController,
                label: 'NumÃ©ro de piÃ¨ce d\'identitÃ©',
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
          // SÃ©lecteur de capital
          _buildCapitalDropdown(),
          SizedBox(height: context.r(16)),

          // SÃ©lecteur de pÃ©riodicitÃ©
          _buildPeriodiciteDropdown(),
          SizedBox(height: context.r(16)),

          // Date d'effet du contrat
          _buildDateEffetField(),
          SizedBox(height: context.r(25)),

          // SÃ©parateur
          const Divider(color: grisClair, height: 1, thickness: 1),
          SizedBox(height: context.r(25)),

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
          SizedBox(height: context.r(16)),

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
          SizedBox(height: context.r(16)),

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
          initialValue: selectedCapital,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.attach_money, color: Color(0xFF002B6B)),
            labelText: 'Capital Ã  garantir',
          ),
          items: capitalOptions
              .map((val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      '${_formatNumber(val)} FCFA',
                      style: TextStyle(
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
          initialValue: selectedPeriodicite,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF002B6B)),
            labelText: 'PÃ©riodicitÃ©',
          ),
          items: periodicites
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p,
                      style: TextStyle(
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
              style: TextStyle(
                  fontSize: context.sp(16),
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
                  style: TextStyle(
                      fontSize: context.sp(16),
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
            style: TextStyle(
              fontSize: context.sp(18),
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B6B),
            ),
          ),
          SizedBox(height: context.r(16)),
          TextFormField(
            initialValue: membre.nomPrenom,
            decoration: InputDecoration(
              labelText: 'Nom et prÃ©nom',
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
            style: TextStyle(color: bleuCoris, fontSize: context.sp(16)),
            onChanged: (value) {
              onChanged(Membre(
                  nomPrenom: value, dateNaissance: membre.dateNaissance));
            },
          ),
          SizedBox(height: context.r(16)),
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
            style: TextStyle(color: bleuCoris, fontSize: context.sp(16)),
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
                // Validation en temps rÃ©el de l'Ã¢ge selon le type de membre
                final now = DateTime.now();
                final age = now.year - picked.year;

                // DÃ©terminer le type de membre basÃ© sur le titre de la section
                bool isValid = true;
                String errorMessage = '';

                if (titre.contains('enfant') || titre.contains('Enfant')) {
                  if (age < 12 || age > 21) {
                    isValid = false;
                    errorMessage =
                        "L'Ã¢ge des enfants doit Ãªtre compris entre 12 et 21 ans. Ã‚ge sÃ©lectionnÃ©: $age ans.";
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
                        "L'Ã¢ge doit Ãªtre d'au moins 18 ans. Ã‚ge sÃ©lectionnÃ©: $age ans.";
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
            if (!_isCommercial) _buildAssistanceCommercialeSection(),
            SizedBox(height: context.r(20)),
            _buildFormSection(
              'BÃ©nÃ©ficiaire et Contact d\'urgence',
              Icons.contacts,
              [
                _buildSubSectionTitle('BÃ©nÃ©ficiaire en cas de dÃ©cÃ¨s'),
                _buildModernTextField(
                  controller: _beneficiaireNomController,
                  label: 'Nom complet du bÃ©nÃ©ficiaire',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: context.r(16)),
                TextFormField(
                  controller: _beneficiaireDateNaissanceController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date de naissance du bÃ©nÃ©ficiaire',
                    labelStyle:
                        TextStyle(color: bleuCoris.withValues(alpha: 0.7)),
                    prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: bleuCoris.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.calendar_today,
                            color: bleuCoris, size: 20)),
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
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onTap: () => _selectBeneficiaireDateNaissance(context),
                ),
                SizedBox(height: context.r(16)),
                // Champ avec indicatif
                _buildPhoneFieldWithIndicatif(
                  controller: _beneficiaireContactController,
                  label: 'Contact du bÃ©nÃ©ficiaire',
                  selectedIndicatif: _selectedBeneficiaireIndicatif,
                  onIndicatifChanged: (value) {
                    setState(() {
                      _selectedBeneficiaireIndicatif = value!;
                    });
                  },
                ),
                SizedBox(height: context.r(16)),
                _buildDropdownField(
                  value: _selectedLienParente,
                  label: 'Lien de parentÃ©',
                  icon: Icons.link,
                  items: _lienParenteOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedLienParente = value!;
                    });
                  },
                ),
                SizedBox(height: context.r(20)),
                _buildSubSectionTitle('Contact d\'urgence'),
                _buildModernTextField(
                  controller: _personneContactNomController,
                  label: 'Nom complet',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: context.r(16)),
                _buildModernTextField(
                  controller: _personneContactTelController,
                  label: 'Contact tÃ©lÃ©phonique (ex: +2250707070707)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: context.r(16)),
                _buildDropdownField(
                  value: _selectedLienParenteUrgence,
                  label: 'Lien de parentÃ©',
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
            SizedBox(height: context.r(20)),
            _buildDocumentUploadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistanceCommercialeSection() {
    return _buildFormSection(
      'Assistance commerciale',
      Icons.support_agent,
      [
        Text(
          'Avez-vous Ã©tÃ© aidÃ© par un commercial pour cette souscription ?',
          style: TextStyle(
            fontSize: context.sp(15),
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: context.r(12)),
        RadioListTile<bool>(
          value: true,
          groupValue: _isAideParCommercial,
          onChanged: (value) {
            setState(() {
              _isAideParCommercial = value ?? false;
            });
          },
          title: const Text('Oui'),
          contentPadding: EdgeInsets.zero,
          activeColor: bleuCoris,
        ),
        RadioListTile<bool>(
          value: false,
          groupValue: _isAideParCommercial,
          onChanged: (value) {
            setState(() {
              _isAideParCommercial = value ?? false;
              if (!_isAideParCommercial) {
                _commercialNomPrenomController.clear();
                _commercialCodeApporteurController.clear();
              }
            });
          },
          title: const Text('Non'),
          contentPadding: EdgeInsets.zero,
          activeColor: bleuCoris,
        ),
        if (_isAideParCommercial) ...[
          SizedBox(height: context.r(12)),
          _buildModernTextField(
            controller: _commercialNomPrenomController,
            label: 'Nom et prÃ©nom du commercial *',
            icon: Icons.badge_outlined,
          ),
          SizedBox(height: context.r(16)),
          _buildModernTextField(
            controller: _commercialCodeApporteurController,
            label: 'Code apporteur *',
            icon: Icons.qr_code,
          ),
        ],
      ],
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.sp(16),
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
          SizedBox(width: context.r(12)),
          Text(title,
              style: TextStyle(
                  fontSize: context.sp(16), fontWeight: FontWeight.w600, color: bleuCoris))
        ]),
        SizedBox(height: context.r(16)),
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

  /// ============================================
  /// WIDGET _buildDateField
  /// ============================================
  /// 
  /// CrÃ©e un champ de saisie de date avec un sÃ©lecteur de date intÃ©grÃ©.
  /// 
  /// PARAMÃˆTRES:
  /// - controller: TextEditingController pour gÃ©rer le texte affichÃ© dans le champ
  /// - label: Label affichÃ© au-dessus du champ
  /// - icon: IcÃ´ne affichÃ©e dans le champ (gÃ©nÃ©ralement Icons.calendar_today)
  /// - onDateSelected: Callback appelÃ© quand une date est sÃ©lectionnÃ©e
  /// 
  /// FONCTIONNEMENT:
  /// 1. Affiche un TextFormField en lecture seule (AbsorbPointer)
  /// 2. Quand l'utilisateur tape sur le champ, ouvre un DatePicker
  /// 3. Le DatePicker utilise un Theme personnalisÃ© pour Ã©viter les erreurs MaterialLocalizations
  /// 4. Une fois la date sÃ©lectionnÃ©e, appelle onDateSelected avec la date choisie
  /// 
  /// CORRECTION DU BUG:
  /// - Avant: Utilisation de ThemeData.light() causait des erreurs MaterialLocalizations
  /// - Maintenant: Utilisation de Theme.of(context).copyWith() pour hÃ©riter du contexte parent
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
                fontSize: context.sp(16), fontWeight: FontWeight.w600, color: bleuCoris)),
        SizedBox(height: context.r(6)),
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
                    ), dialogTheme: DialogThemeData(backgroundColor: blanc),
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
                hintStyle: TextStyle(fontSize: context.sp(14)),
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
                fontSize: context.sp(16), fontWeight: FontWeight.w600, color: bleuCoris)),
        SizedBox(height: context.r(6)),
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
                            Text(value, style: TextStyle(fontSize: context.sp(14))),
                      ),
                    );
                  }).toList(),
                  onChanged: onIndicatifChanged,
                ),
              ),
            ),
            SizedBox(width: context.r(10)),
            // Champ de tÃ©lÃ©phone
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: '00 00 00 00',
                  hintStyle: TextStyle(fontSize: context.sp(14)),
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
                    return 'NumÃ©ro de tÃ©lÃ©phone invalide';
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
      initialValue: value,
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
          SizedBox(width: context.r(12)),
          Text('PiÃ¨ce d\'identitÃ©',
              style: TextStyle(
                  fontSize: context.sp(16), fontWeight: FontWeight.w600, color: bleuCoris))
        ]),
        SizedBox(height: context.r(16)),
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
              SizedBox(height: context.r(10)),
              Text(
                  _pieceIdentite != null
                      ? 'Document ajoutÃ© avec succÃ¨s'
                      : 'TÃ©lÃ©charger votre piÃ¨ce d\'identitÃ©',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w600,
                      color: _pieceIdentite != null ? vertSucces : bleuCoris)),
              SizedBox(height: context.r(6)),
              Text(
                  _pieceIdentite != null
                      ? _pieceIdentite!.path.split('/').last
                      : 'Formats acceptÃ©s: PDF, JPG, PNG (Max: 5MB)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: grisTexte, fontSize: context.sp(11))),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickDocument() async {
    try {
      final picked = await IdentityDocumentPicker.pickDocuments(context);
      if (picked == null || picked.files.isEmpty) return;

      if (mounted) {
        setState(() {
          _pieceIdentiteFiles
            ..clear()
            ..addAll(picked.files);
          _pieceIdentite = _pieceIdentiteFiles.first;
          _pieceIdentiteLabel = picked.labels.isNotEmpty
              ? picked.labels.first
              : _pieceIdentite!.path.split(RegExp(r'[\\/]+')).last;
        });
        _showSuccessSnackBar(_pieceIdentiteFiles.length > 1
            ? '${_pieceIdentiteFiles.length} documents ajoutÃ©s avec succÃ¨s'
            : 'Document ajoutÃ© avec succÃ¨s');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sÃ©lection du fichier');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: blanc),
          SizedBox(width: context.r(12)),
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
          SizedBox(width: context.r(12)),
          Expanded(child: Text(message))
        ]),
        backgroundColor: vertSucces,
      ),
    );
  }

  // MÃ©thode pour dÃ©terminer les Ã©tapes actives en fonction des membres
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
    steps.add(_buildStepModePaiement()); // ðŸ’³ Ã‰tape mode de paiement
    steps.add(_buildStepRecap());

    return steps;
  }

  // MÃ©thode pour obtenir le nombre total d'Ã©tapes
  int _getTotalSteps() {
    int total = 2; // Ã‰tape 1 et Ã©tape finale (bÃ©nÃ©ficiaire/contact)
    if (_isCommercial) total++; // Page client pour commercial
    if (nbConjoints > 0) total++;
    if (nbEnfants > 0) total++;
    if (nbAscendants > 0) total++;
    total++; // ðŸ’³ Mode de paiement
    total++; // RÃ©capitulatif
    return total;
  }

  /// Charge les donnÃ©es utilisateur pour le rÃ©capitulatif (uniquement pour les clients)
  /// Cette mÃ©thode est appelÃ©e dans le FutureBuilder pour charger les donnÃ©es Ã  la volÃ©e
  /// si elles ne sont pas dÃ©jÃ  disponibles dans _userData
  Future<Map<String, dynamic>> _loadUserDataForRecap() async {
    try {
      // Si _userData est dÃ©jÃ  chargÃ© et non vide, l'utiliser directement
      if (_userData.isNotEmpty) {
        debugPrint('âœ… Utilisation des donnÃ©es utilisateur dÃ©jÃ  chargÃ©es');
        return _userData;
      }

      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('âŒ Token non trouvÃ©');
        // Retourner un map vide au lieu de lever une exception
        return <String, dynamic>{};
      }

      debugPrint('ðŸ”„ Chargement des donnÃ©es utilisateur depuis l\'API...');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Timeout lors de la requÃªte API');
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
                'âœ… DonnÃ©es utilisateur: ${userData['nom']} ${userData['prenom']}');
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
                  'âœ… DonnÃ©es utilisateur depuis data: ${userData['nom']} ${userData['prenom']}');
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
                'âœ… DonnÃ©es utilisateur depuis data.user: ${userData['nom']} ${userData['prenom']}');
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
                'âœ… DonnÃ©es utilisateur directes: ${userData['nom']} ${userData['prenom']}');
            if (mounted) {
              setState(() {
                _userData = userData;
              });
            }
            return userData;
          }

          debugPrint(
              'âš ï¸ RÃ©ponse API inattendue (${response.statusCode}): ${response.body}');
        } else {
          debugPrint('âš ï¸ Format invalide (non-Map): ${response.body}');
        }
      } else {
        debugPrint('âŒ Erreur HTTP ${response.statusCode}: ${response.body}');
      }

      // Fallback vers _userData si la requÃªte Ã©choue - GARANTIR non-null
      final result = _userData.isNotEmpty ? _userData : <String, dynamic>{};
      return result;
    } catch (e) {
      debugPrint(
          'âŒ Erreur chargement donnÃ©es utilisateur pour rÃ©capitulatif: $e');
      // Fallback vers _userData en cas d'erreur - GARANTIR non-null
      final result = _userData.isNotEmpty ? _userData : <String, dynamic>{};
      return result;
    }
  }

  /// Parse le RIB unifiÃ© au format: XXXX / XXXXXXXXXXX / XX
  /// Retourne une map avec {code_guichet, numero_compte, cle_rib}
  Map<String, String> _parseRibUnified(String rib) {
    final cleaned = rib.replaceAll(RegExp(r'[^0-9]'), '');
    return {
      'code_guichet': cleaned.length >= 5 ? cleaned.substring(0, 5) : '',
      'numero_compte': cleaned.length >= 16 ? cleaned.substring(5, 16) : '',
      'cle_rib': cleaned.length >= 18 ? cleaned.substring(16, 18) : '',
    };
  }

  /// Valide le format du RIB unifiÃ©
  bool _validateRibUnified(String rib) {
    final cleaned = rib.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length == 18; // 5 + 11 + 2
  }

  /// Formate l'entrÃ©e RIB en temps rÃ©el
  void _formatRibInput() {
    String text = _ribUnifiedController.text;
    String cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      _ribUnifiedController.value = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }

    String formatted = '';
    int cursorPosition = 0;

    // Code guichet (5 chiffres)
    if (cleaned.isNotEmpty) {
      formatted +=
          cleaned.substring(0, cleaned.length > 5 ? 5 : cleaned.length);
      if (cleaned.length > 5) formatted += ' / ';
    }

    // NumÃ©ro de compte (11 chiffres)
    if (cleaned.length > 5) {
      formatted +=
          cleaned.substring(5, cleaned.length > 16 ? 16 : cleaned.length);
      if (cleaned.length > 16) formatted += ' / ';
    }

    // ClÃ© RIB (2 chiffres)
    if (cleaned.length > 16) {
      formatted +=
          cleaned.substring(16, cleaned.length > 18 ? 18 : cleaned.length);
    }

    cursorPosition = formatted.length;

    _ribUnifiedController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// ðŸ’³ Ã‰TAPE MODE DE PAIEMENT
  Widget _buildStepModePaiement() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tÃªte avec gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bleuCoris, bleuSecondaire],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blanc.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payment, color: blanc, size: 32),
                ),
                SizedBox(width: context.r(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode de Paiement',
                        style: TextStyle(
                          color: blanc,
                          fontSize: context.sp(22),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: context.r(4)),
                      Text(
                        'Comment souhaitez-vous payer vos primes ?',
                        style: TextStyle(
                          color: blanc.withAlpha(229),
                          fontSize: context.sp(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.r(30)),

          // SÃ©lection du mode de paiement
          Text(
            'Mode de paiement *',
            style: TextStyle(
              fontSize: context.sp(16),
              fontWeight: FontWeight.w600,
              color: grisTexte,
            ),
          ),
          SizedBox(height: context.r(12)),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: _modePaiementOptions.map((mode) {
                final isSelected = _selectedModePaiement == mode;
                IconData icon;
                Color iconColor;
                Widget? customIconWidget;

                switch (mode) {
                  case 'Virement':
                    icon = Icons.account_balance;
                    iconColor = Colors.blue;
                    break;
                  case 'Wave':
                    icon = Icons.water_drop;
                    iconColor = Color(0xFF00BFFF);
                    customIconWidget = Image.asset(
                      'assets/images/icone_wave.jpeg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.water_drop,
                            color: iconColor, size: 28);
                      },
                    );
                    break;
                  case 'Orange Money':
                    icon = Icons.phone_android;
                    iconColor = Colors.orange;
                    customIconWidget = Image.asset(
                      'assets/images/icone_orange_money.jpeg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.phone_android,
                            color: iconColor, size: 28);
                      },
                    );
                    break;
                  case 'PrÃ©lÃ¨vement Ã  la source':
                    icon = Icons.business;
                    iconColor = Colors.green;
                    break;
                  case 'CORIS Money':
                    icon = Icons.account_balance_wallet;
                    iconColor = Color(0xFF1E3A8A);
                    customIconWidget = Image.asset(
                      'assets/images/icone_corismoney.jpeg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.account_balance_wallet,
                            color: iconColor, size: 28);
                      },
                    );
                    break;
                  default:
                    icon = Icons.payment;
                    iconColor = bleuCoris;
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedModePaiement = mode;
                      // RÃ©initialiser les champs
                      _banqueController.clear();
                      _numeroCompteController.clear();
                      _numeroMobileMoneyController.clear();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? bleuCoris.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: _modePaiementOptions.last == mode
                              ? Colors.transparent
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: customIconWidget ??
                                  Icon(icon, color: iconColor, size: 28)),
                        ),
                        SizedBox(width: context.r(16)),
                        Expanded(
                          child: Text(
                            mode,
                            style: TextStyle(
                              fontSize: context.sp(16),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? bleuCoris : Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: bleuCoris, size: 28),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Champs conditionnels selon le mode sÃ©lectionnÃ©
          if (_selectedModePaiement != null) ...[
            SizedBox(height: context.r(30)),

            // VIREMENT
            if (_selectedModePaiement == 'Virement') ...[
              Text(
                'Informations Bancaires',
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w600,
                  color: grisTexte,
                ),
              ),
              SizedBox(height: context.r(16)),

              // Nom de la banque
              DropdownButtonFormField<String>(
                initialValue: _selectedBanque,
                decoration: InputDecoration(
                  labelText: 'Nom de la banque *',
                  prefixIcon: Icon(Icons.account_balance, color: bleuCoris),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
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
              ),
              SizedBox(height: context.r(16)),

              // Champ texte personnalisÃ© si "Autre" est sÃ©lectionnÃ©
              if (_selectedBanque == 'Autre') ...[
                TextField(
                  controller: _banqueController,
                  decoration: InputDecoration(
                    labelText: 'Nom de votre banque *',
                    hintText: 'Entrez le nom de votre banque',
                    prefixIcon: Icon(Icons.edit, color: bleuCoris),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: context.r(16)),
              ],

              // NumÃ©ro RIB unifiÃ©
              TextField(
                controller: _ribUnifiedController,
                onChanged: (_) => _formatRibInput(),
                decoration: InputDecoration(
                  labelText: 'NumÃ©ro RIB complet *',
                  hintText: '55555 / 11111111111 / 22',
                  helperText:
                      'Code guichet (5) / NumÃ©ro compte (11) / ClÃ© RIB (2)',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.credit_card, color: bleuCoris),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                maxLength:
                    24, // 5 + 3 + 11 + 3 + 2 = 24 caractÃ¨res avec sÃ©parateurs
              ),
            ],
            if (_selectedModePaiement == 'Wave' ||
                _selectedModePaiement == 'Orange Money') ...[
              Text(
                'NumÃ©ro $_selectedModePaiement',
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w600,
                  color: grisTexte,
                ),
              ),
              SizedBox(height: context.r(16)),
              TextField(
                controller: _numeroMobileMoneyController,
                decoration: InputDecoration(
                  labelText: 'NumÃ©ro de tÃ©lÃ©phone *',
                  hintText: 'Ex: 0707070707',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      _selectedModePaiement == 'Wave'
                          ? 'assets/images/icone_wave.jpeg'
                          : 'assets/images/icone_orange_money.jpeg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.phone_android,
                          color: _selectedModePaiement == 'Wave'
                              ? Color(0xFF00BFFF)
                              : Colors.orange,
                        );
                      },
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
              ),
            ],

            // PrÃ©lÃ¨vement Ã  la source
            if (_selectedModePaiement == 'PrÃ©lÃ¨vement Ã  la source') ...[
              Text(
                'Informations PrÃ©lÃ¨vement',
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w600,
                  color: grisTexte,
                ),
              ),
              SizedBox(height: context.r(16)),
              TextField(
                controller: _nomStructureController,
                decoration: InputDecoration(
                  labelText: 'Nom de la structure *',
                  hintText: 'Ex: Entreprise SARL',
                  prefixIcon: Icon(Icons.business, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: context.r(16)),
              TextField(
                controller: _numeroMatriculeController,
                decoration: InputDecoration(
                  labelText: 'NumÃ©ro de matricule *',
                  hintText: 'Ex: 123456789',
                  prefixIcon: Icon(Icons.badge, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ],

            // CORIS MONEY
            if (_selectedModePaiement == 'CORIS Money') ...[
              Text(
                'NumÃ©ro CORIS Money',
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w600,
                  color: grisTexte,
                ),
              ),
              SizedBox(height: context.r(16)),
              TextField(
                controller: _corisMoneyPhoneController,
                decoration: InputDecoration(
                  labelText: 'NumÃ©ro de tÃ©lÃ©phone *',
                  hintText: 'Ex: 0707070707',
                  prefixIcon: Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF1E3A8A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ],

          SizedBox(height: context.r(30)),

          // Note informative
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                SizedBox(width: context.r(12)),
                Expanded(
                  child: Text(
                    'Ces informations seront utilisÃ©es pour le prÃ©lÃ¨vement automatique de vos primes.',
                    style: TextStyle(
                      fontSize: context.sp(14),
                      color: Colors.blue[900],
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
     * - Les informations sont dÃ©jÃ  prÃ©-enregistrÃ©es dans la base de donnÃ©es lors de l'inscription
     * - On doit TOUJOURS charger les donnÃ©es depuis _loadUserDataForRecap() qui rÃ©cupÃ¨re le profil de l'utilisateur connectÃ©
     * 
     * Pour les COMMERCIAUX (plateforme commercial):
     * - Le commercial saisit les informations du client dans les champs du formulaire
     * - On utilise les valeurs des contrÃ´leurs (_clientNomController, etc.)
     */
    return _isCommercial
        ? _buildRecapContent()
        : FutureBuilder<Map<String, dynamic>>(
            future: _loadUserDataForRecap(),
            builder: (context, snapshot) {
              // Pour les clients, attendre le chargement des donnÃ©es
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: bleuCoris),
                );
              }

              if (snapshot.hasError) {
                debugPrint(
                    'Erreur chargement donnÃ©es rÃ©capitulatif: ${snapshot.error}');
                // En cas d'erreur, essayer d'utiliser _userData si disponible
                if (_userData.isNotEmpty) {
                  return _buildRecapContent(userData: _userData);
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: rougeCoris),
                      SizedBox(height: context.r(16)),
                      Text('Erreur lors du chargement des donnÃ©es'),
                      TextButton(
                        onPressed: () => setState(() {}),
                        child: Text('RÃ©essayer'),
                      ),
                    ],
                  ),
                );
              }

              // Utiliser les donnÃ©es chargÃ©es ou _userData en fallback
              final userData = snapshot.data ?? _userData;

              // Si userData est vide, recharger les donnÃ©es
              if (userData.isEmpty && !_isCommercial) {
                // Recharger les donnÃ©es utilisateur
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
     * CONSTRUCTION DU RÃ‰CAPITULATIF:
     * 
     * - Si _isCommercial = true: Utiliser les donnÃ©es des contrÃ´leurs (infos client saisies par le commercial)
     * - Si _isCommercial = false: Utiliser userData (infos du client connectÃ© depuis la base de donnÃ©es)
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

    // S'assurer que la prime est bien calculÃ©e avant affichage
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
                'CivilitÃ©',
                displayData['civilite'] ?? 'Non renseignÃ©',
                'Nom',
                displayData['nom'] ?? 'Non renseignÃ©'),
            _buildCombinedRecapRow(
                'PrÃ©nom',
                displayData['prenom'] ?? 'Non renseignÃ©',
                'Email',
                displayData['email'] ?? 'Non renseignÃ©'),
            _buildCombinedRecapRow(
                'TÃ©lÃ©phone',
                displayData['telephone'] ?? 'Non renseignÃ©',
                'Date de naissance',
                displayData['date_naissance'] ?? 'Non renseignÃ©'),
            _buildCombinedRecapRow(
                'Lieu de naissance',
                displayData['lieu_naissance'] ?? 'Non renseignÃ©',
                'Adresse',
                displayData['adresse'] ?? 'Non renseignÃ©'),
          ]),
          SizedBox(height: context.r(12)),

          // Produit souscrit
          _buildRecapSection(
              'Produit Souscrit', Icons.emoji_people_outlined, vertSucces, [
            _buildCombinedRecapRow('Produit', 'CORIS SOLIDARITÃ‰', 'PÃ©riodicitÃ©',
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
          SizedBox(height: context.r(12)),

          // Conjoints
          if (conjoints.isNotEmpty) ...[
            _buildRecapSection(
                'Conjoint(s)',
                Icons.people,
                bleuCoris,
                conjoints
                    .map((conjoint) => _buildMembreRecap(conjoint))
                    .toList()),
            SizedBox(height: context.r(12)),
          ],

          // Enfants
          if (enfants.isNotEmpty) ...[
            _buildRecapSection('Enfant(s)', Icons.child_care, bleuCoris,
                enfants.map((enfant) => _buildMembreRecap(enfant)).toList()),
            SizedBox(height: context.r(12)),
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
            SizedBox(height: context.r(12)),
          ],

          _buildRecapSection(
            'BÃ©nÃ©ficiaire et Contact d\'urgence',
            Icons.contacts,
            bleuSecondaire,
            [
              // ðŸ”¹ BÃ©nÃ©ficiaire
              _buildSubsectionTitle('BÃ©nÃ©ficiaire'),
              _buildRecapRow(
                'Nom complet',
                _beneficiaireNomController.text.isNotEmpty
                    ? _beneficiaireNomController.text
                    : 'Non renseignÃ©',
              ),
              _buildRecapRow(
                'Date de naissance',
                _beneficiaireDateNaissance != null
                    ? '${_beneficiaireDateNaissance!.day.toString().padLeft(2, '0')}/'
                        '${_beneficiaireDateNaissance!.month.toString().padLeft(2, '0')}/'
                        '${_beneficiaireDateNaissance!.year}'
                    : 'Non renseignÃ©',
              ),
              _buildRecapRow(
                'Contact',
                _beneficiaireContactController.text.isNotEmpty
                    ? '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text}'
                    : 'Non renseignÃ©',
              ),
              _buildRecapRow(
                'Lien de parentÃ©',
                _selectedLienParente.isNotEmpty
                    ? _selectedLienParente
                    : 'Non renseignÃ©',
              ),

              SizedBox(height: context.r(8)),

              // ðŸ”¹ Contact d'urgence
              _buildSubsectionTitle('Contact d\'urgence'),
              _buildRecapRow(
                'Nom complet',
                _personneContactNomController.text.isNotEmpty
                    ? _personneContactNomController.text
                    : 'Non renseignÃ©',
              ),
              _buildRecapRow(
                'Contact',
                _personneContactTelController.text.isNotEmpty
                    ? _personneContactTelController.text
                    : 'Non renseignÃ©',
              ),
              _buildRecapRow(
                'Lien de parentÃ©',
                _selectedLienParenteUrgence.isNotEmpty
                    ? _selectedLienParenteUrgence
                    : 'Non renseignÃ©',
              ),
            ],
          ),
          SizedBox(height: context.r(12)),

          // ðŸ’³ Mode de Paiement
          if (_selectedModePaiement != null)
            _buildRecapSection(
              'Mode de Paiement',
              Icons.payment,
              _selectedModePaiement == 'Virement'
                  ? bleuCoris
                  : _selectedModePaiement == 'Wave'
                      ? Color(0xFF00BFFF)
                      : _selectedModePaiement == 'Orange Money'
                          ? Colors.orange
                          : _selectedModePaiement == 'PrÃ©lÃ¨vement Ã  la source'
                              ? Colors.green
                              : Color(0xFF1E3A8A),
              [
                _buildRecapRow('Mode choisi', _selectedModePaiement!),
                SizedBox(height: context.r(8)),
                if (_selectedModePaiement == 'Virement') ...[
                  _buildRecapRow(
                      'Banque',
                      _banqueController.text.isNotEmpty
                          ? _banqueController.text
                          : 'Non renseignÃ©'),
                  _buildRecapRow(
                      'NumÃ©ro RIB',
                      _ribUnifiedController.text.isNotEmpty
                          ? _ribUnifiedController.text
                          : 'Non renseignÃ©'),
                ] else if (_selectedModePaiement ==
                    'PrÃ©lÃ¨vement Ã  la source') ...[
                  _buildRecapRow(
                      'Nom de la structure',
                      _nomStructureController.text.isNotEmpty
                          ? _nomStructureController.text
                          : 'Non renseignÃ©'),
                  _buildRecapRow(
                      'NumÃ©ro de matricule',
                      _numeroMatriculeController.text.isNotEmpty
                          ? _numeroMatriculeController.text
                          : 'Non renseignÃ©'),
                ] else if (_selectedModePaiement == 'Wave' ||
                    _selectedModePaiement == 'Orange Money') ...[
                  _buildRecapRow(
                      'NumÃ©ro $_selectedModePaiement',
                      _numeroMobileMoneyController.text.isNotEmpty
                          ? _numeroMobileMoneyController.text
                          : 'Non renseignÃ©'),
                ] else if (_selectedModePaiement == 'CORIS Money') ...[
                  _buildRecapRow(
                      'NumÃ©ro CORIS Money',
                      _corisMoneyPhoneController.text.isNotEmpty
                          ? _corisMoneyPhoneController.text
                          : 'Non renseignÃ©'),
                ],
              ],
            ),
          if (_selectedModePaiement != null) SizedBox(height: context.r(12)),

          // Documents
          SubscriptionRecapWidgets.buildDocumentsSection(
            pieceIdentite: _pieceIdentiteLabel ??
                _pieceIdentite?.path.split(RegExp(r'[\\/]+')).last,
            onDocumentTap: _pieceIdentite != null
                ? () => _viewLocalDocument(
                      _pieceIdentite!,
                      _pieceIdentiteLabel ??
                          _pieceIdentite!.path.split(RegExp(r'[\\/]+')).last,
                    )
                : null,
            documents: _pieceIdentiteFiles
                .map((file) => {
                      'label': file.path.split(RegExp(r'[\\/]+')).last,
                      'path': file.path,
                    })
                .toList(),
            onDocumentTapWithInfo: (path, label) => _viewLocalDocument(
              File(path),
              label ?? path.split(RegExp(r'[\\/]+')).last,
            ),
          ),
          SizedBox(height: context.r(12)),

          SubscriptionRecapWidgets.buildAssistanceCommercialeSection(
            nomPrenom: _isAideParCommercial
                ? _commercialNomPrenomController.text.trim()
                : null,
            codeApporteur: _isAideParCommercial
                ? _commercialCodeApporteurController.text.trim()
                : null,
          ),

          SizedBox(height: context.r(12)),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: orangeWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: orangeWarning.withValues(alpha: 0.3))),
            child: Column(children: [
              Icon(Icons.info_outline, color: orangeWarning, size: 24),
              SizedBox(height: context.r(8)),
              Text('VÃ©rification Importante',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: orangeWarning,
                      fontSize: context.sp(12)),
                  textAlign: TextAlign.center),
              SizedBox(height: context.r(6)),
              Text(
                  'VÃ©rifiez attentivement toutes les informations ci-dessus. Une fois la souscription validÃ©e, certaines modifications ne seront plus possibles.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: grisTexte, fontSize: context.sp(10), height: 1.4)),
            ]),
          ),
          SizedBox(height: context.r(20)),
        ],
      ),
    );
  }

  void _viewLocalDocument(File file, String displayLabel) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          documentName: file.path,
          displayLabel: displayLabel,
          subscriptionId: widget.subscriptionId,
        ),
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
                    fontSize: context.sp(12)))),
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
          SizedBox(width: context.r(10)),
          Text(title,
              style: TextStyle(
                  fontSize: context.sp(16), fontWeight: FontWeight.w700, color: color)),
        ]),
        SizedBox(height: context.r(12)),
        ...children,
      ]),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            fontWeight: FontWeight.w600, color: bleuCoris, fontSize: context.sp(14)));
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
                  fontWeight: FontWeight.w500, color: grisTexte, fontSize: context.sp(12))),
          Text(value1,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: bleuCoris, fontSize: context.sp(12))),
        ])),
        SizedBox(width: context.r(12)),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label2 :',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: grisTexte, fontSize: context.sp(12))),
          Text(value2,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: bleuCoris, fontSize: context.sp(12))),
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
                fontWeight: FontWeight.w600, color: bleuCoris, fontSize: context.sp(12))),
        Text(
            'Date de naissance: ${membre.dateNaissance.day.toString().padLeft(2, '0')}/${membre.dateNaissance.month.toString().padLeft(2, '0')}/${membre.dateNaissance.year}',
            style: TextStyle(color: grisTexte, fontSize: context.sp(11))),
      ]),
    );
  }

  Future<void> _showSignatureAndPayment() async {
    // 1. Afficher le dialogue de signature
    final Uint8List? signature = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SignatureDialogFile.SignatureDialog(),
    );

    // Si l'utilisateur annule la signature, on arrÃªte
    if (signature == null) return;

    // Sauvegarder la signature
    setState(() {
      _clientSignature = signature;
    });

    // 2. Afficher les options de paiement
    if (!mounted) return;
    _showPaymentOptions();
  }

  void _showPaymentOptions() {
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaymentBottomSheet(
          onPayNow: (paymentMethod) {
            Navigator.pop(context);
            _processPayment(paymentMethod);
          },
          onPayLater: () {
            Navigator.pop(context);
            _saveAsProposition();
          },
        ),
      );
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
      _showErrorSnackBar('Veuillez saisir le prÃ©nom du client');
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
          'Ã‚ge du client non valide (18-65 ans requis). Ã‚ge calculÃ©: $_clientAge ans');
      return false;
    }
    // Email non obligatoire pour le commercial
    if (_clientTelephoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le tÃ©lÃ©phone du client');
      return false;
    }
    return true;
  }

  /// Valide les Ã¢ges de tous les membres de la famille
  /// Enfants: 12-21 ans
  /// Conjoints: 18+ ans
  /// Ascendants: 18+ ans
  bool _validateMembresAges() {
    final maintenant = DateTime.now();

    // VÃ©rifier les enfants (12-21 ans)
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
            'Enfant ${i + 1}: Ã‚ge non valide (12-21 ans requis). Ã‚ge calculÃ©: $age ans');
        return false;
      }
    }

    // VÃ©rifier les conjoints (18+ ans)
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
            'Conjoint ${i + 1}: Ã‚ge non valide (18 ans minimum requis). Ã‚ge calculÃ©: $age ans');
        return false;
      }
    }

    // VÃ©rifier les ascendants (18+ ans)
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
            'Ascendant ${i + 1}: Ã‚ge non valide (18 ans minimum requis). Ã‚ge calculÃ©: $age ans');
        return false;
      }
    }

    return true;
  }

  /// ðŸ’³ VALIDATION MODE DE PAIEMENT
  bool _validateStepModePaiement() {
    if (_selectedModePaiement == null) {
      _showErrorSnackBar('Veuillez sÃ©lectionner un mode de paiement.');
      return false;
    }

    if (_selectedModePaiement == 'Virement') {
      if (_banqueController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer le nom de votre banque.');
        return false;
      }
      if (_ribUnifiedController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer votre numÃ©ro RIB complet.');
        return false;
      }
      if (!_validateRibUnified(_ribUnifiedController.text)) {
        _showErrorSnackBar(
            'Le numÃ©ro RIB est invalide (18 chiffres attendus au format : 55555 / 11111111111 / 22).');
        return false;
      }
    } else if (_selectedModePaiement == 'PrÃ©lÃ¨vement Ã  la source') {
      if (_nomStructureController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer le nom de la structure.');
        return false;
      }
      if (_numeroMatriculeController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer le numÃ©ro de matricule.');
        return false;
      }
    } else if (_selectedModePaiement == 'Wave' ||
        _selectedModePaiement == 'Orange Money') {
      if (_numeroMobileMoneyController.text.trim().isEmpty) {
        _showErrorSnackBar(
            'Veuillez entrer votre numÃ©ro de tÃ©lÃ©phone $_selectedModePaiement.');
        return false;
      }
      if (!RegExp(r'^[0-9]{8,10}$')
          .hasMatch(_numeroMobileMoneyController.text.trim())) {
        _showErrorSnackBar(
            'Le numÃ©ro de tÃ©lÃ©phone semble invalide (8 Ã  10 chiffres attendus).');
        return false;
      }
      // Validation spÃ©cifique pour Orange Money : doit commencer par 07
      if (_selectedModePaiement == 'Orange Money') {
        if (!_numeroMobileMoneyController.text.trim().startsWith('07')) {
          _showErrorSnackBar('Le numÃ©ro Orange Money doit commencer par 07.');
          return false;
        }
      }
    } else if (_selectedModePaiement == 'CORIS Money') {
      if (_corisMoneyPhoneController.text.trim().isEmpty) {
        _showErrorSnackBar(
            'Veuillez entrer votre numÃ©ro de tÃ©lÃ©phone CORIS Money.');
        return false;
      }
      if (!RegExp(r'^[0-9]{8,10}$')
          .hasMatch(_corisMoneyPhoneController.text.trim())) {
        _showErrorSnackBar(
            'Le numÃ©ro de tÃ©lÃ©phone semble invalide (8 Ã  10 chiffres attendus).');
        return false;
      }
    }

    return true;
  }

  bool _validateStepBeneficiaire() {
    if (_isAideParCommercial) {
      if (_commercialNomPrenomController.text.trim().isEmpty) {
        _showErrorSnackBar(
            'Veuillez renseigner le nom et prÃ©nom du commercial');
        return false;
      }
      if (_commercialCodeApporteurController.text.trim().isEmpty) {
        _showErrorSnackBar(
            'Veuillez renseigner le code apporteur du commercial');
        return false;
      }
    }

    if (_beneficiaireNomController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le nom du bÃ©nÃ©ficiaire');
      return false;
    }
    if (_beneficiaireDateNaissance == null) {
      _showErrorSnackBar(
          'Veuillez saisir la date de naissance du bÃ©nÃ©ficiaire');
      return false;
    }
    if (_beneficiaireContactController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le contact du bÃ©nÃ©ficiaire');
      return false;
    }
    return true;
  }

  void _nextStep() {
    // Valider la page client si c'est un commercial et qu'on est Ã  l'Ã©tape 0
    if (_isCommercial && _currentStep == 0) {
      if (!_validateStepClientInfo()) {
        return; // Ne pas passer Ã  l'Ã©tape suivante si la validation Ã©choue
      }
    }

    // Valider l'Ã©tape bÃ©nÃ©ficiaire (position dynamique : juste avant mode paiement et recap)
    final beneficiaireStep = _getTotalSteps() - 3;
    if (_currentStep == beneficiaireStep) {
      if (!_validateStepBeneficiaire()) {
        return; // Ne pas passer Ã  l'Ã©tape suivante si la validation Ã©choue
      }
    }

    // Valider le mode de paiement si on est sur cette Ã©tape (avant-derniÃ¨re Ã©tape avant rÃ©cap)
    final modePaiementStep = _getTotalSteps() - 2;
    if (_currentStep == modePaiementStep) {
      if (!_validateStepModePaiement()) {
        return; // Ne pas passer au rÃ©cap si le mode de paiement n'est pas validÃ©
      }
    }

    if (_currentStep < _getTotalSteps() - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      // DerniÃ¨re Ã©tape (rÃ©cap), aller Ã  la signature puis paiement
      if (!_validateMembresAges()) {
        return; // Valider les Ã¢ges avant le paiement
      }
      _showSignatureAndPayment();
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
      resizeToAvoidBottomInset: true,
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
                                  SizedBox(width: context.r(8)),
                                  Text('PrÃ©cÃ©dent',
                                      style: TextStyle(
                                          color: bleuCoris,
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.sp(16))),
                                ]),
                          ),
                        ),
                      if (_currentStep > 0) SizedBox(width: context.r(16)),
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
                                Icon(
                                    _currentStep == _getTotalSteps() - 1
                                        ? Icons.draw
                                        : Icons.arrow_forward,
                                    color: blanc,
                                    size: 20),
                                SizedBox(width: context.r(8)),
                                Text(
                                    _currentStep == _getTotalSteps() - 1
                                        ? 'Signer et Finaliser'
                                        : 'Suivant',
                                    style: TextStyle(
                                        color: blanc,
                                        fontWeight: FontWeight.w700,
                                        fontSize: context.sp(16))),
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

  @override
  void dispose() {
    _beneficiaireDateNaissanceController.dispose();
    _clientProfessionController.dispose();
    _clientSecteurActiviteController.dispose();
    _commercialNomPrenomController.dispose();
    _commercialCodeApporteurController.dispose();
    super.dispose();
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
          SizedBox(height: context.r(20)),
          Text('Traitement en cours',
              style: TextStyle(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF002B6B))),
          SizedBox(height: context.r(8)),
          Text('Paiement via $paymentMethod...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: context.sp(14))),
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
          SizedBox(height: context.r(20)),
          Text(
            isPaid ? 'Souscription RÃ©ussie!' : 'Proposition EnregistrÃ©e!',
            style: TextStyle(
              fontSize: context.sp(20),
              fontWeight: FontWeight.w700,
              color: Color(0xFF002B6B),
            ),
          ),
          SizedBox(height: context.r(12)),
          Text(
              isPaid
                  ? 'FÃ©licitations! Votre contrat CORIS SOLIDARITÃ‰ est maintenant actif. Vous recevrez un message de confirmation sous peu.'
                  : 'Votre proposition a Ã©tÃ© enregistrÃ©e avec succÃ¨s. Vous pouvez effectuer le paiement plus tard depuis votre espace client.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF64748B), fontSize: context.sp(14), height: 1.4)),
          SizedBox(height: context.r(24)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  // Retour Ã  la page d'accueil client
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/client_home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF002B6B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Retour Ã  l\'accueil',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600))),
          ),
        ]),
      ),
    );
  }
}

class PaymentBottomSheet extends StatelessWidget {
  final Function(String) onPayNow;
  final VoidCallback onPayLater;
  const PaymentBottomSheet(
      {super.key, required this.onPayNow, required this.onPayLater});

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
                  SizedBox(height: context.r(24)),
                  Row(children: [
                    Icon(Icons.payment, color: Color(0xFF002B6B), size: 28),
                    SizedBox(width: context.r(12)),
                    Text('Options de Paiement',
                        style: TextStyle(
                            fontSize: context.sp(22),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF002B6B)))
                  ]),
                  SizedBox(height: context.r(24)),
                  _buildPaymentOptionWithImage(
                      context,
                      'Wave',
                      'assets/images/icone_wave.jpeg',
                      Colors.blue,
                      'Paiement mobile sÃ©curisÃ©',
                      () => onPayNow('Wave')),
                  // _buildPaymentOptionWithImage(
                  //     'Orange Money',
                  //     'assets/images/icone_orange_money.jpeg',
                  //     Colors.orange,
                  //     'Paiement mobile Orange',
                  //     () => onPayNow('Orange Money')),
                  // SizedBox(height: context.r(12)),
                  // _buildPaymentOptionWithImage(
                  //     'CORIS Money',
                  //     'assets/images/icone_corismoney.jpeg',
                  //     const Color(0xFF1E3A8A),
                  //     'Paiement via CORIS Money',
                  //     () => onPayNow('CORIS Money')),
                  SizedBox(height: context.r(24)),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OU',
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500))),
                    Expanded(child: Divider(color: Colors.grey[300]))
                  ]),
                  SizedBox(height: context.r(20)),
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
                                SizedBox(width: context.r(8)),
                                Text('Payer plus tard',
                                    style: TextStyle(
                                        color: Color(0xFF002B6B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: context.sp(16)))
                              ]))),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ]))));
  }

  Widget _buildPaymentOption(BuildContext context, String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
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
              SizedBox(width: context.r(16)),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF002B6B),
                            fontSize: context.sp(16))),
                    SizedBox(height: context.r(4)),
                    Text(subtitle,
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: context.sp(12)))
                  ])),
              Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 16),
            ])));
  }

  Widget _buildPaymentOptionWithImage(BuildContext context, String title, String imagePath, Color color, String subtitle, VoidCallback onTap) {
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2))),
                  child: Image.asset(
                    imagePath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('âŒ Erreur chargement image: $imagePath - $error');
                      return Icon(Icons.image_not_supported,
                          size: 32, color: Colors.grey);
                    },
                  )),
              SizedBox(width: context.r(16)),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF002B6B),
                            fontSize: context.sp(16))),
                    SizedBox(height: context.r(4)),
                    Text(subtitle,
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: context.sp(12)))
                  ])),
              Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 16),
            ])));
  }
}


