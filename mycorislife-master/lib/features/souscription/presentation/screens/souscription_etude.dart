import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:intl/intl.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';

class SouscriptionEtudePage extends StatefulWidget {
  final int? ageParent;
  final int? ageEnfant;
  final double? prime;
  final double? rente;
  final String? periodicite;
  final String? mode; // 'prime' ou 'rente'
  final DateTime?
      dateNaissanceParent; // Date de naissance du parent depuis la simulation
  final String? clientId; // ID du client si souscription par commercial
  final Map<String, dynamic>?
      clientData; // Données du client si souscription par commercial
  final int?
      subscriptionId; // ID de la souscription à modifier (si mode édition)
  final Map<String, dynamic>? existingData; // Données existantes à préremplir
  const SouscriptionEtudePage({
    super.key,
    this.ageParent,
    this.ageEnfant,
    this.prime,
    this.rente,
    this.periodicite,
    this.mode,
    this.dateNaissanceParent,
    this.clientId,
    this.clientData,
    this.subscriptionId,
    this.existingData,
  });
  @override
  SouscriptionEtudePageState createState() => SouscriptionEtudePageState();
}

class SouscriptionEtudePageState extends State<SouscriptionEtudePage>
    with TickerProviderStateMixin {
  // Charte graphique CORIS améliorée
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color bleuSecondaire = Color(0xFF1E4A8C);
  static const Color blanc = Colors.white;
  static const Color fondCarte = Color(0xFFF8FAFC);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color grisLeger = Color(0xFFF1F5F9);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color orangeWarning = Color(0xFFF59E0B);
  static const Color bleuClair = Color(0xFFE8F4FD);
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  int _currentStep = 0;

  // Données utilisateur (pour les clients)
  Map<String, dynamic> _userData = {};

  // Form controllers
  // Clés de formulaire séparées pour chaque étape afin d'éviter
  // la réutilisation d'un même GlobalKey dans l'arbre de widgets.
  final _formKeyClientInfo = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Step 1 controllers
  final _dureeController = TextEditingController();
  final _montantController = TextEditingController();
  final _dateEffetController = TextEditingController();
  final _dateNaissanceParentController = TextEditingController();
  String? _selectedPeriodicite;
  final _professionController = TextEditingController();
  DateTime? _dateEffetContrat;
  DateTime? _dateEcheanceContrat;
  String _selectedBeneficiaireIndicatif = '+225'; // Côte d'Ivoire par défaut
  String _selectedContactIndicatif = '+225'; // Côte d'Ivoire par défaut
  final List<Map<String, String>> _indicatifOptions = [
    {'code': '+225', 'pays': 'Côte d\'Ivoire'},
    {'code': '+226', 'pays': 'Burkina Faso'},
  ];

  // Step 2 controllers
  final _beneficiaireNomController = TextEditingController();
  final _beneficiaireContactController = TextEditingController();
  String _selectedLienParente = 'Enfant';
  final _personneContactNomController = TextEditingController();
  final _personneContactTelController = TextEditingController();
  String _selectedLienParenteUrgence = 'Parent';
  // Mode de souscription
  String _selectedMode = 'Mode Prime'; // 'Prime' ou 'Rente'
  // Variables pour les calculs
  double _primeCalculee = 0.0;
  double _renteCalculee = 0.0;
  File? _pieceIdentite;
  // Variable pour éviter les soumissions multiples
  bool _isProcessing = false;
  // Options de lien de parenté
  final List<String> _lienParenteOptions = [
    'Enfant',
    'Conjoint',
    'Parent',
    'Frère/Sœur',
    'Ami',
    'Autre'
  ];
  // Options de périodicité
  final List<String> _periodiciteOptions = [
    'Mensuel',
    'Trimestriel',
    'Semestriel',
    'Annuel'
  ];
  // Tableau tarifaire pour les rentes fixes (identique à simulation-etude.dart)
  final Map<int, Map<int, double>> tarifRenteFixe = {
    18: {
      60: 754,
      72: 623,
      84: 530,
      96: 460,
      108: 406,
      120: 362,
      132: 327,
      144: 298,
      156: 273,
      168: 252,
      180: 234,
      192: 219,
      204: 205,
      216: 193,
      228: 182,
      240: 173
    },
    19: {
      60: 754,
      72: 623,
      84: 530,
      96: 460,
      108: 406,
      120: 363,
      132: 327,
      144: 298,
      156: 274,
      168: 253,
      180: 235,
      192: 219,
      204: 205,
      216: 193,
      228: 182,
      240: 173
    },
    20: {
      60: 755,
      72: 623,
      84: 530,
      96: 460,
      108: 406,
      120: 363,
      132: 328,
      144: 299,
      156: 274,
      168: 253,
      180: 235,
      192: 219,
      204: 206,
      216: 194,
      228: 183,
      240: 173
    },
    21: {
      60: 755,
      72: 624,
      84: 530,
      96: 460,
      108: 406,
      120: 363,
      132: 328,
      144: 299,
      156: 274,
      168: 253,
      180: 235,
      192: 220,
      204: 206,
      216: 194,
      228: 183,
      240: 174
    },
    22: {
      60: 755,
      72: 624,
      84: 530,
      96: 460,
      108: 406,
      120: 363,
      132: 328,
      144: 299,
      156: 274,
      168: 253,
      180: 235,
      192: 220,
      204: 206,
      216: 194,
      228: 183,
      240: 174
    },
    23: {
      60: 755,
      72: 624,
      84: 530,
      96: 461,
      108: 406,
      120: 363,
      132: 328,
      144: 299,
      156: 275,
      168: 254,
      180: 236,
      192: 220,
      204: 206,
      216: 194,
      228: 184,
      240: 174
    },
    24: {
      60: 755,
      72: 624,
      84: 531,
      96: 461,
      108: 407,
      120: 364,
      132: 328,
      144: 299,
      156: 275,
      168: 254,
      180: 236,
      192: 220,
      204: 207,
      216: 195,
      228: 184,
      240: 175
    },
    25: {
      60: 755,
      72: 624,
      84: 531,
      96: 461,
      108: 407,
      120: 364,
      132: 329,
      144: 300,
      156: 275,
      168: 254,
      180: 236,
      192: 221,
      204: 207,
      216: 195,
      228: 185,
      240: 175
    },
    26: {
      60: 755,
      72: 624,
      84: 531,
      96: 461,
      108: 407,
      120: 364,
      132: 329,
      144: 300,
      156: 275,
      168: 255,
      180: 237,
      192: 221,
      204: 208,
      216: 196,
      228: 185,
      240: 176
    },
    27: {
      60: 755,
      72: 624,
      84: 531,
      96: 461,
      108: 407,
      120: 364,
      132: 329,
      144: 300,
      156: 276,
      168: 255,
      180: 237,
      192: 222,
      204: 208,
      216: 196,
      228: 186,
      240: 177
    },
    28: {
      60: 756,
      72: 625,
      84: 531,
      96: 462,
      108: 408,
      120: 364,
      132: 329,
      144: 301,
      156: 276,
      168: 255,
      180: 238,
      192: 222,
      204: 209,
      216: 197,
      228: 187,
      240: 177
    },
    29: {
      60: 756,
      72: 625,
      84: 532,
      96: 462,
      108: 408,
      120: 365,
      132: 330,
      144: 301,
      156: 277,
      168: 256,
      180: 238,
      192: 223,
      204: 210,
      216: 198,
      228: 187,
      240: 178
    },
    30: {
      60: 756,
      72: 625,
      84: 532,
      96: 462,
      108: 408,
      120: 365,
      132: 330,
      144: 301,
      156: 277,
      168: 257,
      180: 239,
      192: 224,
      204: 210,
      216: 199,
      228: 188,
      240: 179
    },
    31: {
      60: 756,
      72: 625,
      84: 532,
      96: 462,
      108: 409,
      120: 366,
      132: 331,
      144: 302,
      156: 278,
      168: 257,
      180: 240,
      192: 224,
      204: 211,
      216: 200,
      228: 189,
      240: 180
    },
    32: {
      60: 757,
      72: 626,
      84: 533,
      96: 463,
      108: 409,
      120: 366,
      132: 331,
      144: 303,
      156: 279,
      168: 258,
      180: 241,
      192: 225,
      204: 212,
      216: 201,
      228: 191,
      240: 182
    },
    33: {
      60: 757,
      72: 626,
      84: 533,
      96: 464,
      108: 410,
      120: 367,
      132: 332,
      144: 304,
      156: 279,
      168: 259,
      180: 242,
      192: 227,
      204: 213,
      216: 202,
      228: 192,
      240: 183
    },
    34: {
      60: 757,
      72: 627,
      84: 534,
      96: 464,
      108: 410,
      120: 368,
      132: 333,
      144: 304,
      156: 280,
      168: 260,
      180: 243,
      192: 228,
      204: 215,
      216: 203,
      228: 193,
      240: 184
    },
    35: {
      60: 758,
      72: 627,
      84: 534,
      96: 465,
      108: 411,
      120: 369,
      132: 334,
      144: 305,
      156: 282,
      168: 261,
      180: 244,
      192: 229,
      204: 216,
      216: 205,
      228: 195,
      240: 186
    },
    36: {
      60: 759,
      72: 628,
      84: 535,
      96: 466,
      108: 412,
      120: 370,
      132: 335,
      144: 307,
      156: 283,
      168: 263,
      180: 245,
      192: 230,
      204: 218,
      216: 206,
      228: 196,
      240: 188
    },
    37: {
      60: 759,
      72: 629,
      84: 536,
      96: 467,
      108: 413,
      120: 371,
      132: 336,
      144: 308,
      156: 284,
      168: 264,
      180: 247,
      192: 232,
      204: 219,
      216: 208,
      228: 198,
      240: 189
    },
    38: {
      60: 760,
      72: 630,
      84: 537,
      96: 468,
      108: 414,
      120: 372,
      132: 338,
      144: 309,
      156: 286,
      168: 265,
      180: 248,
      192: 234,
      204: 221,
      216: 210,
      228: 200,
      240: 191
    },
    39: {
      60: 761,
      72: 630,
      84: 538,
      96: 469,
      108: 415,
      120: 373,
      132: 339,
      144: 311,
      156: 287,
      168: 267,
      180: 250,
      192: 235,
      204: 223,
      216: 212,
      228: 202,
      240: 193
    },
    40: {
      60: 762,
      72: 632,
      84: 539,
      96: 470,
      108: 417,
      120: 375,
      132: 340,
      144: 312,
      156: 289,
      168: 269,
      180: 252,
      192: 237,
      204: 225,
      216: 214,
      228: 204,
      240: 196
    },
    41: {
      60: 763,
      72: 633,
      84: 540,
      96: 471,
      108: 418,
      120: 376,
      132: 342,
      144: 314,
      156: 290,
      168: 271,
      180: 254,
      192: 239,
      204: 227,
      216: 216,
      228: 206,
      240: 198
    },
    42: {
      60: 764,
      72: 634,
      84: 542,
      96: 473,
      108: 420,
      120: 378,
      132: 344,
      144: 316,
      156: 292,
      168: 272,
      180: 256,
      192: 241,
      204: 229,
      216: 218,
      228: 209,
      240: 200
    },
    43: {
      60: 765,
      72: 635,
      84: 543,
      96: 474,
      108: 421,
      120: 379,
      132: 345,
      144: 317,
      156: 294,
      168: 274,
      180: 258,
      192: 243,
      204: 231,
      216: 220,
      228: 211,
      240: 203
    },
    44: {
      60: 766,
      72: 637,
      84: 544,
      96: 476,
      108: 423,
      120: 381,
      132: 347,
      144: 319,
      156: 296,
      168: 276,
      180: 260,
      192: 245,
      204: 233,
      216: 223,
      228: 214,
      240: 206
    },
    45: {
      60: 768,
      72: 638,
      84: 546,
      96: 477,
      108: 424,
      120: 382,
      132: 349,
      144: 321,
      156: 298,
      168: 278,
      180: 262,
      192: 248,
      204: 236,
      216: 225,
      228: 216,
      240: 209
    },
    46: {
      60: 769,
      72: 639,
      84: 547,
      96: 479,
      108: 426,
      120: 384,
      132: 350,
      144: 323,
      156: 300,
      168: 280,
      180: 264,
      192: 250,
      204: 238,
      216: 228,
      228: 219,
      240: 212
    },
    47: {
      60: 770,
      72: 640,
      84: 548,
      96: 480,
      108: 427,
      120: 386,
      132: 352,
      144: 325,
      156: 302,
      168: 282,
      180: 266,
      192: 253,
      204: 241,
      216: 231,
      228: 222,
      240: 215
    },
    48: {
      60: 771,
      72: 642,
      84: 550,
      96: 482,
      108: 429,
      120: 387,
      132: 354,
      144: 327,
      156: 304,
      168: 285,
      180: 269,
      192: 255,
      204: 244,
      216: 234,
      228: 226,
      240: 219
    },
    49: {
      60: 772,
      72: 643,
      84: 551,
      96: 483,
      108: 431,
      120: 389,
      132: 356,
      144: 329,
      156: 306,
      168: 287,
      180: 272,
      192: 258,
      204: 247,
      216: 237,
      228: 229,
      240: 223
    },
    50: {
      60: 774,
      72: 644,
      84: 553,
      96: 485,
      108: 433,
      120: 391,
      132: 358,
      144: 331,
      156: 309,
      168: 290,
      180: 275,
      192: 261,
      204: 250,
      216: 241,
      228: 233,
      240: 227
    },
    51: {
      60: 775,
      72: 646,
      84: 554,
      96: 487,
      108: 434,
      120: 393,
      132: 361,
      144: 334,
      156: 312,
      168: 293,
      180: 278,
      192: 265,
      204: 254,
      216: 245,
      228: 238,
      240: 232
    },
    52: {
      60: 776,
      72: 648,
      84: 556,
      96: 489,
      108: 437,
      120: 396,
      132: 363,
      144: 337,
      156: 315,
      168: 297,
      180: 282,
      192: 269,
      204: 259,
      216: 250,
      228: 243,
      240: 237
    },
    53: {
      60: 778,
      72: 649,
      84: 558,
      96: 491,
      108: 439,
      120: 399,
      132: 366,
      144: 340,
      156: 318,
      168: 301,
      180: 286,
      192: 274,
      204: 263,
      216: 255,
      228: 248,
      240: 242
    },
    54: {
      60: 780,
      72: 651,
      84: 560,
      96: 493,
      108: 442,
      120: 402,
      132: 370,
      144: 344,
      156: 322,
      168: 305,
      180: 290,
      192: 278,
      204: 269,
      216: 260,
      228: 254,
      240: 248
    },
    55: {
      60: 782,
      72: 653,
      84: 563,
      96: 496,
      108: 445,
      120: 405,
      132: 373,
      144: 348,
      156: 327,
      168: 310,
      180: 296,
      192: 284,
      204: 274,
      216: 267,
      228: 260,
      240: 255
    },
    56: {
      60: 784,
      72: 656,
      84: 566,
      96: 499,
      108: 449,
      120: 409,
      132: 378,
      144: 352,
      156: 332,
      168: 315,
      180: 301,
      192: 290,
      204: 281,
      216: 273,
      228: 267,
      240: 263
    },
    57: {
      60: 787,
      72: 659,
      84: 569,
      96: 503,
      108: 453,
      120: 414,
      132: 383,
      144: 358,
      156: 337,
      168: 322,
      180: 308,
      192: 297,
      204: 288,
      216: 281,
      228: 275,
      240: 271
    },
    58: {
      60: 790,
      72: 663,
      84: 573,
      96: 508,
      108: 458,
      120: 419,
      132: 388,
      144: 363,
      156: 344,
      168: 328,
      180: 315,
      192: 304,
      204: 296,
      216: 289,
      228: 284,
      240: 280
    },
    59: {
      60: 794,
      72: 667,
      84: 578,
      96: 513,
      108: 463,
      120: 424,
      132: 394,
      144: 370,
      156: 350,
      168: 335,
      180: 322,
      192: 312,
      204: 304,
      216: 298,
      228: 293,
      240: 290
    },
    60: {
      60: 798,
      72: 671,
      84: 583,
      96: 518,
      108: 469,
      120: 430,
      132: 401,
      144: 377,
      156: 358,
      168: 342,
      180: 330,
      192: 320,
      204: 313,
      216: 307,
      228: 303,
      240: 300
    },
  };
  final storage = const FlutterSecureStorage();

  // Variables pour commercial (souscription pour un client)
  bool _isCommercial = false;
  DateTime? _dateNaissanceParent;
  int? _clientAgeParent;

  // Contrôleurs pour les informations client (si commercial)
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
  String _selectedClientCivilite = 'Monsieur';
  String _selectedClientIndicatif = '+225';

  // Nouvelles variables ajoutées
  int?
      _calculatedAgeParent; // Âge calculé à partir de la BD si widget.ageParent est null

  @override
  void initState() {
    super.initState();

    // Si on modifie une proposition existante, préremplir avec les données
    if (widget.existingData != null) {
      _prefillFromExistingData();
    } else {
      // Chargez les données utilisateur dès l'initialisation si pas de simulation
      if (widget.ageParent == null) {
        _loadUserData().then((data) {
          _calculatedAgeParent =
              _calculateAgeFromBirthDate(data['date_naissance']);
          _recalculerValeurs(); // Recalculer après chargement
          if (mounted) {
            setState(() {}); // Rafraîchir l'UI
          }
        }).catchError((e) {
          if (mounted) {
            _showErrorSnackBar(
                'Erreur lors du chargement des données utilisateur: $e');
          }
        });
      } else {
        _calculatedAgeParent =
            widget.ageParent; // Utiliser la valeur de simulation si disponible
      }

      _prefillFromSimulation();
    }

    _dateEffetContrat = DateTime.now();
    _dateEffetController.text =
        DateFormat('dd/MM/yyyy').format(_dateEffetContrat!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vérifier si c'est un commercial qui fait la souscription
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['isCommercial'] == true) {
      if (!_isCommercial) {
        setState(() {
          _isCommercial = true;
        });
      }

      // Pré-remplir les champs avec les informations du client si disponibles
      if (args['clientInfo'] != null) {
        final clientInfo = args['clientInfo'] as Map<String, dynamic>;
        _clientNomController.text = clientInfo['nom'] ?? '';
        _clientPrenomController.text = clientInfo['prenom'] ?? '';
        _clientEmailController.text = clientInfo['email'] ?? '';
        _clientTelephoneController.text = clientInfo['telephone'] ?? '';
        _clientLieuNaissanceController.text =
            clientInfo['lieu_naissance'] ?? '';
        _clientAdresseController.text = clientInfo['adresse'] ?? '';
        _clientNumeroPieceController.text =
            clientInfo['numero_piece_identite'] ?? '';

        if (clientInfo['civilite'] != null) {
          _selectedClientCivilite = clientInfo['civilite'];
        }

        // Gérer la date de naissance du parent
        if (clientInfo['date_naissance'] != null) {
          try {
            DateTime? dateNaissance;
            if (clientInfo['date_naissance'] is String) {
              dateNaissance = DateTime.parse(clientInfo['date_naissance']);
            } else if (clientInfo['date_naissance'] is DateTime) {
              dateNaissance = clientInfo['date_naissance'];
            }

            if (dateNaissance != null) {
              final finalDate = dateNaissance;
              setState(() {
                _dateNaissanceParent = finalDate;
                _clientDateNaissanceController.text =
                    '${finalDate.day.toString().padLeft(2, '0')}/${finalDate.month.toString().padLeft(2, '0')}/${finalDate.year}';
                final maintenant = DateTime.now();
                _clientAgeParent = maintenant.year - finalDate.year;
                if (maintenant.month < finalDate.month ||
                    (maintenant.month == finalDate.month &&
                        maintenant.day < finalDate.day)) {
                  _clientAgeParent = (_clientAgeParent ?? 0) - 1;
                }
                // Utiliser l'âge du client pour le calcul
                _calculatedAgeParent = _clientAgeParent;
              });
            }
          } catch (e) {
            print('Erreur parsing date de naissance: $e');
          }
        }

        // Extraire l'indicatif du téléphone si présent
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
    }

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    // Ajouter un délai pour s'assurer que tout est initialisé avant le calcul
    Future.delayed(Duration(milliseconds: 100), () {
      _recalculerValeurs();
      if (mounted) {
        setState(() {}); // Forcer le rafraîchissement de l'interface
      }
    });
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('❌ Token non trouvé');
        // Retourner un map vide au lieu de lever une exception
        return {};
      }
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map) {
          if (data['success'] == true &&
              data['user'] != null &&
              data['user'] is Map) {
            return Map<String, dynamic>.from(data['user']);
          }
          if (data.containsKey('id') && data.containsKey('email')) {
            return Map<String, dynamic>.from(data);
          }
        }
        return {};
      }
      debugPrint('Erreur serveur: ${response.statusCode}');
      return {};
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
      return {};
    }
  }

  int? _calculateAgeFromBirthDate(String? birthDateStr) {
    if (birthDateStr == null) return null;
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  void _prefillFromExistingData() {
    if (widget.existingData == null) return;

    final data = widget.existingData!;

    // Mode de souscription
    if (data['mode_souscription'] != null) {
      _selectedMode =
          data['mode_souscription'] == 'prime' ? 'Mode Prime' : 'Mode Rente';
    }

    // Date de naissance du parent
    if (data['date_naissance_parent'] != null) {
      try {
        _dateNaissanceParent = DateTime.parse(data['date_naissance_parent']);
        _dateNaissanceParentController.text =
            DateFormat('dd/MM/yyyy').format(_dateNaissanceParent!);
      } catch (e) {
        debugPrint('Erreur parsing date_naissance_parent: $e');
      }
    }

    // Âge parent
    if (data['age_parent'] != null) {
      _calculatedAgeParent = data['age_parent'] is int
          ? data['age_parent']
          : int.tryParse(data['age_parent'].toString());
    }

    // Âge enfant
    if (data['age_enfant'] != null) {
      _dureeController.text = data['age_enfant'].toString();
    }

    // Prime et montant
    if (data['prime_calculee'] != null) {
      _primeCalculee = (data['prime_calculee'] is int)
          ? data['prime_calculee'].toDouble()
          : data['prime_calculee'];
      if (_selectedMode == 'Mode Prime') {
        _montantController.text = _primeCalculee.toStringAsFixed(0);
      }
    }

    // Rente
    if (data['rente_calculee'] != null) {
      _renteCalculee = (data['rente_calculee'] is int)
          ? data['rente_calculee'].toDouble()
          : data['rente_calculee'];
      if (_selectedMode == 'Mode Rente') {
        _montantController.text = _renteCalculee.toStringAsFixed(0);
      }
    }

    // Périodicité
    if (data['periodicite'] != null) {
      String periodicite = data['periodicite'].toString().toLowerCase();
      _selectedPeriodicite =
          periodicite[0].toUpperCase() + periodicite.substring(1);
    }

    // Bénéficiaire
    if (data['beneficiaire'] != null) {
      final benef = data['beneficiaire'];
      _beneficiaireNomController.text = benef['nom'] ?? '';
      if (benef['contact'] != null) {
        final contact = benef['contact'].toString();
        // Extraire l'indicatif et le numéro
        if (contact.startsWith('+')) {
          final parts = contact.split(' ');
          if (parts.length >= 2) {
            _selectedBeneficiaireIndicatif = parts[0];
            _beneficiaireContactController.text = parts.sublist(1).join(' ');
          }
        } else {
          _beneficiaireContactController.text = contact;
        }
      }
      _selectedLienParente = benef['lien_parente'] ?? 'Enfant';
    }

    // Contact d'urgence
    if (data['contact_urgence'] != null) {
      final contact = data['contact_urgence'];
      _personneContactNomController.text = contact['nom'] ?? '';
      if (contact['contact'] != null) {
        final tel = contact['contact'].toString();
        if (tel.startsWith('+')) {
          final parts = tel.split(' ');
          if (parts.length >= 2) {
            _selectedContactIndicatif = parts[0];
            _personneContactTelController.text = parts.sublist(1).join(' ');
          }
        } else {
          _personneContactTelController.text = tel;
        }
      }
      _selectedLienParenteUrgence = contact['lien_parente'] ?? 'Parent';
    }

    // Profession
    if (data['profession'] != null) {
      _professionController.text = data['profession'];
    }

    // Dates
    if (data['date_effet'] != null) {
      try {
        _dateEffetContrat = DateTime.parse(data['date_effet']);
        _dateEffetController.text =
            DateFormat('dd/MM/yyyy').format(_dateEffetContrat!);
      } catch (e) {
        debugPrint('Erreur parsing date_effet: $e');
      }
    }

    if (data['date_echeance'] != null) {
      try {
        _dateEcheanceContrat = DateTime.parse(data['date_echeance']);
      } catch (e) {
        debugPrint('Erreur parsing date_echeance: $e');
      }
    }

    // Forcer le recalcul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculerValeurs();
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _prefillFromSimulation() {
    // Déterminer le mode de souscription
    if (widget.mode != null) {
      _selectedMode = widget.mode == 'prime' ? 'Mode Prime' : 'Mode Rente';
    } else {
      _selectedMode = 'Mode Prime'; // Valeur par défaut
    }

    // Initialiser la date de naissance du parent depuis la simulation
    if (widget.dateNaissanceParent != null) {
      _dateNaissanceParent = widget.dateNaissanceParent;
      // Pré-remplir le champ texte avec la date formatée
      _dateNaissanceParentController.text =
          DateFormat('dd/MM/yyyy').format(widget.dateNaissanceParent!);
    }

    // Pré-remplir l'âge de l'enfant si disponible
    if (widget.ageEnfant != null) {
      _dureeController.text = widget.ageEnfant!.toString();
    }

    // Pré-remplir le montant selon le mode
    if (widget.prime != null && _selectedMode == 'Mode Prime') {
      _montantController.text = widget.prime!.toStringAsFixed(0);
    } else if (widget.rente != null && _selectedMode == 'Mode Rente') {
      _montantController.text = widget.rente!.toStringAsFixed(0);
    }

    // Pré-remplir la périodicité
    if (widget.periodicite != null) {
      // Convertir la périodicité du format de la simulation au format de souscription
      String periodicite = widget.periodicite!;
      switch (periodicite) {
        case 'mensuel':
          _selectedPeriodicite = 'Mensuel';
          break;
        case 'trimestriel':
          _selectedPeriodicite = 'Trimestriel';
          break;
        case 'semestriel':
          _selectedPeriodicite = 'Semestriel';
          break;
        case 'annuel':
          _selectedPeriodicite = 'Annuel';
          break;
        default:
          _selectedPeriodicite = _periodiciteOptions.first;
      }
    } else {
      _selectedPeriodicite = _periodiciteOptions.first;
    }
    // Date d'effet par défaut (aujourd'hui)
    _dateEffetContrat = DateTime.now();
    _dateEffetController.text =
        DateFormat('dd/MM/yyyy').format(_dateEffetContrat!);

    // Mettre à jour la date d'échéance
    _updateEcheanceDate();

    // Forcer le recalcul immédiat des valeurs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculerValeurs();
      if (mounted) {
        setState(() {});
      }
    });
  }

  // Méthode auxiliaire pour trouver la durée la plus proche
  int _closestDuree(int mois) {
    final palliers = [
      60,
      72,
      84,
      96,
      108,
      120,
      132,
      144,
      156,
      168,
      180,
      192,
      204,
      216,
      228,
      240
    ];
    for (int p in palliers) {
      if (mois <= p) return p;
    }
    return 240;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _dureeController.dispose();
    _montantController.dispose();
    _dateEffetController.dispose();
    _professionController.dispose();
    _beneficiaireNomController.dispose();
    _beneficiaireContactController.dispose();
    _personneContactNomController.dispose();
    _personneContactTelController.dispose();
    // Dispose des contrôleurs client
    _clientNomController.dispose();
    _clientPrenomController.dispose();
    _clientDateNaissanceController.dispose();
    _clientLieuNaissanceController.dispose();
    _clientTelephoneController.dispose();
    _clientEmailController.dispose();
    _clientAdresseController.dispose();
    _clientNumeroPieceController.dispose();
    super.dispose();
  }

  String _formatMontant(double montant) {
    return "${montant.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\.))'), (Match m) => '${m[1]} ')} FCFA";
  }

  void _formatMontantInput() {
    final text = _montantController.text.replaceAll(' ', '');
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null) {
        _montantController.text = _formatNumber(value);
        _montantController.selection = TextSelection.fromPosition(
          TextPosition(offset: _montantController.text.length),
        );
      }
    }
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\.))'),
          (Match m) => '${m[1]} ',
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
          setState(() {
            _pieceIdentite = File(result.files.single.path!);
          });
        }

        if (mounted) {
          _showSuccessSnackBar(
              'Votre pièce d\'identité a été téléchargée avec succès.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Une erreur s\'est produite lors de la sélection du fichier. Veuillez réessayer.');
      }
    }
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
        return {};
      }

      debugPrint('🔄 Chargement des données utilisateur depuis l\'API...');
      // Pour les clients, charger les données depuis le profil utilisateur
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10), onTimeout: () {
        debugPrint('⏱️ Timeout lors de la requête API profil');
        throw Exception('Timeout API');
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

          // Aucune correspondance
          debugPrint('⚠️ Réponse API inattendue (200): ${response.body}');
        } else {
          debugPrint('⚠️ Format invalide (non-Map): ${response.body}');
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ Non authentifié (401): Token expiré ou invalide');
      } else {
        debugPrint(
            '❌ Erreur HTTP ${response.statusCode}: ${response.reasonPhrase} - body: ${response.body}');
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rougeCoris,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: blanc, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attention',
                      style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: blanc,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _nextStep() {
    // maxStep est maintenant 4 pour inclure l'étape de paiement
    // Clients: 0 (params), 1 (bénéficiaire), 2 (recap), 3 (paiement)
    // Commerciaux: 0 (client), 1 (params), 2 (bénéficiaire), 3 (recap), 4 (paiement)
    final maxStep = _isCommercial ? 4 : 3;
    if (_currentStep < maxStep) {
      bool canProceed = false;

      if (_isCommercial) {
        // Pour les commerciaux: step 0 = infos client, step 1 = paramètres, step 2 = bénéficiaire, step 3 = recap
        if (_currentStep == 0 && _validateStepClientInfo()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStep2()) {
          canProceed = true;
          _recalculerValeurs(); // Call here before moving to recap (step 3)
        } else if (_currentStep == 3) {
          // Recap pour commerciaux - aller au paiement
          canProceed = true;
        }
      } else {
        // Pour les clients: step 0 = paramètres, step 1 = bénéficiaire, step 2 = recap
        if (_currentStep == 0 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep2()) {
          canProceed = true;
          _recalculerValeurs(); // Call here before moving to recap (step 2)
        } else if (_currentStep == 2) {
          // Recap pour clients - aller au paiement
          canProceed = true;
        }
      }
      if (canProceed) {
        setState(() => _currentStep++);
        _progressController.forward();
        _animationController.reset();
        _animationController.forward();
        _pageController.nextPage(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _progressController.reverse();
      _animationController.reset();
      _animationController.forward();
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
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
    if (_dateNaissanceParent == null) {
      _showErrorSnackBar(
          'Veuillez saisir la date de naissance du souscripteur');
      return false;
    }
    final maintenant = DateTime.now();
    _clientAgeParent = maintenant.year - _dateNaissanceParent!.year;
    if (maintenant.month < _dateNaissanceParent!.month ||
        (maintenant.month == _dateNaissanceParent!.month &&
            maintenant.day < _dateNaissanceParent!.day)) {
      _clientAgeParent = (_clientAgeParent ?? 0) - 1;
    }
    if (_clientAgeParent == null ||
        _clientAgeParent! < 18 ||
        _clientAgeParent! > 60) {
      _showErrorSnackBar(
          'Âge du souscripteur non valide (18-60 ans requis). Âge calculé: ${_clientAgeParent ?? 0} ans');
      return false;
    }
    if (_clientEmailController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir l\'email du client');
      return false;
    }
    if (_clientTelephoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le téléphone du client');
      return false;
    }
    // Utiliser l'âge du client pour le calcul
    _calculatedAgeParent = _clientAgeParent;
    return true;
  }

  bool _validateStep1() {
    // Si c'est un client, valider son propre âge
    if (!_isCommercial) {
      // Si c'est un client, valider son propre âge seulement à l'étape 2
      // À l'étape 1, on ne valide pas l'âge car il sera calculé automatiquement
      if (_currentStep == 1) {
        if (_calculatedAgeParent == null || _calculatedAgeParent! <= 0) {
          _showErrorSnackBar(
              'Veuillez renseigner la date de naissance du souscripteur dans votre profil');
          return false;
        }

        if (_calculatedAgeParent! < 18 || _calculatedAgeParent! > 60) {
          _showErrorSnackBar(
              'L\'âge du souscripteur doit être compris entre 18 et 60 ans pour ce produit. Âge calculé: ${_calculatedAgeParent} ans');
          return false;
        }
      }
    }

    // Valider les champs de souscription
    if (_dureeController.text.trim().isEmpty ||
        _montantController.text.trim().isEmpty ||
        _selectedPeriodicite == null ||
        _dateEffetContrat == null) {
      _showErrorSnackBar(
          'Veuillez compléter tous les champs obligatoires avant de continuer.');
      return false;
    }

    final age = int.tryParse(_dureeController.text);
    if (age == null || age < 0 || age > 17) {
      _showErrorSnackBar(
          'L\'âge de l\'enfant doit être compris entre 0 et 17 ans.');
      return false;
    }

    final montant =
        double.tryParse(_montantController.text.replaceAll(' ', ''));
    if (montant == null || montant <= 0) {
      _showErrorSnackBar(
          'Le montant saisi est invalide. Veuillez entrer un montant positif.');
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    if (_beneficiaireNomController.text.trim().isEmpty ||
        _beneficiaireContactController.text.trim().isEmpty ||
        _personneContactNomController.text.trim().isEmpty ||
        _personneContactTelController.text.trim().isEmpty) {
      _showErrorSnackBar(
          'Veuillez renseigner tous les contacts et informations de bénéficiaire.');
      return false;
    }

    if (_pieceIdentite == null) {
      _showErrorSnackBar(
          'Le téléchargement d\'une pièce d\'identité est obligatoire pour continuer.');
      return false;
    }

    // Validation des numéros de téléphone
    if (!RegExp(r'^[0-9]{8,15}$')
        .hasMatch(_beneficiaireContactController.text)) {
      _showErrorSnackBar(
          'Le numéro du bénéficiaire semble invalide. Veuillez vérifier.');
      return false;
    }

    if (!RegExp(r'^[0-9]{8,15}$')
        .hasMatch(_personneContactTelController.text)) {
      _showErrorSnackBar(
          'Le numéro de contact d\'urgence semble invalide. Veuillez vérifier.');
      return false;
    }

    return true;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: vertSucces,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: blanc, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Succès',
                      style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: blanc,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPaymentOptions() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(
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

  /// Sauvegarde les données de souscription
  /// Si c'est une souscription commerciale, utilise le client_id du client
  /// Sinon, utilise l'ID de l'utilisateur connecté
  /// Si subscriptionId existe, met à jour la souscription existante
  Future<int> _saveSubscriptionData() async {
    try {
      final subscriptionService = SubscriptionService();

      // Calculer la durée en mois (jusqu'à 17 ans)
      final ageEnfant = int.tryParse(_dureeController.text) ?? 0;
      final dureeMois = ((17 - ageEnfant) * 12).round();

      // Préparer les données de souscription
      final subscriptionData = {
        'product_type': 'coris_etude',
        'duree_mois': dureeMois,
        'montant':
            double.parse(_montantController.text.replaceAll(' ', '')).toInt(),
        'periodicite': _selectedPeriodicite?.toLowerCase(),
        'mode_souscription':
            _selectedMode.toLowerCase().replaceAll('mode ', ''),
        'prime_calculee': _primeCalculee.toInt(),
        'rente_calculee': _renteCalculee.toInt(),
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
        'profession': _professionController.text.trim(),
        'date_effet': _dateEffetContrat?.toIso8601String(),
        'date_echeance': _dateEcheanceContrat?.toIso8601String(),
        'piece_identite': _pieceIdentite?.path.split('/').last ?? '',
        'age_enfant': ageEnfant,
        'age_souscripteur': _calculatedAgeParent,
        'age_parent': _calculatedAgeParent,
        'date_naissance_parent':
            _dateNaissanceParent?.toIso8601String().split('T').first,
      };

      // Si c'est un commercial, ajouter les infos client
      if (_isCommercial) {
        subscriptionData['client_info'] = {
          'nom': _clientNomController.text.trim(),
          'prenom': _clientPrenomController.text.trim(),
          'date_naissance':
              _dateNaissanceParent?.toIso8601String().split('T').first,
          'lieu_naissance': _clientLieuNaissanceController.text.trim(),
          'telephone':
              '$_selectedClientIndicatif ${_clientTelephoneController.text.trim()}',
          'email': _clientEmailController.text.trim(),
          'adresse': _clientAdresseController.text.trim(),
          'civilite': _selectedClientCivilite,
          'numero_piece_identite': _clientNumeroPieceController.text.trim(),
        };
      }

      // Si on modifie une proposition existante, mettre à jour au lieu de créer
      final http.Response response;
      if (widget.subscriptionId != null) {
        response = await subscriptionService.updateSubscription(
          widget.subscriptionId!,
          subscriptionData,
        );
      } else {
        response =
            await subscriptionService.createSubscription(subscriptionData);
      }

      final responseData = jsonDecode(response.body);

      if ((widget.subscriptionId != null && response.statusCode != 200) ||
          (widget.subscriptionId == null && response.statusCode != 201) ||
          !responseData['success']) {
        throw Exception(
            responseData['message'] ?? 'Erreur lors de la sauvegarde');
      }

      // RETOURNEZ l'ID de la souscription (créée ou mise à jour)
      return widget.subscriptionId ?? responseData['data']['id'];
    } catch (e) {
      rethrow; // Correction: utiliser rethrow au lieu de throw
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
      rethrow; // Correction: utiliser rethrow au lieu de throw
    }
  }

  Future<bool> _simulatePayment(String paymentMethod) async {
    // Simulation d'un délai de paiement
    await Future.delayed(const Duration(seconds: 2));

    // Pour la démo, retournez true pour succès, false pour échec
    return true; // Changez en false pour tester l'échec
  }

  void _processPayment(String paymentMethod) async {
    // Éviter les soumissions multiples
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(paymentMethod: paymentMethod),
    );

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
        Navigator.pop(context);
      }

      if (paymentSuccess) {
        _showSuccessDialog(true);
      } else {
        _showErrorSnackBar(
            'Paiement échoué. Votre proposition a été sauvegardée.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('Erreur lors du traitement: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
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

      _showSuccessDialog(false);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Upload le document pièce d'identité vers le serveur
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
    }
  }

  void _showSuccessDialog(bool isPaid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(isPaid: isPaid),
    );
  }

  void _selectDateEffet() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('fr', 'FR'),
      initialDatePickerMode: DatePickerMode.day,
    );

    if (picked != null && mounted) {
      setState(() {
        _dateEffetContrat = picked;
        _dateEffetController.text = DateFormat('dd/MM/yyyy').format(picked);
        _updateEcheanceDate();
      });
    }
  }

  void _updateEcheanceDate() {
    if (_dureeController.text.isNotEmpty && _dateEffetContrat != null) {
      final ageEnfant = int.tryParse(_dureeController.text) ?? 0;
      // La durée du contrat est de 17 - âge de l'enfant
      final dureeContratAnnees = 17 - ageEnfant;
      setState(() {
        _dateEcheanceContrat = DateTime(
          _dateEffetContrat!.year + dureeContratAnnees,
          _dateEffetContrat!.month,
          _dateEffetContrat!.day,
        );
      });
    }
  }

  double _convertToMensuel(double valeur, String periodicite) {
    if (valeur <= 0) return 0;

    // Convertir en minuscules pour la comparaison
    String periodiciteLower = periodicite.toLowerCase();

    switch (periodiciteLower) {
      case 'trimestriel':
        double primeAnnuelle = (valeur * 4) / 1.03;
        return (primeAnnuelle * 1.04) / 12;
      case 'semestriel':
        double primeAnnuelle = (valeur * 2) / 1.02;
        return (primeAnnuelle * 1.04) / 12;
      case 'annuel':
        return (valeur * 1.04) / 12;
      case 'mensuel':
      default:
        return valeur;
    }
  }

  double _convertFromMensuel(double primeMensuelle, String periodicite) {
    if (primeMensuelle <= 0) return 0;

    // Convertir en minuscules pour la comparaison
    String periodiciteLower = periodicite.toLowerCase();

    switch (periodiciteLower) {
      case 'trimestriel':
        double primeAnnuelle = (primeMensuelle * 12) / 1.04;
        return (primeAnnuelle * 1.03) / 4;
      case 'semestriel':
        double primeAnnuelle = (primeMensuelle * 12) / 1.04;
        return (primeAnnuelle * 1.02) / 2;
      case 'annuel':
        return (primeMensuelle * 12) / 1.04;
      case 'mensuel':
      default:
        return primeMensuelle;
    }
  }

  double _calculateRente(int age, int dureeMois, double primeMensuelle) {
    if (!tarifRenteFixe.containsKey(age)) {
      return 0;
    }

    int dureeEffective = _closestDuree(dureeMois);

    if (!tarifRenteFixe[age]!.containsKey(dureeEffective)) {
      return 0;
    }
    double primeMensuelleBase = tarifRenteFixe[age]![dureeEffective]!;

    double rente = (primeMensuelle * 10000) / primeMensuelleBase;

    return rente;
  }

  double _calculatePrime(int age, int dureeMois, double renteSouhaitee) {
    if (!tarifRenteFixe.containsKey(age)) {
      return 0;
    }

    int dureeEffective = _closestDuree(dureeMois);

    if (!tarifRenteFixe[age]!.containsKey(dureeEffective)) {
      return 0;
    }
    double primeMensuelleBase = tarifRenteFixe[age]![dureeEffective]!;

    double primeMensuelle = (renteSouhaitee * primeMensuelleBase) / 10000;

    return primeMensuelle;
  }

  void _recalculerValeurs() {
    // Vérifier que toutes les données nécessaires sont disponibles
    if (_calculatedAgeParent == null ||
        _dureeController.text.isEmpty ||
        _montantController.text.isEmpty ||
        _selectedPeriodicite == null) {
      _primeCalculee = 0;
      _renteCalculee = 0;
      return;
    }
    try {
      // Nettoyer le montant (supprimer les espaces)
      final montantText = _montantController.text.replaceAll(' ', '');
      final montant = double.parse(montantText);

      // Calculer la durée en mois (jusqu'à 17 ans)
      final ageEnfant = int.parse(_dureeController.text);
      final dureeMois = ((17 - ageEnfant) * 12).round();
      final dureeEffective = _closestDuree(dureeMois);

      // Déterminer le mode de calcul en fonction de _selectedMode
      if (_selectedMode == 'Mode Prime') {
        // Mode Prime: calculer la rente correspondante
        double primeMensuelle =
            _convertToMensuel(montant, _selectedPeriodicite!);

        _renteCalculee = _calculateRente(
            _calculatedAgeParent!, dureeEffective, primeMensuelle);
        _primeCalculee = montant;
      } else {
        // Mode Rente: calculer la prime correspondante
        double primeMensuelle =
            _calculatePrime(_calculatedAgeParent!, dureeEffective, montant);

        _primeCalculee =
            _convertFromMensuel(primeMensuelle, _selectedPeriodicite!);
        _renteCalculee = montant;
      }

      // Forcer la mise à jour de l'interface
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // En cas d'erreur, mettre les valeurs à 0
      _primeCalculee = 0;
      _renteCalculee = 0;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grisLeger,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: bleuCoris,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [bleuCoris, bleuSecondaire],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_outlined,
                                  color: blanc, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'CORIS ÉTUDE',
                                style: TextStyle(
                                  color: blanc,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Préparez l\'avenir éducatif de vos enfants',
                            style: TextStyle(
                              color: blanc
                                  .withAlpha(230), // .withOpacity(0.9) remplacé
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: blanc),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16),
                child: _buildModernProgressIndicator(),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: _isCommercial
                    ? [
                        _buildStepClientInfo(), // Page 0: Informations client (commercial uniquement)
                        _buildStep1(), // Page 1: Paramètres de souscription
                        _buildStep2(), // Page 2: Bénéficiaire/Contact
                        _buildStep3(), // Page 3: Récapitulatif
                        _buildStep4(), // Page 4: Paiement
                      ]
                    : [
                        _buildStep1(), // Page 0: Paramètres de souscription
                        _buildStep2(), // Page 1: Bénéficiaire/Contact
                        _buildStep3(), // Page 2: Récapitulatif
                        _buildStep4(), // Page 3: Paiement
                      ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8), // .withOpacity(0.03) remplacé
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < (_isCommercial ? 5 : 4); i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: i <= _currentStep ? bleuCoris : grisLeger,
                      shape: BoxShape.circle,
                      boxShadow: i <= _currentStep
                          ? [
                              BoxShadow(
                                color: bleuCoris.withAlpha(
                                    51), // .withOpacity(0.2) remplacé
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isCommercial
                          ? (i == 0
                              ? Icons.person
                              : i == 1
                                  ? Icons.account_balance_wallet
                                  : i == 2
                                      ? Icons.person_add
                                      : i == 3
                                          ? Icons.check_circle
                                          : Icons.payment)
                          : (i == 0
                              ? Icons.account_balance_wallet
                              : i == 1
                                  ? Icons.person_add
                                  : i == 2
                                      ? Icons.check_circle
                                      : Icons.payment),
                      color: i <= _currentStep ? blanc : grisTexte,
                      size: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _isCommercial
                        ? (i == 0
                            ? 'Client'
                            : i == 1
                                ? 'Souscription'
                                : i == 2
                                    ? 'Infos'
                                    : i == 3
                                        ? 'Recap'
                                        : 'Paie')
                        : (i == 0
                            ? 'Souscription'
                            : i == 1
                                ? 'Infos'
                                : i == 2
                                    ? 'Recap'
                                    : 'Paie'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          i <= _currentStep ? FontWeight.w600 : FontWeight.w400,
                      color: i <= _currentStep ? bleuCoris : grisTexte,
                    ),
                  ),
                ],
              ),
            ),
            if (i < (_isCommercial ? 4 : 3))
              Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(bottom: 15, left: 4, right: 4),
                  decoration: BoxDecoration(
                    color: i < _currentStep ? bleuCoris : grisLeger,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Page séparée pour les informations client (uniquement pour les commerciaux)
  Widget _buildStepClientInfo() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Form(
                key: _formKeyClientInfo,
                child: ListView(
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
                          label: 'Date de naissance du souscripteur',
                          icon: Icons.calendar_today,
                          onDateSelected: (date) {
                            setState(() {
                              _dateNaissanceParent = date;
                              _clientDateNaissanceController.text =
                                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                              // Calculer l'âge du parent
                              final maintenant = DateTime.now();
                              _clientAgeParent = maintenant.year - date.year;
                              if (maintenant.month < date.month ||
                                  (maintenant.month == date.month &&
                                      maintenant.day < date.day)) {
                                _clientAgeParent = (_clientAgeParent ?? 0) - 1;
                              }
                              _calculatedAgeParent = _clientAgeParent;
                              _recalculerValeurs();
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
                              _selectedClientIndicatif = value;
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Form(
                key: _formKeyStep1,
                child: ListView(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: blanc,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withAlpha(10), // .withOpacity(0.04) remplacé
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Souscrire à CORIS ÉTUDE",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: bleuCoris,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildModeDropdown(),
                          const SizedBox(height: 16),
                          _buildDateNaissanceParentField(),
                          const SizedBox(height: 16),
                          _buildAgeEnfantField(),
                          const SizedBox(height: 16),
                          _buildPeriodiciteDropdown(),
                          const SizedBox(height: 16),
                          _buildMontantField(),
                          const SizedBox(height: 16),
                          _buildDateEffetField(),
                          SizedBox(height: 16),
                          if (_calculatedAgeParent != null)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: vertSucces.withAlpha(
                                    26), // .withOpacity(0.1) remplacé
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Résultats Calculés :',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: vertSucces)),
                                  SizedBox(height: 8),
                                  Text(
                                      'Prime : ${_formatMontant(_primeCalculee)}'),
                                  Text(
                                      'Rente : ${_formatMontant(_renteCalculee)}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // .withOpacity(0.1) remplacé
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: _selectedMode,
          decoration: const InputDecoration(
            border: InputBorder.none,
            labelText: 'Quel montant souhaitez-vous saisir ?',
          ),
          items: const [
            DropdownMenuItem(
              value: 'Mode Prime',
              child: Text('Saisir la prime'),
            ),
            DropdownMenuItem(
              value: 'Mode Rente',
              child: Text('Saisir la rente'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMode = value;
                _recalculerValeurs();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateNaissanceParentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _dateNaissanceParentController,
              readOnly: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'Date de naissance du parent *',
                labelStyle: TextStyle(color: grisTexte),
                prefixIcon: Icon(Icons.calendar_today, color: bleuCoris),
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(1980),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now(),
                  locale: const Locale('fr', 'FR'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: bleuCoris,
                          onPrimary: Colors.white,
                          onSurface: bleuCoris,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _dateNaissanceParent = picked;
                    _dateNaissanceParentController.text =
                        DateFormat('dd/MM/yyyy').format(picked);
                    // Calculer l'âge du parent
                    final now = DateTime.now();
                    int age = now.year - picked.year;
                    if (now.month < picked.month ||
                        (now.month == picked.month && now.day < picked.day)) {
                      age--;
                    }
                    _calculatedAgeParent = age;
                    _recalculerValeurs();
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La date de naissance du parent est obligatoire';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeEnfantField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Âge de l\'enfant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _dureeController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _updateEcheanceDate();
            _recalculerValeurs();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'L\'âge est obligatoire';
            }
            final age = int.tryParse(value);
            if (age == null || age < 0 || age > 17) {
              return 'L\'âge doit être entre 0 et 17 ans';
            }
            return null;
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: 'saisissez l\'age de votre enfant',
            prefixIcon: Icon(Icons.child_care,
                size: 20,
                color: bleuCoris.withAlpha(179)), // .withOpacity(0.7) remplacé
            filled: true,
            fillColor: bleuClair.withAlpha(77), // .withOpacity(0.3) remplacé
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: bleuCoris, width: 1.5),
            ),
            errorStyle: TextStyle(fontSize: 12),
          ),
        ),
        if (_dureeController.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Durée du contrat: ${(18 - (int.tryParse(_dureeController.text) ?? 0))} ans (jusqu\'\u00e0 18 ans)',
              style: TextStyle(
                color: bleuCoris,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodiciteDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // .withOpacity(0.1) remplacé
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: _selectedPeriodicite,
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF002B6B)),
            labelText: 'Périodicité',
          ),
          items: _periodiciteOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPeriodicite = value;
              _recalculerValeurs();
            });
          },
        ),
      ),
    );
  }

  Widget _buildMontantField() {
    String label = _selectedMode == 'Mode Rente'
        ? 'Rente au terme'
        : 'Prime $_selectedPeriodicite';
    String hint = _selectedMode == 'Mode Rente'
        ? 'Montant de la rente en FCFA'
        : 'Montant de la prime en FCFA';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _montantController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // Recalculer uniquement quand l'utilisateur arrête de taper
            _recalculerValeurs();
          },
          onEditingComplete: () {
            // Formater seulement après la saisie
            _formatMontantInput();
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: hint,
            prefixIcon: Icon(Icons.monetization_on,
                size: 20,
                color: bleuCoris.withAlpha(179)), // .withOpacity(0.7) remplacé
            suffixText: 'CFA',
            filled: true,
            fillColor: bleuClair.withAlpha(77), // .withOpacity(0.3) remplacé
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: bleuCoris, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateEffetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date d\'effet du contrat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: _selectDateEffet,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _dateEffetController,
              decoration: InputDecoration(
                hintText: 'JJ/MM/AAAA',
                prefixIcon: Container(
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        bleuCoris.withAlpha(26), // .withOpacity(0.1) remplacé
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, color: bleuCoris, size: 20),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Form(
                key: _formKeyStep2,
                child: ListView(
                  children: [
                    _buildFormSection(
                      'Bénéficiaire en cas de décès',
                      Icons.family_restroom,
                      [
                        _buildModernTextField(
                          controller: _beneficiaireNomController,
                          label: 'Nom complet du bénéficiaire',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 16),
                        // MODIFICATION ICI - Champ avec indicatif
                        _buildPhoneFieldWithIndicatif(
                          controller: _beneficiaireContactController,
                          label: 'Contact du bénéficiaire',
                          selectedIndicatif: _selectedBeneficiaireIndicatif,
                          onIndicatifChanged: (value) {
                            setState(() {
                              _selectedBeneficiaireIndicatif = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),
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
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildFormSection(
                      'Contact d\'urgence',
                      Icons.contact_phone,
                      [
                        _buildModernTextField(
                          controller: _personneContactNomController,
                          label: 'Nom complet',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 16),
                        // MODIFICATION ICI - Champ avec indicatif
                        _buildPhoneFieldWithIndicatif(
                          controller: _personneContactTelController,
                          label: 'Contact téléphonique',
                          selectedIndicatif: _selectedContactIndicatif,
                          onIndicatifChanged: (value) {
                            setState(() {
                              _selectedContactIndicatif = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),
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
                    SizedBox(height: 20),
                    _buildDocumentUploadSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneFieldWithIndicatif({
    required TextEditingController controller,
    required String label,
    required String selectedIndicatif,
    required ValueChanged<String> onIndicatifChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
        Row(
          children: [
            // Dropdown pour l'indicatif (plus petit et discret)
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: fondCarte,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: grisLeger),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedIndicatif,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, size: 20, color: bleuCoris),
                  items: _indicatifOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['code'],
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          option['code']!,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onIndicatifChanged(value);
                    }
                  },
                ),
              ),
            ),
            SizedBox(width: 8),
            // Champ de texte pour le numéro
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Numéro de téléphone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: grisLeger),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: grisLeger),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: bleuCoris, width: 1.5),
                  ),
                  filled: true,
                  fillColor: fondCarte,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le numéro de téléphone est obligatoire';
                  }
                  if (!RegExp(r'^[0-9]{8,15}$').hasMatch(value)) {
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

  Widget _buildFormSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // .withOpacity(0.05) remplacé
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: bleuCoris, size: 20),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: bleuCoris,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bleuCoris.withAlpha(26), // .withOpacity(0.1) remplacé
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: bleuCoris, size: 20),
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
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(Duration(days: 365 * 30)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: bleuCoris,
                      onPrimary: blanc,
                    ),
                    dialogTheme: DialogThemeData(
                      backgroundColor: blanc,
                    ),
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
                labelText: label,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bleuCoris.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: bleuCoris, size: 20),
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
                suffixIcon: Icon(Icons.calendar_today, color: bleuCoris),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est obligatoire';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bleuCoris.withAlpha(26), // .withOpacity(0.1) remplacé
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: bleuCoris, size: 20),
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
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentUploadSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // .withOpacity(0.05) remplacé
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner, color: bleuCoris, size: 20),
              SizedBox(width: 12),
              Text(
                'Pièce d\'identité',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: bleuCoris,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDocument,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _pieceIdentite != null
                    ? vertSucces.withAlpha(26) // .withOpacity(0.1) remplacé
                    : bleuCoris.withAlpha(13), // .withOpacity(0.05) remplacé
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pieceIdentite != null
                      ? vertSucces
                      : bleuCoris.withAlpha(77), // .withOpacity(0.3) remplacé
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      _pieceIdentite != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      size: 40,
                      color: _pieceIdentite != null ? vertSucces : bleuCoris,
                      key: ValueKey(_pieceIdentite != null),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _pieceIdentite != null
                        ? 'Document ajouté avec succès'
                        : 'Télécharger votre pièce d\'identité',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _pieceIdentite != null ? vertSucces : bleuCoris,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _pieceIdentite != null
                        ? _pieceIdentite!.path.split('/').last
                        : 'Formats acceptés: PDF, JPG, PNG (Max: 5MB)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: grisTexte,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _isCommercial
                  ? _buildRecapContent()
                  : FutureBuilder<Map<String, dynamic>>(
                      future: _loadUserDataForRecap(),
                      builder: (context, snapshot) {
                        // Pour les clients, attendre le chargement des données
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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

                        // Pour les clients, utiliser les données chargées depuis la base de données
                        final userData = snapshot.data ?? _userData;

                        // Si userData est vide, recharger les données
                        if (userData.isEmpty && !_isCommercial) {
                          _loadUserDataForRecap().then((data) {
                            if (mounted && data.isNotEmpty) {
                              setState(() {
                                _userData = data;
                              });
                            }
                          });
                          return Center(
                              child:
                                  CircularProgressIndicator(color: bleuCoris));
                        }

                        return _buildRecapContent(userData: userData);
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecapContent({Map<String, dynamic>? userData}) {
    // S'assurer que les calculs sont effectués avant d'afficher
    if (_primeCalculee == 0 || _renteCalculee == 0) {
      _recalculerValeurs();
    }

    final primeDisplay = _primeCalculee;
    final renteDisplay = _renteCalculee;
    final duree = int.tryParse(_dureeController.text) ?? 0;

    /**
     * CONSTRUCTION DU RÉCAPITULATIF:
     * 
     * - Si _isCommercial = true: Utiliser les données des contrôleurs (infos client saisies par le commercial)
     * - Si _isCommercial = false: Utiliser userData (infos du client connecté depuis la base de données)
     */
    final displayData = _isCommercial
        ? {
            'civilite': _selectedClientCivilite,
            'nom': _clientNomController.text,
            'prenom': _clientPrenomController.text,
            'email': _clientEmailController.text,
            'telephone':
                '$_selectedClientIndicatif ${_clientTelephoneController.text}',
            'date_naissance': _dateNaissanceParent?.toIso8601String(),
            'lieu_naissance': _clientLieuNaissanceController.text,
            'adresse': _clientAdresseController.text,
          }
        : (userData ?? {});

    return ListView(
      children: [
        // Afficher les informations du client (toujours dans "Informations Personnelles")
        SubscriptionRecapWidgets.buildPersonalInfoSection(displayData),

        const SizedBox(height: 20),

        SubscriptionRecapWidgets.buildRecapSection(
          'Produit Souscrit',
          Icons.school,
          vertSucces,
          [
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Produit', 'CORIS ÉTUDE', 'Mode', _selectedMode),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Âge du parent',
                _calculatedAgeParent != null
                    ? '$_calculatedAgeParent ans'
                    : 'Non renseigné',
                'Date de naissance',
                _dateNaissanceParent != null
                    ? '${_dateNaissanceParent!.day.toString().padLeft(2, '0')}/${_dateNaissanceParent!.month.toString().padLeft(2, '0')}/${_dateNaissanceParent!.year}'
                    : 'Non renseigné'),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Cotisation ${_selectedPeriodicite ?? "Mensuel"}',
                _formatMontant(primeDisplay),
                'Rente au terme',
                _formatMontant(renteDisplay)),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Durée du contrat',
                '${17 - duree} ans (jusqu\'à 17 ans)',
                'Périodicité',
                _selectedPeriodicite ?? 'Mensuel'),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Date d\'effet',
                _dateEffetContrat != null
                    ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                    : 'Non définie',
                'Date d\'échéance',
                _dateEcheanceContrat != null
                    ? '${_dateEcheanceContrat!.day}/${_dateEcheanceContrat!.month}/${_dateEcheanceContrat!.year}'
                    : 'Non définie'),
          ],
        ),

        const SizedBox(height: 20),

        // SECTION PARAMÈTRES DE SOUSCRIPTION
        SubscriptionRecapWidgets.buildRecapSection(
          'Paramètres de Souscription',
          Icons.calculate,
          bleuSecondaire,
          [
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Mode',
                _selectedMode,
                'Périodicité',
                _selectedPeriodicite ?? 'Non sélectionnée'),
            SubscriptionRecapWidgets.buildRecapRow(
                'Date d\'effet',
                _dateEffetContrat != null
                    ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                    : 'Non définie'),
          ],
        ),

        const SizedBox(height: 20),

        // SECTION UNIQUE POUR BÉNÉFICIAIRE ET CONTACT D'URGENCE
        SubscriptionRecapWidgets.buildRecapSection(
          'Bénéficiaire et Contact d\'urgence',
          Icons.contacts,
          Colors.amber,
          [
            // Bénéficiaire
            SubscriptionRecapWidgets.buildSubsectionTitle(
                'Bénéficiaire en cas de décès'),
            const SizedBox(height: 8),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Nom complet',
                _beneficiaireNomController.text.isNotEmpty
                    ? _beneficiaireNomController.text
                    : 'Non renseigné',
                'Lien de parenté',
                _selectedLienParente),
            SubscriptionRecapWidgets.buildRecapRow(
                'Téléphone',
                _beneficiaireContactController.text.isNotEmpty
                    ? '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text}'
                    : 'Non renseigné'),

            const SizedBox(height: 16),

            // Contact d'urgence
            SubscriptionRecapWidgets.buildSubsectionTitle('Contact d\'urgence'),
            const SizedBox(height: 8),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Nom complet',
                _personneContactNomController.text.isNotEmpty
                    ? _personneContactNomController.text
                    : 'Non renseigné',
                'Lien de parenté',
                _selectedLienParenteUrgence),
            SubscriptionRecapWidgets.buildRecapRow(
                'Téléphone',
                _personneContactTelController.text.isNotEmpty
                    ? '$_selectedContactIndicatif ${_personneContactTelController.text}'
                    : 'Non renseigné'),
          ],
        ),

        const SizedBox(height: 20),

        SubscriptionRecapWidgets.buildDocumentsSection(
          pieceIdentite: _pieceIdentite?.path.split('/').last,
          onDocumentTap: _pieceIdentite != null
              ? () => _viewLocalDocument(
                  _pieceIdentite!, _pieceIdentite!.path.split('/').last)
              : null,
        ),

        const SizedBox(height: 20),

        SubscriptionRecapWidgets.buildVerificationWarning(),

        const SizedBox(height: 20),
      ],
    );
  }

  void _viewLocalDocument(File? documentFile, String fileName) {
    if (documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: blanc, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Document non disponible'),
              ),
            ],
          ),
          backgroundColor: orangeWarning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Ouvrir le viewer de documents avec le fichier local
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          localFile: documentFile,
          documentName: fileName,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: blanc,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // .withOpacity(0.05) remplacé
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: bleuCoris, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: bleuCoris, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Précédent',
                        style: TextStyle(
                          color: bleuCoris,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Déterminer l'étape finale selon si commercial ou pas
                  int finalStep = _isCommercial ? 3 : 2;

                  if (_currentStep == finalStep) {
                    // Depuis le récapitulatif: ouvrir directement les options de paiement
                    _showPaymentOptions();
                  } else if (_currentStep == finalStep + 1) {
                    // Étape paiement - ouvrir aussi les options de paiement
                    _showPaymentOptions();
                  } else {
                    // Autres étapes - avancer
                    _nextStep();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bleuCoris,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor:
                      bleuCoris.withAlpha(77), // .withOpacity(0.3) remplacé
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      () {
                        int finalStep = _isCommercial ? 3 : 2;
                        if (_currentStep == finalStep) {
                          return 'Finaliser';
                        } else if (_currentStep == finalStep + 1) {
                          return 'Payer maintenant';
                        } else {
                          return 'Suivant';
                        }
                      }(),
                      style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      () {
                        int finalStep = _isCommercial ? 3 : 2;
                        if (_currentStep == finalStep + 1) {
                          return Icons.payment;
                        } else {
                          return Icons.arrow_forward;
                        }
                      }(),
                      color: blanc,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Page étape 4: Paiement
  Widget _buildStep4() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bleuCoris,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.payment, color: blanc, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Finalisation du Paiement',
                          style: TextStyle(
                            color: blanc,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choisissez votre méthode de paiement',
                          style: TextStyle(
                            color: blanc.withAlpha(204),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Montant à payer
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: blanc,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: vertSucces,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: vertSucces.withAlpha(26),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant à payer',
                          style: TextStyle(
                            color: grisTexte,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatMontant(_primeCalculee),
                          style: TextStyle(
                            color: vertSucces,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Méthodes de paiement
                  Text(
                    'Méthodes de paiement disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: bleuCoris,
                    ),
                  ),
                  SizedBox(height: 12),
                  // Wave
                  _buildPaymentMethodCard(
                    icon: Icons.phone_android,
                    title: 'Wave',
                    description: 'Paiement par SMS',
                    onTap: () => _processPayment('Wave'),
                  ),
                  SizedBox(height: 12),
                  // Orange Money
                  _buildPaymentMethodCard(
                    icon: Icons.monetization_on,
                    title: 'Orange Money',
                    description: 'Portefeuille Orange Money',
                    onTap: () => _processPayment('Orange Money'),
                  ),
                  SizedBox(height: 12),
                  // Payer plus tard
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: orangeWarning.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: orangeWarning.withAlpha(128),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: orangeWarning, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payer plus tard',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: orangeWarning,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Enregistrez la proposition et payez ultérieurement',
                                style: TextStyle(
                                  color: grisTexte,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _processPayment('later');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeWarning,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: blanc,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Avertissement de sécurité
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Vos informations de paiement sont sécurisées et chiffrées.',
                            style: TextStyle(
                              fontSize: 12,
                              color: grisTexte,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Widget pour afficher les méthodes de paiement
  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: blanc,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: grisLeger,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bleuCoris.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: bleuCoris, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: bleuCoris,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: grisTexte,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: grisTexte, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final String paymentMethod;
  const _LoadingDialog({required this.paymentMethod});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26), // .withOpacity(0.1) remplacé
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Color(0xFF002B6B),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Traitement en cours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF002B6B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Paiement via $paymentMethod...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
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
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26), // .withOpacity(0.1) remplacé
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isPaid
                    ? Color(0xFF10B981).withAlpha(26)
                    : Color(0xFFF59E0B)
                        .withAlpha(26), // .withOpacity(0.1) remplacé
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.schedule,
                color: isPaid ? Color(0xFF10B981) : Color(0xFFF59E0B),
                size: 40,
              ),
            ),
            SizedBox(height: 20),
            Text(
              isPaid ? 'Souscription Réussie!' : 'Proposition Enregistrée!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF002B6B),
              ),
            ),
            SizedBox(height: 12),
            Text(
              isPaid
                  ? 'Félicitations! Votre contrat CORIS ÉTUDE est maintenant actif. Vous recevrez un email de confirmation sous peu.'
                  : 'Votre proposition a été enregistrée avec succès. Vous pouvez effectuer le paiement plus tard depuis votre espace client.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24),
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
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retour à l\'accueil',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBottomSheet extends StatelessWidget {
  final Function(String) onPayNow;
  final VoidCallback onPayLater;
  const _PaymentBottomSheet({
    required this.onPayNow,
    required this.onPayLater,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26), // .withOpacity(0.1) remplacé
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.payment, color: Color(0xFF002B6B), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Options de Paiement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF002B6B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildPaymentOption(
                'Wave',
                Icons.waves,
                Colors.blue,
                'Paiement mobile sécurisé',
                () => onPayNow('Wave'),
              ),
              SizedBox(height: 12),
              _buildPaymentOption(
                'Orange Money',
                Icons.phone_android,
                Colors.orange,
                'Paiement mobile Orange',
                () => onPayNow('Orange Money'),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPayLater,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF002B6B), width: 2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF002B6B)),
                      SizedBox(width: 8),
                      Text(
                        'Payer plus tard',
                        style: TextStyle(
                          color: Color(0xFF002B6B),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, Color color,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.grey.withAlpha(51)), // .withOpacity(0.2) remplacé
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26), // .withOpacity(0.1) remplacé
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
