import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/models/subscription.dart';
import 'package:mycorislife/features/client/presentation/screens/proposition_detail_page.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';

/// ============================================
/// PAGE DES PROPOSITIONS
/// ============================================
/// Cette page affiche la liste de toutes les propositions d'assurance
/// de l'utilisateur. Une proposition est une souscription en attente
/// de paiement qui n'a pas encore été transformée en contrat.
///
/// Fonctionnalités:
/// - Affichage de la liste des propositions
/// - Filtrage par type de produit
/// - Visualisation des détails d'une proposition
/// - Paiement direct depuis la liste
/// - Animations fluides lors du chargement
class PropositionsPage extends StatefulWidget {
  const PropositionsPage({super.key});

  @override
  State<PropositionsPage> createState() => _PropositionsPageState();
}

class _PropositionsPageState extends State<PropositionsPage>
    with TickerProviderStateMixin {
  // ===================================
  // SERVICES ET DONNÉES
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
    _animationController.dispose();
    super.dispose();
  }

  /// Charge la liste des propositions depuis l'API
  /// Récupère toutes les souscriptions avec le statut 'proposition'
  Future<void> _loadPropositions() async {
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
    } else {
      return 'ÉPARGNE BONUS';
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
      return Icons.elderly_outlined; // Icône de personne âgée pour retraite
    } else if (produit.toLowerCase().contains('serenite')) {
      return Icons.health_and_safety_outlined;
    } else if (produit.toLowerCase().contains('familis')) {
      return Icons.family_restroom_outlined;
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
    } else {
      return const Color(0xFF002B6B); // Bleu par défaut
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
          const Text(
            "Mes Propositions",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            "${propositions.length} proposition${propositions.length > 1 ? 's' : ''}",
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 13,
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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () {
            // Retour à la page d'accueil client
            Navigator.pushNamedAndRemoveUntil(
                context, '/client_home', (route) => false);
          },
        ),
      ),
      actions: [
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
            icon: const Icon(Icons.tune, color: Colors.white, size: 20),
            onPressed: _showFilterMenu,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
          ),
          SizedBox(height: 16),
          Text(
            "Chargement des propositions...",
            style: TextStyle(
              fontSize: 16,
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
                    child: const Icon(
                      Icons.description_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                "Aucune proposition",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Vos propositions d'assurance\napparaîtront ici",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
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
            child: _buildPropositionsList(),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => selectedFilter = 'Tous'),
                  child: const Icon(
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
                // Header avec icône, numéro et badge statut
                Row(
                  children: [
                    // Icône avec effet glassmorphism et couleur selon produit
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getProductIconColor(subscription.produitNom),
                            Color.lerp(_getProductIconColor(subscription.produitNom), Colors.black, 0.2)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _getProductIconColor(subscription.produitNom).withAlpha(40),
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
                    const SizedBox(width: 16),
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
                                  style: const TextStyle(
                                    fontSize: 17,
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
                                    const SizedBox(width: 6),
                                    const Text(
                                      'En attente',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Badge produit redesigné
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
                              style: const TextStyle(
                                fontSize: 11,
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

                const SizedBox(height: 18),

                // Divider élégant
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

                const SizedBox(height: 18),

                // Section informations et actions
                Row(
                  children: [
                    // Date de création avec icône
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
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Color(0xFF002B6B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Créée le',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(subscription.dateCreation),
                                    style: const TextStyle(
                                      fontSize: 12,
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
                    
                    const SizedBox(width: 12),
                    
                    // Bouton PDF avec design élégant
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
                                builder: (_) => PdfViewerPage(
                                    subscriptionId: subscription.id),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
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

                const SizedBox(height: 14),

                // Bouton "Payer maintenant" redesigné en vert
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
                              child: const Icon(
                                Icons.payment_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Payer maintenant',
                              style: TextStyle(
                                fontSize: 15,
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
                              child: const Icon(
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

  void _handlePropositionTap(Subscription subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropositionDetailPage(
          subscriptionId: subscription.id,
          propositionNumber:
              _getPropositionNumber(propositions.indexOf(subscription)),
        ),
      ),
    );
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header avec icône et titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF002B6B),
                          Color(0xFF003D8F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF002B6B).withAlpha(40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options de Paiement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choisissez votre méthode',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              // Options de paiement
              _buildPaymentOption(
                'Wave',
                Icons.waves_rounded,
                const Color(0xFF0066FF),
                'Paiement mobile sécurisé',
                () => _processPayment(subscription, 'Wave'),
              ),
              const SizedBox(height: 14),
              _buildPaymentOption(
                'Orange Money',
                Icons.phone_android_rounded,
                const Color(0xFFFF6600),
                'Paiement mobile Orange',
                () => _processPayment(subscription, 'Orange Money'),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
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
        border: Border.all(
          color: const Color(0xFFE8EEF4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icône avec gradient
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.white, 0.2)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Flèche
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF002B6B),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _processPayment(Subscription subscription, String paymentMethod) {
    Navigator.pop(context); // Fermer le bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.payment, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Paiement via $paymentMethod en cours...'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );

    // TODO: Implémenter la logique de paiement réelle
    // Puis rediriger vers la page d'accueil après paiement réussi
  }

  void _showFilterMenu() {
    final filters = [
      'Tous',
      'CORIS SOLIDARITÉ',
      'FLEX EMPRUNTEUR',
      'CORIS ÉTUDE',
      'CORIS RETRAITE',
      'CORIS SÉRÉNITÉ',
      'CORIS FAMILIS',
      'ÉPARGNE BONUS'
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Filtrer par type",
                  style: TextStyle(
                    fontSize: 18,
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
                    children: filters.map((filter) => ListTile(
                          leading: filter == 'Tous'
                              ? const Icon(Icons.list_alt, color: Color(0xFF64748B))
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
                        )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
