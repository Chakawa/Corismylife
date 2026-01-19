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
import 'package:mycorislife/features/souscription/presentation/widgets/questionnaire_medical_dynamic_widget.dart';
import 'package:mycorislife/services/questionnaire_medical_service.dart';

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
  Future<bool> Function()? _questionnaireValidate;

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
  String? _pieceIdentiteLabel;
  // Variable pour éviter les soumissions multiples
  bool _isProcessing = false;
  
  // 🔒 Flag pour afficher le message du capital sous risque UNE SEULE FOIS
  bool _messageCapitalAffiche = false;

  // 💳 VARIABLES MODE DE PAIEMENT
  String? _selectedModePaiement; // 'Virement', 'Wave', 'Orange Money'
  String? _selectedBanque;
  final _banqueController = TextEditingController();
  final _codeGuichetController = TextEditingController();
  final _numeroCompteController = TextEditingController();
  final _cleRibController = TextEditingController();
  final _numeroMobileMoneyController = TextEditingController();
  final List<String> _modePaiementOptions = [
    'Virement',
    'Wave',
    'Orange Money'
  ];
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

  // 📋 QUESTIONNAIRE MÉDICAL
  List<Map<String, dynamic>> _questionnaireMedicalQuestions = [];  // ✅ Questions de la BD
  List<Map<String, dynamic>> _questionnaireMedicalReponses = [];   // Réponses locales ou de la BD

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
      60: 754.14414,
      72: 623.00430,
      84: 529.56774,
      96: 459.69355,
      108: 405.52705,
      120: 362.35555,
      132: 327.17978,
      144: 298.00048,
      156: 273.43316,
      168: 252.48867,
      180: 234.44293,
      192: 218.75365,
      204: 205.00714,
      216: 192.88096,
      228: 182.12121,
      240: 172.52453
    },
    19: {
      60: 754.44118,
      72: 623.29408,
      84: 529.85248,
      96: 459.97640,
      108: 405.81043,
      120: 362.64091,
      132: 327.46849,
      144: 298.29318,
      156: 273.73008,
      168: 252.79141,
      180: 234.75364,
      192: 219.07524,
      204: 205.34136,
      216: 193.23001,
      228: 182.48677,
      240: 172.90859
    },
    20: {
      60: 754.62253,
      72: 623.47572,
      84: 530.03702,
      96: 460.16576,
      108: 406.00550,
      120: 362.84262,
      132: 327.67704,
      144: 298.50840,
      156: 273.95338,
      168: 253.02487,
      180: 235.00020,
      192: 219.33659,
      204: 205.61968,
      216: 193.52694,
      228: 182.80427,
      240: 173.24887
    },
    21: {
      60: 754.74344,
      72: 623.60364,
      84: 530.17336,
      96: 460.31087,
      108: 406.15984,
      120: 363.00597,
      132: 327.84885,
      144: 298.68995,
      156: 274.14677,
      168: 253.23313,
      180: 235.22503,
      192: 219.58019,
      204: 205.88368,
      216: 193.81331,
      228: 183.11525,
      240: 173.58691
    },
    22: {
      60: 754.83986,
      72: 623.71194,
      84: 530.29314,
      96: 460.44202,
      108: 406.30172,
      120: 363.15763,
      132: 328.01149,
      144: 298.86573,
      156: 274.33891,
      168: 253.44338,
      180: 235.45565,
      192: 219.83282,
      204: 206.16031,
      216: 194.11626,
      228: 183.44704,
      240: 173.95072
    },
    23: {
      60: 754.94137,
      72: 623.82687,
      84: 530.42083,
      96: 460.58142,
      108: 406.45154,
      120: 363.31907,
      132: 328.18691,
      144: 299.05865,
      156: 274.55118,
      168: 253.67739,
      180: 235.71309,
      192: 220.11575,
      204: 206.47113,
      216: 194.45759,
      228: 183.82221,
      240: 174.36201
    },
    24: {
      60: 755.05990,
      72: 623.95910,
      84: 530.56529,
      96: 460.73649,
      108: 406.61849,
      120: 363.50060,
      132: 328.38693,
      144: 299.27920,
      156: 274.79480,
      168: 253.94583,
      180: 236.00849,
      192: 220.44061,
      204: 206.82819,
      216: 194.85035,
      228: 184.25303,
      240: 174.83334
    },
    25: {
      60: 755.19305,
      72: 624.10532,
      84: 530.72241,
      96: 460.90585,
      108: 406.80319,
      120: 363.70502,
      132: 328.61332,
      144: 299.53023,
      156: 275.07227,
      168: 254.25193,
      180: 236.34582,
      192: 220.81202,
      204: 207.23736,
      216: 195.29969,
      228: 184.74507,
      240: 175.37014
    },
    26: {
      60: 755.34348,
      72: 624.26647,
      84: 530.89583,
      96: 461.09526,
      108: 407.01363,
      120: 363.93899,
      132: 328.87362,
      144: 299.81871,
      156: 275.39117,
      168: 254.60395,
      180: 236.73392,
      192: 221.24005,
      204: 207.70781,
      216: 195.81515,
      228: 185.30763,
      240: 175.98167
    },
    27: {
      60: 755.49560,
      72: 624.43199,
      84: 531.07903,
      96: 461.30180,
      108: 407.24614,
      120: 364.20028,
      132: 329.16546,
      144: 300.14329,
      156: 275.75121,
      168: 255.00248,
      180: 237.17495,
      192: 221.72609,
      204: 208.24149,
      216: 196.39855,
      228: 185.94260,
      240: 176.66914
    },
    28: {
      60: 755.65006,
      72: 624.60678,
      84: 531.28041,
      96: 461.53239,
      108: 407.50857,
      120: 364.49610,
      132: 329.49671,
      144: 300.51266,
      156: 276.16176,
      168: 255.45834,
      180: 237.67864,
      192: 222.28027,
      204: 208.84819,
      216: 197.05959,
      228: 186.65882,
      240: 177.44052
    },
    29: {
      60: 755.81874,
      72: 624.80634,
      84: 531.51321,
      96: 461.80063,
      108: 407.81339,
      120: 364.83926,
      132: 329.88082,
      144: 300.94077,
      156: 276.63815,
      168: 255.98554,
      180: 238.25927,
      192: 222.91634,
      204: 209.54145,
      216: 197.81076,
      228: 187.46772,
      240: 178.30659
    },
    30: {
      60: 756.01218,
      72: 625.03913,
      84: 531.78633,
      96: 462.11434,
      108: 408.16893,
      120: 365.23900,
      132: 330.32773,
      144: 301.43923,
      156: 277.19064,
      168: 256.59463,
      180: 238.92690,
      192: 223.64416,
      204: 210.33004,
      216: 198.65973,
      228: 188.37630,
      240: 179.27396
    },
    31: {
      60: 756.25634,
      72: 625.32902,
      84: 532.12089,
      96: 462.49403,
      108: 408.59584,
      120: 365.71606,
      132: 330.85946,
      144: 302.02809,
      156: 277.83917,
      168: 257.30469,
      180: 239.70005,
      192: 224.48082,
      204: 211.22962,
      216: 199.62124,
      228: 189.39873,
      240: 180.35629
    },
    32: {
      60: 756.58345,
      72: 625.70344,
      84: 532.54241,
      96: 462.96471,
      108: 409.11877,
      120: 366.29611,
      132: 331.49924,
      144: 302.73017,
      156: 278.60537,
      168: 258.13655,
      180: 240.59785,
      192: 225.44377,
      204: 212.25652,
      216: 200.71091,
      228: 190.55000,
      240: 181.56895
    },
    33: {
      60: 756.98516,
      72: 626.15492,
      84: 533.04549,
      96: 463.52261,
      108: 409.73674,
      120: 366.97683,
      132: 332.24524,
      144: 303.54320,
      156: 279.48688,
      168: 259.08662,
      180: 241.61544,
      192: 226.52742,
      204: 213.40482,
      216: 201.92253,
      228: 191.82464,
      240: 182.90662
    },
    34: {
      60: 757.45235,
      72: 626.67731,
      84: 533.62620,
      96: 464.16718,
      108: 410.44778,
      120: 367.75673,
      132: 333.09554,
      144: 304.46515,
      156: 280.48028,
      168: 260.15010,
      180: 242.74720,
      192: 227.72578,
      204: 214.66824,
      216: 203.25063,
      228: 193.21739,
      240: 184.36413
    },
    35: {
      60: 757.96165,
      72: 627.25233,
      84: 534.27180,
      96: 464.88524,
      108: 411.23998,
      120: 368.62400,
      132: 334.03866,
      144: 305.48342,
      156: 281.57179,
      168: 261.31256,
      180: 243.97856,
      192: 229.02419,
      204: 216.03320,
      216: 204.68203,
      228: 194.71533,
      240: 185.92925
    },
    36: {
      60: 758.54229,
      72: 627.91103,
      84: 535.00930,
      96: 465.70219,
      108: 412.13655,
      120: 369.60039,
      132: 335.09360,
      144: 306.61439,
      156: 282.77598,
      168: 262.58752,
      180: 245.32217,
      192: 230.43584,
      204: 217.51274,
      216: 206.22958,
      228: 196.33159,
      240: 187.61471
    },
    37: {
      60: 759.19812,
      72: 628.65526,
      84: 535.84026,
      96: 466.61855,
      108: 413.13750,
      120: 370.68378,
      132: 336.25608,
      144: 307.85248,
      156: 284.08674,
      168: 263.96848,
      180: 246.77257,
      192: 231.95554,
      204: 219.10187,
      216: 207.88891,
      228: 198.06168,
      240: 189.41615
    },
    38: {
      60: 759.95625,
      72: 629.50835,
      84: 536.78471,
      96: 467.65217,
      108: 414.25707,
      120: 371.88500,
      132: 337.53471,
      144: 309.20508,
      156: 285.51051,
      168: 265.46261,
      180: 248.33696,
      192: 233.59037,
      204: 220.80808,
      216: 209.66717,
      228: 199.91268,
      240: 191.34578
    },
    39: {
      60: 760.82476,
      72: 630.47558,
      84: 537.84620,
      96: 468.80320,
      108: 415.49211,
      120: 373.19891,
      132: 338.92350,
      144: 310.66563,
      156: 287.04197,
      168: 267.06497,
      180: 250.01056,
      192: 235.33633,
      204: 222.62722,
      216: 211.56033,
      228: 201.88628,
      240: 193.40618
    },
    40: {
      60: 761.80024,
      72: 631.55203,
      84: 539.01649,
      96: 470.06004,
      108: 416.82918,
      120: 374.61153,
      132: 340.40820,
      144: 312.22156,
      156: 288.66928,
      168: 268.76418,
      180: 251.78302,
      192: 237.18307,
      204: 224.54923,
      216: 213.56464,
      228: 203.97983,
      240: 195.59953
    },
    41: {
      60: 762.87390,
      72: 632.72542,
      84: 540.27956,
      96: 471.40480,
      108: 418.25007,
      120: 376.10466,
      132: 341.97275,
      144: 313.85789,
      156: 290.37816,
      168: 270.54723,
      180: 253.64149,
      192: 239.11815,
      204: 226.56860,
      216: 215.67589,
      228: 206.19441,
      240: 197.92507
    },
    42: {
      60: 764.00204,
      72: 633.95111,
      84: 541.59125,
      96: 472.79510,
      108: 419.71414,
      120: 377.64145,
      132: 343.58267,
      144: 315.54183,
      156: 292.13796,
      168: 272.38429,
      180: 255.55712,
      192: 241.12067,
      204: 228.66629,
      216: 217.88112,
      228: 208.51539,
      240: 200.37361
    },
    43: {
      60: 765.18831,
      72: 635.22844,
      84: 542.94959,
      96: 474.22844,
      108: 421.22120,
      120: 379.22281,
      132: 345.23943,
      144: 317.27609,
      156: 293.95131,
      168: 274.27818,
      180: 257.54062,
      192: 243.20286,
      204: 230.86054,
      216: 220.19629,
      228: 210.96411,
      240: 202.96470
    },
    44: {
      60: 766.40319,
      72: 636.52938,
      84: 544.32834,
      96: 475.68307,
      108: 422.75229,
      120: 380.83153,
      132: 346.92807,
      144: 319.04636,
      156: 295.80471,
      168: 276.22456,
      180: 259.58987,
      192: 245.36944,
      204: 233.15398,
      216: 222.63005,
      228: 213.54752,
      240: 205.70505
    },
    45: {
      60: 767.62545,
      72: 637.83478,
      84: 545.71347,
      96: 477.14814,
      108: 424.29834,
      120: 382.46088,
      132: 348.64239,
      144: 320.84709,
      156: 297.70250,
      168: 278.23016,
      180: 261.71892,
      192: 247.63213,
      204: 235.56463,
      216: 225.19847,
      228: 216.28127,
      240: 208.61545
    },
    46: {
      60: 768.82504,
      72: 639.12254,
      84: 547.08799,
      96: 478.60954,
      108: 425.84840,
      120: 384.10087,
      132: 350.37339,
      144: 322.68045,
      156: 299.64981,
      168: 280.30826,
      180: 263.93862,
      192: 250.00858,
      204: 238.10808,
      216: 227.91666,
      228: 219.18599,
      240: 211.71447
    },
    47: {
      60: 770.00504,
      72: 640.40022,
      84: 548.46115,
      96: 480.07865,
      108: 427.41383,
      120: 385.76294,
      132: 352.14409,
      144: 324.57224,
      156: 301.68079,
      168: 282.48987,
      180: 266.28683,
      192: 252.53403,
      204: 240.81860,
      216: 230.82446,
      228: 222.29901,
      240: 215.04010
    },
    48: {
      60: 771.19017,
      72: 641.69274,
      84: 549.85889,
      96: 481.58030,
      108: 429.01851,
      120: 387.48324,
      132: 353.99343,
      144: 326.57013,
      156: 303.83928,
      168: 284.82577,
      180: 268.81113,
      192: 255.25457,
      204: 243.74799,
      216: 233.97076,
      228: 225.66968,
      240: 218.63552
    },
    49: {
      60: 772.40787,
      72: 643.02793,
      84: 551.30723,
      96: 483.13897,
      108: 430.70056,
      120: 389.30320,
      132: 355.97234,
      144: 328.72068,
      156: 306.17912,
      168: 287.36616,
      180: 271.55982,
      192: 258.22452,
      204: 246.94731,
      216: 237.40697,
      228: 229.34267,
      240: 222.54810
    },
    50: {
      60: 773.68309,
      72: 644.42844,
      84: 552.82675,
      96: 484.79076,
      108: 432.50039,
      120: 391.27379,
      132: 358.12697,
      144: 331.07777,
      156: 308.75009,
      168: 290.15852,
      180: 274.58677,
      192: 261.49417,
      204: 250.46713,
      216: 241.17627,
      228: 233.36396,
      240: 226.82449
    },
    51: {
      60: 775.04468,
      72: 645.91914,
      84: 554.45962,
      96: 486.58304,
      108: 434.47672,
      120: 393.44799,
      132: 360.51814,
      144: 333.69735,
      156: 311.60512,
      168: 293.26235,
      180: 277.94741,
      192: 265.11896,
      204: 254.35468,
      216: 245.32869,
      228: 237.78419,
      240: 231.51657
    },
    52: {
      60: 776.48192,
      72: 647.51318,
      84: 556.22869,
      96: 488.55328,
      108: 436.66192,
      120: 395.86741,
      132: 363.18278,
      144: 336.61329,
      156: 314.78561,
      168: 296.71506,
      180: 281.67939,
      192: 269.12787,
      204: 258.64208,
      216: 249.89723,
      228: 242.63791,
      240: 236.66007
    },
    53: {
      60: 778.02042,
      72: 649.24900,
      84: 558.18821,
      96: 490.74912,
      108: 439.11252,
      120: 398.58262,
      132: 366.16705,
      144: 339.87937,
      156: 318.34055,
      168: 300.56538,
      180: 285.82155,
      192: 273.56270,
      204: 263.37190,
      216: 254.92600,
      228: 247.97035,
      240: 242.30066
    },
    54: {
      60: 779.71777,
      72: 651.20065,
      84: 560.40320,
      96: 493.24333,
      108: 441.89352,
      120: 401.65222,
      132: 369.53701,
      144: 343.55582,
      156: 322.32924,
      168: 304.86127,
      180: 290.42459,
      192: 278.47477,
      204: 268.59689,
      216: 260.46883,
      228: 253.83573,
      240: 248.49337
    },
    55: {
      60: 781.65253,
      72: 653.43579,
      84: 562.94807,
      96: 496.10102,
      108: 445.06162,
      120: 405.14069,
      132: 373.35060,
      144: 347.69915,
      156: 326.79546,
      168: 309.64922,
      180: 295.53563,
      192: 283.91277,
      204: 274.36698,
      216: 266.57606,
      228: 260.28530,
      240: 255.29104
    },
    56: {
      60: 783.94347,
      72: 656.07204,
      84: 565.92531,
      96: 499.41071,
      108: 448.71125,
      120: 409.13342,
      132: 377.68982,
      144: 352.37599,
      156: 331.80758,
      168: 314.99758,
      180: 301.22422,
      192: 289.94712,
      204: 280.75267,
      216: 273.31889,
      228: 267.39175,
      240: 262.76872
    },
    57: {
      60: 786.74555,
      72: 659.24044,
      84: 569.44397,
      96: 503.28482,
      108: 452.94294,
      120: 413.72531,
      132: 382.63121,
      144: 357.66361,
      156: 337.44234,
      168: 320.98398,
      180: 307.56861,
      192: 296.65596,
      204: 287.83266,
      216: 280.77751,
      228: 275.23773,
      240: 271.01189
    },
    58: {
      60: 789.98011,
      72: 662.85410,
      84: 573.43548,
      96: 507.65337,
      108: 457.68898,
      120: 418.83512,
      132: 388.09977,
      144: 363.49140,
      156: 343.63419,
      168: 327.54698,
      180: 314.51003,
      192: 303.98340,
      204: 295.55461,
      216: 288.90383,
      228: 283.77955,
      240: 279.98028
    },
    59: {
      60: 793.65750,
      72: 666.93527,
      84: 577.91502,
      96: 512.52846,
      108: 462.94194,
      120: 424.45866,
      132: 394.09390,
      144: 369.86145,
      156: 350.38818,
      168: 334.69321,
      180: 322.05717,
      192: 311.94108,
      204: 303.93403,
      216: 297.71758,
      228: 293.04018,
      240: 289.70152
    },
    60: {
      60: 797.64567,
      72: 671.36226,
      84: 582.76819,
      96: 517.78184,
      108: 468.58324,
      120: 430.48600,
      132: 400.51228,
      144: 376.67933,
      156: 357.61450,
      168: 342.33742,
      180: 330.12986,
      192: 320.45465,
      204: 312.90242,
      216: 307.15481,
      228: 302.96156,
      240: 300.12556
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

    // ⚡ LISTENER AUTOMATIQUE pour vérification du capital sous risque
    _dureeController.addListener(_verifierCapitalSousRisqueAuto);
    _montantController.addListener(_verifierCapitalSousRisqueAuto);

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
    
    // ✅ CHARGER LES QUESTIONS DU QUESTIONNAIRE MÉDICAL AU DÉMARRAGE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestionnaireMedicalQuestions();
    });
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

      // Si on est en mode modification (avec existingData), pré-remplir tout
      if (args['existingData'] != null) {
        // Le pré-remplissage complet est déjà géré dans initState via _prefillFromExistingData
        // On ne fait rien ici pour éviter d'écraser les données
      }
      // Sinon, pré-remplir uniquement les champs client (nouvelle souscription)
      else if (args['clientInfo'] != null) {
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

    // Détecter si c'est une souscription par commercial (présence de client_info)
    if (data['client_info'] != null) {
      _isCommercial = true;
      final clientInfo = data['client_info'] as Map<String, dynamic>;

      // Pré-remplir les champs client
      _clientNomController.text = clientInfo['nom'] ?? '';
      _clientPrenomController.text = clientInfo['prenom'] ?? '';
      _clientEmailController.text = clientInfo['email'] ?? '';
      _clientTelephoneController.text = clientInfo['telephone'] ?? '';
      _clientLieuNaissanceController.text = clientInfo['lieu_naissance'] ?? '';
      _clientAdresseController.text = clientInfo['adresse'] ?? '';
      _clientNumeroPieceController.text =
          clientInfo['numero_piece_identite'] ?? '';

      if (clientInfo['civilite'] != null) {
        _selectedClientCivilite = clientInfo['civilite'];
      }

      // Date de naissance du client
      if (clientInfo['date_naissance'] != null) {
        try {
          DateTime? dateNaissance;
          if (clientInfo['date_naissance'] is String) {
            dateNaissance = DateTime.parse(clientInfo['date_naissance']);
          } else if (clientInfo['date_naissance'] is DateTime) {
            dateNaissance = clientInfo['date_naissance'];
          }

          if (dateNaissance != null) {
            _dateNaissanceParent = dateNaissance;
            _clientDateNaissanceController.text =
                '${dateNaissance.day.toString().padLeft(2, '0')}/${dateNaissance.month.toString().padLeft(2, '0')}/${dateNaissance.year}';
            final maintenant = DateTime.now();
            _clientAgeParent = maintenant.year - dateNaissance.year;
            if (maintenant.month < dateNaissance.month ||
                (maintenant.month == dateNaissance.month &&
                    maintenant.day < dateNaissance.day)) {
              _clientAgeParent = (_clientAgeParent ?? 0) - 1;
            }
            _calculatedAgeParent = _clientAgeParent;
          }
        } catch (e) {
          debugPrint('Erreur parsing date de naissance client: $e');
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

    // 💳 MODE DE PAIEMENT - Pré-remplissage
    if (data['mode_paiement'] != null) {
      _selectedModePaiement = data['mode_paiement'];

      if (data['infos_paiement'] != null) {
        final infos = data['infos_paiement'];
        if (_selectedModePaiement == 'Virement') {
          _banqueController.text = infos['banque'] ?? '';
          _numeroCompteController.text = infos['numero_compte'] ?? '';
        } else if (_selectedModePaiement == 'Wave' ||
            _selectedModePaiement == 'Orange Money') {
          _numeroMobileMoneyController.text = infos['numero_telephone'] ?? '';
        }
      }
    }

    // Forcer le recalcul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculerValeurs();
      if (mounted) {
        setState(() {});
      }
      
      // Charger les réponses questionnaire avec libelle du serveur
      if (widget.subscriptionId != null) {
        _loadQuestionnaireMedicalReponses();
      }
    });
  }

  /// Charger les réponses questionnaire avec libelle du serveur
  Future<void> _loadQuestionnaireMedicalReponses() async {
    try {
      final questionnaireService = QuestionnaireMedicalService();
      final completReponses = await questionnaireService.getReponses(widget.subscriptionId!);
      if (completReponses != null && completReponses.isNotEmpty) {
        debugPrint('✅ Réponses questionnaire chargées (${completReponses.length} items)');
        if (mounted) {
          setState(() {
            _questionnaireMedicalReponses = completReponses;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du chargement des réponses questionnaire: $e');
    }
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

  /// ✅ Charger les questions du questionnaire médical au démarrage
  Future<void> _loadQuestionnaireMedicalQuestions() async {
    try {
      final questionnaireService = QuestionnaireMedicalService();
      final questions = await questionnaireService.getQuestions();
      if (questions.isNotEmpty && mounted) {
        setState(() {
          _questionnaireMedicalQuestions = questions;
        });
        debugPrint('✅ Questions chargées: ${questions.length} questions');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du chargement des questions: $e');
    }
  }

  String _formatMontant(double montant) {
    // Enlever les décimales - affichage sans virgule
    final rounded = montant.round();
    return "${rounded.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
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
    // Enlever les décimales - affichage sans virgule
    final rounded = number.round();
    return rounded.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
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

  /// 🏥 Vérification du capital sous risque et affichage du message médical
  /// Retourne true si l'utilisateur peut continuer, false sinon
  Future<bool> _verifierCapitalSousRisque() async {
    debugPrint('\n╔════════════════════════════════════════════════════════════╗');
    debugPrint('║  🏥 CORIS ÉTUDE - Vérification Capital Sous Risque       ║');
    debugPrint('╚════════════════════════════════════════════════════════════╝');
    
    // Pour Coris Étude: Capital sous risque = (Durée cotisation × 0.5 × Rente) + (5 × Rente)
    // Durée = (17 - âge enfant) × 12 mois
    final ageEnfant = int.tryParse(_dureeController.text) ?? 0;
    final dureeCotisationMois = ((17 - ageEnfant) * 12).toDouble();
    final rente = _renteCalculee;
    
    final capitalSousRisque = (dureeCotisationMois * 0.5 * rente) + (5 * rente);
    
    // Déterminer l'âge du parent (_calculatedAgeParent est utilisé pour tous)
    final age = _calculatedAgeParent ?? 0;
    
    debugPrint('📊 Données de calcul:');
    debugPrint('   - Âge enfant: $ageEnfant ans');
    debugPrint('   - Durée cotisation: (17 - $ageEnfant) × 12 = $dureeCotisationMois mois');
    debugPrint('   - Rente annuelle: ${_formatNumber(rente)} FCFA');
    debugPrint('   - Formule: (Durée × 0.5 × Rente) + (5 × Rente)');
    debugPrint('   - Calcul: ($dureeCotisationMois × 0.5 × ${_formatNumber(rente)}) + (5 × ${_formatNumber(rente)})');
    debugPrint('   - Capital sous risque = ${_formatNumber(capitalSousRisque)} FCFA');
    debugPrint('   - Âge parent (souscripteur): $age ans');
    
    // Vérifier les conditions
    bool afficherMessage = false;
    String raison = '';
    
    if (age < 45 && capitalSousRisque > 30000000) {
      afficherMessage = true;
      raison = 'Âge parent < 45 ans ET Capital > 30M FCFA';
      debugPrint('⚠️  Condition déclenchée: $raison');
    } else if (age >= 45 && capitalSousRisque > 15000000) {
      afficherMessage = true;
      raison = 'Âge parent ≥ 45 ans ET Capital > 15M FCFA';
      debugPrint('⚠️  Condition déclenchée: $raison');
    } else {
      debugPrint('✅ Aucune condition déclenchée - Pas de formulaire médical requis');
      if (age < 45) {
        debugPrint('   - Âge parent < 45: Capital doit être > 30M (actuellement: ${_formatNumber(capitalSousRisque)} FCFA)');
      } else {
        debugPrint('   - Âge parent ≥ 45: Capital doit être > 15M (actuellement: ${_formatNumber(capitalSousRisque)} FCFA)');
      }
    }
    
    if (!afficherMessage) {
      debugPrint('═══════════════════════════════════════════════════════════\n');
      return true; // Pas de message, on peut continuer
    }
    
    debugPrint('🔔 Affichage du dialog de confirmation...');
    
    // Marquer que le message est affiché
    _messageCapitalAffiche = true;
    
    // Afficher le dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  bleuClair.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône avec fond coloré
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bleuCoris.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: bleuCoris,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // Titre
                const Text(
                  'Formulaire Médical',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: bleuCoris,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Message principal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bleuCoris.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Nos équipes vous contacteront pour remplir un formulaire médical complémentaire.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: grisTexte,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Souhaitez-vous continuer ?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bleuCoris,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Boutons Oui/Non
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop(false); // Fermer le dialog
                          // Naviguer vers la page de sélection des produits
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/souscription',
                              (route) => false,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Non',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // Oui
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bleuCoris,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Oui',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Si l'utilisateur clique "Non", il a déjà été redirigé vers l'accueil
    if (result == false) {
      debugPrint('❌ Utilisateur a choisi de NE PAS continuer - Retour à l\'accueil');
      debugPrint('═══════════════════════════════════════════════════════════\n');
      return false;
    }
    
    debugPrint('✅ Utilisateur a choisi de CONTINUER la souscription');
    debugPrint('═══════════════════════════════════════════════════════════\n');
    return true; // L'utilisateur a cliqué "Continuer"
  }

  /// ⚡ Vérification AUTOMATIQUE (sans dialog) dès que les valeurs changent
  void _verifierCapitalSousRisqueAuto() {
    // Si le message a déjà été affiché, ne plus vérifier
    if (_messageCapitalAffiche) {
      return;
    }
    
    // Vérifier seulement si toutes les valeurs nécessaires sont présentes
    final ageEnfant = int.tryParse(_dureeController.text);
    final age = _calculatedAgeParent;
    
    if (ageEnfant == null || age == null || age == 0 || _renteCalculee == 0) {
      debugPrint('⏳ [AUTO ÉTUDE] Valeurs incomplètes (Âge enfant: $ageEnfant, Âge parent: $age, Rente: $_renteCalculee)');
      return;
    }
    
    debugPrint('\n⚡ [AUTO] Vérification automatique déclenchée!');
    debugPrint('   - Âge enfant: $ageEnfant ans');
    debugPrint('   - Âge parent: $age ans');
    debugPrint('   - Rente: ${_formatNumber(_renteCalculee)} FCFA');
    
    final dureeCotisationMois = ((17 - ageEnfant) * 12).toDouble();
    final capitalSousRisque = (dureeCotisationMois * 0.5 * _renteCalculee) + (5 * _renteCalculee);
    
    debugPrint('   - Capital sous risque calculé: ${_formatNumber(capitalSousRisque)} FCFA');
    
    bool depasseSeuil = false;
    if (age < 45 && capitalSousRisque > 30000000) {
      depasseSeuil = true;
      debugPrint('   ⚠️  SEUIL DÉPASSÉ: Âge < 45 ans & Capital > 30M');
    } else if (age >= 45 && capitalSousRisque > 15000000) {
      depasseSeuil = true;
      debugPrint('   ⚠️  SEUIL DÉPASSÉ: Âge ≥ 45 ans & Capital > 15M');
    } else {
      debugPrint('   ✅ Seuil OK - Pas de formulaire médical requis');
    }
    
    if (depasseSeuil) {
      debugPrint('   🏥 Formulaire médical sera requis lors de la validation!\n');
      // Marquer que le message va être affiché
      _messageCapitalAffiche = true;
      // Afficher le dialog immédiatement
      _verifierCapitalSousRisque();
    }
  }

  Future<void> _nextStep() async {
    debugPrint('\n🔵 [ÉTUDE] _nextStep() appelé - Step actuel: $_currentStep, Mode: ${_isCommercial ? "Commercial" : "Client"}');
    // Ajout du questionnaire médical: +1 étape avant le récap
    // Clients: 0 (params), 1 (bénéficiaire), 2 (mode paiement), 3 (questionnaire médical), 4 (recap)
    // Commerciaux: 0 (client), 1 (params), 2 (bénéficiaire), 3 (mode paiement), 4 (questionnaire médical), 5 (recap)
    final maxStep = _isCommercial ? 5 : 4;
    if (_currentStep < maxStep) {
      bool canProceed = false;

      if (_isCommercial) {
        // Pour les commerciaux: step 0 = infos client, step 1 = paramètres, step 2 = bénéficiaire, step 3 = mode paiement, step 4 = questionnaire médical, step 5 = recap
        if (_currentStep == 0 && _validateStepClientInfo()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStep2()) {
          canProceed = true;
          _recalculerValeurs();
        } else if (_currentStep == 3 && _validateStepModePaiement()) {
          debugPrint('\n🔍 [ÉTUDE Commercial] Étape 3 validée - Lancement vérification capital sous risque...');
          // ✅ Vérifier le capital sous risque avant de passer au questionnaire médical
          final canContinue = await _verifierCapitalSousRisque();
          if (!canContinue) return; // L'utilisateur a choisi de ne pas continuer
          // Validation du mode de paiement avant questionnaire médical
          canProceed = true;
        } else if (_currentStep == 4) {
          // Questionnaire médical avant récap — trigger widget validation
          if (_questionnaireValidate != null) {
            final ok = await _questionnaireValidate!();
            debugPrint('[_nextStep] questionnaireValidate returned: $ok');
            debugPrint('[_nextStep] _questionnaireMedicalReponses (len): ${_questionnaireMedicalReponses.length}');
            if (!ok) return;
          } else if (_questionnaireMedicalReponses.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez compléter le questionnaire médical'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          canProceed = true;
        }
      } else {
        // Pour les clients: step 0 = paramètres, step 1 = bénéficiaire, step 2 = mode paiement, step 3 = questionnaire médical, step 4 = recap
        if (_currentStep == 0 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep2()) {
          canProceed = true;
          _recalculerValeurs();
        } else if (_currentStep == 2 && _validateStepModePaiement()) {
          debugPrint('\n🔍 [ÉTUDE Client] Étape 2 validée - Vérification capital sous risque...');
          // ✅ Vérifier le capital sous risque SEULEMENT si pas déjà affiché
          if (!_messageCapitalAffiche) {
            final canContinue = await _verifierCapitalSousRisque();
            if (!canContinue) return; // L'utilisateur a choisi de ne pas continuer
          }
          // Validation du mode de paiement avant questionnaire médical
          canProceed = true;
        } else if (_currentStep == 3) {
          // Questionnaire médical avant récap — trigger widget validation
          if (_questionnaireValidate != null) {
            final ok = await _questionnaireValidate!();
            if (!ok) return;
          } else if (_questionnaireMedicalReponses.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Veuillez compléter le questionnaire médical'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
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
    // Email non obligatoire pour le commercial
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

    // La pièce d'identité n'est obligatoire QUE pour une nouvelle souscription
    // En mode modification, elle est optionnelle
    if (_pieceIdentite == null && widget.subscriptionId == null) {
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
      if (_codeGuichetController.text.trim().isEmpty ||
          _numeroCompteController.text.trim().isEmpty ||
          _cleRibController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez remplir toutes les informations bancaires.');
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
        // 💳 MODE DE PAIEMENT
        'mode_paiement': _selectedModePaiement,
        'infos_paiement': _selectedModePaiement == 'Virement'
            ? {
                'banque': _banqueController.text.trim(),
                'code_guichet': _codeGuichetController.text.trim(),
                'numero_compte': _numeroCompteController.text.trim(),
                'cle_rib': _cleRibController.text.trim(),
              }
            : (_selectedModePaiement == 'Wave' ||
                    _selectedModePaiement == 'Orange Money')
                ? {
                    'numero_telephone':
                        _numeroMobileMoneyController.text.trim(),
                  }
                : null,
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

      // ÉTAPE 1.25: Sauvegarder les réponses du questionnaire médical
      if (_questionnaireMedicalReponses.isNotEmpty) {
        try {
          final questionnaireService = QuestionnaireMedicalService();
          await questionnaireService.saveReponses(
            subscriptionId: subscriptionId,
            reponses: _questionnaireMedicalReponses,
          );
          debugPrint('✅ Réponses questionnaire médical sauvegardées pour souscription $subscriptionId');
        } catch (e) {
          debugPrint('❌ Erreur sauvegarde questionnaire: $e');
        }
      }

      // ÉTAPE 1.5: Upload du document pièce d'identité si présent
      if (_pieceIdentite != null) {
        try {
          await _uploadDocument(subscriptionId);
        } catch (uploadError) {
          debugPrint('⚠️ Erreur upload document (non bloquant): $uploadError');
          // On continue même si l'upload échoue
        }
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

      // Sauvegarder les réponses du questionnaire médical
      if (_questionnaireMedicalReponses.isNotEmpty) {
        try {
          final questionnaireService = QuestionnaireMedicalService();
          await questionnaireService.saveReponses(
            subscriptionId: subscriptionId,
            reponses: _questionnaireMedicalReponses,
          );
          debugPrint('✅ Réponses questionnaire médical sauvegardées pour souscription $subscriptionId');
        } catch (e) {
          debugPrint('❌ Erreur sauvegarde questionnaire: $e');
        }
      }

      // Upload du document pièce d'identité si présent
      if (_pieceIdentite != null) {
        try {
          await _uploadDocument(subscriptionId);
        } catch (uploadError) {
          debugPrint('⚠️ Erreur upload document (non bloquant): $uploadError');
          // On continue même si l'upload échoue
        }
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

      // Si le serveur renvoie le subscription mis à jour, récupérer le label original
      try {
        final updated = responseData['data']?['subscription'];
        if (updated != null) {
          final souscriptiondata = updated['souscriptiondata'];
          if (souscriptiondata != null) {
            // Le champ peut être stocké sous forme d'objet/d'une string JSON
            if (souscriptiondata is Map) {
              _pieceIdentiteLabel = souscriptiondata['piece_identite_label'];
            } else if (souscriptiondata is String) {
              try {
                final parsed = jsonDecode(souscriptiondata);
                _pieceIdentiteLabel = parsed['piece_identite_label'];
              } catch (_) {
                // ignore
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Impossible de lire piece_identite_label depuis la réponse: $e');
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: _buildModernProgressIndicator(),
              ),
            ),
          ];
        },
        body: SafeArea(
          child: Column(
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
                          _buildStepModePaiement(), // Page 3: Mode de paiement
                          _buildStepQuestionnaireMedical(), // Page 4: Questionnaire médical
                          _buildStep3(), // Page 5: Récapitulatif (Finaliser ouvre modal)
                        ]
                      : [
                          _buildStep1(), // Page 0: Paramètres de souscription
                          _buildStep2(), // Page 1: Bénéficiaire/Contact
                          _buildStepModePaiement(), // Page 2: Mode de paiement
                          _buildStepQuestionnaireMedical(), // Page 3: Questionnaire médical
                          _buildStep3(), // Page 4: Récapitulatif (Finaliser ouvre modal)
                        ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
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
          for (int i = 0; i < (_isCommercial ? 6 : 5); i++) ...[
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
                                          ? Icons.payment
                                          : i == 4
                                              ? Icons.assignment
                                              : i == 5
                                                  ? Icons.check_circle
                                                  : Icons.credit_card)
                          : (i == 0
                              ? Icons.account_balance_wallet
                              : i == 1
                                  ? Icons.person_add
                                  : i == 2
                                      ? Icons.payment
                                      : i == 3
                                          ? Icons.assignment
                                          : Icons.check_circle),
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
                                        ? 'Paiement'
                                        : i == 4
                                            ? 'Questionnaire médical'
                                            : i == 5
                                                ? 'Recap'
                                                : 'Finaliser')
                        : (i == 0
                            ? 'Souscription'
                            : i == 1
                                ? 'Infos'
                                : i == 2
                                    ? 'Paiement'
                                    : i == 3
                                        ? 'Questionnaire médical'
                                        : 'Recap'),
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
            if (i < (_isCommercial ? 5 : 4))
              Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(bottom: 8, left: 4, right: 4),
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          // Masquer le champ date de naissance parent si c'est un commercial
                          // car le client EST le parent dans ce cas
                          if (widget.clientId == null) ...[
                            _buildDateNaissanceParentField(),
                            const SizedBox(height: 16),
                          ],
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
              'Durée du contrat: ${(17 - (int.tryParse(_dureeController.text) ?? 0))} ans (jusqu\'\u00e0 17 ans)',
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
    // Vérifier si la valeur est valide (null ou dans la liste)
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
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

  /// 💳 ÉTAPE MODE DE PAIEMENT
  Widget _buildStepModePaiement() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec gradient
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
                          child:
                              const Icon(Icons.payment, color: blanc, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode de Paiement',
                                style: const TextStyle(
                                  color: blanc,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comment souhaitez-vous payer vos primes ?',
                                style: TextStyle(
                                  color: blanc.withAlpha(229),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sélection du mode de paiement
                  Text(
                    'Mode de paiement *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: grisTexte,
                    ),
                  ),
                  SizedBox(height: 12),
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

                        switch (mode) {
                          case 'Virement':
                            icon = Icons.account_balance;
                            iconColor = Colors.blue;
                            break;
                          case 'Wave':
                            icon = Icons.water_drop;
                            iconColor = Color(0xFF00BFFF);
                            break;
                          case 'Orange Money':
                            icon = Icons.phone_android;
                            iconColor = Colors.orange;
                            break;
                          default:
                            icon = Icons.payment;
                            iconColor = bleuCoris;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedModePaiement = mode;
                              // Réinitialiser les champs
                              _banqueController.clear();
                              _codeGuichetController.clear();
                              _numeroCompteController.clear();
                              _cleRibController.clear();
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
                                  child: Icon(icon, color: iconColor, size: 28),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    mode,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? bleuCoris
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle,
                                      color: bleuCoris, size: 28),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Champs conditionnels selon le mode sélectionné
                  if (_selectedModePaiement != null) ...[
                    SizedBox(height: 30),

                    // VIREMENT
                    if (_selectedModePaiement == 'Virement') ...[
                      Text(
                        'Informations Bancaires',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nom de la banque
                      DropdownButtonFormField<String>(
                        value: _selectedBanque,
                        decoration: InputDecoration(
                          labelText: 'Nom de la banque *',
                          prefixIcon:
                              Icon(Icons.account_balance, color: bleuCoris),
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
                      SizedBox(height: 16),

                      // Champ texte personnalisé si "Autre" est sélectionné
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
                        SizedBox(height: 16),
                      ],

                      // Informations du RIB
                      Text(
                        'Informations du RIB',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: bleuCoris,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Code guichet (4 chiffres)
                      TextField(
                        controller: _codeGuichetController,
                        decoration: InputDecoration(
                          labelText: 'Code guichet *',
                          hintText: '4 chiffres',
                          prefixIcon: Icon(Icons.domain, color: bleuCoris),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),
                      SizedBox(height: 16),

                      // Numéro de compte (11 chiffres)
                      TextField(
                        controller: _numeroCompteController,
                        decoration: InputDecoration(
                          labelText: 'Numéro de compte *',
                          hintText: '11 chiffres',
                          prefixIcon: Icon(Icons.credit_card, color: bleuCoris),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 11,
                      ),
                      SizedBox(height: 16),

                      // Clé RIB (2 chiffres)
                      TextField(
                        controller: _cleRibController,
                        decoration: InputDecoration(
                          labelText: 'Clé RIB *',
                          hintText: '2 chiffres',
                          prefixIcon: Icon(Icons.key, color: bleuCoris),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                      ),
                    ],

                    // WAVE ou ORANGE MONEY
                    if (_selectedModePaiement == 'Wave' ||
                        _selectedModePaiement == 'Orange Money') ...[
                      Text(
                        'Numéro ${_selectedModePaiement}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _numeroMobileMoneyController,
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone *',
                          hintText: 'Ex: 0707070707',
                          prefixIcon: Icon(
                            Icons.phone_android,
                            color: _selectedModePaiement == 'Wave'
                                ? Color(0xFF00BFFF)
                                : Colors.orange,
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

                  SizedBox(height: 30),

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
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ces informations seront utilisées pour le prélèvement automatique de vos primes.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Étape du questionnaire médical
  Widget _buildStepQuestionnaireMedical() {
    return QuestionnaireMedicalDynamicWidget(
      subscriptionId: widget.subscriptionId,
      initialReponses: _questionnaireMedicalReponses,
      showActions: false,
      registerValidate: (fn) {
        _questionnaireValidate = fn;
      },
      onValidated: (reponses) async {
        setState(() {
          _questionnaireMedicalReponses = reponses;
        });

        // Sauvegarder les réponses du questionnaire avant de passer à l'étape suivante
        try {
          if (widget.subscriptionId != null) {
            final questionnaireService = QuestionnaireMedicalService();
            await questionnaireService.saveReponses(
              subscriptionId: widget.subscriptionId!,
              reponses: reponses,
            );
            debugPrint('✅ Questionnaire médical sauvegardé');
            
            // Fetch complete responses with libelle from server
            final completReponses = await questionnaireService.getReponses(widget.subscriptionId!);
            if (completReponses != null && completReponses.isNotEmpty) {
              setState(() {
                _questionnaireMedicalReponses = completReponses;
              });
              debugPrint('✅ Réponses complètes avec libelle récupérées (${completReponses.length} items)');
            }
          }
        } catch (e) {
          debugPrint('❌ Erreur lors de la sauvegarde du questionnaire: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Erreur lors de la sauvegarde du questionnaire: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Validation/save complete — parent will advance after validate returns true
      },
      onCancel: () {
        _previousStep();
      },
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
        : (userData ?? _userData);

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

        // 💳 SECTION MODE DE PAIEMENT
        if (_selectedModePaiement != null)
          SubscriptionRecapWidgets.buildRecapSection(
            'Mode de Paiement',
            Icons.payment,
            _selectedModePaiement == 'Virement'
                ? Colors.blue
                : _selectedModePaiement == 'Wave'
                    ? Color(0xFF00BFFF)
                    : Colors.orange,
            [
              SubscriptionRecapWidgets.buildRecapRow(
                'Mode choisi',
                _selectedModePaiement!,
              ),
              const SizedBox(height: 8),
              if (_selectedModePaiement == 'Virement') ...[
                SubscriptionRecapWidgets.buildRecapRow(
                  'Banque',
                  _banqueController.text.isNotEmpty
                      ? _banqueController.text
                      : 'Non renseigné',
                ),
                SubscriptionRecapWidgets.buildRecapRow(
                  'Code guichet',
                  _codeGuichetController.text.isNotEmpty
                      ? _codeGuichetController.text
                      : 'Non renseigné',
                ),
                SubscriptionRecapWidgets.buildRecapRow(
                  'Numéro de compte',
                  _numeroCompteController.text.isNotEmpty
                      ? _numeroCompteController.text
                      : 'Non renseigné',
                ),
                SubscriptionRecapWidgets.buildRecapRow(
                  'Clé RIB',
                  _cleRibController.text.isNotEmpty
                      ? _cleRibController.text
                      : 'Non renseigné',
                ),
              ] else if (_selectedModePaiement == 'Wave' ||
                  _selectedModePaiement == 'Orange Money') ...[
                SubscriptionRecapWidgets.buildRecapRow(
                  'Numéro ${_selectedModePaiement}',
                  _numeroMobileMoneyController.text.isNotEmpty
                      ? _numeroMobileMoneyController.text
                      : 'Non renseigné',
                ),
              ],
            ],
          ),

        if (_selectedModePaiement != null) const SizedBox(height: 20),

        // RÉCAP: Questionnaire médical (questions + réponses)
        // Passe la liste des questions pour afficher toutes les questions avec réponses
        SubscriptionRecapWidgets.buildQuestionnaireMedicalSection(
            _questionnaireMedicalReponses, _questionnaireMedicalQuestions),

        const SizedBox(height: 20),

        SubscriptionRecapWidgets.buildDocumentsSection(
          pieceIdentite: _pieceIdentiteLabel ?? _pieceIdentite?.path.split('/').last,
          onDocumentTap: _pieceIdentite != null
              ? () => _viewLocalDocument(
                  _pieceIdentite!, _pieceIdentiteLabel ?? _pieceIdentite!.path.split('/').last)
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
                onPressed: _currentStep == (_isCommercial ? 5 : 4)
                    ? _showPaymentOptions
                    : _nextStep,
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
                      _currentStep == (_isCommercial ? 5 : 4)
                          ? 'Finaliser'
                          : 'Suivant',
                      style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      _currentStep == (_isCommercial ? 5 : 4)
                          ? Icons.check
                          : Icons.arrow_forward,
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
                  // En-tête de finalisation
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [vertSucces, vertSucces.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: vertSucces.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: blanc, size: 56),
                        SizedBox(height: 16),
                        Text(
                          'Souscription Prête !',
                          style: TextStyle(
                            color: blanc,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toutes vos informations ont été enregistrées',
                          style: TextStyle(
                            color: blanc.withOpacity(0.9),
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
                          _selectedMode == 'prime'
                              ? 'Prime ${_selectedPeriodicite?.toLowerCase() ?? 'mensuel'} à payer'
                              : 'Rente ${_selectedPeriodicite?.toLowerCase() ?? 'mensuel'} à payer',
                          style: TextStyle(
                            color: grisTexte,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatMontant(
                              double.tryParse(_montantController.text) ?? 0),
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

                  // Titre de la section
                  Text(
                    'Que souhaitez-vous faire maintenant ?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: bleuCoris,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Option 1: Payer maintenant
                  InkWell(
                    onTap: () => _showPaymentOptions(),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bleuCoris,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: bleuCoris.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: blanc.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.payment, color: blanc, size: 32),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payer Maintenant',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: blanc,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Finalisez votre souscription avec un paiement immédiat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: blanc.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: blanc, size: 20),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Option 2: Payer plus tard
                  InkWell(
                    onTap: () => _saveAsProposition(),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: blanc,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: orangeWarning, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: orangeWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.schedule,
                                color: orangeWarning, size: 32),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payer Plus Tard',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: orangeWarning,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Enregistrez votre proposition et payez ultérieurement',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: grisTexte,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: orangeWarning, size: 20),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Note informative
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: bleuCoris, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Information importante',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: bleuCoris,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Si vous choisissez de payer plus tard, votre souscription sera enregistrée comme proposition et vous pourrez la finaliser ultérieurement.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
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
  // Méthode non utilisée - conservée pour référence future
  // ignore: unused_element
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
                  ? 'Félicitations! Votre contrat CORIS ÉTUDE est maintenant actif. Vous recevrez un message de confirmation sous peu.'
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
