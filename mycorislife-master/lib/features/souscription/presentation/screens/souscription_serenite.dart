import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'dart:convert';
import 'dart:io';

// Enum pour le type de simulation
enum SimulationType { parCapital, parPrime }

enum Periode { mensuel, trimestriel, semestriel, annuel }

// Couleurs partagées (top-level pour accessibilité globale)
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color bleuSecondaire = Color(0xFF1E4A8C);
const Color blanc = Colors.white;
const Color fondCarte = Color(0xFFF8FAFC);
const Color grisTexte = Color(0xFF64748B);
const Color grisLeger = Color(0xFFF1F5F9);
const Color vertSucces = Color(0xFF10B981);
const Color orangeWarning = Color(0xFFF59E0B);

/// Page de souscription pour le produit CORIS SÉRÉNITÉ
/// Permet de souscrire à une assurance vie avec garantie décès
///
/// [simulationData] : Données de simulation (capital, prime, durée, périodicité)
/// [clientId] : ID du client si souscription par commercial (optionnel)
/// [clientData] : Données du client si souscription par commercial (optionnel)
class SouscriptionSerenitePage extends StatefulWidget {
  final Map<String, dynamic>? simulationData;
  final String? clientId; // ID du client si souscription par commercial
  final Map<String, dynamic>?
      clientData; // Données du client si souscription par commercial

  const SouscriptionSerenitePage({
    super.key,
    this.simulationData,
    this.clientId,
    this.clientData,
  });

  @override
  SouscriptionSerenitePageState createState() =>
      SouscriptionSerenitePageState();
}

class SouscriptionSerenitePageState extends State<SouscriptionSerenitePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _currentStep = 0;

  // Contrôleurs pour la simulation
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _primeController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();

  // Variables pour la simulation
  int _dureeEnMois = 12;
  String _selectedUnite = 'mois';
  Periode _selectedPeriode = Periode.annuel;
  SimulationType _currentSimulation = SimulationType.parCapital;
  String _selectedSimulationType = 'Par Capital';
  double _calculatedPrime = 0.0;
  double _calculatedCapital = 0.0;
  final List<String> _indicatifs = [
    '+225',
    '+226',
    '+237',
    '+228',
    '+229',
    '+234'
  ];

  // Données utilisateur
  Map<String, dynamic> _userData = {};
  DateTime? _dateNaissance;
  int _age = 0;

  // Variables pour commercial (souscription pour un client)
  bool _isCommercial = false;
  DateTime? _clientDateNaissance;
  int _clientAge = 0;

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

  // Contrôleurs pour la souscription
  final _formKey = GlobalKey<FormState>();
  final _beneficiaireNomController = TextEditingController();
  final _beneficiaireContactController = TextEditingController();
  String _selectedLienParente = 'Enfant';
  final _personneContactNomController = TextEditingController();
  final _personneContactTelController = TextEditingController();
  String _selectedLienParenteUrgence = 'Parent';
  DateTime? _dateEffetContrat;
  DateTime? _dateEcheanceContrat;
  String _selectedBeneficiaireIndicatif = '+225';
  String _selectedContactIndicatif = '+225';

  File? _pieceIdentite;

  // Options
  final List<String> _lienParenteOptions = [
    'Enfant',
    'Conjoint',
    'Parent',
    'Frère/Sœur',
    'Ami',
    'Autre'
  ];
  final storage = FlutterSecureStorage();

  // Tableau tarifaire (identique à la simulation)
  final Map<int, Map<int, double>> _tarifaire = {
    18: {
      12: 211.068,
      24: 107.682,
      36: 73.248,
      48: 56.051,
      60: 45.749,
      72: 38.895,
      84: 34.010,
      96: 30.356,
      108: 27.524,
      120: 25.266,
      132: 23.426,
      144: 21.900,
      156: 20.616,
      168: 19.521,
      180: 18.578
    },
    19: {
      12: 216.612,
      24: 110.520,
      36: 75.183,
      48: 57.535,
      60: 46.962,
      72: 39.927,
      84: 34.913,
      96: 31.163,
      108: 28.256,
      120: 25.939,
      132: 24.051,
      144: 22.485,
      156: 21.166,
      168: 20.043,
      180: 19.075
    },
    20: {
      12: 222.215,
      24: 113.384,
      36: 77.134,
      48: 59.030,
      60: 48.183,
      72: 40.966,
      84: 35.822,
      96: 31.976,
      108: 28.993,
      120: 26.616,
      132: 24.679,
      144: 23.073,
      156: 21.721,
      168: 20.568,
      180: 19.576
    },
    21: {
      12: 227.940,
      24: 116.309,
      36: 79.126,
      48: 60.555,
      60: 49.429,
      72: 42.026,
      84: 36.750,
      96: 32.804,
      108: 29.745,
      120: 27.307,
      132: 25.320,
      144: 23.673,
      156: 22.286,
      168: 21.104,
      180: 20.086
    },
    22: {
      12: 233.824,
      24: 119.313,
      36: 81.171,
      48: 62.121,
      60: 50.708,
      72: 43.114,
      84: 37.703,
      96: 33.655,
      108: 30.518,
      120: 28.017,
      132: 25.979,
      144: 24.289,
      156: 22.867,
      168: 21.655,
      180: 20.612
    },
    23: {
      12: 239.895,
      24: 122.413,
      36: 83.281,
      48: 63.737,
      60: 52.028,
      72: 44.238,
      84: 38.686,
      96: 34.534,
      108: 31.315,
      120: 28.749,
      132: 26.659,
      144: 24.926,
      156: 23.467,
      168: 22.224,
      180: 21.154
    },
    24: {
      12: 246.167,
      24: 125.616,
      36: 85.461,
      48: 65.407,
      60: 53.393,
      72: 45.399,
      84: 39.702,
      96: 35.442,
      108: 32.139,
      120: 29.507,
      132: 27.363,
      144: 25.584,
      156: 24.088,
      168: 22.813,
      180: 21.716
    },
    25: {
      12: 252.640,
      24: 128.921,
      36: 87.712,
      48: 67.131,
      60: 54.802,
      72: 46.598,
      84: 40.752,
      96: 36.380,
      108: 32.991,
      120: 30.290,
      132: 28.090,
      144: 26.265,
      156: 24.730,
      168: 23.423,
      180: 22.298
    },
    26: {
      12: 259.322,
      24: 132.334,
      36: 90.037,
      48: 68.912,
      60: 56.257,
      72: 47.837,
      84: 41.837,
      96: 37.349,
      108: 33.871,
      120: 31.099,
      132: 28.841,
      144: 26.970,
      156: 25.395,
      168: 24.054,
      180: 22.900
    },
    27: {
      12: 266.209,
      24: 135.852,
      36: 92.433,
      48: 70.748,
      60: 57.757,
      72: 49.114,
      84: 42.955,
      96: 38.349,
      108: 34.779,
      120: 31.934,
      132: 29.617,
      144: 27.697,
      156: 26.081,
      168: 24.705,
      180: 23.522
    },
    28: {
      12: 273.306,
      24: 139.478,
      36: 94.903,
      48: 72.640,
      60: 59.303,
      72: 50.430,
      84: 44.107,
      96: 39.380,
      108: 35.715,
      120: 32.796,
      132: 30.419,
      144: 28.448,
      156: 26.791,
      168: 25.379,
      180: 24.166
    },
    29: {
      12: 280.625,
      24: 143.217,
      36: 97.449,
      48: 74.592,
      60: 60.898,
      72: 51.788,
      84: 45.297,
      96: 40.444,
      108: 36.683,
      120: 33.687,
      132: 31.247,
      144: 29.225,
      156: 27.525,
      168: 26.077,
      180: 24.833
    },
    30: {
      12: 288.169,
      24: 147.071,
      36: 100.074,
      48: 76.603,
      60: 62.543,
      72: 53.190,
      84: 46.526,
      96: 41.544,
      108: 37.683,
      120: 34.608,
      132: 32.104,
      144: 30.029,
      156: 28.284,
      168: 26.800,
      180: 25.524
    },
    31: {
      12: 295.952,
      24: 151.047,
      36: 102.783,
      48: 78.680,
      60: 64.242,
      72: 54.638,
      84: 47.796,
      96: 42.681,
      108: 38.718,
      120: 35.561,
      132: 32.991,
      144: 30.862,
      156: 29.073,
      168: 27.550,
      180: 26.242
    },
    32: {
      12: 303.987,
      24: 155.154,
      36: 105.583,
      48: 80.828,
      60: 66.001,
      72: 56.138,
      84: 49.112,
      96: 43.860,
      108: 39.790,
      120: 36.550,
      132: 33.912,
      144: 31.728,
      156: 29.892,
      168: 28.330,
      180: 26.988
    },
    33: {
      12: 312.260,
      24: 159.385,
      36: 108.470,
      48: 83.044,
      60: 67.816,
      72: 57.686,
      84: 50.471,
      96: 45.077,
      108: 40.900,
      120: 37.573,
      132: 34.866,
      144: 32.624,
      156: 30.741,
      168: 29.139,
      180: 27.763
    },
    34: {
      12: 320.759,
      24: 163.736,
      36: 111.439,
      48: 85.324,
      60: 69.684,
      72: 59.280,
      84: 51.871,
      96: 46.333,
      108: 42.044,
      120: 38.629,
      132: 35.851,
      144: 33.551,
      156: 31.619,
      168: 29.976,
      180: 28.565
    },
    35: {
      12: 329.461,
      24: 168.191,
      36: 114.481,
      48: 87.661,
      60: 71.599,
      72: 60.916,
      84: 53.308,
      96: 47.623,
      108: 43.220,
      120: 39.716,
      132: 36.865,
      144: 34.505,
      156: 32.523,
      168: 30.839,
      180: 29.392
    },
    36: {
      12: 338.379,
      24: 172.759,
      36: 117.601,
      48: 90.059,
      60: 73.566,
      72: 62.597,
      84: 54.787,
      96: 48.951,
      108: 44.432,
      120: 40.836,
      132: 37.911,
      144: 35.490,
      156: 33.457,
      168: 31.730,
      180: 30.247
    },
    37: {
      12: 347.501,
      24: 177.433,
      36: 120.795,
      48: 92.516,
      60: 75.582,
      72: 64.322,
      84: 56.305,
      96: 50.315,
      108: 45.678,
      120: 41.988,
      132: 38.987,
      144: 36.504,
      156: 34.420,
      168: 32.648,
      180: 31.128
    },
    38: {
      12: 356.831,
      24: 182.217,
      36: 124.067,
      48: 95.035,
      60: 77.651,
      72: 66.093,
      84: 57.865,
      96: 51.718,
      108: 46.960,
      120: 43.174,
      132: 40.096,
      144: 37.550,
      156: 35.412,
      168: 33.595,
      180: 32.036
    },
    39: {
      12: 366.360,
      24: 187.107,
      36: 127.414,
      48: 97.614,
      60: 79.772,
      72: 67.910,
      84: 59.466,
      96: 53.159,
      108: 48.278,
      120: 44.394,
      132: 41.237,
      144: 38.625,
      156: 36.433,
      168: 34.570,
      180: 32.972
    },
    40: {
      12: 376.073,
      24: 192.096,
      36: 130.834,
      48: 100.251,
      60: 81.942,
      72: 69.770,
      84: 61.107,
      96: 54.636,
      108: 49.629,
      120: 45.646,
      132: 42.408,
      144: 39.729,
      156: 37.481,
      168: 35.572,
      180: 33.934
    },
    41: {
      12: 385.954,
      24: 197.179,
      36: 134.320,
      48: 102.942,
      60: 84.157,
      72: 71.671,
      84: 62.784,
      96: 56.147,
      108: 51.011,
      120: 46.926,
      132: 43.606,
      144: 40.860,
      156: 38.555,
      168: 36.599,
      180: 34.921
    },
    42: {
      12: 395.974,
      24: 202.335,
      36: 137.859,
      48: 105.675,
      60: 86.410,
      72: 73.604,
      84: 64.491,
      96: 57.685,
      108: 52.419,
      120: 48.231,
      132: 44.827,
      144: 42.012,
      156: 39.650,
      168: 37.646,
      180: 35.927
    },
    43: {
      12: 406.137,
      24: 207.570,
      36: 141.455,
      48: 108.454,
      60: 88.701,
      72: 75.572,
      84: 66.228,
      96: 59.251,
      108: 53.853,
      120: 49.560,
      132: 46.071,
      144: 43.187,
      156: 40.768,
      168: 38.715,
      180: 36.956
    },
    44: {
      12: 416.435,
      24: 212.878,
      36: 145.103,
      48: 111.276,
      60: 91.028,
      72: 77.570,
      84: 67.993,
      96: 60.842,
      108: 55.310,
      120: 50.911,
      132: 47.337,
      144: 44.383,
      156: 41.906,
      168: 39.804,
      180: 38.004
    },
    45: {
      12: 426.866,
      24: 218.258,
      36: 148.803,
      48: 114.138,
      60: 93.388,
      72: 79.598,
      84: 69.785,
      96: 62.458,
      108: 56.790,
      120: 52.285,
      132: 48.625,
      144: 45.600,
      156: 43.065,
      168: 40.915,
      180: 39.074
    },
    46: {
      12: 437.430,
      24: 223.709,
      36: 152.552,
      48: 117.037,
      60: 95.780,
      72: 81.653,
      84: 71.601,
      96: 64.097,
      108: 58.293,
      120: 53.680,
      132: 49.933,
      144: 46.838,
      156: 44.244,
      168: 42.046,
      180: 40.167
    },
    47: {
      12: 448.143,
      24: 229.236,
      36: 156.353,
      48: 119.978,
      60: 98.206,
      72: 83.738,
      84: 73.445,
      96: 65.762,
      108: 59.821,
      120: 55.099,
      132: 51.265,
      144: 48.099,
      156: 45.448,
      168: 43.203,
      180: 41.285
    },
    48: {
      12: 459.029,
      24: 234.853,
      36: 160.217,
      48: 122.968,
      60: 100.675,
      72: 85.861,
      84: 75.324,
      96: 67.459,
      108: 61.379,
      120: 56.547,
      132: 52.626,
      144: 49.390,
      156: 46.682,
      168: 44.391,
      180: 42.436
    },
    49: {
      12: 470.112,
      24: 240.573,
      36: 164.153,
      48: 126.015,
      60: 103.192,
      72: 88.028,
      84: 77.242,
      96: 69.194,
      108: 62.972,
      120: 58.031,
      132: 54.022,
      144: 50.716,
      156: 47.952,
      168: 45.616,
      180: 43.625
    },
    50: {
      12: 481.407,
      24: 246.404,
      36: 168.168,
      48: 129.126,
      60: 105.764,
      72: 90.243,
      84: 79.206,
      96: 70.970,
      108: 64.606,
      120: 59.554,
      132: 55.459,
      144: 52.084,
      156: 49.265,
      168: 46.886,
      180: 44.859
    },
    51: {
      12: 492.933,
      24: 252.360,
      36: 172.273,
      48: 132.309,
      60: 108.398,
      72: 92.514,
      84: 81.219,
      96: 72.795,
      108: 66.288,
      120: 61.126,
      132: 56.945,
      144: 53.501,
      156: 50.629,
      168: 48.206,
      180: 46.145
    },
    52: {
      12: 504.687,
      24: 258.439,
      36: 176.465,
      48: 135.563,
      60: 111.092,
      72: 94.839,
      84: 83.284,
      96: 74.670,
      108: 68.021,
      120: 62.749,
      132: 58.482,
      144: 54.971,
      156: 52.045,
      168: 49.581,
      180: 47.487
    },
    53: {
      12: 516.671,
      24: 264.642,
      36: 180.747,
      48: 138.890,
      60: 113.849,
      72: 97.221,
      84: 85.406,
      96: 76.602,
      108: 69.809,
      120: 64.428,
      132: 60.077,
      144: 56.500,
      156: 53.522,
      168: 51.017,
      180: 48.892
    },
    54: {
      12: 528.894,
      24: 270.975,
      36: 185.123,
      48: 142.291,
      60: 116.674,
      72: 99.670,
      84: 87.592,
      96: 78.598,
      108: 71.663,
      120: 66.174,
      132: 61.738,
      144: 58.096,
      156: 55.066,
      168: 52.522,
      180: 50.366
    },
    55: {
      12: 541.357,
      24: 277.437,
      36: 189.591,
      48: 145.774,
      60: 119.575,
      72: 102.192,
      84: 89.851,
      96: 80.666,
      108: 73.589,
      120: 67.991,
      132: 63.472,
      144: 59.765,
      156: 56.686,
      168: 54.102,
      180: 51.917
    },
    56: {
      12: 554.072,
      24: 284.035,
      36: 194.170,
      48: 149.355,
      60: 122.569,
      72: 104.803,
      84: 92.197,
      96: 82.820,
      108: 75.600,
      120: 69.893,
      132: 65.291,
      144: 61.520,
      156: 58.391,
      168: 55.768,
      180: 53.555
    },
    57: {
      12: 567.054,
      24: 290.806,
      36: 198.885,
      48: 153.059,
      60: 125.676,
      72: 107.522,
      84: 94.647,
      96: 85.074,
      108: 77.709,
      120: 71.893,
      132: 67.208,
      144: 63.372,
      156: 60.193,
      168: 57.532,
      180: 55.289
    },
    58: {
      12: 580.212,
      24: 297.691,
      36: 203.704,
      48: 156.855,
      60: 128.872,
      72: 110.327,
      84: 97.180,
      96: 87.413,
      108: 79.904,
      120: 73.979,
      132: 69.209,
      144: 65.309,
      156: 62.080,
      168: 59.383,
      180: 57.113
    },
    59: {
      12: 593.509,
      24: 304.693,
      36: 208.618,
      48: 160.744,
      60: 132.156,
      72: 113.217,
      84: 99.798,
      96: 89.836,
      108: 82.183,
      120: 76.148,
      132: 71.295,
      144: 67.331,
      156: 64.054,
      168: 61.322,
      180: 59.028
    },
    60: {
      12: 606.852,
      24: 311.731,
      36: 213.582,
      48: 164.684,
      60: 135.492,
      72: 116.163,
      84: 102.476,
      96: 92.321,
      108: 84.524,
      120: 78.382,
      132: 73.447,
      144: 69.421,
      156: 66.100,
      168: 63.336,
      180: 61.021
    },
    61: {
      12: 620.256,
      24: 318.848,
      36: 218.619,
      48: 168.693,
      60: 138.900,
      72: 119.183,
      84: 105.228,
      96: 94.880,
      108: 86.940,
      120: 80.691,
      132: 75.676,
      144: 71.592,
      156: 68.228,
      168: 65.435,
      180: 63.104
    },
    62: {
      12: 633.637,
      24: 325.971,
      36: 223.673,
      48: 172.734,
      60: 142.348,
      72: 122.247,
      84: 108.027,
      96: 97.488,
      108: 89.409,
      120: 83.056,
      132: 77.966,
      144: 73.827,
      156: 70.425,
      168: 67.609,
      180: 65.264
    },
    63: {
      12: 647.006,
      24: 333.107,
      36: 228.764,
      48: 176.822,
      60: 145.849,
      72: 125.365,
      84: 110.881,
      96: 100.154,
      108: 91.938,
      120: 85.486,
      132: 80.324,
      144: 76.136,
      156: 72.701,
      168: 69.865,
      180: 67.515
    },
    64: {
      12: 660.380,
      24: 340.302,
      36: 233.920,
      48: 180.977,
      60: 149.412,
      72: 128.545,
      84: 113.799,
      96: 102.887,
      108: 94.539,
      120: 87.993,
      132: 82.764,
      144: 78.530,
      156: 75.068,
      168: 72.219,
      180: 69.868
    },
    65: {
      12: 673.678,
      24: 347.480,
      36: 239.085,
      48: 185.144,
      60: 152.995,
      72: 131.752,
      84: 116.752,
      96: 105.663,
      108: 97.189,
      120: 90.555,
      132: 85.266,
      144: 80.994,
      156: 77.512,
      168: 74.658,
      180: 72.315
    },
    66: {
      12: 687.096,
      24: 354.662,
      36: 244.254,
      48: 189.326,
      60: 156.602,
      72: 134.993,
      84: 119.748,
      96: 108.489,
      108: 99.898,
      120: 93.183,
      132: 87.841,
      144: 83.539,
      156: 80.045,
      168: 77.196,
      180: 74.871
    },
    67: {
      12: 700.093,
      24: 361.797,
      36: 249.407,
      48: 193.511,
      60: 160.228,
      72: 138.267,
      84: 122.786,
      96: 111.367,
      108: 102.667,
      120: 95.880,
      132: 90.496,
      144: 86.173,
      156: 82.678,
      168: 79.844,
      180: 77.549
    },
    68: {
      12: 713.310,
      24: 368.993,
      36: 254.629,
      48: 197.774,
      60: 163.940,
      72: 141.631,
      84: 125.922,
      96: 114.349,
      108: 105.547,
      120: 98.697,
      132: 93.278,
      144: 88.945,
      156: 85.459,
      168: 82.653,
      180: 80.403
    },
    69: {
      12: 725.580,
      24: 376.248,
      36: 259.924,
      48: 202.119,
      60: 167.741,
      72: 145.092,
      84: 129.161,
      96: 117.443,
      108: 108.548,
      120: 101.644,
      132: 96.202,
      144: 91.870,
      156: 88.409,
      168: 85.646,
      180: 83.457
    },
  };

  @override
  void initState() {
    super.initState();

    // Initialisation des animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Pré-remplir d'abord avec les données de simulation
    _prefillSimulationData();

    // Listeners pour le calcul automatique
    _capitalController.addListener(() {
      _formatTextField(_capitalController);
      if (_currentSimulation == SimulationType.parCapital && _age > 0) {
        _effectuerCalcul();
      }
    });

    _primeController.addListener(() {
      _formatTextField(_primeController);
      if (_currentSimulation == SimulationType.parPrime && _age > 0) {
        _effectuerCalcul();
      }
    });

    _dureeController.addListener(() {
      if (_dureeController.text.isNotEmpty && _age > 0) {
        int? duree = int.tryParse(_dureeController.text);
        if (duree != null) {
          setState(() {
            _dureeEnMois = _selectedUnite == 'années' ? duree * 12 : duree;
          });
          _effectuerCalcul();
        }
      }
    });

    // Déplacer ce code à la fin de initState()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forcer un recalcul après le premier rendu
      if (_age > 0 &&
          (_capitalController.text.isNotEmpty ||
              _primeController.text.isNotEmpty)) {
        _effectuerCalcul();
      }
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

        // Gérer la date de naissance
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
                _clientDateNaissance = finalDate;
                _clientDateNaissanceController.text =
                    '${finalDate.day.toString().padLeft(2, '0')}/${finalDate.month.toString().padLeft(2, '0')}/${finalDate.year}';
                final now = DateTime.now();
                _clientAge = now.year - finalDate.year;
                if (now.month < finalDate.month ||
                    (now.month == finalDate.month && now.day < finalDate.day)) {
                  _clientAge--;
                }
                // Utiliser l'âge du client pour le calcul
                _age = _clientAge;
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

    if (!_isCommercial) {
      _loadUserData();
    }
  }

  void _prefillSimulationData() {
    if (widget.simulationData != null) {
      final data = widget.simulationData!;

      // Type de simulation
      if (data['typeSimulation'] != null) {
        setState(() {
          _selectedSimulationType = data['typeSimulation'];
          _currentSimulation = data['typeSimulation'] == 'Par Capital'
              ? SimulationType.parCapital
              : SimulationType.parPrime;
        });
      }

      // Capital ou prime
      if (data['capital'] != null &&
          _currentSimulation == SimulationType.parCapital) {
        _capitalController.text = _formatNumber(data['capital'].toDouble());
      }
      if (data['prime'] != null &&
          _currentSimulation == SimulationType.parPrime) {
        _primeController.text = _formatNumber(data['prime'].toDouble());
      }

      // Durée et unité
      if (data['duree'] != null) {
        _dureeController.text = data['duree'].toString();
        int duree = int.tryParse(data['duree'].toString()) ?? 0;
        _dureeEnMois = _selectedUnite == 'années' ? duree * 12 : duree;
      }
      if (data['dureeUnite'] != null) {
        setState(() {
          _selectedUnite = data['dureeUnite'];
        });
      }

      // Périodicité
      if (data['periodicite'] != null) {
        setState(() {
          switch (data['periodicite']) {
            case 'mensuelle':
              _selectedPeriode = Periode.mensuel;
              break;
            case 'trimestrielle':
              _selectedPeriode = Periode.trimestriel;
              break;
            case 'semestrielle':
              _selectedPeriode = Periode.semestriel;
              break;
            case 'annuelle':
              _selectedPeriode = Periode.annuel;
              break;
          }
        });
      }

      // Résultat
      if (data['resultat'] != null) {
        if (_currentSimulation == SimulationType.parCapital) {
          _calculatedPrime = data['resultat'].toDouble();
        } else {
          _calculatedCapital = data['resultat'].toDouble();
        }
      }

      // Forcer le recalcul après un court délai
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _age > 0) {
          _effectuerCalcul();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();

    // Dispose des contrôleurs
    _capitalController.dispose();
    _primeController.dispose();
    _dureeController.dispose();
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

  // Méthode pour charger les données utilisateur
  Future<void> _loadUserData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        // Même sans token, on peut recalculer avec les données de simulation
        if (_age > 0 &&
            (_capitalController.text.isNotEmpty ||
                _primeController.text.isNotEmpty)) {
          _effectuerCalcul();
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<String, dynamic>? userData;

        // 1) Cas standard: { success: true, user: { ... } }
        if (data['success'] == true &&
            data['user'] != null &&
            data['user'] is Map) {
          userData = Map<String, dynamic>.from(data['user']);
        }
        // 2) Cas nested: { success: true, data: { ... } }
        else if (data['success'] == true &&
            data['data'] != null &&
            data['data'] is Map) {
          userData = Map<String, dynamic>.from(data['data']);
        }
        // 3) Direct user object
        else if (data is Map && data.containsKey('id')) {
          userData = Map<String, dynamic>.from(data);
        }

        if (userData != null && userData.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userData = userData!;
              // Extraire la date de naissance et calculer l'âge
              if (_userData['date_naissance'] != null) {
                _dateNaissance = DateTime.parse(_userData['date_naissance']);
                final maintenant = DateTime.now();
                _age = maintenant.year - _dateNaissance!.year;
                if (maintenant.month < _dateNaissance!.month ||
                    (maintenant.month == _dateNaissance!.month &&
                        maintenant.day < _dateNaissance!.day)) {
                  _age--;
                }
              }
            });

            // Recalculer après le chargement des données utilisateur
            if (_age > 0 &&
                (_capitalController.text.isNotEmpty ||
                    _primeController.text.isNotEmpty)) {
              _effectuerCalcul();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
      // Recalculer même en cas d'erreur
      if (_age > 0 &&
          (_capitalController.text.isNotEmpty ||
              _primeController.text.isNotEmpty)) {
        _effectuerCalcul();
      }
    }
  }

  // Méthodes pour la simulation (identiques à simulation_serenite.dart)
  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  void _formatTextField(TextEditingController controller) {
    String text = controller.text.replaceAll(' ', '');
    if (text.isNotEmpty) {
      double? value = double.tryParse(text);
      if (value != null) {
        String formatted = _formatNumber(value);
        if (formatted != controller.text) {
          controller.value = controller.value.copyWith(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    }
  }

  int _findDureeTarifaire(int dureeSaisie) {
    if (_tarifaire.isEmpty) return dureeSaisie;

    List<int> durees = _tarifaire[18]!.keys.toList()..sort();
    for (int duree in durees) {
      if (duree >= dureeSaisie) return duree;
    }
    return durees.last;
  }

  double _getPrimePour1000() {
    if (_age < 18 || _age > 69) return 0.0;

    int duree = _findDureeTarifaire(_dureeEnMois);

    if (!_tarifaire.containsKey(_age)) {
      List<int> ages = _tarifaire.keys.toList()..sort();
      for (int a in ages) {
        if (a >= _age) {
          _age = a;
          break;
        }
      }
      if (_age > ages.last) _age = ages.last;
    }

    return _tarifaire[_age]?[duree] ?? 0.0;
  }

  double _getCoefficientPeriodicite() {
    switch (_selectedPeriode) {
      case Periode.mensuel:
        return 1.0 / 12;
      case Periode.trimestriel:
        return 1.0 / 4;
      case Periode.semestriel:
        return 1.0 / 2;
      case Periode.annuel:
        return 1.0;
    }
  }

  void _effectuerCalcul() async {
    if (_age < 18 || _age > 69) {
      _showProfessionalDialog(
        title: 'Limite d\'âge dépassée',
        message:
            'Le Coris Sérénité est disponible pour les personnes âgées de 18 à 69 ans. L\'âge actuel (${_age} ans) n\'est pas éligible pour ce produit.',
        icon: Icons.schedule_outlined,
        iconColor: orangeWarning,
        backgroundColor: orangeWarning,
      );
      return;
    }

    // Vérification de la durée maximale (15 ans = 180 mois)
    if (_dureeController.text.isNotEmpty) {
      int duree = int.tryParse(_dureeController.text) ?? 0;
      if (_selectedUnite == 'années' && duree > 15) {
        _showErrorSnackBar('La durée du contrat ne peut pas dépasser 15 ans');
        _dureeController.text = '15';
        _dureeEnMois = 15 * 12;
      } else if (_selectedUnite == 'mois' && duree > 180) {
        _showErrorSnackBar(
            'La durée du contrat ne peut pas dépasser 180 mois (15 ans)');
        _dureeController.text = '180';
        _dureeEnMois = 180;
      }
    }

    double primePour1000 = _getPrimePour1000();
    if (primePour1000 == 0.0) {
      return;
    }

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        double coefficient = _getCoefficientPeriodicite();

        if (_currentSimulation == SimulationType.parCapital) {
          // Calcul à partir du capital saisi
          String capitalText = _capitalController.text.replaceAll(' ', '');
          double capital = double.tryParse(capitalText) ?? 0;
          if (capital <= 0) {
            _calculatedPrime = 0;
            _calculatedCapital = 0;
            return;
          }

          // Vérification du capital maximum (40 000 000 FCFA)
          if (capital > 40000000) {
            _showProfessionalDialog(
              title: 'Limite de capital dépassée',
              message:
                  'Le capital maximum garanti pour CORIS SÉRÉNITÉ est de 40 000 000 FCFA. Le montant a été ajusté automatiquement.',
              icon: Icons.monetization_on_outlined,
              iconColor: orangeWarning,
              backgroundColor: orangeWarning,
            );
            capital = 40000000;
            _capitalController.text = _formatNumber(capital);
          }

          // Calcul de la prime annuelle
          double primeAnnuelle = (capital / 1000) * primePour1000;

          // Ajustement selon la périodicité
          if (_selectedPeriode == Periode.annuel) {
            _calculatedPrime = primeAnnuelle;
          } else {
            // Pour les autres périodicités, on divise la prime annuelle
            _calculatedPrime = primeAnnuelle * coefficient;
          }

          // Le capital reste celui saisi par l'utilisateur
          _calculatedCapital = capital;
        } else {
          // Calcul à partir de la prime saisie
          String primeText = _primeController.text.replaceAll(' ', '');
          double prime = double.tryParse(primeText) ?? 0;
          if (prime <= 0) {
            _calculatedPrime = 0;
            _calculatedCapital = 0;
            return;
          }

          // Prime annuelle pour 1000 FCFA de capital
          double primeAnnuellePour1000 = primePour1000;

          // Ajustement selon la périodicité
          double primePeriodiquePour1000;
          if (_selectedPeriode == Periode.annuel) {
            primePeriodiquePour1000 = primeAnnuellePour1000;
          } else {
            primePeriodiquePour1000 = primeAnnuellePour1000 * coefficient;
          }

          // Calcul du capital garanti
          _calculatedCapital = (prime / primePeriodiquePour1000) * 1000;

          // Vérification du capital maximum (40 000 000 FCFA)
          if (_calculatedCapital > 40000000) {
            _showProfessionalDialog(
              title: 'Limite de capital dépassée',
              message:
                  'Le capital maximum garanti pour CORIS SÉRÉNITÉ est de 40 000 000 FCFA. Le montant et la prime ont été ajustés automatiquement.',
              icon: Icons.monetization_on_outlined,
              iconColor: orangeWarning,
              backgroundColor: orangeWarning,
            );
            _calculatedCapital = 40000000;
            // Recalculer la prime correspondante
            double primeAnnuelle = (_calculatedCapital / 1000) * primePour1000;
            if (_selectedPeriode == Periode.annuel) {
              prime = primeAnnuelle;
            } else {
              prime = primeAnnuelle * coefficient;
            }
            _primeController.text = _formatNumber(prime);
          }

          // La prime reste celle saisie par l'utilisateur
          _calculatedPrime = prime;
        }
      });
    }
  }

  void _selectDateEffet() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _dateEffetContrat = picked;
          // Calculer la date d'échéance
          final duree = int.tryParse(_dureeController.text) ?? 0;
          final dureeMois = _selectedUnite == 'années' ? duree * 12 : duree;
          _dateEcheanceContrat = picked.add(Duration(days: dureeMois * 30));
        });
      }
    }
  }

  void _onSimulationTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedSimulationType = newValue;
        _currentSimulation = newValue == 'Par Capital'
            ? SimulationType.parCapital
            : SimulationType.parPrime;
        _effectuerCalcul();
      });
    }
  }

  void _onPeriodeChanged(Periode? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedPeriode = newValue;
        _effectuerCalcul();
      });
    }
  }

  void _onUniteChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedUnite = newValue;
        if (_dureeController.text.isNotEmpty) {
          int duree = int.tryParse(_dureeController.text) ?? 0;

          // Vérification de la durée maximale (15 ans = 180 mois)
          if (_selectedUnite == 'années' && duree > 15) {
            _showProfessionalDialog(
              title: 'Limite de durée dépassée',
              message:
                  'La durée maximale du contrat CORIS SÉRÉNITÉ est de 15 ans. La durée a été ajustée automatiquement.',
              icon: Icons.schedule_outlined,
              iconColor: orangeWarning,
              backgroundColor: orangeWarning,
            );
            _dureeController.text = '15';
            duree = 15;
          } else if (_selectedUnite == 'mois' && duree > 180) {
            _showProfessionalDialog(
              title: 'Limite de durée dépassée',
              message:
                  'La durée maximale du contrat CORIS SÉRÉNITÉ est de 180 mois (15 ans). La durée a été ajustée automatiquement.',
              icon: Icons.schedule_outlined,
              iconColor: orangeWarning,
              backgroundColor: orangeWarning,
            );
            _dureeController.text = '180';
            duree = 180;
          }

          _dureeEnMois = _selectedUnite == 'années' ? duree * 12 : duree;
          _effectuerCalcul();
        }
      });
    }
  }

  String _getPeriodeTextForDisplay() {
    switch (_selectedPeriode) {
      case Periode.mensuel:
        return 'Mensuel';
      case Periode.trimestriel:
        return 'Trimestriel';
      case Periode.semestriel:
        return 'Semestriel';
      case Periode.annuel:
        return 'Annuel';
    }
  }

  // Méthodes pour la souscription
  String _formatMontant(double montant) {
    return "${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
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
          Text(message)
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
          Text(message)
        ]),
        backgroundColor: vertSucces,
      ),
    );
  }

  void _showProfessionalDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                        backgroundColor.withAlpha(25), Colors.white),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: bleuCoris,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bleuCoris,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Compris',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _nextStep() {
    final maxStep = _isCommercial ? 3 : 2;
    if (_currentStep < maxStep) {
      bool canProceed = false;

      if (_isCommercial) {
        // Pour les commerciaux: step 0 = infos client, step 1 = simulation, step 2 = bénéficiaire
        if (_currentStep == 0 && _validateStepClientInfo()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStep2()) {
          canProceed = true;
        }
      } else {
        // Pour les clients: step 0 = simulation, step 1 = bénéficiaire
        if (_currentStep == 0 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep2()) {
          canProceed = true;
        }
      }

      if (canProceed) {
        // Ensure calculations are up-to-date when moving to the recap
        if (_currentStep + 1 == maxStep) {
          try {
            _effectuerCalcul();
          } catch (e) {
            debugPrint('Erreur lors du calcul avant récapitulatif: $e');
          }
        }
        setState(() => _currentStep++);
        _progressController.forward();
        _animationController.reset();
        _animationController.forward();
        _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic);
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
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
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
      _clientAge--;
    }
    if (_clientAge < 18 || _clientAge > 69) {
      _showErrorSnackBar(
          'Âge du client non valide (18-69 ans requis). Âge calculé: $_clientAge ans');
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
    _age = _clientAge;
    return true;
  }

  bool _validateStep1() {
    // Si c'est un client, valider son propre âge
    if (!_isCommercial) {
      // Recalculer l'âge si la date de naissance est disponible
      if (_dateNaissance != null) {
        final maintenant = DateTime.now();
        _age = maintenant.year - _dateNaissance!.year;
        if (maintenant.month < _dateNaissance!.month ||
            (maintenant.month == _dateNaissance!.month &&
                maintenant.day < _dateNaissance!.day)) {
          _age--;
        }
      }

      // Valider l'âge seulement à l'étape 2 si disponible
      // À l'étape 1, on ne valide pas l'âge car il sera calculé automatiquement
      if (_currentStep == 1) {
        if (_age > 0) {
          if (_age < 18 || _age > 69) {
            _showErrorSnackBar(
                'Âge non valide (18-69 ans requis). Votre âge: $_age ans');
            return false;
          }
        } else if (_age <= 0) {
          _showErrorSnackBar(
              'Veuillez renseigner votre date de naissance dans votre profil');
          return false;
        }
      }
    }

    // Valider les champs de simulation
    if (_currentSimulation == SimulationType.parCapital) {
      if (_capitalController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez saisir un capital');
        return false;
      }
    } else {
      if (_primeController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez saisir une prime');
        return false;
      }
    }

    if (_dureeController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir une durée');
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    if (_beneficiaireNomController.text.trim().isEmpty ||
        _beneficiaireContactController.text.trim().isEmpty ||
        _personneContactNomController.text.trim().isEmpty ||
        _personneContactTelController.text.trim().isEmpty ||
        _pieceIdentite == null) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return false;
    }
    return true;
  }

  // Méthodes d'interface utilisateur
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.security,
                                  color: blanc, size: 28),
                              const SizedBox(width: 12),
                              const Text('CORIS SÉRÉNITÉ',
                                  style: TextStyle(
                                      color: blanc,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Protection et épargne pour votre sérénité',
                              style: TextStyle(
                                  color: blanc.withValues(alpha: 0.9),
                                  fontSize: 14)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: blanc),
                  onPressed: () => Navigator.pop(context)),
            ),
            SliverToBoxAdapter(
                child: Container(
                    margin: const EdgeInsets.all(20),
                    child: _buildModernProgressIndicator())),
          ];
        },
        body: Column(
          children: [
            Expanded(
                child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _isCommercial
                        ? [
                            _buildStepClientInfo(), // Page 0: Informations client (commercial uniquement)
                            _buildStep1(), // Page 1: Simulation
                            _buildStep2(), // Page 2: Bénéficiaire/Contact
                            _buildStep3(), // Page 3: Récapitulatif
                          ]
                        : [
                            _buildStep1(), // Page 0: Simulation
                            _buildStep2(), // Page 1: Bénéficiaire/Contact
                            _buildStep3(), // Page 2: Récapitulatif
                          ])),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneFieldWithIndicatif({
    required TextEditingController controller,
    required String label,
    required String selectedIndicatif,
    required ValueChanged<String?> onIndicatifChanged,
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

  Widget _buildModernProgressIndicator() {
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
      child: Row(children: [
        for (int i = 0; i < (_isCommercial ? 4 : 3); i++) ...[
          Expanded(
              child: Column(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: i <= _currentStep ? bleuCoris : grisLeger,
                    shape: BoxShape.circle,
                    boxShadow: i <= _currentStep
                        ? [
                            BoxShadow(
                                color: bleuCoris.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : null),
                child: Icon(
                    _isCommercial
                        ? (i == 0
                            ? Icons.person
                            : i == 1
                                ? Icons.monetization_on
                                : i == 2
                                    ? Icons.person_add
                                    : Icons.check_circle)
                        : (i == 0
                            ? Icons.monetization_on
                            : i == 1
                                ? Icons.person_add
                                : Icons.check_circle),
                    color: i <= _currentStep ? blanc : grisTexte,
                    size: 20)),
            const SizedBox(height: 6),
            Text(
                _isCommercial
                    ? (i == 0
                        ? 'Client'
                        : i == 1
                            ? 'Simulation'
                            : i == 2
                                ? 'Informations'
                                : 'Validation')
                    : (i == 0
                        ? 'Simulation'
                        : i == 1
                            ? 'Informations'
                            : 'Validation'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i <= _currentStep ? FontWeight.w600 : FontWeight.w400,
                    color: i <= _currentStep ? bleuCoris : grisTexte)),
          ])),
          if (i < (_isCommercial ? 3 : 2))
            Expanded(
                child: Container(
                    height: 2,
                    margin:
                        const EdgeInsets.only(bottom: 20, left: 6, right: 6),
                    decoration: BoxDecoration(
                        color: i < _currentStep ? bleuCoris : grisLeger,
                        borderRadius: BorderRadius.circular(1)))),
        ],
      ]),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        label: 'Date de naissance',
                        icon: Icons.calendar_today,
                        onDateSelected: (date) {
                          setState(() {
                            _clientDateNaissance = date;
                            _clientDateNaissanceController.text =
                                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                            // Calculer l'âge et effectuer le calcul
                            final maintenant = DateTime.now();
                            _clientAge = maintenant.year - date.year;
                            if (maintenant.month < date.month ||
                                (maintenant.month == date.month &&
                                    maintenant.day < date.day)) {
                              _clientAge--;
                            }
                            _age = _clientAge;
                            _effectuerCalcul();
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  // Carte de simulation
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6))
                        ]),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: bleuCoris.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.settings,
                                    color: bleuCoris, size: 22)),
                            const SizedBox(width: 12),
                            const Text("Paramètres de simulation",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002B6B))),
                          ]),
                          const SizedBox(height: 20),

                          // Sélecteur de type de simulation
                          _buildSimulationTypeDropdown(),
                          const SizedBox(height: 16),

                          // Champ pour le capital/prime
                          _buildMontantField(),
                          const SizedBox(height: 16),

                          // Champ pour la durée
                          _buildDureeField(),
                          const SizedBox(height: 16),

                          // Sélecteur de périodicité
                          _buildPeriodiciteDropdown(),
                          const SizedBox(height: 16),

                          // Champ date d'effet
                          _buildDateEffetField(),

                          // Affichage du résultat
                          const SizedBox(height: 16),
                          _buildResultDisplay(),
                        ],
                      ),
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

  Widget _buildDateEffetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date d\'effet du contrat',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _selectDateEffet,
          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(
                  text: _dateEffetContrat != null
                      ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                      : ''),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                hintText: 'Sélectionner une date',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.calendar_today,
                    size: 20, color: bleuCoris.withValues(alpha: 0.7)),
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    // Afficher même si les valeurs sont à 0 pendant le calcul
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vertSucces.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vertSucces.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résultat de la simulation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: bleuCoris,
            ),
          ),
          const SizedBox(height: 8),

          // Toujours afficher la prime périodique
          Text(
            'Prime ${_getPeriodeTextForDisplay().toLowerCase()} à verser: ${_formatMontant(_calculatedPrime)}',
            style: TextStyle(
              fontSize: 14,
              color: grisTexte,
            ),
          ),
          const SizedBox(height: 8),

          // Toujours afficher le capital garanti
          Text(
            'Capital garanti: ${_formatMontant(_calculatedCapital)}',
            style: TextStyle(
              fontSize: 14,
              color: grisTexte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<String>(
          value: _selectedSimulationType,
          decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.calculate, color: Color(0xFF002B6B)),
              labelText: 'Type de simulation'),
          items: const [
            DropdownMenuItem(value: 'Par Capital', child: Text('Par Capital')),
            DropdownMenuItem(value: 'Par Prime', child: Text('Par Prime'))
          ],
          onChanged: _onSimulationTypeChanged,
        ),
      ),
    );
  }

  Widget _buildMontantField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            _currentSimulation == SimulationType.parCapital
                ? 'Capital souhaité'
                : 'Prime à verser',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris)),
        const SizedBox(height: 6),
        TextField(
          controller: _currentSimulation == SimulationType.parCapital
              ? _capitalController
              : _primeController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // Validation en temps réel pour le capital
            if (_currentSimulation == SimulationType.parCapital &&
                value.isNotEmpty) {
              String cleanValue = value.replaceAll(' ', '');
              double? montant = double.tryParse(cleanValue);
              if (montant != null && montant > 40000000) {
                _showProfessionalDialog(
                  title: 'Limite de capital dépassée',
                  message:
                      'Le capital maximum garanti pour CORIS SÉRÉNITÉ est de 40 000 000 FCFA.',
                  icon: Icons.monetization_on_outlined,
                  iconColor: orangeWarning,
                  backgroundColor: orangeWarning,
                );
                _capitalController.text = _formatNumber(40000000);
                _capitalController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _capitalController.text.length),
                );
              }
            }
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: 'Ex: 1 000 000',
            hintStyle: const TextStyle(fontSize: 14),
            prefixIcon: Icon(Icons.monetization_on,
                size: 20, color: bleuCoris.withValues(alpha: 0.7)),
            suffixText: 'FCFA',
            filled: true,
            fillColor: fondCarte,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: bleuCoris, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDureeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Durée',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
                flex: 3,
                child: TextField(
                  controller: _dureeController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    // Validation en temps réel pour la durée
                    if (value.isNotEmpty) {
                      int duree = int.tryParse(value) ?? 0;
                      if (_selectedUnite == 'années' && duree > 15) {
                        _showErrorSnackBar(
                            'La durée du contrat ne peut pas dépasser 15 ans');
                        _dureeController.text = '15';
                        _dureeController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _dureeController.text.length),
                        );
                      } else if (_selectedUnite == 'mois' && duree > 180) {
                        _showErrorSnackBar(
                            'La durée du contrat ne peut pas dépasser 180 mois (15 ans)');
                        _dureeController.text = '180';
                        _dureeController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _dureeController.text.length),
                        );
                      }
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    hintText: 'Saisir la durée',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: Icon(Icons.calendar_month,
                        size: 20, color: bleuCoris.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: fondCarte,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: bleuCoris, width: 1.5)),
                  ),
                )),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnite,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    filled: true,
                    fillColor: fondCarte,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: bleuCoris, width: 1.5)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'mois', child: Text('Mois')),
                    DropdownMenuItem(value: 'années', child: Text('Années'))
                  ],
                  onChanged: _onUniteChanged,
                )),
          ],
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DropdownButtonFormField<Periode>(
          value: _selectedPeriode,
          decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF002B6B)),
              labelText: 'Périodicité'),
          items: const [
            DropdownMenuItem(value: Periode.mensuel, child: Text('Mensuel')),
            DropdownMenuItem(
                value: Periode.trimestriel, child: Text('Trimestriel')),
            DropdownMenuItem(
                value: Periode.semestriel, child: Text('Semestriel')),
            DropdownMenuItem(value: Periode.annuel, child: Text('Annuel')),
          ],
          onChanged: _onPeriodeChanged,
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Form(
                key: _formKey,
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFormSection(
                      'Contact d\'urgence',
                      Icons.contact_phone,
                      [
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
            ),
          ),
        );
      },
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

  Widget _buildModernTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildDropdownField(
      {required String? value,
      required String label,
      required IconData icon,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
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
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
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
                          ? Icons.check_circle_outlined
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
                  style: TextStyle(fontSize: 11, color: grisTexte)),
            ]),
          ),
        ),
      ]),
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
              child: _isCommercial
                  ? _buildRecapContent()
                  : FutureBuilder<Map<String, dynamic>>(
                      future: _loadUserDataForRecap(),
                      builder: (context, snapshot) {
                        // Pour les clients, attendre le chargement des données
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                              child:
                                  CircularProgressIndicator(color: bleuCoris));
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                              'Erreur chargement données récapitulatif: ${snapshot.error}');
                          // En cas d'erreur, essayer d'utiliser _userData si disponible
                          if (_userData.isNotEmpty) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildRecapContent(userData: _userData),
                            );
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
                        // Prioriser snapshot.data, sinon utiliser _userData, sinon Map vide
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
                              child:
                                  CircularProgressIndicator(color: bleuCoris));
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildRecapContent(userData: userData),
                        );
                      },
                    ),
            ));
      },
    );
  }

  /// Charge les données utilisateur pour le récapitulatif (uniquement pour les clients)
  /// Cette méthode est appelée dans le FutureBuilder pour charger les données à la volée
  /// si elles ne sont pas déjà disponibles dans _userData
  ///
  /// IMPORTANT:
  /// - Pour les CLIENTS: Charge les données du client connecté depuis /users/profile
  /// - Pour les COMMERCIAUX: Retourne null car les données sont dans les contrôleurs
  Future<Map<String, dynamic>> _loadUserDataForRecap() async {
    /**
     * MODIFICATION IMPORTANTE:
     * 
     * Pour les CLIENTS (plateforme client):
     * - Les informations sont déjà pré-enregistrées dans la base de données lors de l'inscription
     * - On doit TOUJOURS charger les données depuis /users/profile qui récupère le profil de l'utilisateur connecté
     * 
     * Pour les COMMERCIAUX (plateforme commercial):
     * - Le commercial saisit les informations du client dans les champs du formulaire
     * - On n'a pas besoin de charger les données ici, elles sont dans les contrôleurs
     * - Cette fonction ne sera pas appelée pour les commerciaux (voir _buildStep3)
     */
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

      // Pour les clients, charger les données depuis le profil utilisateur
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔄 Chargement des données utilisateur depuis l\'API...');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

      // Fallback vers _userData si la requête échoue
      return _userData.isNotEmpty ? _userData : {};
    } catch (e) {
      debugPrint(
          '❌ Erreur chargement données utilisateur pour récapitulatif: $e');
      // Fallback vers _userData en cas d'erreur
      final result = _userData.isNotEmpty ? _userData : <String, dynamic>{};
      return result;
    }
  }

  /// Construit le contenu du récapitulatif
  ///
  /// [userData] : Données de l'utilisateur (client connecté depuis la base de données)
  ///
  /// IMPORTANT:
  /// - Si _isCommercial = true: Utilise les données des contrôleurs (infos client saisies par le commercial)
  /// - Si _isCommercial = false: Utilise userData (infos du client connecté depuis la base de données)
  Widget _buildRecapContent({Map<String, dynamic>? userData}) {
    final duree = _dureeController.text.isNotEmpty
        ? int.tryParse(_dureeController.text) ?? 0
        : 0;

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
            'date_naissance': _clientDateNaissance?.toIso8601String(),
            'lieu_naissance': _clientLieuNaissanceController.text,
            'adresse': _clientAdresseController.text,
          }
        : (userData ?? _userData);

    return ListView(children: [
      // Afficher les informations du client (toujours dans "Informations Personnelles")
      _buildRecapSection(
        'Informations Personnelles',
        Icons.person,
        bleuCoris,
        [
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
              displayData['date_naissance'] != null
                  ? _formatDate(displayData['date_naissance'].toString())
                  : 'Non renseigné'),
          _buildCombinedRecapRow(
              'Lieu de naissance',
              displayData['lieu_naissance'] ?? 'Non renseigné',
              'Adresse',
              displayData['adresse'] ?? 'Non renseigné'),
        ],
      ),
      const SizedBox(height: 20),
      _buildRecapSection('Produit Souscrit', Icons.security, vertSucces, [
        // Produit et Prime
        _buildCombinedRecapRow(
            'Produit',
            'CORIS SÉRÉNITÉ',
            'Prime ${_getPeriodeTextForDisplay()}',
            _formatMontant(_calculatedPrime)),

        // Capital au terme et Durée du contrat
        _buildCombinedRecapRow(
            'Capital au terme',
            '${_formatNumber(_calculatedCapital)} FCFA',
            'Durée du contrat',
            '$duree ${_selectedUnite == 'années' ? 'ans' : 'mois'}'),

        // Date d'effet et Date d'échéance
        _buildCombinedRecapRow(
            'Date d\'effet',
            _dateEffetContrat != null
                ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                : 'Non définie',
            'Date d\'échéance',
            _dateEcheanceContrat != null
                ? '${_dateEcheanceContrat!.day}/${_dateEcheanceContrat!.month}/${_dateEcheanceContrat!.year}'
                : 'Non définie'),
      ]),
      const SizedBox(height: 20),
      _buildRecapSection(
          'Bénéficiaire et Contact d\'urgence', Icons.contacts, orangeWarning, [
        _buildSubsectionTitle('Bénéficiaire'),
        _buildRecapRow(
            'Nom complet',
            _beneficiaireNomController.text.isEmpty
                ? 'Non renseigné'
                : _beneficiaireNomController.text),
        _buildRecapRow('Contact',
            '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text.isEmpty ? 'Non renseigné' : _beneficiaireContactController.text}'),
        _buildRecapRow('Lien de parenté', _selectedLienParente),
        const SizedBox(height: 12),
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
      const SizedBox(height: 20),
      SubscriptionRecapWidgets.buildDocumentsSection(
        pieceIdentite: _pieceIdentite?.path.split('/').last,
        onDocumentTap: _pieceIdentite != null
            ? () => _viewLocalDocument(
                _pieceIdentite!, _pieceIdentite!.path.split('/').last)
            : null,
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: orangeWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: orangeWarning.withValues(alpha: 0.3))),
        child: Column(children: [
          Icon(Icons.info_outline, color: orangeWarning, size: 28),
          const SizedBox(height: 10),
          Text('Vérification Importante',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: orangeWarning,
                  fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Vérifiez attentivement toutes les informations ci-dessus. Une fois la souscription validée, certaines modifications ne seront plus possibles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: grisTexte, fontSize: 12, height: 1.4)),
        ]),
      ),
      const SizedBox(height: 20),
    ]);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
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

  void _viewLocalDocument(File document, String filename) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          localFile: document,
          documentName: filename,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.arrow_back, color: bleuCoris, size: 20),
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
              onPressed: _currentStep == (_isCommercial ? 3 : 2)
                  ? _showPaymentOptions
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                  backgroundColor: bleuCoris,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  shadowColor: bleuCoris.withValues(alpha: 0.3)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                    _currentStep == (_isCommercial ? 3 : 2)
                        ? 'Payer maintenant'
                        : 'Suivant',
                    style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(width: 8),
                Icon(
                    _currentStep == (_isCommercial ? 3 : 2)
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: blanc,
                    size: 20),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _showPaymentOptions() {
    if (mounted) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PaymentBottomSheet(
              onPayNow: _processPayment, onPayLater: _saveAsProposition));
    }
  }

  Future<int> _saveSubscriptionData() async {
    try {
      final subscriptionService = SubscriptionService();

      final subscriptionData = {
        'product_type': 'coris_serenite',
        'capital': _calculatedCapital,
        'prime': _calculatedPrime,
        'duree': int.parse(_dureeController.text),
        'duree_type': _selectedUnite,
        'periodicite': _getPeriodeTextForDisplay().toLowerCase(),
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
        'date_effet': _dateEffetContrat?.toIso8601String(),
        'date_echeance': _dateEcheanceContrat?.toIso8601String(),
        'piece_identite': _pieceIdentite?.path.split('/').last ?? '',
        // NE PAS inclure 'status' ici - il sera 'proposition' par défaut dans la base
      };

      // Si c'est un commercial, ajouter les infos client
      if (_isCommercial) {
        subscriptionData['client_info'] = {
          'nom': _clientNomController.text.trim(),
          'prenom': _clientPrenomController.text.trim(),
          'date_naissance':
              _clientDateNaissance?.toIso8601String().split('T').first,
          'lieu_naissance': _clientLieuNaissanceController.text.trim(),
          'telephone':
              '$_selectedClientIndicatif ${_clientTelephoneController.text.trim()}',
          'email': _clientEmailController.text.trim(),
          'adresse': _clientAdresseController.text.trim(),
          'civilite': _selectedClientCivilite,
          'numero_piece_identite': _clientNumeroPieceController.text.trim(),
        };
      }

      final response =
          await subscriptionService.createSubscription(subscriptionData);
      final responseData = jsonDecode(response.body);

      if (response.statusCode != 201 || !responseData['success']) {
        throw Exception(
            responseData['message'] ?? 'Erreur lors de la sauvegarde');
      }

      // RETOURNER l'ID de la souscription créée
      return responseData['data']['id'];
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
        builder: (context) => LoadingDialog(paymentMethod: paymentMethod));

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
      }

      debugPrint('✅ Document uploadé avec succès');
    } catch (e) {
      debugPrint('❌ Exception upload document: $e');
    }
  }

  void _showSuccessDialog(bool isPaid) {
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(isPaid: isPaid));
  }
}

// Classes pour les dialogues
class LoadingDialog extends StatelessWidget {
  final String paymentMethod;
  const LoadingDialog({super.key, required this.paymentMethod});

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
        ));
  }
}

class SuccessDialog extends StatelessWidget {
  final bool isPaid;
  const SuccessDialog({super.key, required this.isPaid});

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
            Text(isPaid ? 'Souscription Réussie!' : 'Proposition Enregistrée!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF002B6B))),
            const SizedBox(height: 12),
            Text(
                isPaid
                    ? 'Félicitations! Votre contrat CORIS SÉRÉNITÉ est maintenant actif. Vous recevrez un email de confirmation sous peu.'
                    : 'Votre proposition a été enregistrée avec succès. Vous pouvez effectuer le paiement plus tard depuis votre espace client.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 14, height: 1.4)),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/client_home', (route) => false),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF002B6B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text('Retour à l\'accueil',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)))),
          ]),
        ));
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
                    Expanded(child: Divider(color: Colors.grey[300]))
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
