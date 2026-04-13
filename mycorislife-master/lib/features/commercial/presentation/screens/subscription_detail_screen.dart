import 'dart:convert';
import 'package:mycorislife/core/utils/responsive.dart';

import 'package:flutter/material.dart';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/services/wave_service.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/core/utils/amount_parser.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subscription;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscription,
  });

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  final SubscriptionService _service = SubscriptionService();
  Map<String, dynamic>? _fullSubscriptionData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  static const bleuCoris = Color(0xFF002B6B);
  static const vertSucces = Color(0xFF10B981);
  static const orangeWarning = Color(0xFFF59E0B);
  static const blanc = Colors.white;
  static const grisTexte = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadFullSubscriptionData();
  }

  Future<void> _loadFullSubscriptionData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final data =
          await _service.getSubscriptionDetail(widget.subscription['id']);

      if (mounted) {
        setState(() {
          /**
           * CORRECTION DE L'ERREUR DE TYPE:
           * - Le backend peut retourner Map<dynamic, dynamic> au lieu de Map<String, dynamic>
           * - On utilise Map<String, dynamic>.from() pour convertir explicitement
           * - Cela Ã©vite l'erreur "type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?'"
           */
          _fullSubscriptionData = data['subscription'] != null
              ? Map<String, dynamic>.from(data['subscription'] as Map)
              : null;
          _userData = data['user'] != null
              ? Map<String, dynamic>.from(data['user'] as Map)
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Non renseignÃ©';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatMontant(dynamic value) {
    if (value == null) return '0 FCFA';
    final num = AmountParser.parse(value);
    return "${num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }

  /// ============================================
  /// MÃ‰THODE _formatProductName
  /// ============================================
  /// 
  /// Formate le nom du produit pour un affichage plus lisible.
  /// 
  /// TRANSFORMATION:
  /// - coris_retraite -> Coris Retraite
  /// - coris_solidaritÃ© -> Coris SolidaritÃ©
  /// - coris_etude -> Coris Etude
  /// 
  /// LOGIQUE:
  /// 1. Divise le nom par le caractÃ¨re '_' (underscore)
  /// 2. Pour chaque mot:
  ///    - PremiÃ¨re lettre en majuscule
  ///    - Reste en minuscules
  /// 3. Joint les mots avec un espace
  /// 
  /// EXEMPLE:
  /// Input: "coris_retraite"
  /// Output: "Coris Retraite"
  String _formatProductName(String productName) {
    if (productName.isEmpty || productName == 'Non renseignÃ©') {
      return productName;
    }
    // Diviser le nom par '_' et formater chaque mot
    return productName
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' '); // Joindre les mots avec un espace
  }

  double _extractPaymentAmount() {
    final souscriptionData =
        _fullSubscriptionData?['souscriptiondata'] as Map<String, dynamic>? ??
            {};

    final value = souscriptionData['prime_totale'] ??
        souscriptionData['montant_total'] ??
        souscriptionData['prime'] ??
        souscriptionData['montant'] ??
        souscriptionData['versement_initial'] ??
        souscriptionData['montant_cotisation'] ??
        souscriptionData['prime_mensuelle'] ??
        souscriptionData['capital'] ??
        0;

    return AmountParser.parse(value);
  }

  Future<void> _startWavePayment() async {
    if (_isProcessingPayment) return;

    final amount = _extractPaymentAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Montant de paiement introuvable pour cette souscription.'),
          backgroundColor: orangeWarning,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    final waveService = WaveService();
    final subscriptionId = widget.subscription['id'] as int;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Initialisation du paiement Wave...'),
        backgroundColor: bleuCoris,
      ),
    );

    final createResult = await waveService.createCheckoutSession(
      subscriptionId: subscriptionId,
      amount: amount,
      description: 'Paiement souscription #$subscriptionId',
    );

    if (!(createResult['success'] == true)) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(createResult['message']?.toString() ?? 'Impossible de dÃ©marrer le paiement Wave.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = createResult['data'] as Map<String, dynamic>? ?? {};
    final launchUrlValue = data['launchUrl']?.toString();
    final sessionId = data['sessionId']?.toString() ?? '';
    final transactionId = data['transactionId']?.toString();

    if (launchUrlValue == null || launchUrlValue.isEmpty || sessionId.isEmpty) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RÃ©ponse Wave incomplÃ¨te (URL/session). DÃ©tail: ${createResult['message'] ?? 'n/a'}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(launchUrlValue);
    if (uri == null) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL Wave invalide.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool launched = false;
    if (await canLaunchUrl(uri)) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
    if (!launched) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir Wave. URL: $launchUrlValue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement Wave lancÃ©. VÃ©rification du statut en cours...'),
          backgroundColor: bleuCoris,
        ),
      );
    }

    bool handled = false;
    for (int attempt = 0; attempt < 8; attempt++) {
      await Future.delayed(const Duration(seconds: 3));

      final statusResult = await waveService.getCheckoutStatus(
        sessionId: sessionId,
        subscriptionId: subscriptionId,
        transactionId: transactionId,
      );

      if (!(statusResult['success'] == true)) {
        continue;
      }

      final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
      final status = (statusData['status'] ?? '').toString().toUpperCase();

      if (status == 'SUCCESS') {
        handled = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('âœ… Paiement Wave confirmÃ© ! La proposition est devenue un contrat.'),
              backgroundColor: vertSucces,
            ),
          );
          await _loadFullSubscriptionData();
        }
        break;
      }

      if (status == 'FAILED') {
        handled = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('âŒ Paiement Wave Ã©chouÃ© ou annulÃ©.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      }
    }

    if (!handled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement initiÃ©. Confirmation en attente, vÃ©rifiez Ã  nouveau dans quelques instants.'),
          backgroundColor: orangeWarning,
        ),
      );
    }

    if (mounted) {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _processPayment(String paymentMethod) async {
    if (_isProcessingPayment) return;

    // Si c'est CORIS Money, afficher le modal de paiement
    if (paymentMethod == 'CORIS Money') {
      // Extraire le montant depuis souscriptiondata
      final souscriptionData = _fullSubscriptionData?['souscriptiondata'] as Map<String, dynamic>? ?? {};
      double montant = 0.0;

      // Essayer de rÃ©cupÃ©rer le montant selon le produit
      montant = (souscriptionData['prime_totale'] ?? 
                 souscriptionData['montant_total'] ?? 
                 souscriptionData['prime'] ??
                 souscriptionData['montant'] ??
                 souscriptionData['versement_initial'] ??
                 souscriptionData['montant_cotisation'] ??
                 souscriptionData['prime_mensuelle'] ??
                 souscriptionData['capital'] ?? 0.0).toDouble();

      final subscriptionId = widget.subscription['id'];
      final productType = widget.subscription['product_type'] ?? widget.subscription['produit_type'] ?? 'Souscription';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CorisMoneyPaymentModal(
          subscriptionId: subscriptionId,
          montant: montant,
          description: 'Paiement $productType #$subscriptionId',
          onPaymentSuccess: () {
            // RafraÃ®chir les donnÃ©es aprÃ¨s paiement rÃ©ussi
            _loadFullSubscriptionData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('âœ… Paiement effectuÃ© ! La proposition est devenue un contrat.'),
                backgroundColor: vertSucces,
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
      );
      return;
    }

    if (paymentMethod == 'Wave') {
      await _startWavePayment();
      return;
    }

    // Placeholder pour les mÃ©thodes non encore branchÃ©es
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction, color: blanc, size: 20),
            SizedBox(width: context.r(12)),
            Expanded(
              child: Text('$paymentMethod sera disponible bientÃ´t. Utilisez Wave ou CORIS Money.'),
            ),
          ],
        ),
        backgroundColor: orangeWarning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _viewDocument(String documentName, [String? displayLabel]) {
    if (documentName.isEmpty || documentName == 'Non tÃ©lÃ©chargÃ©e') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun document disponible'),
          backgroundColor: orangeWarning,
        ),
      );
      return;
    }

    final normalizedDocumentName = Uri.decodeFull(documentName)
        .replaceAll('\\\\', '/')
        .split('/')
        .last
        .trim();

    if (normalizedDocumentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom du document invalide'),
          backgroundColor: orangeWarning,
        ),
      );
      return;
    }

    final subscriptionId = widget.subscription['id'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          documentName: normalizedDocumentName,
          subscriptionId: subscriptionId,
          displayLabel: displayLabel,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _extractDocumentsList(dynamic rawDocs) {
    if (rawDocs == null) return [];
    final List<Map<String, dynamic>> docs = [];

    try {
      if (rawDocs is String) {
        final trimmed = rawDocs.trim();
        if (trimmed.isEmpty) return [];

        // Try JSON decode all types de formats
        final decoded = jsonDecode(trimmed);
        return _extractDocumentsList(decoded);
      }

      if (rawDocs is List) {
        for (final item in rawDocs) {
          if (item is Map<String, dynamic>) {
            docs.add(item);
          } else if (item is Map) {
            docs.add(Map<String, dynamic>.from(item));
          } else if (item is String) {
            docs.add({'path': item, 'label': item});
          }
        }
        return docs;
      }

      if (rawDocs is Map) {
        rawDocs.forEach((key, value) {
          if (value is String || value is num || value is bool) {
            docs.add({'path': value, 'label': key});
          } else if (value is Map || value is List) {
            docs.addAll(_extractDocumentsList(value));
          }
        });
        return docs;
      }
    } catch (_) {
      // ignore decode error - fallback empty
    }

    return [];
  }

  void _modifyProposition() {
    final subscriptionId = widget.subscription['id'];
    final productType =
        (widget.subscription['produit_nom'] ?? '').toLowerCase();
    final souscriptionData = _fullSubscriptionData?['souscriptiondata'];

    // Extraire les infos client depuis souscriptionData
    final clientInfo = souscriptionData?['client_info'];
    final String? clientId = clientInfo?['id']?.toString();
    final Map<String, dynamic>? clientData =
        clientInfo != null ? Map<String, dynamic>.from(clientInfo) : null;

    // DÃ©terminer le type de produit pour la route
    String routeProductType = '';
    if (productType.contains('etude')) {
      routeProductType = 'etude';
    } else if (productType.contains('serenite') ||
        productType.contains('sÃ©rÃ©nitÃ©')) {
      routeProductType = 'serenite';
    } else if (productType.contains('retraite')) {
      routeProductType = 'retraite';
    } else if (productType.contains('solidarite') ||
        productType.contains('solidaritÃ©')) {
      routeProductType = 'solidarite';
    } else if (productType.contains('familis')) {
      routeProductType = 'familis';
    }
    // âŒ PRODUIT DÃ‰SACTIVÃ‰ - FLEX EMPRUNTEUR
    // else if (productType.contains('flex') ||
    //     productType.contains('emprunteur')) {
    //   routeProductType = 'flex';
    // }
    else if (productType.contains('epargne') ||
        productType.contains('Ã©pargne')) {
      routeProductType = 'epargne';
    } else if (productType.contains('assure') ||
        productType.contains('prestige')) {
      routeProductType = 'assure_prestige';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La modification de ce type de produit n\'est pas encore disponible'),
          backgroundColor: orangeWarning,
        ),
      );
      return;
    }

    // En mode modification, naviguer DIRECTEMENT vers la page de souscription
    // avec les donnÃ©es prÃ©-remplies (pas de sÃ©lection de client)
    Navigator.pushNamed(
      context,
      '/souscription_$routeProductType',
      arguments: {
        'isCommercial': true,
        'client_id': clientId,
        'client': clientData,
        'clientInfo': clientData,
        'simulationData': souscriptionData,
        'existingData': souscriptionData,
        'subscriptionId': subscriptionId,
      },
    ).then((_) {
      // Recharger les donnÃ©es aprÃ¨s modification
      _loadFullSubscriptionData();
    });
  }

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(
        onPayNow: _processPayment,
        onPayLater: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous pourrez effectuer le paiement plus tard.'),
              backgroundColor: orangeWarning,
            ),
          );
        },
      ),
    );
  }

  /// ============================================
  /// WIDGET _buildRecapSection
  /// ============================================
  /// 
  /// CrÃ©e une section de rÃ©capitulatif avec un titre, une icÃ´ne et un contenu.
  /// 
  /// MODIFICATIONS APPORTÃ‰ES:
  /// - Avant: Utilisation de Color.fromRGBO(r, g, b, 25) qui rendait les icÃ´nes invisibles
  /// - Maintenant: Utilisation de color.withValues(alpha: 0.1) pour une meilleure visibilitÃ©
  /// - Augmentation de la taille des icÃ´nes de 18 Ã  20 pixels
  /// - Augmentation du padding du conteneur d'icÃ´ne de 6 Ã  8 pixels
  /// 
  /// PARAMÃˆTRES:
  /// - title: Titre de la section (ex: "Informations Personnelles")
  /// - icon: IcÃ´ne Ã  afficher (ex: Icons.person)
  /// - color: Couleur de l'icÃ´ne et du titre (ex: bleuCoris, vertSucces)
  /// - children: Liste des widgets Ã  afficher dans la section (lignes de rÃ©capitulatif)
  /// 
  /// UTILISATION:
  /// Cette mÃ©thode est utilisÃ©e pour crÃ©er les sections du rÃ©capitulatif:
  /// - Informations Personnelles (icÃ´ne person, couleur bleue)
  /// - Produit Souscrit (icÃ´ne description, couleur verte)
  /// - BÃ©nÃ©ficiaire et Contact d'urgence (icÃ´ne contacts, couleur orange)
  /// - Documents (icÃ´ne description, couleur bleue secondaire)
  Widget _buildRecapSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Conteneur pour l'icÃ´ne avec fond colorÃ©
              // CORRECTION: Utilisation de withValues(alpha: 0.1) au lieu de Color.fromRGBO pour meilleure visibilitÃ©
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(
                      alpha: 0.1), // Fond colorÃ© avec transparence
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: color,
                    size: 20), // IcÃ´ne visible avec la couleur spÃ©cifiÃ©e
              ),
              SizedBox(width: context.r(10)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: context.r(12)),
          ...children, // Afficher tous les enfants (lignes de rÃ©capitulatif)
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                fontSize: context.sp(12),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isHighlighted ? vertSucces : bleuCoris,
                fontSize: isHighlighted ? 13 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section du questionnaire mÃ©dical (alignÃ© avec l'expÃ©rience client)
  Widget _buildQuestionnaireMedicalSection(Map<String, dynamic> souscriptionData) {
    final List<Map<String, dynamic>> reponses = _getQuestionnaireMedicalReponses(souscriptionData);
    if (reponses.isEmpty) return const SizedBox.shrink();

    final List<Map<String, dynamic>> questions = _getQuestionnaireMedicalQuestions();
    final subscriptionId = widget.subscription['id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: SubscriptionRecapWidgets.buildQuestionnaireMedicalSection(
            reponses,
            questions,
          ),
        ),
        SizedBox(height: context.r(8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final token = await AuthService.getToken();
                if (token == null) return;
                final baseUrl = AppConfig.baseUrl.replaceAll('/api', '');
                final url = Uri.parse(
                  '$baseUrl/api/subscriptions/$subscriptionId/questionnaire-medical/print?token=${Uri.encodeComponent(token)}',
                );
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Impossible d\'ouvrir le formulaire: $e')),
                );
              }
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('TÃ©lÃ©charger le formulaire mÃ©dical'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF002B6B),
              side: const BorderSide(color: Color(0xFF002B6B)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getQuestionnaireMedicalReponses(Map<String, dynamic> souscriptionData) {
    final reponses = _fullSubscriptionData?['questionnaire_reponses'];

    // 1) RÃ©ponses dÃ©jÃ  au niveau racine (format liste ou map)
    if (reponses != null) {
      if (reponses is List) {
        return List<Map<String, dynamic>>.from(
          reponses.map((r) => r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{}),
        );
      }
      if (reponses is Map) {
        return reponses.values
            .where((v) => v != null)
            .map((v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{})
            .toList();
      }
    }

    // 2) Fallback: dans les donnÃ©es de souscription (questionnaire_medical_reponses / questionnaire_reponses)
    final fallback = souscriptionData['questionnaire_medical_reponses'] ??
        souscriptionData['questionnaire_reponses'];
    if (fallback is List) {
      return List<Map<String, dynamic>>.from(
        fallback.map((r) => r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{}),
      );
    }
    if (fallback is Map) {
      return fallback.values
          .where((v) => v != null)
          .map((v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{})
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _getQuestionnaireMedicalQuestions() {
    final rawQuestions = _fullSubscriptionData?['questionnaire_questions'] ??
        _fullSubscriptionData?['questions'];
    if (rawQuestions is List) {
      return List<Map<String, dynamic>>.from(
        rawQuestions.map((q) => q is Map ? Map<String, dynamic>.from(q) : <String, dynamic>{}),
      );
    }
    return [];
  }

  /// ============================================
  /// WIDGET _buildProductSection
  /// ============================================
  /// 
  /// Construit la section produit avec les dÃ©tails spÃ©cifiques selon le type
  Widget _buildProductSection(Map<String, dynamic> subscription,
      Map<String, dynamic> souscriptionData, bool isPaid) {
    final productType =
        (subscription['product_type'] ?? subscription['produit_type'] ?? '')
            .toString()
            .toLowerCase();

    // Pour CORIS ASSURE PRESTIGE
    if (productType.contains('assure') || productType.contains('prestige')) {
      final versementInitial = souscriptionData['versement_initial'] ??
          souscriptionData['montant_versement'] ??
          0;
      final capitalDeces = souscriptionData['capital_deces'] ?? 0;
      final primeDecesAnnuelle = souscriptionData['prime_deces_annuelle'] ?? 0;
      final duree = souscriptionData['duree'] ??
          souscriptionData['duree_contrat'] ??
          'Non dÃ©finie';
      final uniteDuree = souscriptionData['duree_type'] ??
          souscriptionData['unite_duree'] ??
          'ans';
      final dateEffet = souscriptionData['date_effet'];
      final dateEcheance = souscriptionData['date_echeance'];

      return _buildRecapSection(
        'DÃ©tails du Contrat - CORIS ASSURE PRESTIGE',
        Icons.verified_user,
        vertSucces,
        [
          _buildCombinedRecapRow(
            'Produit',
            'CORIS ASSURE PRESTIGE',
            'NÂ° Police',
            subscription['numero_police'] ?? 'N/A',
          ),
          _buildCombinedRecapRow(
            'Montant du versement initial',
            _formatMontant(versementInitial),
            'DurÃ©e du contrat',
            '$duree $uniteDuree',
          ),
          _buildCombinedRecapRow(
            'Capital dÃ©cÃ¨s',
            _formatMontant(capitalDeces),
            'Prime dÃ©cÃ¨s annuelle',
            _formatMontant(primeDecesAnnuelle),
          ),
          _buildCombinedRecapRow(
            'PÃ©riodicitÃ©',
            souscriptionData['periodicite'] ?? 'Annuel',
            '',
            '',
          ),
          _buildCombinedRecapRow(
            'Date d\'effet',
            _formatDate(dateEffet?.toString()),
            'Date d\'Ã©chÃ©ance',
            _formatDate(dateEcheance?.toString()),
          ),
          _buildCombinedRecapRow(
            'Date de crÃ©ation',
            _formatDate(subscription['date_creation']?.toString()),
            'Statut',
            isPaid ? 'Contrat' : 'Proposition',
          ),
        ],
      );
    }

    // Pour CORIS SOLIDARITÃ‰
    if (productType.contains('solidarite')) {
      final capital = souscriptionData['capital'] ?? 0;
      final periodicite = souscriptionData['periodicite'] ?? 'mensuel';
      final primeTotale = souscriptionData['prime_totale'] ?? souscriptionData['prime'] ?? 0;
      final dateEffet = souscriptionData['date_effet'];
      
      // RÃ©cupÃ©rer le nombre de membres
      final conjoints = souscriptionData['conjoints'] as List? ?? [];
      final enfants = souscriptionData['enfants'] as List? ?? [];
      final ascendants = souscriptionData['ascendants'] as List? ?? [];

      return _buildRecapSection(
        'Produit Souscrit - CORIS SOLIDARITÃ‰',
        Icons.emoji_people_outlined,
        vertSucces,
        [
          _buildCombinedRecapRow(
            'Produit',
            'CORIS SOLIDARITÃ‰',
            'NÂ° Police',
            subscription['numero_police'] ?? 'N/A',
          ),
          _buildCombinedRecapRow(
            'Capital garanti',
            _formatMontant(capital),
            'PÃ©riodicitÃ©',
            periodicite.toUpperCase(),
          ),
          _buildCombinedRecapRow(
            'Prime totale',
            _formatMontant(primeTotale),
            'Date d\'effet',
            _formatDate(dateEffet?.toString()),
          ),
          _buildCombinedRecapRow(
            'Nombre de conjoints',
            conjoints.length.toString(),
            'Nombre d\'enfants',
            enfants.length.toString(),
          ),
          _buildRecapRow(
            'Nombre d\'ascendants',
            ascendants.length.toString(),
          ),
          _buildCombinedRecapRow(
            'Date de crÃ©ation',
            _formatDate(subscription['date_creation']?.toString()),
            'Statut',
            isPaid ? 'Contrat' : 'Proposition',
          ),
        ],
      );
    }

    // Section gÃ©nÃ©rique pour les autres produits
    return _buildRecapSection(
      'Produit Souscrit',
      Icons.description,
      vertSucces,
      [
        _buildCombinedRecapRow(
          'Produit',
          _formatProductName(subscription['produit_nom'] ?? 'Non renseignÃ©'),
          'NÂ° Police',
          subscription['numero_police'] ?? 'N/A',
        ),
        if (souscriptionData['capital'] != null)
          _buildCombinedRecapRow(
            'Capital',
            _formatMontant(souscriptionData['capital']),
            'Prime',
            _formatMontant(souscriptionData['prime']),
          ),
        if (souscriptionData['duree'] != null)
          _buildCombinedRecapRow(
            'DurÃ©e',
            '${souscriptionData['duree']} ${souscriptionData['duree_type'] ?? ''}',
            'PÃ©riodicitÃ©',
            souscriptionData['periodicite'] ?? 'Non renseignÃ©',
          ),
        _buildCombinedRecapRow(
          'Date de crÃ©ation',
          _formatDate(subscription['date_creation']?.toString()),
          'Statut',
          isPaid ? 'Contrat' : 'Proposition',
        ),
      ],
    );
  }

  Widget _buildCombinedRecapRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                    fontSize: context.sp(12),
                  ),
                ),
                Text(
                  value1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: context.sp(12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.r(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label2.isNotEmpty)
                  Text(
                    '$label2 :',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: grisTexte,
                      fontSize: context.sp(12),
                    ),
                  ),
                if (value2.isNotEmpty)
                  Text(
                    value2,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: bleuCoris,
                      fontSize: context.sp(12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapContent() {
    final subscription = _fullSubscriptionData ?? widget.subscription;
    final user = _userData ?? {};

    /**
     * EXTRACTION DES DONNÃ‰ES DE SOUSCRIPTION
     * - souscriptionData : DonnÃ©es JSONB de la souscription (capital, prime, bÃ©nÃ©ficiaire, etc.)
     * - clientInfo : Informations du client stockÃ©es dans souscriptiondata.client_info (pour souscriptions crÃ©Ã©es par commercial)
     */
    final souscriptionData = subscription['souscriptiondata'] != null
        ? Map<String, dynamic>.from(subscription['souscriptiondata'] as Map)
        : <String, dynamic>{};

    // Extraire client_info en s'assurant du bon type
    Map<String, dynamic> clientInfo = {};
    if (souscriptionData['client_info'] != null) {
      try {
        clientInfo =
            Map<String, dynamic>.from(souscriptionData['client_info'] as Map);
      } catch (e) {
        print('Erreur extraction client_info: $e');
      }
    }

    final isPaid = subscription['statut'] == 'contrat';

    /**
     * PRIORISATION DES INFORMATIONS CLIENT:
     * - Si clientInfo existe et n'est pas vide : Utiliser les infos depuis client_info (souscription crÃ©Ã©e par commercial)
     * - Sinon : Utiliser les infos depuis user (souscription crÃ©Ã©e directement par le client)
     * 
     * IMPORTANT: Pour les souscriptions crÃ©Ã©es par un commercial, on DOIT toujours afficher
     * les informations du client (depuis client_info) et non celles du commercial.
     */
    final displayUser = (clientInfo.isNotEmpty &&
            clientInfo.containsKey('nom') &&
            clientInfo['nom'] != null &&
            clientInfo['nom'].toString().isNotEmpty)
        ? clientInfo
        : user;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Informations Personnelles
        _buildRecapSection(
          'Informations Personnelles',
          Icons.person,
          bleuCoris,
          [
            _buildCombinedRecapRow(
              'CivilitÃ©',
              displayUser['civilite'] ?? 'Non renseignÃ©',
              'Nom',
              displayUser['nom'] ?? 'Non renseignÃ©',
            ),
            _buildCombinedRecapRow(
              'PrÃ©nom',
              displayUser['prenom'] ?? 'Non renseignÃ©',
              'Email',
              displayUser['email'] ?? 'Non renseignÃ©',
            ),
            _buildCombinedRecapRow(
              'TÃ©lÃ©phone',
              displayUser['telephone'] ?? 'Non renseignÃ©',
              'Date de naissance',
              _formatDate(displayUser['date_naissance']?.toString()),
            ),
            _buildCombinedRecapRow(
              'Lieu de naissance',
              displayUser['lieu_naissance'] ?? 'Non renseignÃ©',
              'Adresse',
              displayUser['adresse'] ?? 'Non renseignÃ©',
            ),
          ],
        ),

        // Produit souscrit - Section adaptÃ©e selon le type de produit
        _buildProductSection(subscription, souscriptionData, isPaid),

        // BÃ©nÃ©ficiaire et Contact d'urgence (si disponibles)
        if (souscriptionData['beneficiaire'] != null ||
            souscriptionData['contact_urgence'] != null)
          _buildRecapSection(
            'BÃ©nÃ©ficiaire et Contact d\'urgence',
            Icons.contacts,
            orangeWarning,
            [
              if (souscriptionData['beneficiaire'] != null) ...[
                Text(
                  'BÃ©nÃ©ficiaire',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: context.sp(14),
                  ),
                ),
                SizedBox(height: context.r(8)),
                _buildRecapRow(
                  'Nom complet',
                  souscriptionData['beneficiaire']['nom'] ?? 'Non renseignÃ©',
                ),
                _buildRecapRow(
                  'Contact',
                  souscriptionData['beneficiaire']['contact'] ??
                      'Non renseignÃ©',
                ),
                _buildRecapRow(
                  'Lien de parentÃ©',
                  souscriptionData['beneficiaire']['lien_parente'] ??
                      'Non renseignÃ©',
                ),
                if (souscriptionData['beneficiaire'] != null &&
                    (souscriptionData['beneficiaire']['date_naissance'] != null ||
                     souscriptionData['beneficiaire']['dateNaissance'] != null ||
                     souscriptionData['beneficiaire']['date_de_naissance'] != null))
                  _buildRecapRow(
                    'Date de naissance',
                    _formatDate(souscriptionData['beneficiaire']['date_naissance'] ??
                        souscriptionData['beneficiaire']['dateNaissance'] ??
                        souscriptionData['beneficiaire']['date_de_naissance']),
                  ),
                SizedBox(height: context.r(12)),
              ],
              if (souscriptionData['contact_urgence'] != null) ...[
                Text(
                  'Contact d\'urgence',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bleuCoris,
                    fontSize: context.sp(14),
                  ),
                ),
                SizedBox(height: context.r(8)),
                _buildRecapRow(
                  'Nom complet',
                  souscriptionData['contact_urgence']['nom'] ?? 'Non renseignÃ©',
                ),
                _buildRecapRow(
                  'Contact',
                  souscriptionData['contact_urgence']['contact'] ??
                      'Non renseignÃ©',
                ),
                _buildRecapRow(
                  'Lien de parentÃ©',
                  souscriptionData['contact_urgence']['lien_parente'] ??
                      'Non renseignÃ©',
                ),
              ],
            ],
          ),

        () {
          final assistanceCommerciale =
              souscriptionData['assistance_commerciale'];

          if (assistanceCommerciale is! Map) {
            return const SizedBox.shrink();
          }

          final isAideParCommercial =
              assistanceCommerciale['is_aide_par_commercial'] == true;
          final nomPrenom =
              assistanceCommerciale['commercial_nom_prenom']?.toString();
          final codeApporteur =
              assistanceCommerciale['commercial_code_apporteur']?.toString();

          if (!isAideParCommercial &&
              (nomPrenom == null || nomPrenom.trim().isEmpty) &&
              (codeApporteur == null || codeApporteur.trim().isEmpty)) {
            return const SizedBox.shrink();
          }

          return SubscriptionRecapWidgets.buildAssistanceCommercialeSection(
            nomPrenom: nomPrenom,
            codeApporteur: codeApporteur,
          );
        }(),

        // ðŸ’³ Mode de Paiement - Version amÃ©liorÃ©e avec icÃ´nes
        if (souscriptionData['mode_paiement'] != null &&
            souscriptionData['mode_paiement'].toString().isNotEmpty)
          SubscriptionRecapWidgets.buildPaymentModeSection(souscriptionData),

        // RÃ‰CAP: Questionnaire mÃ©dical (questions + rÃ©ponses)
        // N'afficher que pour Ã‰TUDE, FAMILIS et SÃ‰RÃ‰NITÃ‰
        () {
          final prod = (souscriptionData['produit_nom'] ?? souscriptionData['product_type'] ?? widget.subscription['product_type'] ?? widget.subscription['produit_nom'] ?? '').toString().toLowerCase();
          if (prod.contains('etude') || prod.contains('familis') || prod.contains('serenite') || prod.contains('sÃ©rÃ©nitÃ©')) {
            return _buildQuestionnaireMedicalSection(souscriptionData);
          }
          return const SizedBox.shrink();
        }(),

        // Documents
        () {
          String? pieceIdentite =
              (souscriptionData['piece_identite'] ??
                      _fullSubscriptionData?['piece_identite'])
                  ?.toString()
                  .trim();
          String? pieceIdentiteLabel =
              (souscriptionData['piece_identite_label'] ??
                      _fullSubscriptionData?['piece_identite_label'])
                  ?.toString()
                  .trim();

          List<Map<String, dynamic>> docsList = [];

          void addFrom(dynamic raw) {
            final extracted = _extractDocumentsList(raw);
            for (final item in extracted) {
              final path = item['path']?.toString().trim() ??
                  item['url']?.toString().trim() ??
                  item['filename']?.toString().trim();
              if (path == null || path.isEmpty || path.toLowerCase() == 'null') {
                continue;
              }
              if (docsList.any((d) {
                final existing = d['path']?.toString().trim() ??
                    d['url']?.toString().trim() ??
                    d['filename']?.toString().trim();
                return existing != null && existing == path;
              })) {
                continue;
              }
              docsList.add(item);
            }
          }

          // Collecte tous les documents depuis les diffÃ©rentes sources
          addFrom(souscriptionData['documents']);
          addFrom(_fullSubscriptionData?['documents']);
          addFrom(souscriptionData['souscription_documents']);
          addFrom(_fullSubscriptionData?['souscription_documents']);

          // Ajoute les documents de piÃ¨ce d'identitÃ© seulement s'ils ne sont pas dÃ©jÃ  inclus
          addFrom(souscriptionData['piece_identite_documents']);
          addFrom(_fullSubscriptionData?['piece_identite_documents']);

          // VÃ©rifie si pieceIdentite est dÃ©jÃ  dans la liste avant de l'ajouter
          bool pieceIdentiteAlreadyIncluded = false;
          if (pieceIdentite != null && pieceIdentite.isNotEmpty) {
            pieceIdentiteAlreadyIncluded = docsList.any((d) {
              final path = d['path']?.toString().trim() ??
                  d['url']?.toString().trim() ??
                  d['filename']?.toString().trim();
              return path == pieceIdentite;
            });
          }

          // Ajoute pieceIdentite seulement si elle n'est pas dÃ©jÃ  incluse
          if (pieceIdentite != null && pieceIdentite.isNotEmpty && !pieceIdentiteAlreadyIncluded) {
            docsList.insert(0, {
              'path': pieceIdentite,
              'label': pieceIdentiteLabel ?? 'PiÃ¨ce d\'identitÃ©',
            });
          }

          final totalDocuments = docsList.length;

          return SubscriptionRecapWidgets.buildDocumentsSection(
            pieceIdentite: null,
            documents: docsList.isNotEmpty ? docsList : null,
            documentCount: totalDocuments,
            onDocumentTap: pieceIdentite != null &&
                    pieceIdentite.isNotEmpty &&
                    pieceIdentite != 'Non tÃ©lÃ©chargÃ©e'
              ? () => _viewDocument(pieceIdentite, pieceIdentiteLabel)
                : null,
            onDocumentTapWithInfo: (path, label) => _viewDocument(path, label),
          );
        }(),

        // Message de vÃ©rification
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(245, 158, 11, 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(245, 158, 11, 0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: orangeWarning, size: 28),
              SizedBox(height: context.r(10)),
              Text(
                'VÃ©rification Importante',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: orangeWarning,
                  fontSize: context.sp(14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.r(8)),
              Text(
                'VÃ©rifiez attentivement toutes les informations ci-dessus. Une fois la souscription validÃ©e, certaines modifications ne seront plus possibles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: grisTexte,
                  fontSize: context.sp(12),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.r(20)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _fullSubscriptionData ?? widget.subscription;
    final isPaid = subscription['statut'] == 'contrat';
    final isProposition = subscription['statut'] == 'proposition';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: bleuCoris,
        elevation: 0,
        title: const Text(
          'DÃ©tails de la Proposition',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () {
              // DÃ©terminer le type de produit pour exclure ou non le questionnaire
              final productName = subscription['nom_produit']?.toString().toLowerCase() ?? '';
              final excludeQ = productName.contains('etude') ||
                  productName.contains('familis') ||
                  productName.contains('serenite') ||
                  productName.contains('sÃ©rÃ©nitÃ©');
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerPage(
                    subscriptionId: subscription['id'],
                    excludeQuestionnaire: excludeQ,
                  ),
                ),
              );
            },
            tooltip: 'Voir le PDF du contrat',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _buildRecapContent(),
                ),

                /**
                 * ============================================
                 * BOUTON DE PAIEMENT
                 * ============================================
                 * 
                 * AFFICHAGE CONDITIONNEL:
                 * - Le bouton "Finaliser la souscription" n'apparaÃ®t QUE si:
                 *   1. isProposition = true (statut == 'proposition')
                 *   2. _isProcessingPayment = false (pas de paiement en cours)
                 * 
                 * FONCTIONNEMENT:
                 * - Si la souscription est dÃ©jÃ  un contrat (paiement effectuÃ©) : Affiche un message de confirmation
                 * - Si la souscription est une proposition (non payÃ©e) : Affiche le bouton de paiement
                 * - Si un paiement est en cours : Affiche un indicateur de chargement
                 * 
                 * ACTIONS:
                 * - Clic sur "Payer maintenant" : Ouvre le bottom sheet avec les options de paiement (Wave, Orange Money, CORIS Money)
                 */
                if (isProposition && !_isProcessingPayment)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: blanc,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Bouton Modifier
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _modifyProposition,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: bleuCoris,
                                side: const BorderSide(
                                    color: bleuCoris, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: bleuCoris.withOpacity(0.05),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: context.r(8)),
                                  Text(
                                    'Modifier la proposition',
                                    style: TextStyle(
                                      fontSize: context.sp(15),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: context.r(12)),
                          // Bouton Payer maintenant
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showPaymentOptions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bleuCoris,
                                foregroundColor: blanc,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                shadowColor:
                                    const Color.fromRGBO(0, 43, 107, 0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Payer maintenant',
                                    style: TextStyle(
                                      fontSize: context.sp(16),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: context.r(8)),
                                  Icon(Icons.check, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isProcessingPayment)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: blanc,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (isPaid)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: blanc,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: vertSucces.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: vertSucces),
                          SizedBox(width: context.r(8)),
                          Text(
                            'Contrat activÃ© - Paiement effectuÃ©',
                            style: TextStyle(
                              color: vertSucces,
                              fontWeight: FontWeight.w600,
                              fontSize: context.sp(16),
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
}

/// ============================================
/// WIDGET _PaymentBottomSheet
/// ============================================
/// 
/// Bottom sheet (panneau qui s'ouvre depuis le bas) pour choisir le moyen de paiement.
/// 
/// DESIGN IDENTIQUE Ã€ LA VERSION CLIENT:
/// - MÃªme structure et disposition que le bottom sheet dans proposition_detail_page.dart
/// - MÃªmes couleurs et styles
/// - MÃªmes options de paiement (Wave, Orange Money et CORIS Money uniquement)
/// - MÃªme bouton "Payer plus tard"
/// 
/// OPTIONS DE PAIEMENT:
/// - Wave : Paiement mobile sÃ©curisÃ© (icÃ´ne Icons.waves, couleur bleue)
/// - Orange Money : Paiement mobile Orange (icÃ´ne Icons.phone_android, couleur orange)
/// 
/// FONCTIONNEMENT:
/// 1. L'utilisateur clique sur "Payer maintenant la souscription"
/// 2. Ce bottom sheet s'ouvre avec les options de paiement
/// 3. L'utilisateur choisit un moyen de paiement ou "Payer plus tard"
/// 4. onPayNow est appelÃ© avec le moyen de paiement choisi
/// 5. onPayLater est appelÃ© si l'utilisateur choisit de payer plus tard
/// 
/// BIBLIOTHÃˆQUES UTILISÃ‰ES:
/// - Flutter Material : Pour les widgets UI (Container, Row, Column, etc.)
/// - SafeArea : Pour Ã©viter que le contenu soit masquÃ© par les encoches de l'Ã©cran
class _PaymentBottomSheet extends StatelessWidget {
  final Function(String)
      onPayNow; // Callback appelÃ© quand un moyen de paiement est sÃ©lectionnÃ©
  final VoidCallback
      onPayLater; // Callback appelÃ© quand l'utilisateur choisit "Payer plus tard"
  static const bleuCoris = Color(0xFF002B6B); // Couleur bleue CORIS

  const _PaymentBottomSheet({
    required this.onPayNow,
    required this.onPayLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(158, 158, 158, 77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: context.r(24)),
              Row(
                children: [
                  const Icon(Icons.payment, color: bleuCoris, size: 28),
                  SizedBox(width: context.r(12)),
                  Text(
                    'Options de Paiement',
                    style: TextStyle(
                      fontSize: context.sp(22),
                      fontWeight: FontWeight.w700,
                      color: bleuCoris,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.r(24)),
              _buildPaymentOptionWithImage(
                context,
                'Wave',
                'assets/images/icone_wave.jpeg',
                Colors.blue,
                'Paiement mobile sÃ©curisÃ©',
                () => onPayNow('Wave'),
              ),
              // _buildPaymentOptionWithImage(
              //   context,
              //   'Orange Money',
              //   'assets/images/icone_orange_money.jpeg',
              //   Colors.orange,
              //   'Paiement mobile Orange',
              //   () => onPayNow('Orange Money'),
              // ),
              // _buildPaymentOptionWithImage(
              //   context,
              //   'CORIS Money',
              //   'assets/images/icone_corismoney.jpeg',
              //   const Color(0xFF1E3A8A),
              //   'Paiement via CORIS Money',
              //   () => onPayNow('CORIS Money'),
              // ),
              SizedBox(height: context.r(24)),
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: const Color.fromRGBO(158, 158, 158, 77))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: const Color.fromRGBO(158, 158, 158, 77))),
                ],
              ),
              SizedBox(height: context.r(20)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onPayLater();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: bleuCoris, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: bleuCoris),
                      SizedBox(width: context.r(8)),
                      Text(
                        'Payer plus tard',
                        style: TextStyle(
                          color: bleuCoris,
                          fontWeight: FontWeight.w600,
                          fontSize: context.sp(16),
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

  /// ============================================
  /// WIDGET _buildPaymentOption
  /// ============================================
  /// 
  /// CrÃ©e une option de paiement dans le bottom sheet.
  /// 
  /// MODIFICATIONS POUR CORRESPONDRE AU STYLE CLIENT:
  /// - Avant: Utilisation de couleurs dynamiques Color.fromRGBO qui cachaient les icÃ´nes
  /// - Maintenant: Utilisation de fondCarte (Color(0xFFF8FAFC)) comme dans la version client
  /// - Utilisation de color.withValues(alpha: 0.1) pour les icÃ´nes au lieu de Color.fromRGBO
  /// - Ajout de borderRadius: BorderRadius.circular(16) et border pour correspondre au style client
  /// - Utilisation de Icons.arrow_forward_ios au lieu de Icons.chevron_right
  /// 
  /// PARAMÃˆTRES:
  /// - context: Contexte Flutter pour la navigation
  /// - title: Nom de l'option de paiement (ex: "Wave", "Orange Money")
  /// - icon: IcÃ´ne Ã  afficher (ex: Icons.waves, Icons.phone_android)
  /// - color: Couleur de l'icÃ´ne (ex: Colors.blue pour Wave, Colors.orange pour Orange Money)
  /// - subtitle: Description de l'option (ex: "Paiement mobile sÃ©curisÃ©")
  /// - onTap: Callback appelÃ© quand l'option est sÃ©lectionnÃ©e
  /// 
  /// DESIGN:
  /// - Fond gris clair (fondCarte) pour correspondre au style client
  /// - IcÃ´ne dans un conteneur avec fond colorÃ© transparent
  /// - Titre en gras, sous-titre en gris
  /// - FlÃ¨che Ã  droite pour indiquer que c'est cliquable
  Widget _buildPaymentOptionWithImage(BuildContext context, String title, String imagePath,
      Color color, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Fermer le bottom sheet
        onTap(); // Appeler le callback de paiement
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              const Color(0xFFF8FAFC), // fondCarte - identique au style client
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Conteneur pour l'image avec fond colorÃ© transparent
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Image.asset(
                imagePath,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('âŒ Erreur chargement image: $imagePath - $error');
                  return Icon(Icons.image_not_supported, size: 32, color: Colors.grey);
                },
              ),
            ),
            SizedBox(width: context.r(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: bleuCoris,
                      fontSize: context.sp(16),
                    ),
                  ),
                  SizedBox(height: context.r(4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF64748B), // grisTexte
                      fontSize: context.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            // FlÃ¨che Ã  droite - identique au style client
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFF64748B), size: 16),
          ],
        ),
      ),
    );
  }
}

