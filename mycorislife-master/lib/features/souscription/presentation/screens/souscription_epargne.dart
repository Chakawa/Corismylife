import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/services/wave_payment_handler.dart';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/core/utils/identity_document_picker.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import '../widgets/signature_dialog_syncfusion.dart' as SignatureDialogFile;
import 'dart:typed_data';

class SouscriptionEpargnePage extends StatefulWidget {
  final int? subscriptionId; // ID pour modification
  final Map<String, dynamic>?
      existingData; // Données existantes pour modification

  const SouscriptionEpargnePage(
      {super.key, this.subscriptionId, this.existingData});

  @override
  State<SouscriptionEpargnePage> createState() =>
      _SouscriptionEpargnePageState();
}

class _SouscriptionEpargnePageState extends State<SouscriptionEpargnePage>
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
  static const Color orangeCoris = Color(0xFFFF6B00);

  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _currentStep = 0;

  // Données utilisateur
  Map<String, dynamic> _userData = {};

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
  String _selectedClientCivilite = 'Monsieur';
  String _selectedClientIndicatif = '+225';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  int? _selectedCapital;
  int? _selectedPrime;
  final _beneficiaireNomController = TextEditingController();
  final _beneficiaireContactController = TextEditingController();
  final _beneficiaireDateNaissanceController = TextEditingController();
  DateTime? _beneficiaireDateNaissance;
  String _selectedLienParente = 'Enfant';
  final _personneContactNomController = TextEditingController();
  final _personneContactTelController = TextEditingController();
  String _selectedLienParenteUrgence = 'Parent';
  DateTime? _dateEffetContrat;
  DateTime? _dateFinContrat;

  File? _pieceIdentite;
  // ignore: unused_field
  String? _pieceIdentiteLabel;
  final List<File> _pieceIdentiteFiles = [];
  bool _isAideParCommercial = false;
  final _commercialNomPrenomController = TextEditingController();
  final _commercialCodeApporteurController = TextEditingController();

  // Signature du client
  Uint8List? _clientSignature;

  // Mode de paiement
  String? _selectedModePaiement;
  String? _selectedBanque;
  final _banqueController = TextEditingController();
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
  final _ribUnifiedController =
      TextEditingController(); // RIB unifié: XXXXX (5 chiffres) / XXXXXXXXXXX / XX
  final _numeroMobileMoneyController = TextEditingController();
  final _nomStructureController =
      TextEditingController(); // Pour Prélèvement à la source
  final _numeroMatriculeController =
      TextEditingController(); // Pour Prélèvement à la source
  final _corisMoneyPhoneController =
      TextEditingController(); // Pour CORIS Money
  final List<String> _modePaiementOptions = [
    'Virement',
    'Wave',
    'Prélèvement à la source',
  ];

  String _selectedBeneficiaireIndicatif = '+225'; // Côte d\'Ivoire par défaut
  String _selectedContactIndicatif = '+225'; // Côte d\'Ivoire par défaut
  final List<Map<String, String>> _indicatifOptions = [
    {'code': '+225', 'pays': 'Côte d\'Ivoire'},
    {'code': '+226', 'pays': 'Burkina Faso'},
  ];

  // Options de capital et prime avec bonus
  final List<Map<String, dynamic>> _capitalOptions = [
    {
      'capital': 1000000,
      'prime': 5500,
      'popularite': false,
      'bonus': '+ 5% de bonus au terme',
    },
    {
      'capital': 2000000,
      'prime': 10500,
      'popularite': true,
      'bonus': '+ 7% de bonus au terme',
    },
    {
      'capital': 4000000,
      'prime': 20500,
      'popularite': false,
      'bonus': '+ 10% de bonus au terme',
    },
    {
      'capital': 6000000,
      'prime': 30500,
      'popularite': false,
      'bonus': '+ 15% de bonus au terme',
    },
  ];

  // Options de lien de parenté
  final List<String> _lienParenteOptions = [
    'Enfant',
    'Conjoint',
    'Parent',
    'Frère/Sœur',
    'Ami',
    'Autre'
  ];

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
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

    if (widget.existingData != null) {
      _prefillFromExistingData();
    }
  }

  /// Méthode pour pré-remplir les champs depuis une proposition existante
  void _prefillFromExistingData() {
    if (widget.existingData == null) return;

    final data = widget.existingData!;
    debugPrint('🔄 Pré-remplissage ÉPARGNE depuis données existantes');

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
      // Note: souscription_epargne n'a pas de champ numéro de pièce
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
      setState(() {
        if (data['capital'] != null)
          _selectedCapital = data['capital'] is int
              ? data['capital']
              : int.parse(data['capital'].toString());
        if (data['prime_mensuelle'] != null)
          _selectedPrime = data['prime_mensuelle'] is int
              ? data['prime_mensuelle']
              : int.parse(data['prime_mensuelle'].toString());

        if (data['date_effet'] != null) {
          try {
            _dateEffetContrat = DateTime.parse(data['date_effet'].toString());
          } catch (e) {
            debugPrint('⚠️ Erreur parsing date_effet: $e');
          }
        }
        if (data['date_fin'] != null) {
          try {
            _dateFinContrat = DateTime.parse(data['date_fin'].toString());
          } catch (e) {
            debugPrint('⚠️ Erreur parsing date_fin: $e');
          }
        }
      });

      if (data['beneficiaire'] != null && data['beneficiaire'] is Map) {
        final beneficiaire = data['beneficiaire'];
        if (beneficiaire['nom'] != null)
          _beneficiaireNomController.text = beneficiaire['nom'].toString();
        if (beneficiaire['contact'] != null) {
          final contact = beneficiaire['contact'].toString();
          final parts = contact.split(' ');
          if (parts.length >= 2) {
            _selectedBeneficiaireIndicatif = parts[0];
            _beneficiaireContactController.text = parts.sublist(1).join(' ');
          }
        }
        if (beneficiaire['lien_parente'] != null)
          _selectedLienParente = beneficiaire['lien_parente'].toString();
        if (beneficiaire['date_naissance'] != null) {
          try {
            _beneficiaireDateNaissance =
                DateTime.parse(beneficiaire['date_naissance']);
            _beneficiaireDateNaissanceController.text =
                DateFormat('dd/MM/yyyy').format(_beneficiaireDateNaissance!);
          } catch (e) {
            debugPrint('Erreur parsing date_naissance beneficiaire: $e');
          }
        }
      }

      if (data['contact_urgence'] != null && data['contact_urgence'] is Map) {
        final contactUrgence = data['contact_urgence'];
        if (contactUrgence['nom'] != null)
          _personneContactNomController.text = contactUrgence['nom'].toString();
        if (contactUrgence['contact'] != null) {
          final contact = contactUrgence['contact'].toString();
          final parts = contact.split(' ');
          if (parts.length >= 2) {
            _selectedContactIndicatif = parts[0];
            _personneContactTelController.text = parts.sublist(1).join(' ');
          }
        }
        if (contactUrgence['lien_parente'] != null)
          _selectedLienParenteUrgence =
              contactUrgence['lien_parente'].toString();
      }

        if (data['assistance_commerciale'] != null &&
          data['assistance_commerciale'] is Map) {
        final assistance = data['assistance_commerciale'];
        _isAideParCommercial =
          assistance['is_aide_par_commercial'] == true;
        _commercialNomPrenomController.text =
          assistance['commercial_nom_prenom']?.toString() ?? '';
        _commercialCodeApporteurController.text =
          assistance['commercial_code_apporteur']?.toString() ?? '';
        }

      debugPrint('✅ Pré-remplissage ÉPARGNE terminé');
    } catch (e) {
      debugPrint('❌ Erreur pré-remplissage ÉPARGNE: $e');
    }
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

        if (clientInfo['civilite'] != null) {
          _selectedClientCivilite = clientInfo['civilite'];
        }

        // Gérer la date de naissance
        if (clientInfo['date_naissance'] != null) {
          try {
            _clientDateNaissance = DateTime.parse(clientInfo['date_naissance']);
            _clientDateNaissanceController.text =
                '${_clientDateNaissance!.day.toString().padLeft(2, '0')}/${_clientDateNaissance!.month.toString().padLeft(2, '0')}/${_clientDateNaissance!.year}';
            final maintenant = DateTime.now();
            _clientAge = maintenant.year - _clientDateNaissance!.year;
            if (maintenant.month < _clientDateNaissance!.month ||
                (maintenant.month == _clientDateNaissance!.month &&
                    maintenant.day < _clientDateNaissance!.day)) {
              _clientAge--;
            }
          } catch (e) {
            debugPrint('Erreur parsing date de naissance: $e');
          }
        }

        // Gérer l'indicatif téléphonique
        if (clientInfo['telephone'] != null) {
          final telephone = clientInfo['telephone'].toString();
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
        if (data == null || data is! Map) {
          debugPrint(
              '⚠️ Profil: réponse API vide ou non-Map: ${response.body}');
          if (mounted) {
            setState(() {
              _userData = _userData.isNotEmpty ? _userData : {};
            });
          }
          return;
        }

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
        else if (data.containsKey('id') && data.containsKey('email')) {
          userData = Map<String, dynamic>.from(data);
        }

        if (userData != null && userData.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userData = userData!;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _clientNomController.dispose();
    _clientPrenomController.dispose();
    _clientDateNaissanceController.dispose();
    _clientLieuNaissanceController.dispose();
    _clientTelephoneController.dispose();
    _clientEmailController.dispose();
    _clientAdresseController.dispose();
    _beneficiaireNomController.dispose();
    _beneficiaireContactController.dispose();
    _beneficiaireDateNaissanceController.dispose();
    _personneContactNomController.dispose();
    _personneContactTelController.dispose();
    _commercialNomPrenomController.dispose();
    _commercialCodeApporteurController.dispose();
    _banqueController.dispose();
    _ribUnifiedController.dispose();
    _numeroMobileMoneyController.dispose();
    _nomStructureController.dispose();
    _numeroMatriculeController.dispose();
    _corisMoneyPhoneController.dispose();
    super.dispose();
  }

  String _formatMontant(int montant) {
    return "${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }

  /// Parse le RIB unifié en ses 3 composantes
  Map<String, String> _parseRibUnified(String rib) {
    final parts = rib.split('/').map((s) => s.trim()).toList();
    return {
      'code_guichet': parts.isNotEmpty ? parts[0] : '',
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
      buffer.write(onlyDigits.substring(5, min(16, onlyDigits.length)));
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

  Future<void> _pickDocument() async {
    try {
      final picked = await IdentityDocumentPicker.pickDocuments(context);
      if (picked == null || picked.files.isEmpty || !mounted) return;

      setState(() {
        _pieceIdentiteFiles
          ..clear()
          ..addAll(picked.files);
        _pieceIdentite = _pieceIdentiteFiles.first;
        _pieceIdentiteLabel = picked.labels.isNotEmpty
            ? picked.labels.first
            : _pieceIdentite!.path.split(RegExp(r'[\\/]+')).last;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: blanc),
              SizedBox(width: 12),
              Text(_pieceIdentiteFiles.length > 1
                  ? '${_pieceIdentiteFiles.length} documents ajoutés avec succès'
                  : 'Document ajouté avec succès'),
            ],
          ),
          backgroundColor: vertSucces,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur lors de la sélection du fichier');
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _getBonusText() {
    if (_selectedCapital == null) return 'Non défini';

    final option = _capitalOptions.firstWhere(
      (opt) => opt['capital'] == _selectedCapital,
      orElse: () => {'bonus': 'Bonus non défini'},
    );

    return option['bonus'];
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
            // Calculer l'âge si la date de naissance est disponible
            if (userData['date_naissance'] != null) {
              try {
                final dateNaissance =
                    DateTime.parse(userData['date_naissance']);
                final maintenant = DateTime.now();
                int age = maintenant.year - dateNaissance.year;
                if (maintenant.month < dateNaissance.month ||
                    (maintenant.month == dateNaissance.month &&
                        maintenant.day < dateNaissance.day)) {
                  age--;
                }
                userData['age'] = age;
              } catch (e) {
                debugPrint('Erreur parsing date: $e');
              }
            }
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
              if (userData['date_naissance'] != null) {
                try {
                  final dateNaissance =
                      DateTime.parse(userData['date_naissance']);
                  final maintenant = DateTime.now();
                  int age = maintenant.year - dateNaissance.year;
                  if (maintenant.month < dateNaissance.month ||
                      (maintenant.month == dateNaissance.month &&
                          maintenant.day < dateNaissance.day)) {
                    age--;
                  }
                  userData['age'] = age;
                } catch (e) {
                  debugPrint('Erreur parsing date: $e');
                }
              }
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
            if (userData['date_naissance'] != null) {
              try {
                final dateNaissance =
                    DateTime.parse(userData['date_naissance']);
                final maintenant = DateTime.now();
                int age = maintenant.year - dateNaissance.year;
                if (maintenant.month < dateNaissance.month ||
                    (maintenant.month == dateNaissance.month &&
                        maintenant.day < dateNaissance.day)) {
                  age--;
                }
                userData['age'] = age;
              } catch (e) {
                debugPrint('Erreur parsing date: $e');
              }
            }
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
            if (userData['date_naissance'] != null) {
              try {
                final dateNaissance =
                    DateTime.parse(userData['date_naissance']);
                final maintenant = DateTime.now();
                int age = maintenant.year - dateNaissance.year;
                if (maintenant.month < dateNaissance.month ||
                    (maintenant.month == dateNaissance.month &&
                        maintenant.day < dateNaissance.day)) {
                  age--;
                }
                userData['age'] = age;
              } catch (e) {
                debugPrint('Erreur parsing date: $e');
              }
            }
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: blanc),
              SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: rougeCoris,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _nextStep() {
    final maxStep = _isCommercial ? 4 : 3;
    if (_currentStep < maxStep) {
      bool canProceed = false;

      if (_isCommercial) {
        // Pour les commerciaux: step 0 = infos client, step 1 = capital, step 2 = contrat, step 3 = mode paiement, step 4 = recap
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
        // Pour les clients: step 0 = capital, step 1 = contrat, step 2 = mode paiement, step 3 = recap
        if (_currentStep == 0 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep2()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStepModePaiement()) {
          canProceed = true;
        }
      }

      if (canProceed) {
        // Si on avance vers le récapitulatif, s'assurer que les valeurs sont calculées
        if (_currentStep + 1 == maxStep) {
          try {
            _ensureEpargneCalculated();
          } catch (e) {
            debugPrint('Erreur lors du calcul Epargne avant récap: $e');
          }
        }

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

  /// Ensure selected capital/prime are set before showing recap
  void _ensureEpargneCalculated() {
    if (_selectedCapital == null && _capitalOptions.isNotEmpty) {
      setState(() {
        _selectedCapital = _capitalOptions.first['capital'] as int?;
        _selectedPrime = _capitalOptions.first['prime'] as int?;
      });
      return;
    }

    if (_selectedPrime == null && _selectedCapital != null) {
      final opt = _capitalOptions.firstWhere(
          (opt) => opt['capital'] == _selectedCapital,
          orElse: () => {});
      if (opt.isNotEmpty) {
        setState(() {
          _selectedPrime = opt['prime'] as int?;
        });
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
    if (_clientDateNaissance == null) {
      _showErrorSnackBar('Veuillez saisir la date de naissance du client');
      return false;
    }
    if (_clientAge < 18 || _clientAge > 65) {
      _showErrorSnackBar('L\'âge du client doit être entre 18 et 65 ans');
      return false;
    }
    // Email non obligatoire pour le commercial
    if (_clientTelephoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez saisir le téléphone du client');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_selectedCapital == null) {
      _showErrorSnackBar('Veuillez sélectionner un capital');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_beneficiaireNomController.text.trim().isEmpty ||
        _beneficiaireContactController.text.trim().isEmpty ||
        _beneficiaireDateNaissance == null ||
        _personneContactNomController.text.trim().isEmpty ||
        _personneContactTelController.text.trim().isEmpty ||
        _dateEffetContrat == null) {
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
    if (_isAideParCommercial &&
        (_commercialNomPrenomController.text.trim().isEmpty ||
            _commercialCodeApporteurController.text.trim().isEmpty)) {
      _showErrorSnackBar(
          'Veuillez renseigner le nom/prénom et le code apporteur du commercial.');
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
        _showErrorSnackBar('Veuillez renseigner le nom de la banque');
        return false;
      }
      if (_ribUnifiedController.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez renseigner votre RIB complet');
        return false;
      }
      if (!_validateRibUnified(_ribUnifiedController.text.trim())) {
        _showErrorSnackBar(
            'Format RIB invalide. Format attendu: 55555 / 11111111111 / 22 (5 chiffres / 11 chiffres / 2 chiffres)');
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

  void _showPaymentOptions() async {
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

  Future<int> _saveSubscriptionData() async {
    try {
      final subscriptionService = SubscriptionService();

      final subscriptionData = {
        'product_type': 'coris_epargne_bonus',
        'montant': _selectedPrime ?? _selectedCapital, // Ajouté pour l'admin
        'capital': _selectedCapital,
        'prime_mensuelle': _selectedPrime,
        'duree_mois': 180,
        'beneficiaire': {
          'nom': _beneficiaireNomController.text.trim(),
          'contact':
              '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text.trim()}',
          'date_naissance': _beneficiaireDateNaissance?.toIso8601String(),
          'lien_parente': _selectedLienParente,
        },
        'contact_urgence': {
          'nom': _personneContactNomController.text.trim(),
          'contact':
              '$_selectedContactIndicatif ${_personneContactTelController.text.trim()}',
          'lien_parente': _selectedLienParenteUrgence,
        },
        'assistance_commerciale': {
          'is_aide_par_commercial': _isAideParCommercial,
          'commercial_nom_prenom': _commercialNomPrenomController.text.trim(),
          'commercial_code_apporteur':
              _commercialCodeApporteurController.text.trim(),
        },
        'date_effet': _dateEffetContrat?.toIso8601String(),
        'date_fin': _dateFinContrat?.toIso8601String(),
        'piece_identite': _pieceIdentite?.path.split('/').last ?? '',
        'mode_paiement': _selectedModePaiement,
        'infos_paiement': _selectedModePaiement == 'Virement'
            ? {
                'banque': _banqueController.text.trim(),
                ..._parseRibUnified(_ribUnifiedController.text.trim()),
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
                        'numero_matricule':
                            _numeroMatriculeController.text.trim(),
                      }
                    : _selectedModePaiement == 'CORIS Money'
                        ? {
                            'numero_telephone':
                                _corisMoneyPhoneController.text.trim(),
                          }
                        : null,
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
          'lieu_naissance': _clientLieuNaissanceController.text.trim(),
          'telephone':
              '$_selectedClientIndicatif ${_clientTelephoneController.text.trim()}',
          'email': _clientEmailController.text.trim(),
          'adresse': _clientAdresseController.text.trim(),
          'civilite': _selectedClientCivilite,
          'date_naissance': _clientDateNaissance?.toIso8601String(),
        };
      }

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

      return responseData['data']['id'];
    } catch (e) {
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
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  void _processPayment(String paymentMethod) async {
    // Si CORIS Money est sélectionné, utiliser le modal de paiement
    if (paymentMethod == 'CORIS Money') {
      try {
        final subscriptionId = await _saveSubscriptionData();

        // Upload du document pièce d'identité si présent
        if (_pieceIdentite != null) {
          await _uploadDocument(subscriptionId);
        }

        // Afficher le modal de paiement CorisMoney
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CorisMoneyPaymentModal(
              subscriptionId: subscriptionId,
              montant: _selectedPrime?.toDouble() ?? 0.0,
              description: 'Paiement prime CORIS ÉPARGNE',
              onPaymentSuccess: () {
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessDialog(true);
                }
              },
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Erreur lors du processus: $e');
        if (mounted) {
          _showErrorSnackBar('Erreur lors du traitement: $e');
        }
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(paymentMethod: paymentMethod),
    );

    try {
      final subscriptionId = await _saveSubscriptionData();

      // Upload du document pièce d'identité si présent
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
          amount: _selectedPrime?.toDouble() ?? 0.0,
          description: 'Paiement prime CORIS ÉPARGNE',
          onSuccess: () => _showSuccessDialog(true),
        );
        return;
      }

      final paymentSuccess = await _simulatePayment(paymentMethod);
      await _updatePaymentStatus(subscriptionId, paymentSuccess,
          paymentMethod: paymentMethod);

      if (mounted) {
        Navigator.pop(context);
        if (paymentSuccess) {
          _showSuccessDialog(true);
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
      final paths = _pieceIdentiteFiles.isNotEmpty
          ? _pieceIdentiteFiles.map((f) => f.path).toList()
          : (_pieceIdentite != null
              ? <String>[_pieceIdentite!.path]
              : <String>[]);
      if (paths.isEmpty) return;

      for (final filePath in paths) {
        final response = await subscriptionService.uploadDocument(
          subscriptionId,
          filePath,
        );
        final responseData = jsonDecode(response.body);
        if (response.statusCode != 200 || !responseData['success']) {
          debugPrint('❌ Erreur upload: ${responseData['message']}');
        }
      }
      debugPrint('✅ Document uploadé avec succès');
    } catch (e) {
      debugPrint('❌ Exception upload document: $e');
    }
  }

  void _showSuccessDialog(bool isPaid) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(isPaid: isPaid),
      );
    }
  }

  void _selectDateEffet() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateEffetContrat = picked;
        _dateFinContrat = DateTime(picked.year + 15, picked.month, picked.day);
      });
    }
  }

  void _selectBeneficiaireDateNaissance() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _beneficiaireDateNaissance ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _beneficiaireDateNaissance = picked;
        _beneficiaireDateNaissanceController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grisLeger,
      resizeToAvoidBottomInset: true,
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
                              Icon(Icons.savings_outlined,
                                  color: blanc, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'CORIS ÉPARGNE BONUS',
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
                            'Votre avenir financier commence ici',
                            style: TextStyle(
                              color: blanc.withAlpha(230),
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
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                          _buildStep1(), // Page 1: Sélection capital/prime
                          _buildStep2(), // Page 2: Informations contrat
                          _buildStepModePaiement(), // Page 3: Mode de paiement
                          _buildStep3(), // Page 4: Récapitulatif
                        ]
                      : [
                          _buildStep1(), // Page 0: Sélection capital/prime
                          _buildStep2(), // Page 1: Informations contrat
                          _buildStepModePaiement(), // Page 2: Mode de paiement
                          _buildStep3(), // Page 3: Récapitulatif
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: Offset(0, 4),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: i <= _currentStep ? bleuCoris : grisLeger,
                      shape: BoxShape.circle,
                      boxShadow: i <= _currentStep
                          ? [
                              BoxShadow(
                                color: bleuCoris.withAlpha(77),
                                blurRadius: 8,
                                offset: Offset(0, 2),
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
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _isCommercial
                        ? (i == 0
                            ? 'Client'
                            : i == 1
                                ? 'Capital'
                                : i == 2
                                    ? 'Contrat'
                                    : i == 3
                                        ? 'Paiement'
                                        : i == 4
                                            ? 'Récap'
                                            : 'Finaliser')
                        : (i == 0
                            ? 'Capital'
                            : i == 1
                                ? 'Contrat'
                                : i == 2
                                    ? 'Paiement'
                                    : i == 3
                                        ? 'Récap'
                                        : 'Finaliser'),
                    style: TextStyle(
                      fontSize: 11,
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
                  margin: EdgeInsets.only(bottom: 20, left: 6, right: 6),
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
              padding: EdgeInsets.symmetric(horizontal: 20),
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
                      SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _clientNomController,
                        label: 'Nom du client',
                        icon: Icons.person_outline,
                      ),
                      SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _clientPrenomController,
                        label: 'Prénom du client',
                        icon: Icons.person_outline,
                      ),
                      SizedBox(height: 16),
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
                              _clientAge--;
                            }
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _clientLieuNaissanceController,
                        label: 'Lieu de naissance',
                        icon: Icons.location_on,
                      ),
                      SizedBox(height: 16),
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
                      SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _clientEmailController,
                        label: 'Email du client',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _clientAdresseController,
                        label: 'Adresse du client',
                        icon: Icons.home,
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _capitalOptions.length,
                      itemBuilder: (context, index) {
                        final option = _capitalOptions[index];
                        final isSelected =
                            _selectedCapital == option['capital'];
                        final isPopular = option['popularite'] as bool;

                        return Container(
                          margin: EdgeInsets.only(bottom: 0),
                          child: Stack(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCapital = option['capital'];
                                    _selectedPrime = option['prime'];
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: blanc,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? bleuCoris
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? bleuCoris.withAlpha(26)
                                            : Colors.black.withAlpha(13),
                                        blurRadius: isSelected ? 20 : 10,
                                        offset: Offset(0, isSelected ? 6 : 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 300),
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? bleuCoris
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? bleuCoris
                                                    : grisTexte,
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? Icon(Icons.check,
                                                    size: 14, color: blanc)
                                                : null,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _formatMontant(
                                                      option['capital']!),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: bleuCoris,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${_formatMontant(option['prime']!)} / mois',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: grisTexte,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: vertSucces.withAlpha(26),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.trending_up,
                                                color: vertSucces, size: 14),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                option['bonus'],
                                                style: TextStyle(
                                                  color: vertSucces,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
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
                              if (isPopular)
                                Positioned(
                                  top: -6,
                                  right: 12,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: rougeCoris,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: rougeCoris.withAlpha(77),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'POPULAIRE',
                                      style: TextStyle(
                                        color: blanc,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_selectedCapital != null) _buildSelectedOptionSummary(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedOptionSummary() {
    return Container(
      margin: EdgeInsets.only(bottom: 20, top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [vertSucces.withAlpha(26), vertSucces.withAlpha(13)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vertSucces.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: vertSucces, size: 18),
              SizedBox(width: 8),
              Text(
                'Votre sélection',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: vertSucces,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildSummaryRow(
              'Capital au terme', _formatMontant(_selectedCapital!)),
          _buildSummaryRow('Prime mensuelle', _formatMontant(_selectedPrime!)),
          _buildSummaryRow('Durée', '15 ans (180 mois)'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: grisTexte, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: bleuCoris,
              fontSize: 13,
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildFormSection(
                      'Date d\'effet',
                      Icons.calendar_today,
                      [
                        GestureDetector(
                          onTap: _selectDateEffet,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: TextEditingController(
                                  text: _dateEffetContrat != null
                                      ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                                      : ''),
                              decoration: InputDecoration(
                                labelText: 'Date d\'effet du contrat',
                                prefixIcon: Container(
                                  margin: EdgeInsets.all(8),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bleuCoris.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.calendar_today,
                                      color: bleuCoris, size: 20),
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
                                  borderSide:
                                      BorderSide(color: bleuCoris, width: 2),
                                ),
                                filled: true,
                                fillColor: fondCarte,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
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
                    ),
                    SizedBox(height: 20),
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
                        TextFormField(
                          controller: _beneficiaireDateNaissanceController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date de naissance du bénéficiaire',
                            prefixIcon:
                                Icon(Icons.calendar_today, color: bleuCoris),
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
                              borderSide:
                                  BorderSide(color: bleuCoris, width: 2),
                            ),
                            filled: true,
                            fillColor: blanc,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          onTap: _selectBeneficiaireDateNaissance,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner la date de naissance';
                            }
                            return null;
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
                    _buildAssistanceCommercialeSection(),
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

  Widget _buildAssistanceCommercialeSection() {
    return _buildFormSection(
      'Assistance commerciale',
      Icons.support_agent,
      [
        Text(
          'Êtes-vous aidé par un commercial pour la souscription ?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: grisTexte,
          ),
        ),
        RadioListTile<bool>(
          value: false,
          groupValue: _isAideParCommercial,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Non'),
          onChanged: (value) {
            setState(() {
              _isAideParCommercial = value ?? false;
              if (!_isAideParCommercial) {
                _commercialNomPrenomController.clear();
                _commercialCodeApporteurController.clear();
              }
            });
          },
        ),
        RadioListTile<bool>(
          value: true,
          groupValue: _isAideParCommercial,
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text('Oui'),
          onChanged: (value) {
            setState(() {
              _isAideParCommercial = value ?? false;
            });
          },
        ),
        if (_isAideParCommercial) ...[
          SizedBox(height: 12),
          _buildModernTextField(
            controller: _commercialNomPrenomController,
            label: 'Nom et prénom du commercial',
            icon: Icons.person_search,
          ),
          SizedBox(height: 16),
          _buildModernTextField(
            controller: _commercialCodeApporteurController,
            label: 'Code apporteur du commercial',
            icon: Icons.badge_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _clientDateNaissance ??
              DateTime.now().subtract(Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
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
            labelText: label,
            prefixIcon: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bleuCoris.withAlpha(26),
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
            hintText: 'JJ/MM/AAAA',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
        ),
      ),
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
            color: Colors.black.withAlpha(13),
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
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bleuCoris.withAlpha(26),
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
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Vérifier si la valeur est dans la liste
    final validValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bleuCoris.withAlpha(26),
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
            color: Colors.black.withAlpha(13),
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
                    ? vertSucces.withAlpha(26)
                    : bleuCoris.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pieceIdentite != null
                      ? vertSucces
                      : bleuCoris.withAlpha(77),
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

  Widget _buildStepModePaiement() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 24),

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
                                  child: Center(
                                      child: customIconWidget ??
                                          Icon(icon,
                                              color: iconColor, size: 28)),
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

                      // Informations du RIB
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Informations du RIB',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: bleuCoris,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildModernTextField(
                        controller: _ribUnifiedController,
                        label: 'Numéro RIB complet (XXXXX / XXXXXXXXXXX / XX)',
                        icon: Icons.account_balance,
                        keyboardType: TextInputType.number,
                        maxLength: 24,
                        onChanged: (_) => _formatRibInput(),
                      ),
                    ] else if (_selectedModePaiement == 'Wave' ||
                        _selectedModePaiement == 'Orange Money') ...[
                      Text(
                        'Numéro Mobile Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numeroMobileMoneyController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone',
                          labelStyle: TextStyle(
                              color: bleuCoris.withValues(alpha: 0.7)),
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
                                  Icons.phone,
                                  color: bleuCoris,
                                  size: 20,
                                );
                              },
                            ),
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
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Ce champ est obligatoire'
                                : null,
                      ),
                    ] else if (_selectedModePaiement ==
                        'Prélèvement à la source') ...[
                      Text(
                        'Informations Prélèvement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _nomStructureController,
                        label: 'Nom de la structure',
                        icon: Icons.business,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _numeroMatriculeController,
                        label: 'Numéro de matricule',
                        icon: Icons.badge,
                        keyboardType: TextInputType.text,
                      ),
                    ] else if (_selectedModePaiement == 'CORIS Money') ...[
                      Text(
                        'Numéro CORIS Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: grisTexte,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _corisMoneyPhoneController,
                        label: 'Numéro de téléphone',
                        icon: Icons.account_balance_wallet,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Note informative
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ces informations seront utilisées pour le prélèvement automatique de vos primes.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ], // Fin du children du Column
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
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
                          'Cotisation mensuelle à payer',
                          style: TextStyle(
                            color: grisTexte,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatMontant(_selectedPrime ?? 0),
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

    return ListView(
      children: [
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
        SizedBox(height: 20),
        _buildRecapSection(
          'Produit Souscrit',
          Icons.savings,
          vertSucces,
          [
            _buildRecapRow('Produit', 'CORIS ÉPARGNE BONUS'),
            _buildRecapRow(
                'Capital au terme', _formatMontant(_selectedCapital ?? 0)),
            _buildRecapRow(
                'Prime mensuelle', _formatMontant(_selectedPrime ?? 0)),
            _buildRecapRow('Durée', '15 ans (180 mois)'),
            _buildRecapRow(
                'Date d\'effet',
                _dateEffetContrat != null
                    ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                    : 'Non définie'),
            _buildRecapRow(
                'Date de fin',
                _dateFinContrat != null
                    ? '${_dateFinContrat!.day}/${_dateFinContrat!.month}/${_dateFinContrat!.year}'
                    : 'Non définie'),
            _buildRecapRow('Bonus', _getBonusText()),
          ],
        ),
        SizedBox(height: 20),
// SECTION CONTACTS
        _buildRecapSection(
          'Contacts',
          Icons.contacts,
          bleuSecondaire,
          [
            // 🔹 Bénéficiaire
            _buildSubsectionTitle('Bénéficiaire en cas de décès'),
            const SizedBox(height: 8),
            _buildCombinedRecapRow(
              'Nom complet',
              _beneficiaireNomController.text.isNotEmpty
                  ? _beneficiaireNomController.text
                  : 'Non renseigné',
              'Lien de parenté',
              _selectedLienParente.isNotEmpty
                  ? _selectedLienParente
                  : 'Non renseigné',
            ),
            _buildRecapRow(
              'Date de naissance',
              _beneficiaireDateNaissanceController.text.isNotEmpty
                  ? SubscriptionRecapWidgets.formatDate(
                      _beneficiaireDateNaissanceController.text)
                  : 'Non renseigné',
            ),
            _buildRecapRow(
              'Téléphone',
              _beneficiaireContactController.text.isNotEmpty
                  ? '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text}'
                  : 'Non renseigné',
            ),

            const SizedBox(height: 16),

            // 🔹 Contact d'urgence
            _buildSubsectionTitle('Contact d\'urgence'),
            const SizedBox(height: 8),
            _buildCombinedRecapRow(
              'Nom complet',
              _personneContactNomController.text.isNotEmpty
                  ? _personneContactNomController.text
                  : 'Non renseigné',
              'Lien de parenté',
              _selectedLienParenteUrgence.isNotEmpty
                  ? _selectedLienParenteUrgence
                  : 'Non renseigné',
            ),
            _buildRecapRow(
              'Téléphone',
              _personneContactTelController.text.isNotEmpty
                  ? '$_selectedContactIndicatif ${_personneContactTelController.text}'
                  : 'Non renseigné',
            ),
          ],
        ),
        if (_isAideParCommercial ||
            _commercialNomPrenomController.text.trim().isNotEmpty ||
            _commercialCodeApporteurController.text.trim().isNotEmpty) ...[
          SizedBox(height: 20),
          _buildRecapSection(
            'Assistance commerciale',
            Icons.support_agent,
            orangeCoris,
            [
              _buildRecapRow(
                'Nom et prénom du commercial',
                _commercialNomPrenomController.text.isNotEmpty
                    ? _commercialNomPrenomController.text
                    : 'Non renseigné',
              ),
              _buildRecapRow(
                'Code apporteur',
                _commercialCodeApporteurController.text.isNotEmpty
                    ? _commercialCodeApporteurController.text
                    : 'Non renseigné',
              ),
            ],
          ),
        ],
        SizedBox(height: 20),
        // 💳 SECTION MODE DE PAIEMENT
        if (_selectedModePaiement != null)
          _buildRecapSection(
            'Mode de Paiement',
            Icons.payment,
            _selectedModePaiement == 'Virement'
                ? Colors.blue
                : _selectedModePaiement == 'Wave'
                    ? Color(0xFF00BFFF)
                    : orangeCoris,
            [
              _buildRecapRow('Mode choisi', _selectedModePaiement!),
              SizedBox(height: 8),
              if (_selectedModePaiement == 'Virement') ...[
                _buildRecapRow(
                    'Banque',
                    _banqueController.text.isNotEmpty
                        ? _banqueController.text
                        : 'Non renseigné'),
                _buildRecapRow(
                    'Numéro RIB',
                    _ribUnifiedController.text.isNotEmpty
                        ? _ribUnifiedController.text
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
        if (_selectedModePaiement != null) SizedBox(height: 20),
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
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: orangeWarning.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: orangeWarning.withAlpha(77)),
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: orangeWarning, size: 28),
              SizedBox(height: 10),
              Text(
                'Vérification Importante',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: orangeWarning,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Vérifiez attentivement toutes les informations ci-dessus. Une fois la souscription validée, certaines modifications ne seront plus possibles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: grisTexte,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
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

  Widget _buildRecapSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: bleuCoris,
        fontSize: 14,
      ),
    );
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: grisTexte,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: bleuCoris,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedRecapRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label1 :',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label2 :',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: grisTexte,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            color: Colors.black.withAlpha(13),
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
                onPressed: _currentStep == (_isCommercial ? 4 : 3)
                    ? _showSignatureAndPayment
                    : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bleuCoris,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: bleuCoris.withAlpha(77),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == (_isCommercial ? 4 : 3)
                          ? 'Signer et Finaliser'
                          : 'Suivant',
                      style: TextStyle(
                        color: blanc,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      _currentStep == (_isCommercial ? 4 : 3)
                          ? Icons.draw
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
}

// Dialog de chargement moderne
class LoadingDialog extends StatelessWidget {
  final String paymentMethod;
  const LoadingDialog({super.key, required this.paymentMethod});

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
              color: Colors.black.withAlpha(26),
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

// Dialog de succès moderne
class SuccessDialog extends StatelessWidget {
  final bool isPaid;
  const SuccessDialog({super.key, required this.isPaid});

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
              color: Colors.black.withAlpha(26),
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
                    : Color(0xFFF59E0B).withAlpha(26),
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
                  ? 'Félicitations! Votre contrat CORIS ÉPARGNE BONUS est maintenant actif. Vous recevrez un message de confirmation sous peu.'
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

// Bottom sheet de paiement moderne
class PaymentBottomSheet extends StatelessWidget {
  final Function(String) onPayNow;
  final VoidCallback onPayLater;
  const PaymentBottomSheet({
    super.key,
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
            color: Colors.black.withAlpha(26),
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
              _buildPaymentOptionWithImage(
                'Wave',
                'assets/images/icone_wave.jpeg',
                Colors.blue,
                'Paiement mobile sécurisé',
                () => onPayNow('Wave'),
              ),
              // _buildPaymentOptionWithImage(
              //   'Orange Money',
              //   'assets/images/icone_orange_money.jpeg',
              //   Colors.orange,
              //   'Paiement mobile Orange',
              //   () => onPayNow('Orange Money'),
              // ),
              // _buildPaymentOptionWithImage(
              //   'CORIS Money',
              //   'assets/images/icone_corismoney.jpeg',
              //   const Color(0xFF1E3A8A),
              //   'Paiement via CORIS Money',
              //   () => onPayNow('CORIS Money'),
              // ),
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
          border: Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
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

  Widget _buildPaymentOptionWithImage(String title, String imagePath,
      Color color, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(51)),
              ),
              child: Image.asset(
                imagePath,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Erreur chargement image: $imagePath - $error');
                  return Icon(Icons.image_not_supported,
                      size: 32, color: Colors.grey);
                },
              ),
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
