import 'package:flutter/material.dart';
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
/// PAGE DE DÉTAILS D'UNE PROPOSITION
/// ============================================
/// Cette page affiche les détails complets d'une proposition d'assurance.
/// Elle permet à l'utilisateur de visualiser toutes les informations de sa
/// souscription avant de procéder au paiement.
///
/// Fonctionnalités:
/// - Affichage des informations personnelles
/// - Affichage des détails du produit (capital, prime, durée, etc.)
/// - Affichage des bénéficiaires et contacts d'urgence
/// - Affichage des documents joints
/// - Possibilité de modifier la proposition
/// - Possibilité de payer directement

// ===================================
// COULEURS PARTAGÉES
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
                  '✅ Paiement Wave confirmé ($successCount). Votre contrat a été mis à jour.'),
              backgroundColor: vertSucces,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      print('📥 Chargement détails proposition ${widget.subscriptionId}...');
      final data = await _service.getSubscriptionDetail(widget.subscriptionId);

      print('\n=== DONNÉES REÇUES DU SERVEUR ===');
      print(
          '✅ Subscription reçue: ${data['subscription'] != null ? 'OUI' : 'NON'}');
      print('✅ User reçue: ${data['user'] != null ? 'OUI' : 'NON'}');
      print(
          '✅ questionnaire_reponses reçue: ${data['subscription']?['questionnaire_reponses'] != null ? 'OUI' : 'NON'}');

      // DEBUG: afficher toute la structure data
      print('\n🔍 DEBUG: Structure complète data:');
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
        print('📋 Détail questionnaire_reponses:');
        if (questReponses is List) {
          print('  - Type: List avec ${questReponses.length} éléments');
          questReponses.forEach((r) {
            if (r is Map && r['libelle'] != null) {
              print(
                  '    Q: "${r['libelle']}" → ${r['reponse_oui_non'] ?? r['reponse_text'] ?? "N/A"}');
            }
          });
        } else {
          print('  - Type: ${questReponses.runtimeType} (non liste)');
        }
      } else {
        print('⚠️ questionnaire_reponses est null');
      }

      developer.log('=== DONNÉES REÇUES ===');
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
                '✅ Paiement confirmé. Votre proposition est devenue un contrat.'),
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
      print('❌ Erreur chargement: $e');

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
      return 'CORIS SOLIDARITÉ';
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return 'FLEX EMPRUNTEUR';
    } else if (produit.toLowerCase().contains('etude')) {
      return 'CORIS ÉTUDE';
    } else if (produit.toLowerCase().contains('retraite')) {
      return 'CORIS RETRAITE';
    } else if (produit.toLowerCase().contains('serenite')) {
      return 'CORIS SÉRÉNITÉ';
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
      return 'CORIS ÉPARGNE BONUS';
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
    // Debug: Afficher les données pour vérifier prime_calculee
    developer.log('=== DÉTAILS SOUSCRIPTION ===');
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
            const SizedBox(height: 16),
            const Text(
              "Chargement des détails...",
              style: TextStyle(
                fontSize: 16,
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
            const SizedBox(height: 16),
            const Text(
              "Erreur de chargement",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: grisTexte,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSubscriptionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: bleuCoris,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
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
                      const SizedBox(width: 12),
                      Text(
                        widget.propositionNumber,
                        style: const TextStyle(
                          color: blanc,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getBadgeText(_getProductType()),
                    style: TextStyle(
                      color: blanc.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                productType.contains('sérénité');
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
                  const SizedBox(height: 20),

                  // Informations Personnelles
                  SubscriptionRecapWidgets.buildPersonalInfoSection(
                      _userData ?? {}),

                  const SizedBox(height: 20),

                  // Produit Souscrit (selon le type)
                  _buildProductSection(),

                  const SizedBox(height: 20),

                  // Sections spécifiques pour CORIS SOLIDARITÉ
                  ..._buildSolidariteMembersSection(),

                  // Bénéficiaires et Contact d'urgence
                  _buildBeneficiariesSection(),

                  const SizedBox(height: 20),

                  _buildCommercialAssistanceSection(),

                  const SizedBox(height: 20),

                  // 💳 Mode de Paiement
                  _buildPaymentMethodSection(),

                  const SizedBox(height: 20),

                  // 📋 RÉCAP: Questionnaire médical (questions + réponses) —
                  // n'afficher que pour ÉTUDE, FAMILIS et SÉRÉNITÉ
                  Builder(builder: (context) {
                    final productType = _getProductType().toLowerCase();
                    if (productType.contains('etude') ||
                        productType.contains('familis') ||
                        productType.contains('serenite') ||
                        productType.contains('sérénité')) {
                      return Column(
                        children: [
                          // Passe les questions si disponibles (_getQuestionnaireMedicalQuestions)
                          SubscriptionRecapWidgets
                              .buildQuestionnaireMedicalSection(
                                  _getQuestionnaireMedicalReponses(),
                                  _getQuestionnaireMedicalQuestions()),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Documents
                  _buildDocumentsSection(),

                  const SizedBox(height: 20),

                  // Avertissement
                  SubscriptionRecapWidgets.buildVerificationWarning(),

                  const SizedBox(height: 20),
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

    // Pour CORIS SÉRÉNITÉ
    if (productType.contains('serenite')) {
      final duree = details['duree'] ?? 'Non définie';
      final dureeType = details['duree_type'] ?? 'mois';
      final prime = details['prime'] ?? 0;
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildSereniteProductSection(
        productName: 'CORIS SÉRÉNITÉ',
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
      final duree = details['duree'] ?? 'Non définie';
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

    // Pour CORIS ÉTUDE
    if (productType.contains('etude')) {
      final prime = details['prime_calculee'] ??
          details['prime'] ??
          details['montant'] ??
          0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final rente = details['rente_calculee'] ?? details['rente'] ?? 0;
      final duree = details['duree'] ?? details['duree_mois'] != null
          ? '${(details['duree_mois'] as int) ~/ 12}'
          : 'Non définie';
      final mode = details['mode_souscription'] ?? 'Mode Capital';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];
      final ageParent = details['age_parent'] ?? 'Non renseigné';
      final dateNaissanceParent = details['date_naissance_parent'];

      // Formater la périodicité avec majuscule
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
              'Produit', 'CORIS ÉTUDE', 'Mode', mode),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Âge du parent',
            ageParent.toString() + ' ans',
            'Date de naissance',
            dateNaissanceParent != null
                ? SubscriptionRecapWidgets.formatDate(dateNaissanceParent)
                : 'Non renseignée',
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Cotisation $periodiciteFormatee',
            SubscriptionRecapWidgets.formatMontant(prime),
            'Rente au terme',
            SubscriptionRecapWidgets.formatMontant(rente),
          ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Durée du contrat',
              duree != 'Non définie'
                  ? '$duree ans (jusqu\'à 17 ans)'
                  : 'Non définie',
              'Périodicité',
              periodiciteFormatee),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null
                ? SubscriptionRecapWidgets.formatDate(dateEffet)
                : 'Non définie',
            'Date d\'échéance',
            dateEcheance != null
                ? SubscriptionRecapWidgets.formatDate(dateEcheance)
                : 'Non définie',
          ),
        ],
      );
    }

    // Pour CORIS FAMILIS
    if (productType.contains('familis')) {
      final capital = details['capital'] ?? 0;
      final prime = details['prime'] ?? details['prime_mensuelle'] ?? 0;
      final duree = details['duree'] ?? details['duree_mois'] ?? 'Non définie';
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
              'Durée',
              '$duree mois'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Date d\'effet',
            dateEffet != null
                ? SubscriptionRecapWidgets.formatDate(dateEffet)
                : 'Non définie',
            'Date d\'échéance',
            dateEcheance != null
                ? SubscriptionRecapWidgets.formatDate(dateEcheance)
                : 'Non définie',
          ),
        ],
      );
    }

    // Pour CORIS SOLIDARITÉ
    if (productType.contains('solidarite')) {
      final capital = details['capital'] ?? 0;
      final periodicite = details['periodicite'] ?? 'mensuel';
      final primeTotale = details['prime_totale'] ?? 0;

      // Récupérer le nombre de membres
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
              'CORIS SOLIDARITÉ', 'Périodicité', periodicite.toUpperCase()),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Capital assuré',
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

    // Pour CORIS ÉPARGNE BONUS
    if (productType.contains('epargne') || productType.contains('bonus')) {
      final capital = details['capital_au_terme'] ?? details['capital'] ?? 0;
      final prime = details['prime_mensuelle'] ?? details['prime'] ?? 0;
      final dateEffet = details['date_effet'];
      final dateFin = details['date_fin'] ?? details['date_echeance'];
      final bonus = details['bonus'] ?? 'Non défini';

      return SubscriptionRecapWidgets.buildRecapSection(
        'Produit Souscrit',
        Icons.savings,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow(
              'Produit', 'CORIS ÉPARGNE BONUS'),
          SubscriptionRecapWidgets.buildRecapRow('Capital au terme',
              SubscriptionRecapWidgets.formatMontant(capital)),
          SubscriptionRecapWidgets.buildRecapRow(
              'Prime mensuelle', SubscriptionRecapWidgets.formatMontant(prime)),
          SubscriptionRecapWidgets.buildRecapRow('Durée', '15 ans (180 mois)'),
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
          details['duree'] ?? details['duree_contrat'] ?? 'Non définie';
      final uniteDuree =
          details['duree_type'] ?? details['unite_duree'] ?? 'ans';
      final dateEffet = details['date_effet'];
      final dateEcheance = details['date_echeance'];

      return SubscriptionRecapWidgets.buildRecapSection(
        'Détails du Contrat - CORIS ASSURE PRESTIGE',
        Icons.verified_user,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow(
              'Produit', 'CORIS ASSURE PRESTIGE'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Montant du versement initial',
              SubscriptionRecapWidgets.formatMontant(versementInitial),
              'Durée du contrat',
              '$duree $uniteDuree'),
          SubscriptionRecapWidgets.buildRecapRow('Capital décès',
              SubscriptionRecapWidgets.formatMontant(capitalDeces)),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Prime décès annuelle',
              SubscriptionRecapWidgets.formatMontant(primeDecesAnnuelle),
              'Périodicité',
              details['periodicite'] ?? 'Annuel'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              dateEffet != null
                  ? SubscriptionRecapWidgets.formatDate(dateEffet)
                  : 'Non définie',
              'Date d\'échéance',
              dateEcheance != null
                  ? SubscriptionRecapWidgets.formatDate(dateEcheance)
                  : 'Non définie'),
        ],
      );
    }

    // Pour MON BON PLAN CORIS
    if (productType.contains('bon') && productType.contains('plan')) {
      final montantCotisation = details['montant_cotisation'] ?? 0;
      final periodicite = details['periodicite'] ?? 'Non définie';
      final dateEffet = details['date_effet'];

      return SubscriptionRecapWidgets.buildRecapSection(
        'Détails du Contrat - MON BON PLAN CORIS',
        Icons.savings,
        vertSucces,
        [
          SubscriptionRecapWidgets.buildRecapRow(
              'Produit', 'MON BON PLAN CORIS'),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Périodicité',
              periodicite,
              'Date d\'effet',
              dateEffet != null
                  ? SubscriptionRecapWidgets.formatDate(dateEffet)
                  : 'Non définie'),
          SubscriptionRecapWidgets.buildRecapRow(
              'Montant de la cotisation ${periodicite.toLowerCase()}',
              SubscriptionRecapWidgets.formatMontant(montantCotisation)),
        ],
      );
    }

    // Pour FLEX EMPRUNTEUR
    if (productType.contains('flex') || productType.contains('emprunteur')) {
      final typePret = details['type_pret'] ?? 'Non défini';
      final capital = details['capital_garanti'] ?? details['capital'] ?? 0;
      final duree = details['duree'] ?? 'Non définie';
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
              'Produit', 'FLEX EMPRUNTEUR', 'Type de prêt', typePret),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
            'Capital à garantir',
            SubscriptionRecapWidgets.formatMontant(capital),
            'Durée',
            '$duree $dureeType',
          ),
          if (dateEffet != null && dateEcheance != null)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Date d\'effet',
              SubscriptionRecapWidgets.formatDate(dateEffet),
              'Date d\'échéance',
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
              'Date d\'échéance',
              SubscriptionRecapWidgets.formatDate(dateEcheance),
              '',
              '',
            ),
          SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Prime annuelle estimée',
              SubscriptionRecapWidgets.formatMontant(prime),
              '',
              ''),
          if (garantiePrevoyance && garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie Prévoyance',
              SubscriptionRecapWidgets.formatMontant(capitalPrevoyance),
              'Garantie Perte d\'emploi',
              SubscriptionRecapWidgets.formatMontant(capitalPerteEmploi),
            ),
          if (garantiePrevoyance && !garantiePerteEmploi)
            SubscriptionRecapWidgets.buildCombinedRecapRow(
              'Garantie Prévoyance',
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

    // Section par défaut pour les autres produits
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
          SubscriptionRecapWidgets.buildRecapRow('Durée',
              '${details['duree']} ${details['duree_type'] ?? 'mois'}'),
        if (details['date_effet'] != null)
          SubscriptionRecapWidgets.buildRecapRow('Date d\'effet',
              SubscriptionRecapWidgets.formatDate(details['date_effet'])),
      ],
    );
  }

  /// Construit les sections des membres pour CORIS SOLIDARITÉ
  /// Retourne une liste de widgets pour Conjoints, Enfants, Ascendants
  List<Widget> _buildSolidariteMembersSection() {
    final details = _getSubscriptionDetails();
    final productType = _getProductType().toLowerCase();

    // Ne rien afficher si ce n'est pas CORIS SOLIDARITÉ
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
      sections.add(const SizedBox(height: 20));
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
      sections.add(const SizedBox(height: 20));
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
      sections.add(const SizedBox(height: 20));
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
        'Non renseigné';
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: bleuCoris,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateNaissance != null
                ? 'Date de naissance: ${SubscriptionRecapWidgets.formatDate(dateNaissance)}'
                : 'Date de naissance: Non renseignée',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: grisTexte,
              fontSize: 12,
            ),
          ),
          if (lieuNaissance != null) ...[
            const SizedBox(height: 2),
            Text(
              'Lieu de naissance: $lieuNaissance',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: grisTexte,
                fontSize: 12,
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

  /// 💳 Construit la section Mode de Paiement
  Widget _buildPaymentMethodSection() {
    final details = _getSubscriptionDetails();

    // Utiliser la nouvelle méthode avec icônes et couleurs
    return SubscriptionRecapWidgets.buildPaymentModeSection(details);
  }

  List<Map<String, dynamic>> _extractDocumentsList(dynamic raw) {
    final docs = <Map<String, dynamic>>[];

    void addDoc(dynamic path, {dynamic label}) {
      if (path == null) return;
      final normalizedPath = path.toString().trim();
      if (normalizedPath.isEmpty || normalizedPath.toLowerCase() == 'null')
        return;
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
    developer.log('_subscriptionData: ${_subscriptionData}');
    developer
        .log('_subscriptionData keys: ${_subscriptionData?.keys.toList()}');
    developer.log('souscriptiondata: $souscriptiondata');
    developer.log('souscriptiondata type: ${souscriptiondata?.runtimeType}');
    if (souscriptiondata is Map) {
      developer.log('souscriptiondata keys: ${souscriptiondata.keys.toList()}');
    }
    developer.log('Final pieceIdentite trouvé: $pieceIdentite');

    final hasDocument = pieceIdentite != null &&
        pieceIdentite.toString().isNotEmpty &&
        pieceIdentite != 'Non téléchargée' &&
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

    // Ne plus ajouter manuellement pieceIdentite - elle devrait déjà être incluse dans piece_identite_documents
    // Si elle n'y est pas, c'est un problème de données côté serveur
// Ajouter pieceIdentite seulement si elle n'existe pas déjà
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
    // Déduplication stricte par nom de fichier
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
        documentName == 'Non téléchargée') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: blanc, size: 20),
              const SizedBox(width: 12),
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
                              productType.contains('sérénité');
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
                            const SizedBox(width: 8),
                            Text(
                              'Imprimer',
                              style: TextStyle(
                                color: bleuCoris,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                            const SizedBox(width: 8),
                            Text(
                              'Modifier',
                              style: TextStyle(
                                color: orangeWarning,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
            const SizedBox(height: 12),
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
                      const SizedBox(width: 10),
                      Text(
                        'Accepter et Payer',
                        style: TextStyle(
                          color: blanc,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
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

    // Rediriger vers la page de souscription appropriée avec les données
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
        productType.contains('sérénité')) {
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
        productType.contains('solidarité')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'La modification de CORIS SOLIDARITÉ sera bientôt disponible'),
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
        productType.contains('épargne')) {
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
    } else if (productType.contains('assuré prestige') ||
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.payment, color: bleuCoris, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Options de Paiement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: bleuCoris,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPaymentOptionWithImage(
                'Wave',
                'assets/images/icone_wave.jpeg',
                Colors.blue,
                'Paiement mobile sécurisé',
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
                  print('❌ Erreur chargement image: $imagePath - $error');
                  return Icon(Icons.image_not_supported,
                      size: 32, color: Colors.grey);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: bleuCoris,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: grisTexte,
                      fontSize: 12,
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
      debugPrint('[TEST MODE] Montant forcé à 10 XOF au lieu de $amount');
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
                'Impossible de démarrer le paiement Wave.'),
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
                'Réponse Wave incomplète (URL/session). Détail: ${createResult['message'] ?? 'n/a'}'),
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
              '🔄 Paiement Wave lancé. Retournez à l\'application après paiement pour confirmation automatique.'),
          backgroundColor: bleuCoris,
          duration: Duration(seconds: 5),
        ),
      );

      // 🔄 POLLING AMÉLIORÉ: Essayer pendant 2 minutes (40 tentatives × 3s)
      // Cela permet à l'utilisateur de compléter le paiement même s'il prend du temps
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
              '⏳ Tentative ${attempt + 1}/40: Statut non récupéré, réessai...');
          continue;
        }

        final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
        final status = (statusData['status'] ?? '').toString().toUpperCase();

        debugPrint('📊 Tentative ${attempt + 1}/40: Statut Wave = $status');

        if (status == 'SUCCESS') {
          if (!mounted) return;

          // 🎉 PAIEMENT RÉUSSI - Convertir la proposition en contrat + envoyer SMS
          try {
            final confirmResult =
                await waveService.confirmWavePayment(widget.subscriptionId);

            if (confirmResult['success'] == true) {
              if (!mounted) return;

              // ✅ Afficher le message de succès avec les détails
              final confirmData =
                  confirmResult['data'] as Map<String, dynamic>? ?? {};
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Paiement Wave confirmé avec succès !',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Montant: ${confirmData['montant']} FCFA',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '🎉 Votre proposition est maintenant un CONTRAT valide.',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '📱 Un SMS de confirmation a été envoyé.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  backgroundColor: vertSucces,
                  duration: const Duration(seconds: 8),
                ),
              );

              // Recharger les données pour afficher le nouveau statut
              await _loadSubscriptionData();
              return;
            } else {
              // La confirmation backend peut être asynchrone si l'utilisateur revient vite depuis Wave.
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
              content: Text('❌ Paiement Wave échoué ou annulé.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }

        // Si PENDING, continuer à attendre
        if (status == 'PENDING') {
          debugPrint('⏳ Paiement en attente (PENDING), continue le polling...');
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

    // Ne pas afficher de message transitoire ici pour éviter les faux positifs perçus comme erreur.
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
                content: Text('✅ Paiement CORIS Money effectué avec succès.'),
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
              'Orange Money sera branché juste après Wave. Utilisez Wave ou CORIS Money.'),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Paiement via $paymentMethod - Fonctionnalité en cours de développement'),
            ),
          ],
        ),
        backgroundColor: orangeWarning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Récupère les réponses au questionnaire médical depuis questionnaire_reponses
  List<Map<String, dynamic>> _getQuestionnaireMedicalReponses() {
    // Essayer d'abord le champ questionnaire_reponses (retourné par le serveur)
    final reponses = _subscriptionData?['questionnaire_reponses'];

    print('🔍 _getQuestionnaireMedicalReponses() appelé');
    print('  - _subscriptionData type: ${_subscriptionData.runtimeType}');
    print('  - reponses (questionnaire_reponses): $reponses');

    if (reponses == null) {
      print(
          '  ⚠️ questionnaire_reponses est null, cherche dans souscriptiondata...');
      // Fallback: chercher dans souscriptiondata
      final souscriptiondata = _subscriptionData?['souscriptiondata'];
      if (souscriptiondata != null &&
          souscriptiondata['questionnaire_medical_reponses'] != null) {
        final fallback = souscriptiondata['questionnaire_medical_reponses'];
        print(
            '  ✅ Trouvé questionnaire_medical_reponses dans souscriptiondata: $fallback');
        if (fallback is List) {
          return List<Map<String, dynamic>>.from(
            fallback.map((r) => r is Map ? Map<String, dynamic>.from(r) : {}),
          );
        }
      }
      print('  ❌ Aucun questionnaire trouvé');
      return [];
    }

    print('  ✅ questionnaire_reponses trouvé: ${reponses.runtimeType}');

    // Si c'est déjà une liste, la retourner
    if (reponses is List) {
      print('  ✅ Format liste détecté: ${reponses.length} réponses');
      reponses.forEach((r) {
        if (r is Map && r['libelle'] != null) {
          print(
              '    - Q: "${r['libelle']}" → R: ${r['reponse_oui_non'] ?? r['reponse_text'] ?? "N/A"}');
        }
      });
      return List<Map<String, dynamic>>.from(
        reponses.map((r) => r is Map ? Map<String, dynamic>.from(r) : {}),
      );
    }

    // Si le backend renvoie un Map (index => objet), le convertir en liste
    print('  ⚠️ Format inattendu: ${reponses.runtimeType}');
    if (reponses is Map) {
      print('  🔄 Conversion Map → List...');
      return reponses.values
          .where((v) => v != null)
          .map((v) =>
              v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{})
          .toList();
    }

    // Pas de format reconnu -> retourner liste vide
    return [];
  }

  /// Tentative de récupération des questions depuis les données chargées
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
      print('⚠️ _getQuestionnaireMedicalQuestions erreur: $e');
    }
    return [];
  }

  // Fin de la classe PropositionDetailPageState
}
