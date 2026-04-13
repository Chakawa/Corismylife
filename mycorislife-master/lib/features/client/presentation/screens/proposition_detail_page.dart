import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/services/wave_service.dart';
import 'package:mycorislife/core/widgets/subscription_recap_widgets.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';
import 'package:mycorislife/features/client/presentation/screens/document_viewer_page.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_etude.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_serenite.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_retraite.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_flex.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_epargne.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_familis.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_mon_bon_plan.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_assure_prestige.dart';
import 'package:url_launcher/url_launcher.dart';

/// ============================================
/// PAGE DE DÃ‰TAILS D'UNE PROPOSITION
/// ============================================
/// Cette page affiche les dÃ©tails complets d'une proposition d'assurance.
/// Elle permet Ã  l'utilisateur de visualiser toutes les informations de sa
/// souscription avant de procÃ©der au paiement.
///
/// FonctionnalitÃ©s:
/// - Affichage des informations personnelles
/// - Affichage des dÃ©tails du produit (capital, prime, durÃ©e, etc.)
/// - Affichage des bÃ©nÃ©ficiaires et contacts d'urgence
/// - Affichage des documents joints
/// - PossibilitÃ© de modifier la proposition
/// - PossibilitÃ© de payer directement

// ===================================
// COULEURS PARTAGÃ‰ES
// ===================================
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color bleuSecondaire = Color(0xFF1E4A8C);
const Color blanc = Colors.white;
const Color fondCarte = Color(0xFFF8FAFC);
const Color grisTexte = Color(0xFF64748B);
const Color grisLeger = Color(0xFFF1F5F9);
const Color vertSucces = Color(0xFF10B981);
const Color orangeWarning = Color(0xFFF59E0B);

class PropositionDetailPage extends StatefulWidget {
  final int subscriptionId;
  final String propositionNumber;

  const PropositionDetailPage({
    super.key,
    required this.subscriptionId,
    required this.propositionNumber,
  });

  @override
  PropositionDetailPageState createState() => PropositionDetailPageState();
}

class PropositionDetailPageState extends State<PropositionDetailPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final SubscriptionService _service = SubscriptionService();
  Map<String, dynamic>? _subscriptionData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _autoClosedAfterWaveSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _loadSubscriptionData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadSubscriptionData();
    }
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;

    try {
      final waveService = WaveService();
      final reconcileResult = await waveService.reconcileWavePayments();
      if (mounted && reconcileResult['success'] == true) {
        final data = reconcileResult['data'] as Map<String, dynamic>? ?? {};
        final successCount = (data['successCount'] as num?)?.toInt() ?? 0;
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'âœ… Paiement Wave confirmÃ© ($successCount). Votre contrat a Ã©tÃ© mis Ã  jour.'),
              backgroundColor: vertSucces,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      print('ðŸ“¥ Chargement dÃ©tails proposition ${widget.subscriptionId}...');
      final data = await _service.getSubscriptionDetail(widget.subscriptionId);

      print('\n=== DONNÃ‰ES REÃ‡UES DU SERVEUR ===');
      print(
          'âœ… Subscription reÃ§ue: ${data['subscription'] != null ? 'OUI' : 'NON'}');
      print('âœ… User reÃ§ue: ${data['user'] != null ? 'OUI' : 'NON'}');
      print(
          'âœ… questionnaire_reponses reÃ§ue: ${data['subscription']?['questionnaire_reponses'] != null ? 'OUI' : 'NON'}');

      // DEBUG: afficher toute la structure data
      print('\nðŸ” DEBUG: Structure complÃ¨te data:');
      print('  Keys au top level: ${data.keys.toList()}');
      if (data['subscription'] != null) {
        print(
            '  Keys dans subscription: ${(data['subscription'] as Map).keys.toList()}');
      }
      if (data['data'] != null) {
        print('  Keys dans data.data: ${(data['data'] as Map).keys.toList()}');
        if ((data['data'] as Map)['subscription'] != null) {
          print(
              '  Keys dans data.data.subscription: ${((data['data'] as Map)['subscription'] as Map).keys.toList()}');
        }
      }

      // Afficher les questionnaire_reponses
      final questReponses = data['subscription']?['questionnaire_reponses'];
      if (questReponses != null) {
        print('ðŸ“‹ DÃ©tail questionnaire_reponses:');
        if (questReponses is List) {
          print('  - Type: List avec ${questReponses.length} Ã©lÃ©ments');
          for (var r in questReponses) {
            if (r is Map && r['libelle'] != null) {
              print(
                  '    Q: "${r['libelle']}" â†’ ${r['reponse_oui_non'] ?? r['reponse_text'] ?? "N/A"}');
            }
          }
        } else {
          print('  - Type: ${questReponses.runtimeType} (non liste)');
        }
      } else {
        print('âš ï¸ questionnaire_reponses est null');
      }

      developer.log('=== DONNÃ‰ES REÃ‡UES ===');
      developer.log('Subscription: ${data['subscription']}');
      developer.log('Subscription type: ${data['subscription'].runtimeType}');
      developer.log(
          'souscriptiondata: ${data['subscription']?['souscriptiondata']}');
      developer.log(
          'souscriptiondata type: ${data['subscription']?['souscriptiondata'].runtimeType}');
      developer.log(
          'piece_identite direct: ${data['subscription']?['souscriptiondata']?['piece_identite']}');
      developer.log('User: ${data['user']}');

      if (!mounted) return;

      setState(() {
        _subscriptionData = data['subscription'];
        _userData = data['user'];
        _isLoading = false;
      });

      final currentStatus =
          (_subscriptionData?['statut'] ?? _subscriptionData?['status'] ?? '')
              .toString()
              .toLowerCase();
      final isContractConfirmed = currentStatus == 'contrat' ||
          currentStatus == 'paid' ||
          currentStatus == 'valid';

      if (mounted && isContractConfirmed && !_autoClosedAfterWaveSuccess) {
        _autoClosedAfterWaveSuccess = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'âœ… Paiement confirmÃ©. Votre proposition est devenue un contrat.'),
            backgroundColor: vertSucces,
            duration: Duration(seconds: 4),
          ),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        });
      }

      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      developer.log('Erreur: $e', error: e);
      print('âŒ Erreur chargement: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(String produit) {
    // Toujours retourner le bleu Coris pour uniformiser
    return const Color(0xFF002B6B);
  }

  String _getBadgeText(String produit) {
    if (produit.toLowerCase().contains('solidarite')) {
      return 'CORIS SOLIDARITÃ‰';
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return 'FLEX EMPRUNTEUR';
    } else if (produit.toLowerCase().contains('etude')) {
      return 'CORIS Ã‰TUDE';
    } else if (produit.toLowerCase().contains('retraite')) {
      return 'CORIS RETRAITE';
    } else if (produit.toLowerCase().contains('serenite')) {
      return 'CORIS SÃ‰RÃ‰NITÃ‰';
    } else if (produit.toLowerCase().contains('familis')) {
      return 'CORIS FAMILIS';
    } else if (produit.toLowerCase().contains('assure') ||
        produit.toLowerCase().contains('prestige')) {
      return 'CORIS ASSURE PRESTIGE';
    } else if (produit.toLowerCase().contains('bon') &&
        produit.toLowerCase().contains('plan')) {
      return 'MON BON PLAN CORIS';
    } else if (produit.toLowerCase().contains('epargne') ||
        produit.toLowerCase().contains('bonus')) {
      return 'CORIS Ã‰PARGNE BONUS';
    } else {
      return 'ASSURANCE VIE';
    }
  }

  String _getProductType() {
    return _subscriptionData?['produit_nom'] ??
        _subscriptionData?['product_type'] ??
        'Produit inconnu';
  }

  Map<String, dynamic> _getSubscriptionDetails() {
    final details = _subscriptionData?['souscriptiondata'] ?? {};
    // Debug: Afficher les donnÃ©es pour vÃ©rifier prime_calculee
    developer.log('=== DÃ‰TAILS SOUSCRIPTION ===');
    developer.log('prime_calculee: ${details['prime_calculee']}');
    developer.log('prime: ${details['prime']}');
    developer.log('montant: ${details['montant']}');
    developer.log('periodicite: ${details['periodicite']}');
    return details;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: grisLeger,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            _buildSliverAppBar(),
          ];
        },
        body: Column(
          children: [
            Expanded(child: _buildRecapContent()),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: grisLeger,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(bleuCoris),
            ),
            SizedBox(height: context.r(16)),
            Text(
              "Chargement des dÃ©tails...",
              style: TextStyle(
                fontSize: context.sp(16),
                color: grisTexte,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: grisLeger,
      appBar: AppBar(
        title: const Text('Erreur'),
        backgroundColor: bleuCoris,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: context.r(16)),
            Text(
              "Erreur de chargement",
              style: TextStyle(
                fontSize: context.sp(20),
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: context.r(8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(16),
                  color: grisTexte,
                ),
              ),
            ),
            SizedBox(height: context.r(24)),
            ElevatedButton(
              onPressed: _loadSubscriptionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: bleuCoris,
                foregroundColor: Colors.white,
              ),
              child: const Text('RÃ©essayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final badgeColor = _getBadgeColor(_getProductType());

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: badgeColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [badgeColor, bleuSecondaire],
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
                      Icon(Icons.description, color: blanc, size: 28),
                      SizedBox(width: context.r(12)),
                      Text(
                        widget.propositionNumber,
                        style: TextStyle(
                          color: blanc,
                          fontSize: context.sp(22),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.r(8)),
                  Text(
                    _getBadgeText(_getProductType()),
                    style: TextStyle(
                      color: blanc.withValues(alpha: 0.9),
                      fontSize: context.sp(14),
                    ),
                  ),
                  SizedBox(height: context.r(16)),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: blanc),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: blanc),
          onPressed: () {
            HapticFeedback.lightImpact();
            final productType = _getProductType().toLowerCase();
            final excludeQ = productType.contains('etude') ||
                productType.contains('familis') ||
                productType.contains('serenite') ||
                productType.contains('sÃ©rÃ©nitÃ©');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerPage(
                    subscriptionId: widget.subscriptionId,
                    excludeQuestionnaire: excludeQ),
              ),
            );
          },
          tooltip: 'Voir le PDF du contrat',
        ),
      ],
    );
  }

  Widget _buildRecapContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value.dy * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  SizedBox(height: context.r(20)),

                  // Informations Personnelles
                  SubscriptionRecapWidgets.buildPersonalInfoSection(
                      _userData ?? {}),

                  SizedBox(height: context.r(20)),

                  // Produit Souscrit (selon le type)
                  _buildProductSection(),

                  SizedBox(height: context.r(20)),

                  // Sections spÃ©cifiques pour CORIS SOLIDARITÃ‰
                  ..._buildSolidariteMembersSection(),

                  // BÃ©nÃ©ficiaires et Contact d'urgence
                  _buildBeneficiariesSection(),

                  SizedBox(height: context.r(20)),

                  _buildCommercialAssistanceSection(),

                  SizedBox(height: context.r(20)),

                  // ðŸ’³ Mode de Paiement
                  _buildPaymentMethodSection(),

                  SizedBox(height: context.r(20)),

                  // ðŸ“‹ RÃ‰CAP: Questionnaire mÃ©dical (questions + rÃ©ponses) â€”
                  // n'afficher que pour Ã‰TUDE, FAMILIS et SÃ‰RÃ‰NITÃ‰
                  Builder(builder: (context) {
                    final productType = _getProductType().toLowerCase();
                    if (productType.contains('etude') ||
                        productType.contains('familis') ||
                        productType.contains('serenite') ||
                        productType.contains('sÃ©rÃ©nitÃ©')) {
                      return Column(
                        children: [
                          // Passe les questions si disponibles (_getQuestionnaireMedicalQuestions)
                          SubscriptionRecapWidgets
                              .buildQuestionnaireMedicalSection(
                                  _getQuestionnaireMedicalReponses(),
                                  _getQuestionnaireMedicalQuestions()),
                          SizedBox(height: context.r(20)),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Documents
                  _buildDocumentsSection(),

                  SizedBox(height: context.r(20)),

                  // Avertissement
                  SubscriptionRecapWidgets.buildVerificationWarning(),

                  SizedBox(height: context.r(20)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductSection() {
    final details = _getSubscriptionDetails();
    final productType = _getProductType().toLowerCase();

    // Pour CORIS SÃ‰RÃ‰NITÃ‰
    if (productType.contains('serenite')) {
      final duree = details['duree'] ?? 'Non dÃ©finie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime'] ?? 0;
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildSereniteProductSection(
        productName: 'CORIS SÃ‰RÃ‰NITÃ‰',
        prime: prime,
        periodicite: periodicite,
        capital: capital,
        duree: duree,
        dureeType: dureeType,
        dateEffet: dateEffet,
        dateEcheance: dateEcheance,
      );
    }

    // Pour CORIS RETRAITE
    if (productType.contains('retraite')) {
      final duree = details['duree'] ?? 'Non dÃ©finie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime'] ?? 0;
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildRetraiteProductSection(
        productName: 'CORIS RETRAITE',
        prime: prime,
        periodicite: periodicite,
        capital: capital,
        duree: duree,
        dureeType: dureeType,
        dateEffet: dateEffet,
        dateEcheance: dateEcheance,
      );
    }

    // Pour CORIS Ã‰TUDE
    if (productType.contains('etude')) {
      final prime = details['prime_calculee'] ??
          details['prime'] ??
          details['montant'] ??
          0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final rente = details['rente_calculee'] ?? details['rente'] ?? 0;
      final duree = details['duree'] ?? details['duree_mois'] != null
          ? '${(details['duree_mois'] as int) ~/ 12}'
          : 'Non dÃ©finie';
      final mode = details['mode_souscription'] ?? 'Mode Capital';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];
      final ageParent = details['age_parent'] ?? 'Non renseignÃ©';
      final dateNaissanceParent = details['date_naissance_parent'];

      // Formater la pÃ©riodicitÃ© avec majuscule
      String periodiciteFormatee = periodicite;
      if (periodicite != null && periodicite.isNotEmpty) {
        periodiciteFormatee = periodicite[0].toUpperCase() +
            periodicite.substring(1).toLowerCase();
      }

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.school,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Produit', 'CORIS Ã‰TUDE', 'Mode', mode),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Ã‚ge du parent',
            '$ageParent ans',
            'Date de naissance',
            dateNaissanceParent != null
                ? SubscriptionRecapWidgets.formatDate(dateNaissanceParent)
                : 'Non renseignÃ©e',
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Cotisation $periodiciteFormatee',
            SubscriptionRecapWidgets.formatMontant(prime),
            'Rente au terme',
            SubscriptionRecapWidgets.formatMontant(rente),
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'DurÃ©e du contrat',
              duree != 'Non dÃ©finie'
                  ? '$duree ans (jusqu\'Ã  17 ans)'
                  : 'Non dÃ©finie',
              'PÃ©riodicitÃ©',
              periodiciteFormatee),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null
                ? SubscriptionRecapWidgets.formatDate(dateEffet)
                : 'Non dÃ©finie',
            'Date d\'Ã©chÃ©ance',
            dateEcheance != null
                ? SubscriptionRecapWidgets.formatDate(dateEcheance)
                : 'Non dÃ©finie',
          ),
        ],
      );
    }

    // Pour CORIS FAMILIS
    if (productType.contains('familis')) {
      final capital = details['capital'] ?? 0;
      final prime = details['prime'] ?? details['prime_mensuelle'] ?? 0;
      final duree = details['duree'] ?? details['duree_mois'] ?? 'Non dÃ©finie';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.family_restroom,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Produit',
              'CORIS FAMILIS',
              'Capital',
              SubscriptionRecapWidgets.formatMontant(capital)),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Prime mensuelle',
              SubscriptionRecapWidgets.formatMontant(prime),
              'DurÃ©e',
              '$duree mois'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null
                ? SubscriptionRecapWidgets.formatDate(dateEffet)
                : 'Non dÃ©finie',
            'Date d\'Ã©chÃ©ance',
            dateEcheance != null
                ? SubscriptionRecapWidgets.formatDate(dateEcheance)
                : 'Non dÃ©finie',
          ),
        ],
      );
    }

    // Pour CORIS SOLIDARITÃ‰
    if (productType.contains('solidarite')) {
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final primeTotale = details['prime_totale'] ?? 0;

      // RÃ©cupÃ©rer le nombre de membres
      final conjoints = details['conjoints'] as List? ?? [];
      final enfants = details['enfants'] as List? ?? [];
      final ascendants = details['ascendants'] as List? ?? [];

      // Afficher le produit avec les membres
      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.emoji_people_outlined,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow('Produit',
              'CORIS SOLIDARITÃ‰', 'PÃ©riodicitÃ©', periodicite.toUpperCase()),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Capital assurÃ©',
              SubscriptionRecapWidgets.formatMontant(capital),
              'Prime $periodicite',
              SubscriptionRecapWidgets.formatMontant(primeTotale)),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Nombre de conjoints',
              conjoints.length.toString(),
              'Nombre d\'enfants',
              enfants.length.toString()),
          SubscriptionRecapWidgets.buildRecapRow(
              'Nombre d\'ascendants', ascendants.length.toString()),
        ],
      );
    }

    // Pour CORIS Ã‰PARGNE BONUS
    if (productType.contains('epargne') || productType.contains('bonus')) {
      final capital = details['capital_au_terme'] ?? details['capital'] ?? 0;
      final prime = details['prime_mensuelle'] ?? details['prime'] ?? 0;
      final dateEffet = details['date_effet'];
      final dateFin = details['date_fin'] ?? details['date_echeance'];
      final bonus = details['bonus'] ?? 'Non dÃ©fini';

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.savings,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow(
              'Produit', 'CORIS Ã‰PARGNE BONUS'),
          SubscriptionRecapWidgets.buildRecapRow('Capital au terme',
              SubscriptionRecapWidgets.formatMontant(capital)),
          SubscriptionRecapWidgets.buildRecapRow(
              'Prime mensuelle', SubscriptionRecapWidgets.formatMontant(prime)),
          SubscriptionRecapWidgets.buildRecapRow('DurÃ©e', '15 ans (180 mois)'),
          if (dateEffet != null)
            SubscriptionRecapWidgets.buildRecapRow('Date d\'effet',
                SubscriptionRecapWidgets.formatDate(dateEffet)),
          if (dateFin != null)
            SubscriptionRecapWidgets.buildRecapRow(
                'Date de fin', SubscriptionRecapWidgets.formatDate(dateFin)),
          SubscriptionRecapWidgets.buildRecapRow('Bonus', bonus.toString()),
        ],
      );
    }

    // Pour CORIS ASSURE PRESTIGE
    if (productType.contains('assure') || productType.contains('prestige')) {
      final versementInitial =
          details['versement_initial'] ?? details['montant_versement'] ?? 0;
      final capitalDeces = details['capital_deces'] ?? 0;
      final primeDecesAnnuelle = details['prime_deces_annuelle'] ?? 0;
      final duree =
          details['duree'] ?? details['duree_contrat'] ?? 'Non dÃ©finie';
      final uniteDuree =
          details['duree_type'] ?? details['unite_duree'] ?? 'ans';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildRecapSection(
        'DÃ©tails du Contrat - CORIS ASSURE PRESTIGE',
        Icons.verified_user,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow(
              'Produit', 'CORIS ASSURE PRESTIGE'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Montant du versement initial',
              SubscriptionRecapWidgets.formatMontant(versementInitial),
              'DurÃ©e du contrat',
              '$duree $uniteDuree'),
          SubscriptionRecapWidgets.buildRecapRow('Capital dÃ©cÃ¨s',
              SubscriptionRecapWidgets.formatMontant(capitalDeces)),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Prime dÃ©cÃ¨s annuelle',
              SubscriptionRecapWidgets.formatMontant(primeDecesAnnuelle),
              'PÃ©riodicitÃ©',
              details['periodicite'] ?? 'Annuel'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              dateEffet != null
                  ? SubscriptionRecapWidgets.formatDate(dateEffet)
                  : 'Non dÃ©finie',
              'Date d\'Ã©chÃ©ance',
              dateEcheance != null
                  ? SubscriptionRecapWidgets.formatDate(dateEcheance)
                  : 'Non dÃ©finie'),
        ],
      );
    }

    // Pour MON BON PLAN CORIS
    if (productType.contains('bon') && productType.contains('plan')) {
      final montantCotisation = details['montant_cotisation'] ?? 0;
      final periodicite = details['periodicite'] ?? 'Non dÃ©finie';
      final dateEffet = details['date_effet'];

      return SubscriptionRecapWidgets.buildRecapSection(
        'DÃ©tails du Contrat - MON BON PLAN CORIS',
        Icons.savings,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow(
              'Produit', 'MON BON PLAN CORIS'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'PÃ©riodicitÃ©',
              periodicite,
              'Date d\'effet',
              dateEffet != null
                  ? SubscriptionRecapWidgets.formatDate(dateEffet)
                  : 'Non dÃ©finie'),
          SubscriptionRecapWidgets.buildRecapRow(
              'Montant de la cotisation ${periodicite.toLowerCase()}',
              SubscriptionRecapWidgets.formatMontant(montantCotisation)),
        ],
      );
    }

    // Pour FLEX EMPRUNTEUR
    if (productType.contains('flex') || productType.contains('emprunteur')) {
      final typePret = details['type_pret'] ?? 'Non dÃ©fini';
      final capital = details['capital_garanti'] ?? details['capital'] ?? 0;
      final duree = details['duree'] ?? 'Non dÃ©finie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime_annuelle'] ?? details['prime'] ?? 0;
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];
      final garantiePrevoyance = details['garantie_prevoyance'] ?? false;
      final garantiePerteEmploi = details['garantie_perte_emploi'] ?? false;
      final capitalPrevoyance = details['capital_prevoyance'] ?? 0;
      final capitalPerteEmploi = details['capital_perte_emploi'] ?? 0;

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.account_balance,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Produit', 'FLEX EMPRUNTEUR', 'Type de prÃªt', typePret),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Capital Ã  garantir',
            SubscriptionRecapWidgets.formatMontant(capital),
            'DurÃ©e',
            '$duree $dureeType',
          ),
          if (dateEffet != null && dateEcheance != null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              SubscriptionRecapWidgets.formatDate(dateEffet),
              'Date d\'Ã©chÃ©ance',
              SubscriptionRecapWidgets.formatDate(dateEcheance),
            ),
          if (dateEffet != null && dateEcheance == null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              SubscriptionRecapWidgets.formatDate(dateEffet),
              '',
              '',
            ),
          if (dateEffet == null && dateEcheance != null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'Ã©chÃ©ance',
              SubscriptionRecapWidgets.formatDate(dateEcheance),
              '',
              '',
            ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Prime annuelle estimÃ©e',
              SubscriptionRecapWidgets.formatMontant(prime),
              '',
              ''),
          if (garantiePrevoyance && garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie PrÃ©voyance',
              SubscriptionRecapWidgets.formatMontant(capitalPrevoyance),
              'Garantie Perte d\'emploi',
              SubscriptionRecapWidgets.formatMontant(capitalPerteEmploi),
            ),
          if (garantiePrevoyance && !garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie PrÃ©voyance',
              SubscriptionRecapWidgets.formatMontant(capitalPrevoyance),
              '',
              '',
            ),
          if (!garantiePrevoyance && garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie Perte d\'emploi',
              SubscriptionRecapWidgets.formatMontant(capitalPerteEmploi),
              '',
              '',
            ),
        ],
      );
    }

    // Section par dÃ©faut pour les autres produits
    return SubscriptionRecapWidgets.buildRecapSection(
      'Produit Souscrit',
      Icons.security,
      vertSucces,
      [
        SubscriptionRecapWidgets.buildRecapRow(
            'Produit', _getBadgeText(_getProductType())),
        if (details['capital'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Capital',
              SubscriptionRecapWidgets.formatMontant(details['capital'])),
        if (details['prime'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Prime',
              SubscriptionRecapWidgets.formatMontant(details['prime'])),
        if (details['duree'] != null)
          SubscriptionRecapWidgets.buildRecapRow('DurÃ©e',
              '${details['duree']} ${details['duree_type'] ?? 'mois'}'),
        if (details['date_effet'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Date d\'effet',
              SubscriptionRecapWidgets.formatDate(details['date_effet'])),
      ],
    );
  }

  /// Construit les sections des membres pour CORIS SOLIDARITÃ‰
  /// Retourne une liste de widgets pour Conjoints, Enfants, Ascendants
  List<Widget> _buildSolidariteMembersSection() {
    final details = _getSubscriptionDetails();
    final productType = _getProductType().toLowerCase();

    // Ne rien afficher si ce n'est pas CORIS SOLIDARITÃ‰
    if (!productType.contains('solidarite')) {
      return [];
    }

    final List<Widget> sections = [];
    final conjoints = details['conjoints'] as List<dynamic>?;
    final enfants = details['enfants'] as List<dynamic>?;
    final ascendants = details['ascendants'] as List<dynamic>?;

    // Section Conjoints
    if (conjoints != null && conjoints.isNotEmpty) {
      sections.add(
        SubscriptionRecapWidgets.buildRecapSection(
          'Conjoint(s)',
          Icons.people,
          bleuCoris,
          conjoints.map((conjoint) => _buildMembreRecap(conjoint)).toList(),
        ),
      );
      sections.add(SizedBox(height: context.r(20)));
    }

    // Section Enfants
    if (enfants != null && enfants.isNotEmpty) {
      sections.add(
        SubscriptionRecapWidgets.buildRecapSection(
          'Enfant(s)',
          Icons.child_care,
          bleuCoris,
          enfants.map((enfant) => _buildMembreRecap(enfant)).toList(),
        ),
      );
      sections.add(SizedBox(height: context.r(20)));
    }

    // Section Ascendants
    if (ascendants != null && ascendants.isNotEmpty) {
      sections.add(
        SubscriptionRecapWidgets.buildRecapSection(
          'Ascendant(s)',
          Icons.elderly,
          bleuCoris,
          ascendants.map((ascendant) => _buildMembreRecap(ascendant)).toList(),
        ),
      );
      sections.add(SizedBox(height: context.r(20)));
    }

    return sections;
  }

  /// Construit l'affichage d'un membre (conjoint, enfant, ascendant)
  /// Format : Nom en gras + Date de naissance et Lieu de naissance en dessous
  Widget _buildMembreRecap(Map<String, dynamic> membre) {
    final nom = membre['nom'] ??
        membre['nomPrenom'] ??
        membre['nom_prenom'] ??
        membre['prenom'] ??
        'Non renseignÃ©';
    final dateNaissance = membre['date_naissance'] ??
        membre['dateNaissance'] ??
        membre['date_de_naissance'];
    final lieuNaissance = membre['lieu_naissance'] ??
        membre['lieuNaissance'] ??
        membre['lieu_de_naissance'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nom,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: bleuCoris,
              fontSize: context.sp(14),
            ),
          ),
          SizedBox(height: context.r(2)),
          Text(
            dateNaissance != null
                ? 'Date de naissance: ${SubscriptionRecapWidgets.formatDate(dateNaissance)}'
                : 'Date de naissance: Non renseignÃ©e',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: grisTexte,
              fontSize: context.sp(12),
            ),
          ),
          if (lieuNaissance != null) ...[
            SizedBox(height: context.r(2)),
            Text(
              'Lieu de naissance: $lieuNaissance',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: grisTexte,
                fontSize: context.sp(12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBeneficiariesSection() {
    final details = _getSubscriptionDetails();
    final beneficiaire = details['beneficiaire'];
    final contactUrgence = details['contact_urgence'];

    return SubscriptionRecapWidgets.buildBeneficiariesSection(
      beneficiaireNom: beneficiaire?['nom'],
      beneficiaireDateNaissance: beneficiaire?['date_naissance'] ??
          beneficiaire?['dateNaissance'] ??
          beneficiaire?['date_de_naissance'],
      beneficiaireContact: beneficiaire?['contact'],
      beneficiaireLienParente: beneficiaire?['lien_parente'],
      contactUrgenceNom: contactUrgence?['nom'],
      contactUrgenceContact: contactUrgence?['contact'],
      contactUrgenceLienParente: contactUrgence?['lien_parente'],
    );
  }

  Widget _buildCommercialAssistanceSection() {
    final details = _getSubscriptionDetails();
    final assistanceCommerciale = details['assistance_commerciale'];

    if (assistanceCommerciale is! Map) {
      return const SizedBox.shrink();
    }

    final isAideParCommercial =
        assistanceCommerciale['is_aide_par_commercial'] == true;
    final nomPrenom = assistanceCommerciale['commercial_nom_prenom']?.toString();
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
  }

  /// ðŸ’³ Construit la section Mode de Paiement
  Widget _buildPaymentMethodSection() {
    final details = _getSubscriptionDetails();

    // Utiliser la nouvelle mÃ©thode avec icÃ´nes et couleurs
    return SubscriptionRecapWidgets.buildPaymentModeSection(details);
  }

  List<Map<String, dynamic>> _extractDocumentsList(dynamic raw) {
    final docs = <Map<String, dynamic>>[];

    void addDoc(dynamic path, {dynamic label}) {
      if (path == null) return;
      final normalizedPath = path.toString().trim();
      if (normalizedPath.isEmpty || normalizedPath.toLowerCase() == 'null') {
        return;
      }
      final normalizedLabel = label?.toString().trim();
      docs.add({
        'path': normalizedPath,
        if (normalizedLabel != null && normalizedLabel.isNotEmpty)
          'label': normalizedLabel,
      });
    }

    void parse(dynamic value) {
      if (value == null) return;

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return;
        if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
            (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
          try {
            parse(jsonDecode(trimmed));
            return;
          } catch (_) {
            addDoc(trimmed);
            return;
          }
        }
        addDoc(trimmed);
        return;
      }

      if (value is List) {
        for (final item in value) {
          parse(item);
        }
        return;
      }

      if (value is Map) {
        if (value['path'] != null ||
            value['url'] != null ||
            value['filename'] != null) {
          addDoc(
            value['path'] ?? value['url'] ?? value['filename'] ?? value['name'],
            label: value['label'] ?? value['title'] ?? value['name'],
          );
          return;
        }

        for (final entry in value.entries) {
          final key = entry.key.toString();
          final entryValue = entry.value;
          if (entryValue is String) {
            addDoc(entryValue, label: key);
          } else {
            parse(entryValue);
          }
        }
      }
    }

    parse(raw);

    final seen = <String>{};
    return docs.where((doc) {
      final path = doc['path']?.toString() ?? '';
      if (path.isEmpty || seen.contains(path)) return false;
      seen.add(path);
      return true;
    }).toList();
  }

  Widget _buildDocumentsSection() {
    // Chercher piece_identite dans tous les endroits possibles
    String? pieceIdentite;
    String? pieceIdentiteLabel; // Nom original du fichier

    final souscriptiondata = _subscriptionData?['souscriptiondata'];
    final details = _getSubscriptionDetails();

    if (souscriptiondata != null) {
      pieceIdentiteLabel = souscriptiondata['piece_identite_label'];
      pieceIdentite = souscriptiondata['piece_identite'] ??
          souscriptiondata['pieceIdentite'] ??
          souscriptiondata['document'];

      if (pieceIdentite == null && souscriptiondata['documents'] != null) {
        final docs = souscriptiondata['documents'];
        if (docs is Map) {
          pieceIdentite = docs['piece_identite'] ?? docs['pieceIdentite'];
        }
      }
    }

    pieceIdentite ??= _subscriptionData?['piece_identite'];
    pieceIdentite ??= _subscriptionData?['document'];

    if (pieceIdentite == null) {
      pieceIdentiteLabel ??= details['piece_identite_label'];
      pieceIdentite = details['piece_identite'] ??
          details['pieceIdentite'] ??
          details['document'];

      if (pieceIdentite == null && details['documents'] != null) {
        final docs = details['documents'];
        if (docs is Map) {
          pieceIdentite = docs['piece_identite'] ?? docs['pieceIdentite'];
        }
      }
    }

    developer.log('=== DOCUMENT DEBUG COMPLET ===');
    developer.log('_subscriptionData: $_subscriptionData');
    developer
        .log('_subscriptionData keys: ${_subscriptionData?.keys.toList()}');
    developer.log('souscriptiondata: $souscriptiondata');
    developer.log('souscriptiondata type: ${souscriptiondata?.runtimeType}');
    if (souscriptiondata is Map) {
      developer.log('souscriptiondata keys: ${souscriptiondata.keys.toList()}');
    }
    developer.log('Final pieceIdentite trouvÃ©: $pieceIdentite');

    final hasDocument = pieceIdentite != null &&
        pieceIdentite.toString().isNotEmpty &&
        pieceIdentite != 'Non tÃ©lÃ©chargÃ©e' &&
        pieceIdentite != 'null' &&
        pieceIdentite.toString().toLowerCase() != 'null';

    developer.log('hasDocument: $hasDocument');

    String? displayLabel;
    if (pieceIdentiteLabel != null &&
        pieceIdentiteLabel.toString().isNotEmpty) {
      displayLabel = pieceIdentiteLabel;
    } else if (pieceIdentite != null && pieceIdentite.toString().isNotEmpty) {
      final s = pieceIdentite.toString();
      displayLabel = s.split(RegExp(r'[\\/]+')).last;
    } else {
      displayLabel = null;
    }

    final actualFilename = hasDocument ? pieceIdentite : null;

    final docsList = [
      ..._extractDocumentsList(souscriptiondata?['documents']),
      ..._extractDocumentsList(_subscriptionData?['documents']),
      ..._extractDocumentsList(details['documents']),
      ..._extractDocumentsList(souscriptiondata?['souscription_documents']),
      ..._extractDocumentsList(_subscriptionData?['souscription_documents']),
      ..._extractDocumentsList(souscriptiondata?['piece_identite_documents']),
      ..._extractDocumentsList(_subscriptionData?['piece_identite_documents']),
    ];

    // Ne plus ajouter manuellement pieceIdentite - elle devrait dÃ©jÃ  Ãªtre incluse dans piece_identite_documents
    // Si elle n'y est pas, c'est un problÃ¨me de donnÃ©es cÃ´tÃ© serveur
// Ajouter pieceIdentite seulement si elle n'existe pas dÃ©jÃ 
    if (actualFilename != null && actualFilename.isNotEmpty) {
      final alreadyExists = docsList.any((doc) {
        final path = doc['path']?.toString().trim() ?? '';
        final normalized = path.replaceAll('\\', '/').split('/').last.trim();
        final currentFile =
            actualFilename.replaceAll('\\', '/').split('/').last.trim();
        return normalized == currentFile;
      });

      if (!alreadyExists) {
        docsList.add(
            {'path': actualFilename, 'label': displayLabel ?? actualFilename});
      }
    }
    // DÃ©duplication stricte par nom de fichier
    final seenFiles = <String>{};
    final deduplicatedDocsList = docsList.where((doc) {
      final path = doc['path']?.toString().trim() ?? '';
      final filename = path.replaceAll('\\', '/').split('/').last.trim();
      if (filename.isEmpty || seenFiles.contains(filename)) return false;
      seenFiles.add(filename);
      return true;
    }).toList();
    developer.log(
        'Documents finaux uniques: ${deduplicatedDocsList.map((d) => d['path']).toList()}');

    final normalizedDocsList =
        deduplicatedDocsList.isEmpty ? null : deduplicatedDocsList;

    // Calculate total document count - seulement compter les documents uniques dans la liste
    final totalDocuments = normalizedDocsList?.length ?? 0;

    return SubscriptionRecapWidgets.buildDocumentsSection(
      pieceIdentite: null,
      documents: normalizedDocsList,
      onDocumentTapWithInfo: (path, label) => _viewDocument(path, label),
      onDocumentTap: actualFilename != null
          ? () => _viewDocument(actualFilename, displayLabel)
          : null,
      documentCount: totalDocuments, // Compte seulement les documents uniques
    );
  }

  void _viewDocument(String? documentName, String? displayLabel) {
    developer.log('_viewDocument called with: $documentName');

    if (documentName == null ||
        documentName.isEmpty ||
        documentName == 'Non tÃ©lÃ©chargÃ©e') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: blanc, size: 20),
              SizedBox(width: context.r(12)),
              const Expanded(
                child: Text('Aucun document disponible'),
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

    // Normaliser le document pour transmettre uniquement un nom de fichier serveur.
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

    // Ouvrir le viewer de documents
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerPage(
          documentName: normalizedDocumentName,
          displayLabel: displayLabel,
          subscriptionId: widget.subscriptionId,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Bouton Imprimer
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: bleuCoris.withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final productType = _getProductType().toLowerCase();
                          final excludeQ = productType.contains('etude') ||
                              productType.contains('familis') ||
                              productType.contains('serenite') ||
                              productType.contains('sÃ©rÃ©nitÃ©');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerPage(
                                  subscriptionId: widget.subscriptionId,
                                  excludeQuestionnaire: excludeQ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_outlined,
                                color: bleuCoris, size: 20),
                            SizedBox(width: context.r(8)),
                            Text(
                              'Imprimer',
                              style: TextStyle(
                                color: bleuCoris,
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: context.r(12)),
                // Bouton Modifier
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: orangeWarning.withValues(alpha: 0.5),
                          width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: orangeWarning.withValues(alpha: 0.05),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _modifyProposition,
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined,
                                color: orangeWarning, size: 20),
                            SizedBox(width: context.r(8)),
                            Text(
                              'Modifier',
                              style: TextStyle(
                                color: orangeWarning,
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.r(12)),
            // Bouton Accepter et Payer (pleine largeur)
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _acceptAndPay,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: blanc, size: 22),
                      SizedBox(width: context.r(10)),
                      Text(
                        'Accepter et Payer',
                        style: TextStyle(
                          color: blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(16),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: context.r(8)),
                      Icon(Icons.arrow_forward, color: blanc, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _modifyProposition() {
    HapticFeedback.lightImpact();

    if (_subscriptionData == null) return;

    final productType = _getProductType().toLowerCase();
    final details = _getSubscriptionDetails();

    // Extraire client_info si c'est une souscription par commercial
    final clientInfo = details['client_info'];
    final String? clientId =
        clientInfo != null ? clientInfo['id']?.toString() : null;
    final Map<String, dynamic>? clientData =
        clientInfo != null ? Map<String, dynamic>.from(clientInfo) : null;

    // Rediriger vers la page de souscription appropriÃ©e avec les donnÃ©es
    if (productType.contains('etude')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionEtudePage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('serenite') ||
        productType.contains('sÃ©rÃ©nitÃ©')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionSerenitePage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('retraite')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionRetraitePage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('solidarite') ||
        productType.contains('solidaritÃ©')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'La modification de CORIS SOLIDARITÃ‰ sera bientÃ´t disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (productType.contains('familis')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionFamilisPage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('flex') ||
        productType.contains('emprunteur')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionFlexPage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('epargne') ||
        productType.contains('Ã©pargne')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionEpargnePage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('mon bon plan')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionBonPlanPage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else if (productType.contains('assurÃ© prestige') ||
        productType.contains('assure prestige') ||
        productType.contains('prestige')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SouscriptionPrestigePage(
            subscriptionId: widget.subscriptionId,
            existingData: details,
            clientId: clientId,
            clientData: clientData,
          ),
        ),
      ).then((_) {
        if (mounted) _loadSubscriptionData();
      });
    } else {
      // Produit non reconnu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'La modification de ce type de produit n\'est pas encore disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _acceptAndPay() {
    HapticFeedback.lightImpact();

    // Afficher les options de paiement (comme dans la souscription)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentBottomSheet(),
    );
  }

  Widget _buildPaymentBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: context.r(24)),
              Row(
                children: [
                  Icon(Icons.payment, color: bleuCoris, size: 28),
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
                'Wave',
                'assets/images/icone_wave.jpeg',
                Colors.blue,
                'Paiement mobile sÃ©curisÃ©',
                () => _processPayment('Wave'),
              ),
              // _buildPaymentOptionWithImage(
              //   'Orange Money',
              //   'assets/images/icone_orange_money.jpeg',
              //   Colors.orange,
              //   'Paiement mobile Orange',
              //   () => _processPayment('Orange Money'),
              // ),
              // _buildPaymentOptionWithImage(
              //   'CORIS Money',
              //   'assets/images/icone_corismoney.jpeg',
              //   const Color(0xFF1E3A8A),
              //   'Paiement via CORIS Money',
              //   () => _processPayment('CORIS Money'),
              // ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionWithImage(
    String title,
    String imagePath,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: fondCarte,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
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
                  return Icon(Icons.image_not_supported,
                      size: 32, color: Colors.grey);
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
                      color: grisTexte,
                      fontSize: context.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: grisTexte, size: 16),
          ],
        ),
      ),
    );
  }

  double _extractPaymentAmount() {
    final souscriptionData = _subscriptionData?['souscriptiondata'];
    if (souscriptionData is! Map) return 0.0;

    final rawValue = souscriptionData['prime_totale'] ??
        souscriptionData['montant_total'] ??
        souscriptionData['prime'] ??
        souscriptionData['montant'] ??
        souscriptionData['versement_initial'] ??
        souscriptionData['montant_cotisation'] ??
        souscriptionData['prime_mensuelle'] ??
        souscriptionData['capital'] ??
        0;

    double amount = rawValue is num
        ? rawValue.toDouble()
        : double.tryParse(rawValue.toString()) ?? 0.0;

    // Mode test: forcer 10 XOF pour les tests de paiement Wave
    if (AppConfig.TEST_MODE_FORCE_10_XOF) {
      debugPrint('[TEST MODE] Montant forcÃ© Ã  10 XOF au lieu de $amount');
      return 10.0;
    }
    return amount;
  }

  Future<void> _startWavePayment() async {
    try {
      final amount = _extractPaymentAmount();
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Montant de paiement introuvable pour cette proposition.'),
            backgroundColor: orangeWarning,
          ),
        );
        return;
      }

      final waveService = WaveService();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initialisation du paiement Wave...'),
          backgroundColor: bleuCoris,
        ),
      );

      final createResult = await waveService.createCheckoutSession(
        subscriptionId: widget.subscriptionId,
        amount: amount,
        description: 'Paiement proposition #${widget.subscriptionId}',
      );

      if (!(createResult['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(createResult['message']?.toString() ??
                'Impossible de dÃ©marrer le paiement Wave.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = createResult['data'] as Map<String, dynamic>? ?? {};
      final launchUrlValue = data['launchUrl']?.toString();
      final sessionId = data['sessionId']?.toString() ?? '';
      final transactionId = data['transactionId']?.toString();

      if (launchUrlValue == null ||
          launchUrlValue.isEmpty ||
          sessionId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'RÃ©ponse Wave incomplÃ¨te (URL/session). DÃ©tail: ${createResult['message'] ?? 'n/a'}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final uri = Uri.tryParse(launchUrlValue);
      if (uri == null) {
        if (!mounted) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir Wave. URL: $launchUrlValue'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'ðŸ”„ Paiement Wave lancÃ©. Retournez Ã  l\'application aprÃ¨s paiement pour confirmation automatique.'),
          backgroundColor: bleuCoris,
          duration: Duration(seconds: 5),
        ),
      );

      // ðŸ”„ POLLING AMÃ‰LIORÃ‰: Essayer pendant 2 minutes (40 tentatives Ã— 3s)
      // Cela permet Ã  l'utilisateur de complÃ©ter le paiement mÃªme s'il prend du temps
      for (int attempt = 0; attempt < 40; attempt++) {
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        final statusResult = await waveService.getCheckoutStatus(
          sessionId: sessionId,
          subscriptionId: widget.subscriptionId,
          transactionId: transactionId,
        );

        if (!(statusResult['success'] == true)) {
          debugPrint(
              'â³ Tentative ${attempt + 1}/40: Statut non rÃ©cupÃ©rÃ©, rÃ©essai...');
          continue;
        }

        final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
        final status = (statusData['status'] ?? '').toString().toUpperCase();

        debugPrint('ðŸ“Š Tentative ${attempt + 1}/40: Statut Wave = $status');

        if (status == 'SUCCESS') {
          if (!mounted) return;

          // ðŸŽ‰ PAIEMENT RÃ‰USSI - Convertir la proposition en contrat + envoyer SMS
          try {
            final confirmResult =
                await waveService.confirmWavePayment(widget.subscriptionId);

            if (confirmResult['success'] == true) {
              if (!mounted) return;

              // âœ… Afficher le message de succÃ¨s avec les dÃ©tails
              final confirmData =
                  confirmResult['data'] as Map<String, dynamic>? ?? {};
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'âœ… Paiement Wave confirmÃ© avec succÃ¨s !',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: context.sp(16)),
                      ),
                      SizedBox(height: context.r(6)),
                      Text(
                        'Montant: ${confirmData['montant']} FCFA',
                        style: TextStyle(fontSize: context.sp(13)),
                      ),
                      SizedBox(height: context.r(4)),
                      Text(
                        'ðŸŽ‰ Votre proposition est maintenant un CONTRAT valide.',
                        style: TextStyle(
                            fontSize: context.sp(13), fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: context.r(4)),
                      Text(
                        'ðŸ“± Un SMS de confirmation a Ã©tÃ© envoyÃ©.',
                        style: TextStyle(fontSize: context.sp(12)),
                      ),
                    ],
                  ),
                  backgroundColor: vertSucces,
                  duration: const Duration(seconds: 8),
                ),
              );

              // Recharger les donnÃ©es pour afficher le nouveau statut
              await _loadSubscriptionData();
              return;
            } else {
              // La confirmation backend peut Ãªtre asynchrone si l'utilisateur revient vite depuis Wave.
              // Ne pas afficher de message d'erreur/info transitoire.
              await _loadSubscriptionData();
              return;
            }
          } catch (confirmError) {
            debugPrint('Confirmation asynchrone en cours: $confirmError');
            await _loadSubscriptionData();
            return;
          }
        }

        if (status == 'FAILED') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('âŒ Paiement Wave Ã©chouÃ© ou annulÃ©.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }

        // Si PENDING, continuer Ã  attendre
        if (status == 'PENDING') {
          debugPrint('â³ Paiement en attente (PENDING), continue le polling...');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement Wave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Ne pas afficher de message transitoire ici pour Ã©viter les faux positifs perÃ§us comme erreur.
  }

  void _processPayment(String paymentMethod) {
    Navigator.pop(context); // Fermer le bottom sheet

    final amount = _extractPaymentAmount();

    if (paymentMethod == 'CORIS Money') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CorisMoneyPaymentModal(
          subscriptionId: widget.subscriptionId,
          montant: amount,
          description: 'Paiement proposition #${widget.subscriptionId}',
          onPaymentSuccess: () {
            _loadSubscriptionData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('âœ… Paiement CORIS Money effectuÃ© avec succÃ¨s.'),
                backgroundColor: vertSucces,
              ),
            );
          },
        ),
      );
      return;
    }

    if (paymentMethod == 'Wave') {
      _startWavePayment();
      return;
    }

    if (paymentMethod == 'Orange Money') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Orange Money sera branchÃ© juste aprÃ¨s Wave. Utilisez Wave ou CORIS Money.'),
          backgroundColor: orangeWarning,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction, color: blanc, size: 20),
            SizedBox(width: context.r(12)),
            Expanded(
              child: Text(
                  'Paiement via $paymentMethod - FonctionnalitÃ© en cours de dÃ©veloppement'),
            ),
          ],
        ),
        backgroundColor: orangeWarning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// RÃ©cupÃ¨re les rÃ©ponses au questionnaire mÃ©dical depuis questionnaire_reponses
  List<Map<String, dynamic>> _getQuestionnaireMedicalReponses() {
    // Essayer d'abord le champ questionnaire_reponses (retournÃ© par le serveur)
    final reponses = _subscriptionData?['questionnaire_reponses'];

    print('ðŸ” _getQuestionnaireMedicalReponses() appelÃ©');
    print('  - _subscriptionData type: ${_subscriptionData.runtimeType}');
    print('  - reponses (questionnaire_reponses): $reponses');

    if (reponses == null) {
      print(
          '  âš ï¸ questionnaire_reponses est null, cherche dans souscriptiondata...');
      // Fallback: chercher dans souscriptiondata
      final souscriptiondata = _subscriptionData?['souscriptiondata'];
      if (souscriptiondata != null &&
          souscriptiondata['questionnaire_medical_reponses'] != null) {
        final fallback = souscriptiondata['questionnaire_medical_reponses'];
        print(
            '  âœ… TrouvÃ© questionnaire_medical_reponses dans souscriptiondata: $fallback');
        if (fallback is List) {
          return List<Map<String, dynamic>>.from(
            fallback.map((r) => r is Map ? Map<String, dynamic>.from(r) : {}),
          );
        }
      }
      print('  âŒ Aucun questionnaire trouvÃ©');
      return [];
    }

    print('  âœ… questionnaire_reponses trouvÃ©: ${reponses.runtimeType}');

    // Si c'est dÃ©jÃ  une liste, la retourner
    if (reponses is List) {
      print('  âœ… Format liste dÃ©tectÃ©: ${reponses.length} rÃ©ponses');
      for (var r in reponses) {
        if (r is Map && r['libelle'] != null) {
          print(
              '    - Q: "${r['libelle']}" â†’ R: ${r['reponse_oui_non'] ?? r['reponse_text'] ?? "N/A"}');
        }
      }
      return List<Map<String, dynamic>>.from(
        reponses.map((r) => r is Map ? Map<String, dynamic>.from(r) : {}),
      );
    }

    // Si le backend renvoie un Map (index => objet), le convertir en liste
    print('  âš ï¸ Format inattendu: ${reponses.runtimeType}');
    if (reponses is Map) {
      print('  ðŸ”„ Conversion Map â†’ List...');
      return reponses.values
          .where((v) => v != null)
          .map((v) =>
              v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{})
          .toList();
    }

    // Pas de format reconnu -> retourner liste vide
    return [];
  }

  /// Tentative de rÃ©cupÃ©ration des questions depuis les donnÃ©es chargÃ©es
  List<Map<String, dynamic>> _getQuestionnaireMedicalQuestions() {
    try {
      final questions = _subscriptionData?['questionnaire_questions'] ??
          _subscriptionData?['questions'];
      if (questions is List) {
        return List<Map<String, dynamic>>.from(
          questions.map((q) => q is Map ? Map<String, dynamic>.from(q) : {}),
        );
      }
    } catch (e) {
      print('âš ï¸ _getQuestionnaireMedicalQuestions erreur: $e');
    }
    return [];
  }

  // Fin de la classe PropositionDetailPageState
}

