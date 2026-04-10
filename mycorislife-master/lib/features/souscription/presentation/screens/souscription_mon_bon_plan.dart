import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/services/wave_payment_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:mycorislife/services/subscription_service.dart';
import 'package:intl/intl.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/core/utils/identity_document_picker.dart';
import '../widgets/signature_dialog_syncfusion.dart' as SignatureDialogFile;
import 'dart:typed_data';

class SouscriptionBonPlanPage extends StatefulWidget {
  final String? clientId; // ID du client si souscription par commercial
  final Map<String, dynamic>?
      clientData; // Données du client si souscription par commercial
  final int?
      subscriptionId; // ID de la souscription à modifier (si mode édition)
  final Map<String, dynamic>? existingData; // Données existantes à préremplir

  const SouscriptionBonPlanPage({
    super.key,
    this.clientId,
    this.clientData,
    this.subscriptionId,
    this.existingData,
  });

  @override
  SouscriptionBonPlanPageState createState() => SouscriptionBonPlanPageState();
}

class SouscriptionBonPlanPageState extends State<SouscriptionBonPlanPage>
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
  Future<Map<String, dynamic>>? _userDataFuture;

  // Form controllers
  final _formKeyClientInfo = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // 🟦 1. PREMIÈRE PARTIE DU FORMULAIRE
  // Step 1 controllers
  final _montantCotisationController = TextEditingController();
  final _dateEffetController = TextEditingController();
  final _dureeController = TextEditingController();
  final FocusNode _dureeFocusNode = FocusNode();

  // Variables pour la périodicité
  String _selectedPeriodicite =
      'Journalière'; // 'Journalière', 'Hebdomadaire', 'Mensuel'
  final List<String> _periodiciteOptions = [
    'Journalière',
    'Hebdomadaire',
    'Mensuel',
    'Libre'
  ];

  // Variables pour la durée
  String _selectedDureeType = 'ans'; // 'ans' ou 'mois'
  final List<String> _dureeTypeOptions = ['ans', 'mois'];

  DateTime? _dateEffetContrat;

  // Constantes pour les validations
  static const double MONTANT_MINIMAL_COTISATION = 3000;

  // 🟦 2. DEUXIÈME PARTIE DU FORMULAIRE
  // Step 2 controllers
  String _selectedBeneficiaireIndicatif = '+225'; // Côte d'Ivoire par défaut
  String _selectedContactIndicatif = '+225'; // Côte d'Ivoire par défaut
  final List<Map<String, String>> _indicatifOptions = [
    {'code': '+225', 'pays': 'Côte d\'Ivoire'},
    {'code': '+226', 'pays': 'Burkina Faso'},
  ];

  final _beneficiaireNomController = TextEditingController();
  final _beneficiaireContactController = TextEditingController();
  final _beneficiaireDateNaissanceController = TextEditingController();
  DateTime? _beneficiaireDateNaissance;
  String _selectedLienParente = 'Conjoint';
  final _personneContactNomController = TextEditingController();
  final _personneContactTelController = TextEditingController();
  String _selectedLienParenteUrgence = 'Parent';
  bool _isAideParCommercial = false;
  final _commercialNomPrenomController = TextEditingController();
  final _commercialCodeApporteurController = TextEditingController();

  // Options de lien de parenté
  final List<String> _lienParenteOptions = [
    'Conjoint',
    'Enfant',
    'Parent',
    'Frère/Sœur',
    'Ami',
    'Autre'
  ];

  File? _pieceIdentite;
  // ignore: unused_field
  String? _pieceIdentiteLabel;
  final List<File> _pieceIdentiteFiles = [];
  bool _isProcessing = false;

  // Signature du client
  Uint8List? _clientSignature;

  // 🟦 3. TROISIÈME PARTIE
  // 💳 VARIABLES MODE DE PAIEMENT
  String? _selectedModePaiement; // 'Virement', 'Wave', 'Orange Money'
  String? _selectedBanque;
  final _banqueController = TextEditingController();
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

  // Variables pour commercial (souscription pour un client)
  bool _isCommercial = false;

  // Contrôleurs pour les informations client (si commercial)
  final TextEditingController _clientNomController = TextEditingController();
  final TextEditingController _clientPrenomController = TextEditingController();
  DateTime? _clientDateNaissance;
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
  String _selectedClientCivilite = 'Monsieur';
  String _selectedClientIndicatif = '+225';

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    // Si on modifie une proposition existante, préremplir avec les données
    if (widget.existingData != null) {
      _prefillFromExistingData();
    } else {
      // Charger les données utilisateur une seule fois
      _userDataFuture = _loadUserDataForRecap();
    }

    // Date d'effet par défaut (aujourd'hui)
    _dateEffetContrat = DateTime.now();
    _dateEffetController.text =
        DateFormat('dd/MM/yyyy').format(_dateEffetContrat!);

    // 🔍 Validation de la durée uniquement à la sortie du champ
    // MON BON PLAN CORIS: durée minimale 2 ans, maximale 15 ans
    _dureeFocusNode.addListener(() {
      if (!_dureeFocusNode.hasFocus) {
        // Utiliser Future.delayed pour éviter les appels multiples
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;

          // Le champ a perdu le focus - valider maintenant
          if (_dureeController.text.isNotEmpty) {
            int? duree = int.tryParse(_dureeController.text);
            if (duree != null) {
              // Convertir en années si nécessaire
              int dureeEnAnnees =
                  _selectedDureeType == 'ans' ? duree : (duree ~/ 12);

              // ❌ Validation de la durée minimale (2 ans)
              if (dureeEnAnnees < 2) {
                _showProfessionalDialog(
                  title: 'Durée minimale requise',
                  message:
                      'La durée minimale pour MON BON PLAN CORIS est de 2 ans. Veuillez ajuster la durée du contrat pour continuer.',
                  icon: Icons.access_time,
                  iconColor: orangeWarning,
                  backgroundColor: orangeWarning,
                );
                return;
              }

              // ❌ Validation de la durée maximale (15 ans)
              if (dureeEnAnnees > 15) {
                _showProfessionalDialog(
                  title: 'Durée maximale dépassée',
                  message:
                      'La durée maximale pour MON BON PLAN CORIS est de 15 ans. Veuillez ajuster la durée du contrat pour continuer.',
                  icon: Icons.access_time,
                  iconColor: orangeWarning,
                  backgroundColor: orangeWarning,
                );
                return;
              }
            }
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vérifier si c'est un commercial qui fait la souscription
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isCommercialArg = args != null && args['isCommercial'] == true;
    final bool isCommercialProps =
        widget.clientId != null || widget.clientData != null;
    final bool isCommercialExistingData =
        widget.existingData?['client_info'] != null;
    final bool shouldEnableCommercial =
        isCommercialArg || isCommercialProps || isCommercialExistingData;

    if (shouldEnableCommercial && !_isCommercial) {
      setState(() {
        _isCommercial = true;
        _currentStep = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageController.jumpToPage(0);
        }
      });
    }

    if (isCommercialArg) {
      // Si on est en mode modification (avec existingData), pré-remplir tout
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
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('❌ Token non trouvé');
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

  /// Charge les données utilisateur spécifiquement pour le récapitulatif
  /// Retourne les données depuis l'API ou depuis _userData en fallback
  Future<Map<String, dynamic>> _loadUserDataForRecap() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        debugPrint('❌ Token non trouvé pour récap');
        return _userData.isNotEmpty ? _userData : {};
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
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

    // Montant de la cotisation
    if (data['montant_cotisation'] != null) {
      final montant = data['montant_cotisation'] is int
          ? data['montant_cotisation'].toDouble()
          : data['montant_cotisation'];
      _montantCotisationController.text = _formatNumber(montant);
    }

    // Périodicité
    if (data['periodicite'] != null) {
      _selectedPeriodicite = data['periodicite'];
    }

    // Durée du contrat
    if (data['duree_contrat'] != null) {
      _dureeController.text = data['duree_contrat'].toString();
    }

    // Unité de durée (ans ou mois)
    if (data['unite_duree'] != null) {
      _selectedDureeType = data['unite_duree'];
    }

    // Date d'effet
    if (data['date_effet'] != null) {
      try {
        _dateEffetContrat = DateTime.parse(data['date_effet']);
        _dateEffetController.text =
            DateFormat('dd/MM/yyyy').format(_dateEffetContrat!);
      } catch (e) {
        debugPrint('Erreur parsing date_effet: $e');
      }
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
      if (benef['date_naissance'] != null) {
        try {
          _beneficiaireDateNaissance = DateTime.parse(benef['date_naissance']);
          _beneficiaireDateNaissanceController.text =
              DateFormat('dd/MM/yyyy').format(_beneficiaireDateNaissance!);
        } catch (e) {
          debugPrint('Erreur parsing date_naissance beneficiaire: $e');
        }
      }
      _selectedLienParente = benef['lien_parente'] ?? 'Conjoint';
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

    if (data['assistance_commerciale'] != null) {
      final assistance = data['assistance_commerciale'];
      _isAideParCommercial =
          assistance['is_aide_par_commercial'] == true;
      _commercialNomPrenomController.text =
          assistance['commercial_nom_prenom'] ?? '';
      _commercialCodeApporteurController.text =
          assistance['commercial_code_apporteur'] ?? '';
    }

    // 💳 MODE DE PAIEMENT - Pré-remplissage
    if (data['mode_paiement'] != null) {
      _selectedModePaiement = data['mode_paiement'];

      if (data['infos_paiement'] != null) {
        final infos = data['infos_paiement'];
        if (_selectedModePaiement == 'Virement') {
          _banqueController.text = infos['banque'] ?? '';
          // Construire le RIB unifié à partir des 3 champs séparés
          final codeGuichet = infos['code_guichet'] ?? '';
          final numeroCompte = infos['numero_compte'] ?? '';
          final cleRib = infos['cle_rib'] ?? '';
          if (codeGuichet.isNotEmpty &&
              numeroCompte.isNotEmpty &&
              cleRib.isNotEmpty) {
            _ribUnifiedController.text =
                '$codeGuichet / $numeroCompte / $cleRib';
          }
        } else if (_selectedModePaiement == 'Wave' ||
            _selectedModePaiement == 'Orange Money') {
          _numeroMobileMoneyController.text = infos['numero_telephone'] ?? '';
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    _montantCotisationController.dispose();
    _dateEffetController.dispose();
    _dureeFocusNode.dispose();
    _beneficiaireNomController.dispose();
    _beneficiaireContactController.dispose();
    _beneficiaireDateNaissanceController.dispose();
    _personneContactNomController.dispose();
    _personneContactTelController.dispose();
    _commercialNomPrenomController.dispose();
    _commercialCodeApporteurController.dispose();

    // Dispose des contrôleurs client
    _clientNomController.dispose();
    _clientPrenomController.dispose();
    _clientDateNaissanceController.dispose();
    _clientLieuNaissanceController.dispose();
    _clientTelephoneController.dispose();
    _clientEmailController.dispose();
    _clientAdresseController.dispose();
    _clientProfessionController.dispose();
    _clientSecteurActiviteController.dispose();
    _clientNumeroPieceController.dispose();

    // Dispose des contrôleurs de paiement
    _banqueController.dispose();
    _ribUnifiedController.dispose();
    _numeroMobileMoneyController.dispose();
    _nomStructureController.dispose();
    _numeroMatriculeController.dispose();
    _corisMoneyPhoneController.dispose();

    super.dispose();
  }

  String _formatMontant(double montant) {
    final rounded = montant.round();
    return "${rounded.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }

  String _formatNumber(double number) {
    final rounded = number.round();
    return rounded.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  void _formatMontantInput() {
    final text = _montantCotisationController.text.replaceAll(' ', '');
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null) {
        _montantCotisationController.text = _formatNumber(value);
        _montantCotisationController.selection = TextSelection.fromPosition(
          TextPosition(offset: _montantCotisationController.text.length),
        );
      }
    }
  }

  /// Parse le RIB unifié au format: XXXX / XXXXXXXXXXX / XX
  /// Retourne une map avec {code_guichet, numero_compte, cle_rib}
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
      }

      if (mounted) {
        _showSuccessSnackBar(_pieceIdentiteFiles.length > 1
            ? '${_pieceIdentiteFiles.length} documents ont été téléchargés avec succès.'
            : 'Votre pièce d\'identité a été téléchargée avec succès.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            'Une erreur s\'est produite lors de la sélection du fichier. Veuillez réessayer.');
      }
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

  /// Sauvegarde les données de souscription pour Mon Bon Plan Coris
  Future<int> _saveSubscriptionData() async {
    try {
      final subscriptionService = SubscriptionService();

      // Préparer les données de souscription spécifiques à Mon Bon Plan Coris
      final subscriptionData = {
        'product_type': 'mon_bon_plan_coris',
        'montant':
            double.parse(_montantCotisationController.text.replaceAll(' ', ''))
                .toInt(),
        'montant_cotisation':
            double.parse(_montantCotisationController.text.replaceAll(' ', ''))
                .toInt(),
        'periodicite': _selectedPeriodicite,
        'duree': int.tryParse(_dureeController.text) ?? 0,
        'duree_type': _selectedDureeType,
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
              _personneContactTelController.text.trim(),
          'lien_parente': _selectedLienParenteUrgence,
        },
        'assistance_commerciale': {
          'is_aide_par_commercial': _isAideParCommercial,
          'commercial_nom_prenom': _commercialNomPrenomController.text.trim(),
          'commercial_code_apporteur':
              _commercialCodeApporteurController.text.trim(),
        },
        'date_effet': _dateEffetContrat?.toIso8601String(),
        'piece_identite': _pieceIdentite?.path.split('/').last ?? '',
        // 💳 MODE DE PAIEMENT
        'mode_paiement': _selectedModePaiement,
        'infos_paiement': _selectedModePaiement == 'Virement'
            ? () {
                final parsed =
                    _parseRibUnified(_ribUnifiedController.text.trim());
                return {
                  'banque': _banqueController.text.trim(),
                  'code_guichet': parsed['code_guichet'] ?? '',
                  'numero_compte': parsed['numero_compte'] ?? '',
                  'cle_rib': parsed['cle_rib'] ?? '',
                };
              }()
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
          'profession': _clientProfessionController.text.trim(),
          'secteur_activite': _clientSecteurActiviteController.text.trim(),
          'civilite': _selectedClientCivilite,
          'date_naissance': _clientDateNaissance?.toIso8601String(),
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
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Si CORIS Money est sélectionné, utiliser le modal de paiement
    if (paymentMethod == 'CORIS Money') {
      try {
        // ÉTAPE 1: Sauvegarder la souscription
        final subscriptionId = await _saveSubscriptionData();

        // ÉTAPE 1.5: Upload du document pièce d'identité si présent
        if (_pieceIdentite != null) {
          try {
            await _uploadDocument(subscriptionId);
          } catch (uploadError) {
            debugPrint(
                '⚠️ Erreur upload document (non bloquant): $uploadError');
          }
        }

        // Afficher le modal de paiement CorisMoney
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CorisMoneyPaymentModal(
              subscriptionId: subscriptionId,
              montant: double.tryParse(
                      _montantCotisationController.text.replaceAll(' ', '')) ??
                  0.0,
              description: 'Paiement prime CORIS MON BON PLAN',
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
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoadingDialog(paymentMethod: paymentMethod),
    );

    try {
      // ÉTAPE 1: Sauvegarder la souscription
      final subscriptionId = await _saveSubscriptionData();

      // ÉTAPE 1.5: Upload du document pièce d'identité si présent
      if (_pieceIdentite != null) {
        try {
          await _uploadDocument(subscriptionId);
        } catch (uploadError) {
          debugPrint('⚠️ Erreur upload document (non bloquant): $uploadError');
        }
      }

      if (paymentMethod == 'Wave') {
        if (mounted) {
          Navigator.pop(context);
        }

        await WavePaymentHandler.startPayment(
          context,
          subscriptionId: subscriptionId,
          amount: double.tryParse(
                  _montantCotisationController.text.replaceAll(' ', '')) ??
              0.0,
          description: 'Paiement prime CORIS MON BON PLAN',
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
        try {
          await _uploadDocument(subscriptionId);
        } catch (uploadError) {
          debugPrint('⚠️ Erreur upload document (non bloquant): $uploadError');
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
          debugPrint('❌ Erreur upload: ${localData['message']}');
          throw Exception(
              localData['message'] ?? 'Erreur lors de l\'upload du document');
        }
      }

      // Récupérer le label original si présent dans la réponse
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
            '⚠️ Impossible de lire piece_identite_label depuis la réponse: $e');
      }

      debugPrint('✅ Document uploadé avec succès');
    } catch (e) {
      debugPrint('❌ Exception upload document: $e');
    }
  }

  void _showSuccessDialog(bool isPaid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(isPaid: isPaid),
    );
  }

  /// 📋 Dialog pour les messages de validation (durée, capital, etc.)
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
      });
    }
  }

  void _selectBeneficiaireDateNaissance() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _beneficiaireDateNaissance ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      initialDatePickerMode: DatePickerMode.day,
    );

    if (picked != null && mounted) {
      setState(() {
        _beneficiaireDateNaissance = picked;
        _beneficiaireDateNaissanceController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // =================================================================
  // MÉTHODES DE VALIDATION
  // =================================================================

  void _nextStep() {
    final maxStep = _isCommercial ? 4 : 3;
    if (_currentStep < maxStep) {
      bool canProceed = false;

      if (_isCommercial) {
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
        if (_currentStep == 0 && _validateStep1()) {
          canProceed = true;
        } else if (_currentStep == 1 && _validateStep2()) {
          canProceed = true;
        } else if (_currentStep == 2 && _validateStepModePaiement()) {
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
    if (_clientDateNaissance == null) {
      _showErrorSnackBar('Veuillez saisir la date de naissance du client');
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
    // VALIDATION SPÉCIFIQUE À MON BON PLAN CORIS
    if (_montantCotisationController.text.trim().isEmpty ||
        _selectedPeriodicite.isEmpty ||
        _dateEffetContrat == null ||
        _dureeController.text.trim().isEmpty) {
      _showErrorSnackBar(
          'Veuillez compléter tous les champs obligatoires avant de continuer.');
      return false;
    }

    final montantText = _montantCotisationController.text.replaceAll(' ', '');
    final montant = double.tryParse(montantText);

    if (montant == null || montant <= 0) {
      _showErrorSnackBar(
          'Le montant saisi est invalide. Veuillez entrer un montant positif.');
      return false;
    }

    // VÉRIFICATION DU MONTANT MINIMAL DE 3 000 F
    if (montant < MONTANT_MINIMAL_COTISATION) {
      _showErrorSnackBar(
          'Le montant minimal de la cotisation est de ${_formatMontant(MONTANT_MINIMAL_COTISATION)}.');
      return false;
    }

    // Validation de la durée
    final duree = int.tryParse(_dureeController.text);
    if (duree == null || duree <= 0) {
      _showErrorSnackBar('Veuillez entrer une durée valide.');
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    if (_beneficiaireNomController.text.trim().isEmpty ||
        _beneficiaireContactController.text.trim().isEmpty ||
        _beneficiaireDateNaissance == null ||
        _personneContactNomController.text.trim().isEmpty ||
        _personneContactTelController.text.trim().isEmpty) {
      _showErrorSnackBar(
          'Veuillez renseigner tous les contacts et informations de bénéficiaire.');
      return false;
    }

    // La pièce d'identité n'est obligatoire QUE pour une nouvelle souscription
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

    if (!RegExp(r'^\+?[0-9]{7,15}$')
        .hasMatch(_personneContactTelController.text)) {
      _showErrorSnackBar(
          'Le numéro de contact d\'urgence semble invalide. Veuillez vérifier.');
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
      if (_ribUnifiedController.text.trim().isEmpty) {
        _showErrorSnackBar(
            'Veuillez entrer votre numéro RIB complet (format: 4444 / 11111111111 / 22).');
        return false;
      }
      if (!_validateRibUnified(_ribUnifiedController.text.trim())) {
        _showErrorSnackBar(
            'Le format du RIB est incorrect. Format attendu: 55555 / 11111111111 / 22 (5 chiffres / 11 chiffres / 2 chiffres)');
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

  // =================================================================
  // WIDGET BUILDERS
  // =================================================================

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
                                'MON BON PLAN CORIS',
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
                            'Épargnez régulièrement selon vos moyens',
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
                          _buildStepClientInfo(), // Page 0: Informations client
                          _buildStep1(), // Page 1: Paramètres de souscription
                          _buildStep2(), // Page 2: Bénéficiaire/Contact
                          _buildStepModePaiement(), // Page 3: Mode de paiement
                          _buildStep3(), // Page 4: Récapitulatif (Finaliser ouvre modal)
                        ]
                      : [
                          _buildStep1(), // Page 0: Paramètres de souscription
                          _buildStep2(), // Page 1: Bénéficiaire/Contact
                          _buildStepModePaiement(), // Page 2: Mode de paiement
                          _buildStep3(), // Page 3: Récapitulatif (Finaliser ouvre modal)
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
            color: Colors.black.withAlpha(8),
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
                                color: bleuCoris.withAlpha(51),
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
                                              ? Icons.check_circle
                                              : Icons.credit_card)
                          : (i == 0
                              ? Icons.account_balance_wallet
                              : i == 1
                                  ? Icons.person_add
                                  : i == 2
                                      ? Icons.payment
                                      : i == 3
                                          ? Icons.check_circle
                                          : Icons.credit_card),
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
                                            ? 'Recap'
                                            : 'Finaliser')
                        : (i == 0
                            ? 'Souscription'
                            : i == 1
                                ? 'Infos'
                                : i == 2
                                    ? 'Paiement'
                                    : i == 3
                                        ? 'Recap'
                                        : 'Finaliser'),
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
                        _buildDatePickerField(
                          controller: _clientDateNaissanceController,
                          label: 'Date de naissance du client',
                          icon: Icons.cake_outlined,
                          selectedDate: _clientDateNaissance,
                          onDateSelected: (date) {
                            setState(() {
                              _clientDateNaissance = date;
                              _clientDateNaissanceController.text =
                                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                          controller: _clientProfessionController,
                          label: 'Profession',
                          icon: Icons.work,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _clientSecteurActiviteController,
                          label: "Secteur d'activité",
                          icon: Icons.business,
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
                            color: Colors.black.withAlpha(10),
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
                                  "Souscrire à MON BON PLAN CORIS",
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

                          // 1. PÉRIODICITÉ
                          _buildPeriodiciteDropdown(),
                          const SizedBox(height: 16),

                          // 2. MONTANT DE LA COTISATION
                          _buildMontantCotisationField(),
                          const SizedBox(height: 16),

                          // 3. DATE D'EFFET DU CONTRAT
                          _buildDateEffetField(),

                          const SizedBox(height: 16),

                          // 4. DURÉE DU CONTRAT
                          _buildDureeContratField(),

                          SizedBox(height: 16),

                          // Note informative
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bleuClair,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: bleuCoris.withAlpha(51)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: bleuCoris, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'La cotisation minimum est de ${_formatMontant(MONTANT_MINIMAL_COTISATION)} par période.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: bleuCoris,
                                    ),
                                  ),
                                ),
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

  Widget _buildPeriodiciteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Périodicité *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
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
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedPeriodicite,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon:
                    Icon(Icons.calendar_today, color: Color(0xFF002B6B)),
                labelText: 'Choisissez votre périodicité',
              ),
              items: _periodiciteOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriodicite = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La périodicité est obligatoire';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMontantCotisationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant de la cotisation ${_selectedPeriodicite.toLowerCase()} *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _montantCotisationController,
          keyboardType: TextInputType.number,
          onEditingComplete: () {
            _formatMontantInput();
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            hintText: 'Minimum ${_formatMontant(MONTANT_MINIMAL_COTISATION)}',
            prefixIcon: Icon(Icons.monetization_on,
                size: 20, color: bleuCoris.withAlpha(179)),
            suffixText: 'CFA',
            filled: true,
            fillColor: bleuClair.withAlpha(77),
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le montant est obligatoire';
            }
            final montantText = value.replaceAll(' ', '');
            final montant = double.tryParse(montantText);
            if (montant == null || montant <= 0) {
              return 'Montant invalide';
            }
            if (montant < MONTANT_MINIMAL_COTISATION) {
              return 'Minimum ${_formatMontant(MONTANT_MINIMAL_COTISATION)}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateEffetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date d\'effet du contrat *',
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
                    color: bleuCoris.withAlpha(26),
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La date d\'effet est obligatoire';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDureeContratField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durée du contrat *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _dureeController,
                focusNode: _dureeFocusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  hintText: 'Ex: 10',
                  prefixIcon: Icon(Icons.timelapse,
                      size: 20, color: bleuCoris.withAlpha(179)),
                  filled: true,
                  fillColor: bleuClair.withAlpha(77),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Durée obligatoire';
                  }
                  final duree = int.tryParse(value);
                  if (duree == null || duree <= 0) {
                    return 'Durée invalide';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bleuCoris.withAlpha(51)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedDureeType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _dureeTypeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDureeType = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
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
                          label: 'Nom complet du bénéficiaire *',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 16),
                        _buildPhoneFieldWithIndicatif(
                          controller: _beneficiaireContactController,
                          label: 'Contact du bénéficiaire *',
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
                            labelText: 'Date de naissance du bénéficiaire *',
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
                          label: 'Lien de parenté *',
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
                          label: 'Nom complet *',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 16),
                        _buildPhoneFieldWithIndicatif(
                          controller: _personneContactTelController,
                          label: 'Contact téléphonique *',
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
                          label: 'Lien de parenté *',
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
                    if (!_isCommercial) _buildAssistanceCommercialeSection(),
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

  // =================================================================
  // WIDGETS PARTAGÉS (identique aux autres pages)
  // =================================================================

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
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final DateTime now = DateTime.now();
        final DateTime initial =
            selectedDate ?? now.subtract(Duration(days: 365 * 25));
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: now,
          locale: const Locale('fr', 'FR'),
        );

        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: AbsorbPointer(
        child: _buildModernTextField(
          controller: controller,
          label: label,
          icon: icon,
          keyboardType: TextInputType.datetime,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = (value != null && items.contains(value)) ? value : null;

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
                'Pièce d\'identité *',
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

  /// 💳 ÉTAPE MODE DE PAIEMENT (identique aux autres pages)
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

                      // Informations du RIB (champ unifié)
                      Text(
                        'Informations du RIB',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: bleuCoris,
                        ),
                      ),
                      SizedBox(height: 12),

                      // RIB unifié: XXXXX / XXXXXXXXXXX / XX (5 chiffres / 11 chiffres / 2 chiffres)
                      TextField(
                        controller: _ribUnifiedController,
                        onChanged: (_) => _formatRibInput(),
                        decoration: InputDecoration(
                          labelText: 'Numéro RIB complet *',
                          hintText: '55555 / 11111111111 / 22',
                          helperText:
                              'Code guichet (5) / Numéro compte (11) / Clé RIB (2)',
                          prefixIcon:
                              Icon(Icons.account_balance, color: bleuCoris),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 24, // 5 + 3 + 11 + 3 + 2 = 24 caractères
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
                            'Ces informations seront utilisées pour le prélèvement automatique de vos cotisations.',
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

  /// 🟦 4. PAGE DE RÉCAPITULATIF (sans calculs - juste affichage des informations)
  Widget _buildStep3() {
    debugPrint('🟦 _buildStep3 appelé - _currentStep: $_currentStep');
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _isCommercial
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildRecapContent(),
                  )
                : FutureBuilder<Map<String, dynamic>>(
                    future: _userDataFuture,
                    builder: (context, snapshot) {
                      // Pour les clients, attendre le chargement des données
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(color: bleuCoris));
                      }

                      if (snapshot.hasError) {
                        debugPrint(
                            'Erreur chargement données récapitulatif: ${snapshot.error}');
                        // En cas d'erreur, essayer d'utiliser _userData si disponible
                        if (_userData.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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

                      // Données chargées avec succès
                      final userData = snapshot.data ?? {};
                      debugPrint(
                          '🟦 Données utilisateur chargées pour récap: ${userData.keys}');
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _buildRecapContent(userData: userData),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRecapContent({Map<String, dynamic>? userData}) {
    debugPrint('🟦 _buildRecapContent appelé - userData: ${userData?.keys}');
    // Formater le montant pour l'affichage
    final montantText = _montantCotisationController.text.replaceAll(' ', '');
    final montant = double.tryParse(montantText) ?? 0;

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
        // Informations Personnelles
        SubscriptionRecapWidgets.buildPersonalInfoSection(displayData),

        const SizedBox(height: 20),

        // 🟦 SECTION SPÉCIFIQUE À MON BON PLAN CORIS
        SubscriptionRecapWidgets.buildRecapSection(
          'Produit Souscrit',
          Icons.savings,
          vertSucces,
          [
            SubscriptionRecapWidgets.buildRecapRow(
                'Produit', 'MON BON PLAN CORIS'),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
                'Périodicité',
                _selectedPeriodicite,
                'Date d\'effet',
                _dateEffetContrat != null
                    ? '${_dateEffetContrat!.day}/${_dateEffetContrat!.month}/${_dateEffetContrat!.year}'
                    : 'Non définie'),
            // Durée du contrat
            SubscriptionRecapWidgets.buildRecapRow(
                'Durée du contrat',
                _dureeController.text.isNotEmpty
                    ? '${_dureeController.text} ${_selectedDureeType}'
                    : 'Non définie'),
            // 🟦 MONTANT DE LA COTISATION (affichage simple)
            SubscriptionRecapWidgets.buildRecapRow(
                'Montant de la cotisation ${_selectedPeriodicite.toLowerCase()}',
                _formatMontant(montant)),
          ],
        ),

        const SizedBox(height: 20),

        // SECTION BÉNÉFICIAIRE ET CONTACT D'URGENCE
        SubscriptionRecapWidgets.buildRecapSection(
          'Bénéficiaire et Contact d\'urgence',
          Icons.contacts,
          Colors.amber,
          [
            // 🔹 Bénéficiaire
            SubscriptionRecapWidgets.buildSubsectionTitle(
                'Bénéficiaire en cas de décès'),
            const SizedBox(height: 8),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Nom complet',
              _beneficiaireNomController.text.isNotEmpty
                  ? _beneficiaireNomController.text
                  : 'Non renseigné',
              'Lien de parenté',
              _selectedLienParente.isNotEmpty
                  ? _selectedLienParente
                  : 'Non renseigné',
            ),
            SubscriptionRecapWidgets.buildRecapRow(
              'Date de naissance',
              _beneficiaireDateNaissance != null
                  ? '${_beneficiaireDateNaissance!.day.toString().padLeft(2, '0')}/'
                      '${_beneficiaireDateNaissance!.month.toString().padLeft(2, '0')}/'
                      '${_beneficiaireDateNaissance!.year}'
                  : 'Non renseigné',
            ),
            SubscriptionRecapWidgets.buildRecapRow(
              'Téléphone',
              _beneficiaireContactController.text.isNotEmpty
                  ? '$_selectedBeneficiaireIndicatif ${_beneficiaireContactController.text}'
                  : 'Non renseigné',
            ),

            const SizedBox(height: 16),

            // 🔹 Contact d'urgence
            SubscriptionRecapWidgets.buildSubsectionTitle('Contact d\'urgence'),
            const SizedBox(height: 8),
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Nom complet',
              _personneContactNomController.text.isNotEmpty
                  ? _personneContactNomController.text
                  : 'Non renseigné',
              'Lien de parenté',
              _selectedLienParenteUrgence.isNotEmpty
                  ? _selectedLienParenteUrgence
                  : 'Non renseigné',
            ),
            SubscriptionRecapWidgets.buildRecapRow(
              'Téléphone',
              _personneContactTelController.text.isNotEmpty
                  ? _personneContactTelController.text
                  : 'Non renseigné',
            ),
          ],
        ),
        if (_isAideParCommercial ||
            _commercialNomPrenomController.text.trim().isNotEmpty ||
            _commercialCodeApporteurController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          SubscriptionRecapWidgets.buildAssistanceCommercialeSection(
            nomPrenom: _commercialNomPrenomController.text,
            codeApporteur: _commercialCodeApporteurController.text,
          ),
        ],
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
                  'Numéro RIB',
                  _ribUnifiedController.text.isNotEmpty
                      ? _ribUnifiedController.text
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

        // SECTION DOCUMENTS
        SubscriptionRecapWidgets.buildDocumentsSection(
          pieceIdentite: _pieceIdentite?.path.split('/').last,
          onDocumentTap: _pieceIdentite != null
              ? () => _viewLocalDocument(
                  _pieceIdentite!, _pieceIdentite!.path.split('/').last)
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

  /// Page étape 4: Paiement
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
                          'Cotisation ${_selectedPeriodicite.toLowerCase()} à payer',
                          style: TextStyle(
                            color: grisTexte,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatMontant(double.tryParse(
                                  _montantCotisationController.text
                                      .replaceAll(' ', '')) ??
                              0),
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
}

// =================================================================
// CLASSES AUXILIAIRES (identiques aux autres pages)
// =================================================================

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
                  ? 'Félicitations! Votre contrat MON BON PLAN CORIS est maintenant actif. Vous recevrez un message de confirmation sous peu.'
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
