import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:flutter/services.dart';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/models/subscription.dart';
import 'package:mycorislife/features/client/presentation/screens/proposition_detail_page.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/services/wave_payment_handler.dart';

/// ============================================
/// PAGE DES PROPOSITIONS
/// ============================================
/// Cette page affiche la liste de toutes les propositions d'assurance
/// de l'utilisateur. Une proposition est une souscription en attente
/// de paiement qui n'a pas encore Ã©tÃ© transformÃ©e en contrat.
///
/// FonctionnalitÃ©s:
/// - Affichage de la liste des propositions
/// - Filtrage par type de produit
/// - Visualisation des dÃ©tails d'une proposition
/// - Paiement direct depuis la liste
/// - Animations fluides lors du chargement
class PropositionsPage extends StatefulWidget {
  const PropositionsPage({super.key});

  @override
  State<PropositionsPage> createState() => _PropositionsPageState();
}

class _PropositionsPageState extends State<PropositionsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ===================================
  // SERVICES ET DONNÃ‰ES
  // ===================================
  final SubscriptionService _service = SubscriptionService();
  List<Subscription> propositions = [];
  bool isLoading = true;
  String selectedFilter = 'Tous';

  // ===================================
  // ANIMATIONS
  // ===================================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ===================================
  // INITIALISATION
  // ===================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Configuration de l'animation de fondu d'apparition
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    // Chargement initial des propositions
    _loadPropositions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadPropositions();
    }
  }

  /// Charge la liste des propositions depuis l'API
  /// RÃ©cupÃ¨re toutes les souscriptions avec le statut 'proposition'
  Future<void> _loadPropositions() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _service.getPropositions();
      if (!mounted) return;

      setState(() {
        propositions = result;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;

      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Date inconnue';
      }

      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return "Date inconnue";
    }
  }

  String _getPropositionNumber(int index) {
    return "2025-13-CA${(index + 7075).toString().padLeft(3, '0')}";
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
      return 'Ã‰PARGNE BONUS';
    } else {
      return 'ASSURANCE VIE';
    }
  }

  IconData _getProductIcon(String produit) {
    if (produit.toLowerCase().contains('solidarite')) {
      return Icons.people_outline;
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return Icons.home_outlined;
    } else if (produit.toLowerCase().contains('etude')) {
      return Icons.school_outlined;
    } else if (produit.toLowerCase().contains('retraite')) {
      return Icons.elderly_outlined; // IcÃ´ne de personne Ã¢gÃ©e pour retraite
    } else if (produit.toLowerCase().contains('serenite')) {
      return Icons.health_and_safety_outlined;
    } else if (produit.toLowerCase().contains('familis')) {
      return Icons.family_restroom_outlined;
    } else if (produit.toLowerCase().contains('assure') ||
        produit.toLowerCase().contains('prestige')) {
      return Icons.verified_user_outlined;
    } else if (produit.toLowerCase().contains('bon') &&
        produit.toLowerCase().contains('plan')) {
      return Icons.trending_up_outlined;
    } else if (produit.toLowerCase().contains('epargne') ||
        produit.toLowerCase().contains('bonus')) {
      return Icons.savings_outlined;
    } else {
      return Icons.security_outlined;
    }
  }

  Color _getProductIconColor(String produit) {
    if (produit.toLowerCase().contains('solidarite')) {
      return const Color(0xFF002B6B); // Bleu
    } else if (produit.toLowerCase().contains('emprunteur')) {
      return const Color(0xFFEF4444); // Rouge
    } else if (produit.toLowerCase().contains('etude')) {
      return const Color(0xFF8B5CF6); // Violet
    } else if (produit.toLowerCase().contains('retraite')) {
      return const Color(0xFF10B981); // Vert
    } else if (produit.toLowerCase().contains('serenite')) {
      return const Color(0xFFF59E0B); // Orange
    } else if (produit.toLowerCase().contains('familis')) {
      return const Color(0xFFEC4899); // Rose
    } else if (produit.toLowerCase().contains('assure') ||
        produit.toLowerCase().contains('prestige')) {
      return const Color(0xFF059669); // Vert Ã©meraude pour Prestige
    } else if (produit.toLowerCase().contains('bon') &&
        produit.toLowerCase().contains('plan')) {
      return const Color(0xFF8B5CF6); // Violet pour Bon Plan
    } else if (produit.toLowerCase().contains('epargne') ||
        produit.toLowerCase().contains('bonus')) {
      return const Color(0xFF3B82F6); // Bleu
    } else {
      return const Color(0xFF002B6B); // Bleu par dÃ©faut
    }
  }

  List<Subscription> get filteredPropositions {
    if (selectedFilter == 'Tous') {
      return propositions;
    }
    return propositions
        .where((sub) => _getBadgeText(sub.produitNom) == selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: isLoading
          ? _buildLoadingState()
          : propositions.isEmpty
              ? _buildEmptyState()
              : _buildPropositionsContent(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF002B6B),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 70,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF002B6B),
              Color(0xFF003A85),
            ],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Mes Propositions",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: context.sp(20),
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            "${propositions.length} proposition${propositions.length > 1 ? 's' : ''}",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: context.sp(13),
              color: Color(0xCCFFFFFF),
            ),
          ),
        ],
      ),
      leading: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0x33FFFFFF),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () {
            // Retour Ã  la page d'accueil client
            Navigator.pushNamedAndRemoveUntil(
                context, '/client_home', (route) => false);
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: 'Actualiser',
            onPressed: _loadPropositions,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: Colors.white, size: 20),
            onPressed: _showFilterMenu,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
          ),
          SizedBox(height: context.r(16)),
          Text(
            "Chargement des propositions...",
            style: TextStyle(
              fontSize: context.sp(16),
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration avec cercles concentriques
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF002B6B).withAlpha(15),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF002B6B).withAlpha(30),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF002B6B),
                          Color(0xFF003D8F),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.r(32)),
              Text(
                "Aucune proposition",
                style: TextStyle(
                  fontSize: context.sp(24),
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.r(12)),
              Text(
                "Vos propositions d'assurance\napparaÃ®tront ici",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.sp(16),
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropositionsContent() {
    return Column(
      children: [
        if (selectedFilter != 'Tous') _buildFilterChip(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _loadPropositions,
              child: _buildPropositionsList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF002B6B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedFilter,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: context.r(8)),
                GestureDetector(
                  onTap: () => setState(() => selectedFilter = 'Tous'),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropositionsList() {
    final filtered = filteredPropositions;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(bottom: 8),
            child: _buildModernPropositionCard(filtered[index], index),
          );
        },
      ),
    );
  }

  Widget _buildModernPropositionCard(Subscription subscription, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFFAFBFC),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002B6B).withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF002B6B).withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF002B6B).withAlpha(50),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePropositionTap(subscription),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec icÃ´ne, numÃ©ro et badge statut
                Row(
                  children: [
                    // IcÃ´ne avec effet glassmorphism et couleur selon produit
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getProductIconColor(subscription.produitNom),
                            Color.lerp(
                                _getProductIconColor(subscription.produitNom),
                                Colors.black,
                                0.2)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _getProductIconColor(subscription.produitNom)
                                .withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getProductIcon(subscription.produitNom),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    SizedBox(width: context.r(16)),
                    // Informations principales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getPropositionNumber(index),
                                  style: TextStyle(
                                    fontSize: context.sp(17),
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              // Badge statut
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: context.r(6)),
                                    Text(
                                      'En attente',
                                      style: TextStyle(
                                        fontSize: context.sp(11),
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.r(6)),
                          // Badge produit redesignÃ©
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF002B6B).withAlpha(20),
                                  const Color(0xFF002B6B).withAlpha(10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF002B6B).withAlpha(30),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getBadgeText(subscription.produitNom),
                              style: TextStyle(
                                fontSize: context.sp(11),
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF002B6B),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.r(18)),

                // Divider Ã©lÃ©gant
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE2E8F0).withAlpha(0),
                        const Color(0xFFE2E8F0),
                        const Color(0xFFE2E8F0).withAlpha(0),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: context.r(18)),

                // Section informations et actions
                Row(
                  children: [
                    // Date de crÃ©ation avec icÃ´ne
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE8EEF4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF002B6B).withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Color(0xFF002B6B),
                              ),
                            ),
                            SizedBox(width: context.r(8)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CrÃ©Ã©e le',
                                    style: TextStyle(
                                      fontSize: context.sp(10),
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(subscription.dateCreation),
                                    style: TextStyle(
                                      fontSize: context.sp(12),
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: context.r(12)),

                    // Bouton PDF avec design Ã©lÃ©gant
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF8FAFC),
                            Colors.white,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8EEF4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF002B6B).withAlpha(8),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) {
                                  final prod =
                                      subscription.produitNom.toLowerCase();
                                  final excludeQ = prod.contains('etude') ||
                                      prod.contains('familis') ||
                                      prod.contains('serenite') ||
                                      prod.contains('sÃ©rÃ©nitÃ©');
                                  return PdfViewerPage(
                                      subscriptionId: subscription.id,
                                      excludeQuestionnaire: excludeQ);
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 22,
                              color: Color(0xFF002B6B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.r(14)),

                // Bouton "Payer maintenant" redesignÃ© en vert
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handlePayment(subscription),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.payment_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: context.r(12)),
                            Text(
                              'Payer maintenant',
                              style: TextStyle(
                                fontSize: context.sp(15),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
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
          ),
        ),
      ),
    );
  }

  Future<void> _handlePropositionTap(Subscription subscription) async {
    final paymentCompleted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropositionDetailPage(
          subscriptionId: subscription.id,
          propositionNumber:
              _getPropositionNumber(propositions.indexOf(subscription)),
        ),
      ),
    );

    if (!mounted) return;
    if (paymentCompleted == true) {
      await _loadPropositions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Paiement confirmÃ©. La proposition a Ã©tÃ© retirÃ©e de la liste.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePayment(Subscription subscription) {
    HapticFeedback.lightImpact();

    // Afficher directement les options de paiement
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentBottomSheet(subscription),
    );
  }

  Widget _buildPaymentBottomSheet(Subscription subscription) {
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
                  Icon(Icons.payment, color: const Color(0xFF002B6B), size: 28),
                  SizedBox(width: context.r(12)),
                  Text(
                    'Options de Paiement',
                    style: TextStyle(
                      fontSize: context.sp(22),
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF002B6B),
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
                () => _processPayment(subscription, 'Wave'),
              ),
              // SizedBox(height: context.r(12)),
              // _buildPaymentOptionWithImage(
              //   'Orange Money',
              //   'assets/images/icone_orange_money.jpeg',
              //   Colors.orange,
              //   'Paiement mobile Orange',
              //   () => _processPayment(subscription, 'Orange Money'),
              // ),
              // SizedBox(height: context.r(12)),
              // _buildPaymentOptionWithImage(
              //   'CORIS Money',
              //   'assets/images/icone_corismoney.jpeg',
              //   const Color(0xFF1E3A8A),
              //   'Paiement via CORIS Money',
              //   () => _processPayment(subscription, 'CORIS Money'),
              // ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPaymentOption(
    String title,
    IconData icon,
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                        color: Color(0xFF002B6B),
                        fontSize: context.sp(16)),
                  ),
                  SizedBox(height: context.r(4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: context.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Color(0xFF64748B), size: 16),
          ],
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
          color: const Color(0xFFF8FAFC),
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
                        color: Color(0xFF002B6B),
                        fontSize: context.sp(16)),
                  ),
                  SizedBox(height: context.r(4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: context.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Color(0xFF64748B), size: 16),
          ],
        ),
      ),
    );
  }

  void _processPayment(Subscription subscription, String paymentMethod) async {
    Navigator.pop(context); // Fermer le bottom sheet

    // Si c'est CORIS Money, afficher le modal de paiement
    if (paymentMethod == 'CORIS Money') {
      // Extraire le montant depuis souscriptionData
      final souscriptionData = subscription.souscriptionData;
      double montant = 0.0;

      // Essayer de rÃ©cupÃ©rer le montant selon le produit
      montant = (souscriptionData['prime_totale'] ??
              souscriptionData['montant_total'] ??
              souscriptionData['prime'] ??
              souscriptionData['montant'] ??
              souscriptionData['versement_initial'] ??
              souscriptionData['montant_cotisation'] ??
              souscriptionData['prime_mensuelle'] ??
              souscriptionData['capital'] ??
              0.0)
          .toDouble();
    
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CorisMoneyPaymentModal(
          subscriptionId: subscription.id,
          montant: montant,
          description:
              'Paiement ${subscription.produitNom} #${subscription.id}',
          onPaymentSuccess: () {
            // RafraÃ®chir la liste aprÃ¨s paiement rÃ©ussi
            _loadPropositions();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('âœ… Votre proposition a Ã©tÃ© transformÃ©e en contrat !'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
      );
    } else if (paymentMethod == 'Wave') {
      final souscriptionData = subscription.souscriptionData;
      double montant = 0.0;

      final value = souscriptionData['prime_totale'] ??
          souscriptionData['montant_total'] ??
          souscriptionData['prime'] ??
          souscriptionData['montant'] ??
          souscriptionData['versement_initial'] ??
          souscriptionData['montant_cotisation'] ??
          souscriptionData['prime_mensuelle'] ??
          souscriptionData['capital'] ??
          0.0;

      if (value is num) {
        montant = value.toDouble();
      } else {
        montant = double.tryParse(value.toString()) ?? 0.0;
      }
    
      await WavePaymentHandler.startPayment(
        context,
        subscriptionId: subscription.id,
        amount: montant,
        description: 'Paiement ${subscription.produitNom} #${subscription.id}',
        onSuccess: () async {
          await _loadPropositions();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Paiement Wave confirmÃ©. Votre contrat est maintenant actif.'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    } else {
      // Pour les autres modes de paiement (Wave, Orange Money)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B), // orangeWarning
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.construction, color: Colors.white, size: 24),
                SizedBox(width: context.r(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$paymentMethod bientÃ´t disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: context.sp(14),
                        ),
                      ),
                      SizedBox(height: context.r(4)),
                      Text(
                        'Utilisez CORIS Money pour le moment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.sp(12),
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
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showFilterMenu() {
    final filters = [
      'Tous',
      'CORIS SOLIDARITÃ‰',
      'FLEX EMPRUNTEUR',
      'CORIS Ã‰TUDE',
      'CORIS RETRAITE',
      'CORIS SÃ‰RÃ‰NITÃ‰',
      'CORIS FAMILIS',
      'CORIS ASSURE PRESTIGE',
      'MON BON PLAN CORIS',
      'Ã‰PARGNE BONUS'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Filtrer par type",
                  style: TextStyle(
                    fontSize: context.sp(18),
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: filters
                        .map((filter) => ListTile(
                              leading: filter == 'Tous'
                                  ? Icon(Icons.list_alt,
                                      color: Color(0xFF64748B))
                                  : Icon(
                                      filter == selectedFilter
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: filter == selectedFilter
                                          ? const Color(0xFF002B6B)
                                          : const Color(0xFF64748B),
                                    ),
                              title: Text(
                                filter,
                                style: TextStyle(
                                  color: filter == selectedFilter
                                      ? const Color(0xFF002B6B)
                                      : const Color(0xFF0F172A),
                                  fontWeight: filter == selectedFilter
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                setState(() => selectedFilter = filter);
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
              SizedBox(height: context.r(20)),
            ],
          ),
        ),
      ),
    );
  }
}

