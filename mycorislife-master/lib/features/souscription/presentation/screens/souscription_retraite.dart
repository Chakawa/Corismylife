import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:mycorislife/services/subscription_service.dart';
import '../../../client/presentation/screens/document_viewer_page.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/local_data_service.dart';
import '../../../../core/widgets/subscription_recap_widgets.dart';
import '../widgets/signature_dialog_syncfusion.dart' as SignatureDialogFile;
import 'dart:typed_data';
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/services/wave_payment_handler.dart';

// Enum pour le type de simulation
enum SimulationType { parPrime, parCapital }

enum Periode { mensuel, trimestriel, semestriel, annuel }

/// Page de souscription pour le produit CORIS RETRAITE
/// Permet de souscrire à une assurance retraite
///
/// [simulationData] : Données de simulation (capital, prime, durée, périodicité)
/// [clientId] : ID du client si souscription par commercial (optionnel)
/// [clientData] : Données du client si souscription par commercial (optionnel)
/// [subscriptionId] : ID de la souscription si modification d'une proposition existante
/// [existingData] : Données existantes de la proposition à modifier
class SouscriptionRetraitePage extends StatefulWidget {
  final Map<String, dynamic>? simulationData;
  final String? clientId; // ID du client si souscription par commercial
  final Map<String, dynamic>?
      clientData; // Données du client si souscription par commercial
  final int? subscriptionId; // ID pour modification
  final Map<String, dynamic>?
      existingData; // Données existantes pour modification

  const SouscriptionRetraitePage({
    super.key,
    this.simulationData,
    this.clientId,
    this.clientData,
    this.subscriptionId,
    this.existingData,
  });

  @override
  SouscriptionRetraitePageState createState() =>
      SouscriptionRetraitePageState();
}

class SouscriptionRetraitePageState extends State<SouscriptionRetraitePage>
    with TickerProviderStateMixin {
  // Charte graphique CORIS
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color bleuSecondaire = Color(0xFF1E4A8C);
  static const Color blanc = Colors.white;
  static const Color fondCarte = Color(0xFFF8FAFC);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color grisLeger = Color(0xFFF1F5F9);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color orangeWarning = Color(0xFFF59E0B);
  static const Color orangeCoris = Color(0xFFFF6B00);

  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _currentStep = 0;
  bool _useLocalData = false;

  // Contrôleurs pour la simulation
  final TextEditingController _primeController = TextEditingController();
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();
  final FocusNode _dureeFocusNode = FocusNode();

  // Variables pour la simulation
  int _dureeEnAnnees = 5;
  String _selectedUnite = 'années';
  Periode? _selectedPeriode; // Initialisé dans initState
  SimulationType _currentSimulation = SimulationType.parPrime;
  String _selectedSimulationType = 'Par Prime';
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
  final _dateEffetController = TextEditingController();
  String _selectedLienParenteUrgence = 'Parent';
  DateTime? _dateEffetContrat;
  DateTime? _dateEcheanceContrat;
  String _selectedBeneficiaireIndicatif = '+225';
  String _selectedContactIndicatif = '+225';

  File? _pieceIdentite;
  String? _pieceIdentiteLabel;

  // Signature du client
  Uint8List? _clientSignature;

  // Mode de paiement
  String? _selectedModePaiement;
  String? _selectedBanque;
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
  final _banqueController = TextEditingController();
  final _ribUnifiedController = TextEditingController(); // RIB unifié: XXXXX (5 chiffres) / XXXXXXXXXXX / XX
  final _numeroMobileMoneyController = TextEditingController();
  final _nomStructureController = TextEditingController(); // Pour Prélèvement à la source
  final _numeroMatriculeController = TextEditingController(); // Pour Prélèvement à la source
  final _corisMoneyPhoneController = TextEditingController(); // Pour CORIS Money
  final List<String> _modePaiementOptions = [
    'Virement',
    'Wave',
    'Orange Money',
    'Prélèvement à la source',
    'CORIS Money'
  ];

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

  // Primes minimales par périodicité
  final Map<String, int> minPrimes = {
    'mensuel': 5000,
    'trimestriel': 15000,
    'semestriel': 30000,
    'annuel': 60000,
  };

  // Table tarifaire: CAPITAL À TERME pour les primes de référence (identique à la simulation)
  final Map<int, Map<String, double>> capitalValues = {
    5: {
      'mensuel': 605463.405379,
      'trimestriel': 615056.504123,
      'semestriel': 620331.447928,
      'annuel': 625666.388106
    },
    6: {
      'mensuel': 739294.364577,
      'trimestriel': 752266.795228,
      'semestriel': 758213.774878,
      'annuel': 764734.523010
    },
    7: {
      'mensuel': 877714.810967,
      'trimestriel': 891453.723199,
      'semestriel': 898104.646416,
      'annuel': 908670.042636
    },
    8: {
      'mensuel': 1020882.065727,
      'trimestriel': 1038327.916972,
      'semestriel': 1045708.931812,
      'annuel': 1057643.305449
    },
    9: {
      'mensuel': 1168958.840396,
      'trimestriel': 1190342.707527,
      'semestriel': 1190479.470698,
      'annuel': 1211830.632461
    },
    10: {
      'mensuel': 1322113.421481,
      'trimestriel': 1344587.648202,
      'semestriel': 1356596.978444,
      'annuel': 1371414.515917
    },
    11: {
      'mensuel': 1480519.861382,
      'trimestriel': 1507300.829349,
      'semestriel': 1520248.598961,
      'annuel': 1536583.835295
    },
    12: {
      'mensuel': 1644358.175855,
      'trimestriel': 1675729.671837,
      'semestriel': 1689628.026197,
      'annuel': 1707534.080851
    },
    13: {
      'mensuel': 1813844.548229,
      'trimestriel': 1846605.003713,
      'semestriel': 1861472.384183,
      'annuel': 1880974.450438
    },
    14: {
      'mensuel': 1989081.640624,
      'trimestriel': 2026309.492304,
      'semestriel': 2042794.643842,
      'annuel': 2063978.367524
    },
    15: {
      'mensuel': 2170358.312385,
      'trimestriel': 2213524.637995,
      'semestriel': 2230463.182648,
      'annuel': 2253387.421708
    },
    16: {
      'mensuel': 2361663.347047,
      'trimestriel': 2402847.877909,
      'semestriel': 2424700.120313,
      'annuel': 2449425.792789
    },
    17: {
      'mensuel': 2559654.057923,
      'trimestriel': 2602620.867097,
      'semestriel': 2625735.350796,
      'annuel': 2652329.506857
    },
    18: {
      'mensuel': 2764594.793679,
      'trimestriel': 2809385.910906,
      'semestriel': 2833806.814345,
      'annuel': 2862326.710918
    },
    19: {
      'mensuel': 2976698.105187,
      'trimestriel': 3019148.619548,
      'semestriel': 3044903.438595,
      'annuel': 3079677.957121
    },
    20: {
      'mensuel': 3196225.032957,
      'trimestriel': 3240492.134693,
      'semestriel': 3267645.786918,
      'annuel': 3304636.466941
    },
    21: {
      'mensuel': 3423435.402467,
      'trimestriel': 3469582.672868,
      'semestriel': 3498184.113972,
      'annuel': 3537468.588654
    },
    22: {
      'mensuel': 3658598.135282,
      'trimestriel': 3701991.400963,
      'semestriel': 3736791.284233,
      'annuel': 3778449.797473
    },
    23: {
      'mensuel': 3901991.563746,
      'trimestriel': 3947234.413457,
      'semestriel': 3983749.705453,
      'annuel': 4027865.351705
    },
    24: {
      'mensuel': 4153903.762206,
      'trimestriel': 4201060.933389,
      'semestriel': 4239351.671416,
      'annuel': 4286010.450336
    },
    25: {
      'mensuel': 4414632.887612,
      'trimestriel': 4458560.426312,
      'semestriel': 4498666.347671,
      'annuel': 4547912.261262
    },
    26: {
      'mensuel': 4684487.532408,
      'trimestriel': 4730283.355211,
      'semestriel': 4772290.396112,
      'annuel': 4824259.001727
    },
    27: {
      'mensuel': 4963787.683771,
      'trimestriel': 5011516.586104,
      'semestriel': 5055491.266247,
      'annuel': 5110277.878109
    },
    28: {
      'mensuel': 5252862.131642,
      'trimestriel': 5296815.505562,
      'semestriel': 5348604.207638,
      'annuel': 5406307.415163
    },
    29: {
      'mensuel': 5552054.799978,
      'trimestriel': 5597877.362131,
      'semestriel': 5651976.081074,
      'annuel': 5712697.986015
    },
    30: {
      'mensuel': 5861719.211707,
      'trimestriel': 5909476.383267,
      'semestriel': 5965965.970183,
      'annuel': 6029812.226846
    },
    31: {
      'mensuel': 6182221.877845,
      'trimestriel': 6225575.781317,
      'semestriel': 6284512.371581,
      'annuel': 6358025.466106
    },
    32: {
      'mensuel': 6513942.137299,
      'trimestriel': 6559144.247123,
      'semestriel': 6620641.030858,
      'annuel': 6697726.168741
    },
    33: {
      'mensuel': 6857272.605833,
      'trimestriel': 6904387.609234,
      'semestriel': 6968534.193210,
      'annuel': 7049316.395967
    },
    34: {
      'mensuel': 7212619.840766,
      'trimestriel': 7264612.498187,
      'semestriel': 7328603.616244,
      'annuel': 7413212.281147
    },
    35: {
      'mensuel': 7580403.821922,
      'trimestriel': 7624197.249084,
      'semestriel': 7701275.469085,
      'annuel': 7789844.522308
    },
    36: {
      'mensuel': 7961060.449418,
      'trimestriel': 8006717.466263,
      'semestriel': 8086990.836775,
      'annuel': 8179658.891909
    },
    37: {
      'mensuel': 8355040.058877,
      'trimestriel': 8394751.786861,
      'semestriel': 8478298.278308,
      'annuel': 8575140.790787
    },
    38: {
      'mensuel': 8762808.954867,
      'trimestriel': 8804241.412862,
      'semestriel': 8891209.444321,
      'annuel': 8992440.529785
    },
    39: {
      'mensuel': 9184849.761809,
      'trimestriel': 9228063.175773,
      'semestriel': 9318572.501144,
      'annuel': 9424345.759649
    },
    40: {
      'mensuel': 9621661.997201,
      'trimestriel': 9657988.540329,
      'semestriel': 9760893.264956,
      'annuel': 9871367.672557
    },
    41: {
      'mensuel': 10073762.660832,
      'trimestriel': 10111691.452702,
      'semestriel': 10218695.255501,
      'annuel': 10334035.352417
    },
    42: {
      'mensuel': 10541686.847690,
      'trimestriel': 10581273.967007,
      'semestriel': 10692520.315715,
      'annuel': 10812896.401073
    },
    43: {
      'mensuel': 11025988.381088,
      'trimestriel': 11057612.584807,
      'semestriel': 11173208.346138,
      'annuel': 11308517.586431
    },
    44: {
      'mensuel': 11527240.468155,
      'trimestriel': 11560302.338736,
      'semestriel': 11680441.364525,
      'annuel': 11821485.513277
    },
    45: {
      'mensuel': 12046036.378270,
      'trimestriel': 12080582.334053,
      'semestriel': 12205427.538555,
      'annuel': 12352407.317562
    },
    46: {
      'mensuel': 12582990.145238,
      'trimestriel': 12619080.006705,
      'semestriel': 12748788.228676,
      'annuel': 12901911.384998
    },
    47: {
      'mensuel': 13138737.294051,
      'trimestriel': 13176421.181466,
      'semestriel': 13311166.542952,
      'annuel': 13470648.094793
    },
    48: {
      'mensuel': 13713935.593071,
      'trimestriel': 13753269.236278,
      'semestriel': 13893228.098227,
      'annuel': 14059290.589432
    },
    49: {
      'mensuel': 14309265.832568,
      'trimestriel': 14350306.973009,
      'semestriel': 14483712.331354,
      'annuel': 14668483.327573
    },
    50: {
      'mensuel': 14925432.630426,
      'trimestriel': 14968241.030525,
      'semestriel': 15106812.989223,
      'annuel': 15286630.055359
    },
  };

  // Primes de référence
  final Map<String, double> primeReferenceValues = {
    'mensuel': 10000.00000,
    'trimestriel': 30000.00000,
    'semestriel': 60000.00000,
    'annuel': 120000.00000,
  };

  @override
  void initState() {
    super.initState();

    // Initialiser _selectedPeriode avec une valeur par défaut
    _selectedPeriode = Periode.annuel;

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

    // Pré-remplir depuis les données existantes OU depuis la simulation
    if (widget.existingData != null) {
      _prefillFromExistingData();
    } else {
      _prefillSimulationData();
    }

    // Après init, vérifier si le calcul doit être refait (si l'âge a été défini après)
    Future.microtask(() {
      if (_age > 0 && (_calculatedCapital == 0 || _calculatedPrime == 0)) {
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

      // Si on est en mode modification (avec existingData), ne rien écraser
      if (args['existingData'] != null) {
        // Le pré-remplissage complet est déjà géré dans initState via _prefillFromExistingData
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
                debugPrint('👤 Âge client (commercial) calculé: $_age ans');
              });
              // Déclencher le calcul après avoir défini l'âge
              if (_age > 0) {
                debugPrint(
                    '📢 Appel _effectuerCalcul depuis didChangeDependencies (commercial)');
                _effectuerCalcul();
              }
            }
          } catch (e) {
            debugPrint('Erreur parsing date de naissance: $e');
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

    // Listeners pour le calcul automatique
    _primeController.addListener(() {
      _formatTextField(_primeController);
      if (_currentSimulation == SimulationType.parPrime && _age > 0) {
        _effectuerCalcul();
      }
    });

    _capitalController.addListener(() {
      _formatTextField(_capitalController);
      if (_currentSimulation == SimulationType.parCapital && _age > 0) {
        _effectuerCalcul();
      }
    });

    // 🔍 Validation de la durée uniquement à la sortie du champ
    _dureeFocusNode.addListener(() {
      if (!_dureeFocusNode.hasFocus) {
        // Utiliser Future.delayed pour éviter les appels multiples
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          
          // Le champ a perdu le focus - valider maintenant
          if (_dureeController.text.isNotEmpty && _age > 0) {
            int? duree = int.tryParse(_dureeController.text);
            if (duree != null) {
              setState(() {
                _dureeEnAnnees = _selectedUnite == 'années' ? duree : duree ~/ 12;
              });

              // Validation de la durée en années
              if (_dureeEnAnnees < 5) {
                _showProfessionalDialog(
                  title: 'Durée minimale requise',
                  message:
                      'La durée minimale pour CORIS RETRAITE est de 5 ans. Veuillez ajuster la durée du contrat pour continuer.',
                  icon: Icons.access_time,
                  iconColor: orangeWarning,
                  backgroundColor: orangeWarning,
                );
                setState(() {
                  _calculatedPrime = 0.0;
                  _calculatedCapital = 0.0;
                });
                return;
              }
              if (_dureeEnAnnees > 50) {
                _showProfessionalDialog(
                  title: 'Durée maximale dépassée',
                  message:
                      'La durée maximale pour CORIS RETRAITE est de 50 ans. Le contrat a été ajusté automatiquement.',
                  icon: Icons.access_time,
                  iconColor: orangeWarning,
                  backgroundColor: orangeWarning,
                );
                setState(() {
                  _calculatedPrime = 0.0;
                  _calculatedCapital = 0.0;
                });
                return;
              }

              _effectuerCalcul();
            }
          }
        });
      }
    });
  }

  void _prefillSimulationData() {
    if (widget.simulationData != null) {
      final data = widget.simulationData!;

      // Déterminer le type de simulation
      if (data['type'] == 'capital') {
        _currentSimulation = SimulationType.parCapital;
        _selectedSimulationType = 'Par Capital';
        if (data['capital'] != null) {
          _capitalController.text = _formatNumber(data['capital'].toDouble());
        }
      } else {
        _currentSimulation = SimulationType.parPrime;
        _selectedSimulationType = 'Par Prime';
        if (data['prime'] != null) {
          _primeController.text = _formatNumber(data['prime'].toDouble());
        }
      }

      // Pré-remplir la durée
      if (data['duree'] != null) {
        _dureeController.text = data['duree'].toString();
        _dureeEnAnnees = data['duree'];
        debugPrint(
            '📅 Durée pré-remplie: $_dureeEnAnnees années (valeur: ${data['duree']})');
      }

      // Pré-remplir l'unité si fournie
      if (data['unite'] != null) {
        _selectedUnite = data['unite'];
        debugPrint('📏 Unité pré-remplie: $_selectedUnite');
      }

      // Pré-remplir la périodicité
      if (data['periodicite'] != null) {
        switch (data['periodicite']) {
          case 'mensuel':
            _selectedPeriode = Periode.mensuel;
            break;
          case 'trimestriel':
            _selectedPeriode = Periode.trimestriel;
            break;
          case 'semestriel':
            _selectedPeriode = Periode.semestriel;
            break;
          case 'annuel':
            _selectedPeriode = Periode.annuel;
            break;
        }
      }

      // Déclencher le calcul si l'âge est disponible
      if (_age > 0) {
        debugPrint(
            '📢 Appel _effectuerCalcul depuis _prefillSimulationData (âge: $_age)');
        _effectuerCalcul();
      } else {
        debugPrint(
            '⚠️ _prefillSimulationData: âge non disponible ($_age), calcul différé');
        // Si l'âge n'est pas encore disponible, attendre qu'il soit chargé
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted && _age > 0) {
            debugPrint(
                '📢 Appel _effectuerCalcul depuis _prefillSimulationData (retardé, âge: $_age)');
            _effectuerCalcul();
          } else if (mounted) {
            debugPrint(
                '❌ _prefillSimulationData: âge toujours non disponible après délai');
          }
        });
      }
    }
  }

  /// Méthode pour pré-remplir les champs depuis une proposition existante
  void _prefillFromExistingData() {
    if (widget.existingData == null) return;

    final data = widget.existingData!;
    debugPrint('🔄 Pré-remplissage depuis données existantes: ${data.keys}');

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
      _clientNumeroPieceController.text =
          clientInfo['numero_piece_identite'] ?? '';
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
              _clientAge--;
            }
            _age = _clientAge;
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

    try {
      // Pré-remplir la durée
      if (data['duree'] != null) {
        _dureeController.text = data['duree'].toString();
        _dureeEnAnnees = data['duree'] is int
            ? data['duree']
            : int.parse(data['duree'].toString());
      }

      // Pré-remplir l'unité
      if (data['duree_type'] != null) {
        _selectedUnite = data['duree_type'];
      }

      // Pré-remplir la périodicité
      if (data['periodicite'] != null) {
        final periodicite = data['periodicite'].toString().toLowerCase();
        switch (periodicite) {
          case 'mensuel':
            _selectedPeriode = Periode.mensuel;
            break;
          case 'trimestriel':
            _selectedPeriode = Periode.trimestriel;
            break;
          case 'semestriel':
            _selectedPeriode = Periode.semestriel;
            break;
          case 'annuel':
            _selectedPeriode = Periode.annuel;
            break;
        }
      }

      // Pré-remplir capital et prime
      if (data['capital'] != null) {
        _calculatedCapital = data['capital'] is double
            ? data['capital']
            : double.parse(data['capital'].toString());
        _capitalController.text = _formatNumber(_calculatedCapital);
      }
      if (data['prime'] != null) {
        _calculatedPrime = data['prime'] is double
            ? data['prime']
            : double.parse(data['prime'].toString());
        _primeController.text = _formatNumber(_calculatedPrime);
      }

      // Pré-remplir bénéficiaire
      if (data['beneficiaire'] != null && data['beneficiaire'] is Map) {
        final beneficiaire = data['beneficiaire'];
        if (beneficiaire['nom'] != null) {
          _beneficiaireNomController.text = beneficiaire['nom'].toString();
        }
        if (beneficiaire['contact'] != null) {
          final contact = beneficiaire['contact'].toString();
          // Extraire l'indicatif et le numéro (format: "+225 1234567890")
          final parts = contact.split(' ');
          if (parts.length >= 2) {
            _selectedBeneficiaireIndicatif = parts[0];
            _beneficiaireContactController.text = parts.sublist(1).join(' ');
          } else {
            _beneficiaireContactController.text = contact;
          }
        }
        if (beneficiaire['lien_parente'] != null) {
          _selectedLienParente = beneficiaire['lien_parente'].toString();
        }
      }

      // Pré-remplir contact d'urgence
      if (data['contact_urgence'] != null && data['contact_urgence'] is Map) {
        final contactUrgence = data['contact_urgence'];
        if (contactUrgence['nom'] != null) {
          _personneContactNomController.text = contactUrgence['nom'].toString();
        }
        if (contactUrgence['contact'] != null) {
          final contact = contactUrgence['contact'].toString();
          final parts = contact.split(' ');
          if (parts.length >= 2) {
            _selectedContactIndicatif = parts[0];
            _personneContactTelController.text = parts.sublist(1).join(' ');
          } else {
            _personneContactTelController.text = contact;
          }
        }
        if (contactUrgence['lien_parente'] != null) {
          _selectedLienParenteUrgence =
              contactUrgence['lien_parente'].toString();
        }
      }

      // Pré-remplir dates
      if (data['date_effet'] != null) {
        try {
          _dateEffetContrat = DateTime.parse(data['date_effet'].toString());
          _dateEffetController.text =
              "${_dateEffetContrat!.day.toString().padLeft(2, '0')}/${_dateEffetContrat!.month.toString().padLeft(2, '0')}/${_dateEffetContrat!.year}";
        } catch (e) {
          debugPrint('⚠️ Erreur parsing date_effet: $e');
        }
      }
      if (data['date_echeance'] != null) {
        try {
          _dateEcheanceContrat =
              DateTime.parse(data['date_echeance'].toString());
        } catch (e) {
          debugPrint('⚠️ Erreur parsing date_echeance: $e');
        }
      }

      // Pré-remplir les informations client si commercial et si données présentes
      if (data['client_info'] != null && data['client_info'] is Map) {
        final clientInfo = data['client_info'];
        _isCommercial = true;

        if (clientInfo['nom'] != null) {
          _clientNomController.text = clientInfo['nom'].toString();
        }
        if (clientInfo['prenom'] != null) {
          _clientPrenomController.text = clientInfo['prenom'].toString();
        }
        if (clientInfo['email'] != null) {
          _clientEmailController.text = clientInfo['email'].toString();
        }
        if (clientInfo['telephone'] != null) {
          final telephone = clientInfo['telephone'].toString();
          final parts = telephone.split(' ');
          if (parts.length >= 2) {
            _selectedClientIndicatif = parts[0];
            _clientTelephoneController.text = parts.sublist(1).join(' ');
          } else {
            _clientTelephoneController.text = telephone;
          }
        }
        if (clientInfo['lieu_naissance'] != null) {
          _clientLieuNaissanceController.text =
              clientInfo['lieu_naissance'].toString();
        }
        if (clientInfo['adresse'] != null) {
          _clientAdresseController.text = clientInfo['adresse'].toString();
        }
        if (clientInfo['civilite'] != null) {
          _selectedClientCivilite = clientInfo['civilite'].toString();
        }
        if (clientInfo['numero_piece_identite'] != null) {
          _clientNumeroPieceController.text =
              clientInfo['numero_piece_identite'].toString();
        }
        if (clientInfo['date_naissance'] != null) {
          try {
            _clientDateNaissance =
                DateTime.parse(clientInfo['date_naissance'].toString());
            _clientDateNaissanceController.text =
                "${_clientDateNaissance!.day.toString().padLeft(2, '0')}/${_clientDateNaissance!.month.toString().padLeft(2, '0')}/${_clientDateNaissance!.year}";
            final now = DateTime.now();
            _clientAge = now.year - _clientDateNaissance!.year;
            if (now.month < _clientDateNaissance!.month ||
                (now.month == _clientDateNaissance!.month &&
                    now.day < _clientDateNaissance!.day)) {
              _clientAge--;
            }
          } catch (e) {
            debugPrint('⚠️ Erreur parsing date_naissance client: $e');
          }
        }
      }

      debugPrint('✅ Pré-remplissage terminé avec succès');

      // Déclencher un setState pour rafraîchir l'UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du pré-remplissage: $e');
    }
  }

  // Méthode pour charger les données utilisateur
  Future<void> _loadUserData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return;
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
                debugPrint(
                    '👤 Âge utilisateur calculé: $_age ans (date naissance: $_dateNaissance)');
              } else {
                debugPrint('⚠️ Date de naissance manquante dans userData');
              }
            });
            // Effectuer le calcul après le chargement des données
            if (_age > 0) {
              debugPrint('📢 Appel _effectuerCalcul depuis _loadUserData');
              _effectuerCalcul();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
    }
  }

  // Méthodes pour la simulation
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

  String _getPeriodiciteKey() {
    switch (_selectedPeriode ?? Periode.annuel) {
      case Periode.mensuel:
        return 'mensuel';
      case Periode.trimestriel:
        return 'trimestriel';
      case Periode.semestriel:
        return 'semestriel';
      case Periode.annuel:
        return 'annuel';
    }
  }

  double calculatePremium(
      int duration, String periodicity, double desiredCapital) {
    if (duration < 5 || duration > 50) {
      return -1;
    }

    // Si hors ligne, utiliser les données locales
    if (_useLocalData) {
      final localPremium = LocalDataService.calculateRetraitePremium(
        duration,
        periodicity,
        desiredCapital,
      );
      return localPremium > 0 ? localPremium : -1;
    }

    if (!capitalValues.containsKey(duration) ||
        !capitalValues[duration]!.containsKey(periodicity)) {
      return -1;
    }

    // Récupérer le capital pour la prime de référence
    double capitalPourPrimeRef = capitalValues[duration]![periodicity]!.toDouble();
    double primeReference = primeReferenceValues[periodicity]!;

    // NOUVELLE MÉTHODE: Prime = (Capital_Voulu × Prime_Reference) / Capital_pour_Prime_Reference
    double calculatedPremium = (desiredCapital * primeReference) / capitalPourPrimeRef;

    return calculatedPremium;
  }

  double calculateCapital(
      int duration, String periodicity, double paidPremium) {
    if (duration < 5 || duration > 50) {
      return -1;
    }

    double minPremium = minPrimes[periodicity]!.toDouble();

    if (paidPremium < minPremium) {
      return -1;
    }

    // Si hors ligne, utiliser les données locales
    if (_useLocalData) {
      final localCapital = LocalDataService.calculateRetraiteCapital(
        duration,
        periodicity,
        paidPremium,
      );
      return localCapital > 0 ? localCapital : -1;
    }

    if (!capitalValues.containsKey(duration) ||
        !capitalValues[duration]!.containsKey(periodicity)) {
      return -1;
    }

    // Récupérer le capital pour la prime de référence
    double capitalPourPrimeRef = capitalValues[duration]![periodicity]!.toDouble();
    double primeReference = primeReferenceValues[periodicity]!;

    // NOUVELLE MÉTHODE: Capital = (Prime_Payée × Capital_pour_Prime_Reference) / Prime_Reference
    double calculatedCapital = (paidPremium * capitalPourPrimeRef) / primeReference;

    return calculatedCapital;
  }

  void _effectuerCalcul() async {
    debugPrint(
        '🔍 _effectuerCalcul appelé - âge: $_age, durée: $_dureeEnAnnees années, périodicité: ${_getPeriodiciteKey()}');

    if (_age < 18 || _age > 69) {
      debugPrint(
          '⚠️ Âge invalide pour calcul: $_age (doit être entre 18 et 69)');
      if (mounted) {
        setState(() {
          _calculatedPrime = 0.0;
          _calculatedCapital = 0.0;
        });
      }
      return;
    }

    if (_dureeEnAnnees < 5 || _dureeEnAnnees > 50) {
      debugPrint(
          '⚠️ Durée invalide pour calcul: $_dureeEnAnnees (doit être entre 5 et 50 ans)');
      if (mounted) {
        setState(() {
          _calculatedPrime = 0.0;
          _calculatedCapital = 0.0;
        });
      }
      return;
    }

    // Calcul immédiat: suppression du délai artificiel pour une meilleure réactivité
    if (mounted) {
      setState(() {
        String periodiciteKey = _getPeriodiciteKey();

        double prime = 0.0;
        double capital = 0.0;
        if (_currentSimulation == SimulationType.parPrime) {
          prime =
              double.tryParse(_primeController.text.replaceAll(' ', '')) ?? 0;
          if (prime <= 0) {
            _calculatedPrime = 0.0;
            _calculatedCapital = 0.0;
            return;
          }

          capital = calculateCapital(_dureeEnAnnees, periodiciteKey, prime);
          debugPrint(
              '💰 calculateCapital($_dureeEnAnnees, $periodiciteKey, $prime) = $capital');
          if (capital == -1) {
            debugPrint('❌ calculateCapital a retourné -1 (erreur)');
            capital = 0;
          }
        } else {
          capital =
              double.tryParse(_capitalController.text.replaceAll(' ', '')) ?? 0;
          if (capital <= 0) {
            _calculatedPrime = 0.0;
            _calculatedCapital = 0.0;
            return;
          }

          prime = calculatePremium(_dureeEnAnnees, periodiciteKey, capital);
          debugPrint(
              '💰 calculatePremium($_dureeEnAnnees, $periodiciteKey, $capital) = $prime');
          if (prime == -1) {
            debugPrint('❌ calculatePremium a retourné -1 (erreur)');
            prime = 0;
          }
        }
        _calculatedPrime = prime;
        _calculatedCapital = capital;

        debugPrint(
            '✅ Calcul effectué - Prime: ${_formatNumber(prime)} FCFA, Capital: ${_formatNumber(capital)} FCFA');
      });
    }
  }

  void _selectDateEffet() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _dateEffetContrat = picked;
          _dateEffetController.text =
              '${picked.day}/${picked.month}/${picked.year}';
          // Calculer la date d'échéance
          final duree = int.tryParse(_dureeController.text) ?? 0;
          final dureeAnnees = _selectedUnite == 'années' ? duree : duree ~/ 12;
          _dateEcheanceContrat = picked.add(Duration(days: dureeAnnees * 365));
        });
      }
    }
  }

  void _onSimulationTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedSimulationType = newValue;
        _currentSimulation = newValue == 'Par Prime'
            ? SimulationType.parPrime
            : SimulationType.parCapital;
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
          _dureeEnAnnees = _selectedUnite == 'années' ? duree : duree ~/ 12;

          // Validation de la durée en années
          if (_dureeEnAnnees < 5) {
            _showProfessionalDialog(
              title: 'Durée minimale requise',
              message:
                  'La durée minimale pour CORIS RETRAITE est de 5 ans. Veuillez ajuster la durée du contrat pour continuer.',
              icon: Icons.access_time,
              iconColor: orangeWarning,
              backgroundColor: orangeWarning,
            );
            _calculatedPrime = 0.0;
            _calculatedCapital = 0.0;
            return;
          }
          if (_dureeEnAnnees > 50) {
            _showProfessionalDialog(
              title: 'Durée maximale dépassée',
              message:
                  'La durée maximale pour CORIS RETRAITE est de 50 ans. Le contrat a été ajusté automatiquement.',
              icon: Icons.access_time,
              iconColor: orangeWarning,
              backgroundColor: orangeWarning,
            );
            _calculatedPrime = 0.0;
            _calculatedCapital = 0.0;
            return;
          }

          _effectuerCalcul();
        }
      });
    }
  }

  String _getPeriodeTextForDisplay() {
    switch (_selectedPeriode ?? Periode.annuel) {
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
          Expanded(child: Text(message)),
        ]),
        backgroundColor: rougeCoris,
      ),
    );
  }

  /// Parse le RIB unifié en ses composantes
  Map<String, String> _parseRibUnified(String rib) {
    final parts = rib.split('/').map((p) => p.trim()).toList();
    return {
      'code_guichet': parts.length > 0 ? parts[0] : '',
      'numero_compte': parts.length > 1 ? parts[1] : '',
      'cle_rib': parts.length > 2 ? parts[2] : '',
    };
  }

  /// Valide le format du RIB unifié
  bool _validateRibUnified(String rib) {
    final parts = _parseRibUnified(rib);
    final codeGuichet = parts['code_guichet'] ?? '';
    final numeroCompte = parts['numero_compte'] ?? '';
    final cleRib = parts['cle_rib'] ?? '';
    
    return codeGuichet.length == 5 &&
        numeroCompte.length == 11 &&
        cleRib.length == 2 &&
        RegExp(r'^\d{5}$').hasMatch(codeGuichet) &&
        RegExp(r'^\d{11}$').hasMatch(numeroCompte) &&
        RegExp(r'^\d{2}$').hasMatch(cleRib);
  }

  /// Formate l'entrée RIB en temps réel
  void _formatRibInput() {
    final text = _ribUnifiedController.text;
    final onlyDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (onlyDigits.isEmpty) {
      _ribUnifiedController.text = '';
      return;
    }

    // Construire le format: XXXXX / XXXXXXXXXXX / XX (5 chiffres / 11 chiffres / 2 chiffres)
    final buffer = StringBuffer();
    if (onlyDigits.length > 0) {
      buffer.write(onlyDigits.substring(0, min(5, onlyDigits.length)));
    }
    if (onlyDigits.length > 5) {
      buffer.write(' / ');
      buffer.write(
          onlyDigits.substring(5, min(16, onlyDigits.length)));
    }
    if (onlyDigits.length > 16) {
      buffer.write(' / ');
      buffer.write(onlyDigits.substring(16, min(18, onlyDigits.length)));
    }

    final formatted = buffer.toString();
    if (formatted != text) {
      _ribUnifiedController.text = formatted;
      _ribUnifiedController.selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
    }
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
    final maxStep = _isCommercial ? 4 : 3;
    if (_currentStep < maxStep) {
      bool canProceed = false;

      if (_isCommercial) {
        // Pour les commerciaux: step 0 = infos client, step 1 = simulation, step 2 = bénéficiaire, step 3 = mode paiement, step 4 = recap
        if (_currentStep == 0 && _validateStepClientInfo()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStep2()) {
          canProceed = true;
        } else if (_currentStep == 3 && _validateStepModePaiement()) {
          canProceed = true;
        }
      } else {
        // Pour les clients: step 0 = simulation, step 1 = bénéficiaire, step 2 = mode paiement, step 3 = recap
        if (_currentStep == 0 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep2()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStepModePaiement()) {
          canProceed = true;
        }
      }

      if (canProceed) {
        // If the next step is the recap, ensure calculations are performed
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

  bool _validateStep1() {
    // Vérifier que la date d'effet est sélectionnée
    if (_dateEffetContrat == null) {
      _showErrorSnackBar('Veuillez sélectionner une date d\'effet pour le contrat');
      return false;
    }

    if (_currentSimulation == SimulationType.parPrime) {
      if (_primeController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez saisir une prime');
        return false;
      }
    } else {
      if (_capitalController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez saisir un capital');
        return false;
      }
    }

    if (_dureeController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir une durée');
      return false;
    }

    // Si c'est un commercial, on ne valide pas l'âge à l'étape 1 (les champs client ne sont pas encore remplis)
    if (_isCommercial) {
      // L'âge sera validé à l'étape 2 quand les infos client seront saisies
      return true;
    }

    // Si c'est un client, valider son propre âge
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
      if (_age <= 0) {
        _showErrorSnackBar(
            'Veuillez renseigner votre date de naissance dans votre profil');
        return false;
      }

      if (_age > 0) {
        if (_age < 18 || _age > 69) {
          _showErrorSnackBar(
              'Âge non valide (18-69 ans requis). Votre âge: $_age ans');
          return false;
        }
      }
    }

    return true;
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
    // Email non obligatoire pour le commercial
    if (_clientTelephoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le téléphone du client');
      return false;
    }
    // Utiliser l'âge du client pour le calcul
    _age = _clientAge;
    return true;
  }

  bool _validateStep2() {
    if (_beneficiaireNomController.text.trim().isEmpty ||
        _beneficiaireContactController.text.trim().isEmpty ||
        _personneContactNomController.text.trim().isEmpty ||
        _personneContactTelController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return false;
    }
    // La pièce d'identité n'est obligatoire QUE pour une nouvelle souscription
    // En mode modification, elle est optionnelle
    if (_pieceIdentite == null && widget.subscriptionId == null) {
      _showErrorSnackBar(
          'Le téléchargement d\'une pièce d\'identité est obligatoire pour continuer.');
      return false;
    }
    return true;
  }

  bool _validateStepModePaiement() {
    if (_selectedModePaiement == null || _selectedModePaiement!.isEmpty) {
      _showErrorSnackBar('Veuillez sélectionner un mode de paiement');
      return false;
    }

    if (_selectedModePaiement == 'Virement') {
      if (_banqueController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez sélectionner votre banque.');
        return false;
      }
      if (_ribUnifiedController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez entrer votre numéro RIB complet (format: 55555 / 11111111111 / 22).');
        return false;
      }
      if (!_validateRibUnified(_ribUnifiedController.text.trim())) {
        _showErrorSnackBar('Le format du RIB est incorrect. Format attendu: 55555 / 11111111111 / 22 (5 chiffres / 11 chiffres / 2 chiffres)');
        return false;
      }
    } else if (_selectedModePaiement == 'Wave' ||
        _selectedModePaiement == 'Orange Money') {
      final phone = _numeroMobileMoneyController.text.trim();
      if (phone.isEmpty) {
        _showErrorSnackBar('Veuillez renseigner le numéro de téléphone');
        return false;
      }
      if (phone.length < 8) {
        _showErrorSnackBar(
            'Le numéro de téléphone doit contenir au moins 8 chiffres');
        return false;
      }
      // Validation spécifique pour Orange Money : doit commencer par 07
      if (_selectedModePaiement == 'Orange Money') {
        if (!phone.startsWith('07')) {
          _showErrorSnackBar('Le numéro Orange Money doit commencer par 07.');
          return false;
        }
      }
    } else if (_selectedModePaiement == 'Prélèvement à la source') {
      if (_nomStructureController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez renseigner le nom de la structure');
        return false;
      }
      if (_numeroMatriculeController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez renseigner votre numéro de matricule');
        return false;
      }
    } else if (_selectedModePaiement == 'CORIS Money') {
      final phone = _corisMoneyPhoneController.text.trim();
      if (phone.isEmpty) {
        _showErrorSnackBar('Veuillez renseigner le numéro de téléphone');
        return false;
      }
      if (phone.length < 8) {
        _showErrorSnackBar(
            'Le numéro de téléphone doit contenir au moins 8 chiffres');
        return false;
      }
    }
    return true;
  }

  // Méthodes d'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return ConnectivityBuilder(
      builder: (context, isConnected) {
        _useLocalData = !isConnected;

        return Scaffold(
          backgroundColor: grisLeger,
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              if (!isConnected) ConnectivityBanner(isConnected: isConnected),
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.emoji_people_outlined,
                                            color: blanc, size: 28),
                                        const SizedBox(width: 12),
                                        Text('CORIS RETRAITE',
                                            style: const TextStyle(
                                                color: blanc,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Préparez sereinement votre retraite',
                                        style: TextStyle(
                                            color: blanc.withValues(alpha: 0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400)),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        leading: IconButton(
                            icon:
                                const Icon(Icons.arrow_back_ios, color: blanc),
                            onPressed: () => Navigator.pop(context)),
                      ),
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                      _buildStepModePaiement(), // Page 3: Mode de paiement
                                      _buildStep3(), // Page 4: Récapitulatif
                                    ]
                                  : [
                                      _buildStep1(), // Page 0: Simulation
                                      _buildStep2(), // Page 1: Bénéficiaire/Contact
                                      _buildStepModePaiement(), // Page 2: Mode de paiement
                                      _buildStep3(), // Page 3: Récapitulatif
                                    ])),
                      _buildNavigationButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        for (int i = 0; i < (_isCommercial ? 6 : 5); i++) ...[
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
                                ? Icons.account_balance_wallet
                                : i == 2
                                    ? Icons.person_add
                                    : i == 3
                                        ? Icons.credit_card
                                        : i == 4
                                            ? Icons.check_circle
                                            : Icons.payment)
                        : (i == 0
                            ? Icons.account_balance_wallet
                            : i == 1
                                ? Icons.person_add
                                : i == 2
                                    ? Icons.credit_card
                                    : i == 3
                                        ? Icons.check_circle
                                        : Icons.payment),
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
                                : i == 3
                                    ? 'Paiement'
                                    : i == 4
                                        ? 'Récapitulatif'
                                        : 'Finaliser')
                    : (i == 0
                        ? 'Simulation'
                        : i == 1
                            ? 'Informations'
                            : i == 2
                                ? 'Paiement'
                                : i == 3
                                    ? 'Récapitulatif'
                                    : 'Finaliser'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        i <= _currentStep ? FontWeight.w600 : FontWeight.w400,
                    color: i <= _currentStep ? bleuCoris : grisTexte)),
          ])),
          if (i < (_isCommercial ? 5 : 4))
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
                                    borderRadius: BorderRadius.circular(10))),
                            const SizedBox(width: 12),
                            Text("Souscrire à CORIS RETRAITE",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: bleuCoris)),
                          ]),
                          const SizedBox(height: 20),

                          // Sélecteur de type de simulation
                          _buildSimulationTypeDropdown(),
                          const SizedBox(height: 16),

                          // Champ pour la prime/capital
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
                          const SizedBox(height: 20),

                          // Affichage du résultat de simulation
                          if (_calculatedPrime > 0 || _calculatedCapital > 0)
                            _buildResultSection(),
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
              controller: _dateEffetController,
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
            labelText: 'Mode de souscription',
          ),
          items: const [
            DropdownMenuItem(
                value: 'Par Prime', child: Text('Saisir la Prime')),
            DropdownMenuItem(
                value: 'Par Capital', child: Text('Saisir le Capital'))
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
            _currentSimulation == SimulationType.parPrime
                ? 'Prime souhaitée'
                : 'Capital souhaitée',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: bleuCoris)),
        const SizedBox(height: 6),
        TextField(
          controller: _currentSimulation == SimulationType.parPrime
              ? _primeController
              : _capitalController,
          keyboardType: TextInputType.number,
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
                  focusNode: _dureeFocusNode,
                  keyboardType: TextInputType.number,
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
                    DropdownMenuItem(value: 'années', child: Text('Années')),
                    DropdownMenuItem(value: 'mois', child: Text('Mois'))
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
              prefixIcon: Icon(Icons.calendar_today, color: bleuCoris),
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

  /// Widget d'affichage du résultat de simulation
  Widget _buildResultSection() {
    final resultValue = _currentSimulation == SimulationType.parPrime
        ? _calculatedCapital
        : _calculatedPrime;
    final resultLabel = _currentSimulation == SimulationType.parPrime
        ? 'Capital estimé à l\'échéance'
        : 'Prime ${_getPeriodiciteKey()} à verser';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vertSucces.withAlpha(26), // Fond vert clair comme CORIS ÉTUDE
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résultats Calculés :',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: vertSucces,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$resultLabel : ${_formatNumber(resultValue)}',
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
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
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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

  Widget _buildDropdownField(
      {required String? value,
      required String label,
      required IconData icon,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    // Vérifier si la valeur est valide (null ou dans la liste)
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
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
                  style: TextStyle(fontSize: 11, color: grisTexte)),
            ]),
          ),
        ),
      ]),
    );
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
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
                                return Icon(Icons.water_drop, color: iconColor, size: 28);
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
                                return Icon(Icons.phone_android, color: iconColor, size: 28);
                              },
                            );
                            break;
                          case 'Prélèvement à la source':
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
                                return Icon(Icons.account_balance_wallet, color: iconColor, size: 28);
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
                              // Réinitialiser les champs
                              _banqueController.clear();
                              _ribUnifiedController.clear();
                              _numeroMobileMoneyController.clear();
                              _nomStructureController.clear();
                              _numeroMatriculeController.clear();
                              _corisMoneyPhoneController.clear();
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
                                  child: Center(child: customIconWidget ?? Icon(icon, color: iconColor, size: 28)),
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

                      // RIB Unifié (5 / 11 / 2 chiffres)
                      TextField(
                        controller: _ribUnifiedController,
                        decoration: InputDecoration(
                          labelText: 'Numéro RIB complet *',
                          hintText: '55555 / 11111111111 / 22',
                          prefixIcon: Icon(Icons.account_balance, color: bleuCoris),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          helperText: 'Format: Code guichet (5) / Compte (11) / Clé (2)',
                          helperMaxLines: 2,
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                      maxLength: 24, // 5 + 3 + 11 + 3 + 2 = 24 caractères avec les séparateurs
                      onChanged: (value) => _formatRibInput(),
                    ),
                  ],
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

                    // PRÉLÈVEMENT À LA SOURCE
                    if (_selectedModePaiement == 'Prélèvement à la source') ...[
                      Text(
                        'Informations Prélèvement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nomStructureController,
                        decoration: InputDecoration(
                          labelText: 'Nom de la structure *',
                          hintText: 'Nom de votre entreprise/organisme',
                          prefixIcon: Icon(Icons.business, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _numeroMatriculeController,
                        decoration: InputDecoration(
                          labelText: 'Numéro de matricule *',
                          hintText: 'Votre matricule',
                          prefixIcon: Icon(Icons.badge, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],

                    // CORIS MONEY
                    if (_selectedModePaiement == 'CORIS Money') ...[
                      Text(
                        'Numéro CORIS Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _corisMoneyPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone *',
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
                              child:
                                  CircularProgressIndicator(color: bleuCoris));
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
      SubscriptionRecapWidgets.buildPersonalInfoSection(displayData),

      const SizedBox(height: 20),
      SubscriptionRecapWidgets.buildRecapSection(
          'Produit Souscrit', Icons.emoji_people_outlined, vertSucces, [
        // Produit et Prime
        SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Produit',
            'CORIS RETRAITE',
            'Prime ${_getPeriodeTextForDisplay()}',
            _formatMontant(_calculatedPrime)),

        // Capital au terme et Durée du contrat
        SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Capital au terme',
            '${_formatNumber(_calculatedCapital)} FCFA',
            'Durée du contrat',
            '$duree ${_selectedUnite == 'années' ? 'ans' : 'mois'}'),

        // Date d'effet et Date d'échéance
        SubscriptionRecapWidgets.buildCombinedRecapRow(
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
      SubscriptionRecapWidgets.buildRecapSection(
          'Bénéficiaire et Contact d\'urgence', Icons.contacts, orangeWarning, [
        _buildSubsectionTitle('Bénéficiaire'),
        SubscriptionRecapWidgets.buildRecapRow(
            'Nom complet',
            _beneficiaireNomController.text.isEmpty
                ? 'Non renseigné'
                : _beneficiaireNomController.text),
        SubscriptionRecapWidgets.buildRecapRow('Contact',
            '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text.isEmpty ? 'Non renseigné' : _beneficiaireContactController.text}'),
        SubscriptionRecapWidgets.buildRecapRow('Lien de parenté', _selectedLienParente),
        const SizedBox(height: 12),
        _buildSubsectionTitle('Contact d\'urgence'),
        SubscriptionRecapWidgets.buildRecapRow(
            'Nom complet',
            _personneContactNomController.text.isEmpty
                ? 'Non renseigné'
                : _personneContactNomController.text),
        SubscriptionRecapWidgets.buildRecapRow('Contact',
            '$_selectedContactIndicatif ${_personneContactTelController.text.isEmpty ? 'Non renseigné' : _personneContactTelController.text}'),
        SubscriptionRecapWidgets.buildRecapRow('Lien de parenté', _selectedLienParenteUrgence),
      ]),
      const SizedBox(height: 20),
      // 💳 SECTION MODE DE PAIEMENT
      if (_selectedModePaiement != null)
        SubscriptionRecapWidgets.buildRecapSection(
          'Mode de Paiement',
          Icons.payment,
          _selectedModePaiement == 'Virement'
              ? bleuCoris
              : _selectedModePaiement == 'Wave'
                  ? Color(0xFF00BFFF)
                  : _selectedModePaiement == 'Prélèvement à la source'
                      ? Colors.green
                      : _selectedModePaiement == 'CORIS Money'
                          ? Color(0xFF1E3A8A)
                          : orangeCoris,
          [
            SubscriptionRecapWidgets.buildRecapRow('Mode choisi', _selectedModePaiement!),
            const SizedBox(height: 8),
            if (_selectedModePaiement == 'Virement') ...[
              SubscriptionRecapWidgets.buildRecapRow(
                  'Banque',
                  _banqueController.text.isNotEmpty
                      ? _banqueController.text
                      : 'Non renseigné'),
              SubscriptionRecapWidgets.buildRecapRow(
                  'RIB complet',
                  _ribUnifiedController.text.isNotEmpty
                      ? _ribUnifiedController.text
                      : 'Non renseigné'),
            ] else if (_selectedModePaiement == 'Wave' ||
                _selectedModePaiement == 'Orange Money') ...[
              SubscriptionRecapWidgets.buildRecapRow(
                  'Numéro ${_selectedModePaiement}',
                  _numeroMobileMoneyController.text.isNotEmpty
                      ? _numeroMobileMoneyController.text
                      : 'Non renseigné'),
            ] else if (_selectedModePaiement == 'Prélèvement à la source') ...[
              SubscriptionRecapWidgets.buildRecapRow(
                  'Nom de la structure',
                  _nomStructureController.text.isNotEmpty
                      ? _nomStructureController.text
                      : 'Non renseigné'),
              SubscriptionRecapWidgets.buildRecapRow(
                  'Numéro de matricule',
                  _numeroMatriculeController.text.isNotEmpty
                      ? _numeroMatriculeController.text
                      : 'Non renseigné'),
            ] else if (_selectedModePaiement == 'CORIS Money') ...[
              SubscriptionRecapWidgets.buildRecapRow(
                  'Numéro CORIS Money',
                  _corisMoneyPhoneController.text.isNotEmpty
                      ? _corisMoneyPhoneController.text
                      : 'Non renseigné'),
            ],
          ],
        ),
      if (_selectedModePaiement != null) const SizedBox(height: 20),

      SubscriptionRecapWidgets.buildDocumentsSection(
        pieceIdentite: _pieceIdentite?.path.split('/').last,
        onDocumentTap: _pieceIdentite != null
            ? () => _viewLocalDocument()
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 360;
          final labelWidth = isSmallScreen ? 100.0 : 120.0;
          final fontSize = isSmallScreen ? 11.0 : 12.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  '$label :',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grisTexte,
                    fontSize: fontSize,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? vertSucces : bleuCoris,
                    fontSize: isHighlighted ? fontSize + 1 : fontSize,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          );
        },
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isSmallScreen = screenWidth < 360;
          final fontSize = isSmallScreen ? 11.0 : 12.0;

          // Sur très petits écrans, afficher en colonne au lieu de côte à côte
          if (screenWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label1 :',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: grisTexte,
                            fontSize: fontSize)),
                    Text(value1,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: bleuCoris,
                            fontSize: fontSize),
                        overflow: TextOverflow.visible,
                        softWrap: true),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label2 :',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: grisTexte,
                            fontSize: fontSize)),
                    Text(value2,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: bleuCoris,
                            fontSize: fontSize),
                        overflow: TextOverflow.visible,
                        softWrap: true),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Flexible(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label1 :',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: grisTexte,
                            fontSize: fontSize)),
                    Text(value1,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: bleuCoris,
                            fontSize: fontSize),
                        overflow: TextOverflow.visible,
                        softWrap: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label2 :',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: grisTexte,
                            fontSize: fontSize)),
                    Text(value2,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: bleuCoris,
                            fontSize: fontSize),
                        overflow: TextOverflow.visible,
                        softWrap: true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
                          'Cotisation ${_selectedPeriode.toString().split('.').last.toLowerCase()} à payer',
                          style: TextStyle(
                            color: grisTexte,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatMontant(_calculatedPrime),
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
                    onTap: () => _showSignatureAndPayment(),
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
              onPressed: _currentStep == (_isCommercial ? 4 : 3)
                  ? _showSignatureAndPayment
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
                    _currentStep == (_isCommercial ? 4 : 3)
                        ? 'Signer et Finaliser'
                        : 'Suivant',
                    style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(width: 8),
                Icon(
                    _currentStep == (_isCommercial ? 4 : 3)
                        ? Icons.draw
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

  Future<void> _showSignatureAndPayment() async {
    final Uint8List? signature = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SignatureDialogFile.SignatureDialog(),
    );

    if (signature == null) {
      return; // L'utilisateur a annulé
    }

    setState(() {
      _clientSignature = signature;
    });

    if (!mounted) return;

    // Après la signature, afficher les options de paiement
    _showPaymentOptions();
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
        'product_type': 'coris_retraite',
        'prime': _calculatedPrime,
        'capital': _calculatedCapital,
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
        'mode_paiement': _selectedModePaiement,
        'infos_paiement': _selectedModePaiement == 'Virement'
            ? {
                'banque': _banqueController.text.trim(),
                ...?_parseRibUnified(_ribUnifiedController.text.trim()),
              }
            : (_selectedModePaiement == 'Wave' ||
                    _selectedModePaiement == 'Orange Money')
                ? {
                    'numero_telephone':
                        _numeroMobileMoneyController.text.trim(),
                  }
                : _selectedModePaiement == 'Prélèvement à la source'
                    ? {
                        'nom_structure': _nomStructureController.text.trim(),
                        'numero_matricule': _numeroMatriculeController.text.trim(),
                      }
                    : _selectedModePaiement == 'CORIS Money'
                        ? {
                            'numero_telephone': _corisMoneyPhoneController.text.trim(),
                          }
                        : null,
        // NE PAS inclure 'status' ici - il sera 'proposition' par défaut dans la base
      };

      // Ajouter la signature si elle existe
      if (_clientSignature != null) {
        subscriptionData['signature'] = base64Encode(_clientSignature!);
      }

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

      // Utiliser updateSubscription si on modifie, createSubscription sinon
      final http.Response response;
      if (widget.subscriptionId != null) {
        response = await subscriptionService.updateSubscription(
            widget.subscriptionId!, subscriptionData);
      } else {
        response =
            await subscriptionService.createSubscription(subscriptionData);
      }

      final responseData = jsonDecode(response.body);

      if ((response.statusCode != 201 && response.statusCode != 200) ||
          !responseData['success']) {
        throw Exception(
            responseData['message'] ?? 'Erreur lors de la sauvegarde');
      }

      // RETOURNER l'ID de la souscription (créée ou mise à jour)
      return widget.subscriptionId ?? responseData['data']['id'];
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
    // ✅ SI CORIS MONEY: Afficher le modal de paiement CorisMoney
    if (paymentMethod == 'CORIS Money') {
      try {
        // 1. Sauvegarder la souscription
        final subscriptionId = await _saveSubscriptionData();

        // 2. Upload document si présent
        if (_pieceIdentite != null) {
          try {
            await _uploadDocument(subscriptionId);
          } catch (uploadError) {
            debugPrint('⚠️ Erreur upload document: $uploadError');
          }
        }

        // 3. Afficher le modal CorisMoney
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CorisMoneyPaymentModal(
            subscriptionId: subscriptionId,
            montant: _calculatedPrime,
            description: 'Paiement prime CORIS RETRAITE',
            onPaymentSuccess: () {
              _showSuccessDialog(true);
            },
          ),
        );
        
        return;
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la préparation du paiement: $e');
        return;
      }
    }

    // 👇 AUTRES MÉTHODES
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
        try {
          await _uploadDocument(subscriptionId);
        } catch (uploadError) {
          debugPrint('⚠️ Erreur upload document (non bloquant): $uploadError');
          // On continue même si l'upload échoue
        }
      }

      if (paymentMethod == 'Wave') {
        if (mounted) {
          Navigator.pop(context);
        }

        await WavePaymentHandler.startPayment(
          context,
          subscriptionId: subscriptionId,
          amount: _calculatedPrime,
          description: 'Paiement prime CORIS RETRAITE',
          onSuccess: () => _showSuccessDialog(true),
        );
        return;
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
        try {
          await _uploadDocument(subscriptionId);
        } catch (uploadError) {
          debugPrint('⚠️ Erreur upload document (non bloquant): $uploadError');
          // On continue même si l'upload échoue
        }
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
  void _viewLocalDocument() {
    if (_pieceIdentite == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          localFile: _pieceIdentite!,
          documentName: _pieceIdentite!.path.split('/').last,
        ),
      ),
    );
  }

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
        // Ne pas continuer si erreur
        throw Exception(responseData['message'] ?? 'Erreur upload document');
      }

      debugPrint('✅ Document uploadé avec succès');
    } catch (e) {
      debugPrint('❌ Exception upload document: $e');
      // Rethrow pour que l'appelant puisse gérer l'erreur
      rethrow;
    }
  }

  void _showSuccessDialog(bool isPaid) {
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(isPaid: isPaid));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _primeController.dispose();
    _capitalController.dispose();
    _dureeController.dispose();
    _dureeFocusNode.dispose();
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
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(isPaid ? Icons.check_circle : Icons.schedule,
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 40)),
            const SizedBox(height: 20),
            Text(isPaid ? 'Souscription Réussie!' : 'Proposition Enregistrée!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF002B6B))),
            const SizedBox(height: 12),
            Text(
                isPaid
                    ? 'Félicitations! Votre contrat CORIS RETRAITE est maintenant actif. Vous recevrez un message de confirmation sous peu.'
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
                    child: Text('Retour à l\'accueil',
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
                    Text('Options de Paiement',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF002B6B)))
                  ]),
                  const SizedBox(height: 24),
                  _buildPaymentOptionWithImage('Wave', 'assets/images/icone_wave.jpeg', Colors.blue,
                      'Paiement mobile sécurisé', () => onPayNow('Wave')),
                  const SizedBox(height: 12),
                  _buildPaymentOptionWithImage(
                      'Orange Money',
                      'assets/images/icone_orange_money.jpeg',
                      Colors.orange,
                      'Paiement mobile Orange',
                      () => onPayNow('Orange Money')),
                  const SizedBox(height: 12),
                  _buildPaymentOptionWithImage(
                      'CORIS Money',
                      'assets/images/icone_corismoney.jpeg',
                      Color(0xFF1E3A8A),
                      'Paiement par CORIS Money',
                      () => onPayNow('CORIS Money')),
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
                                Text('Payer plus tard',
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

  Widget _buildPaymentOptionWithImage(String title, String imagePath, Color color,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                  child: Image.asset(
                    imagePath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Erreur chargement image: $imagePath - $error');
                      return Icon(Icons.image_not_supported, size: 32, color: Colors.grey);
                    },
                  )),
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
