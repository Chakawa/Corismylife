import 'package:flutter/material.dart';
import 'package:mycorislife/services/subscription_service.dart';
import 'package:mycorislife/models/contrat.dart';
import 'package:mycorislife/features/client/presentation/screens/contrat_detail_page.dart';
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/services/wave_payment_handler.dart';

/// ============================================
/// PAGE DES CONTRATS
/// ============================================
/// Cette page affiche la liste de tous les contrats actifs
/// de l'utilisateur. Un contrat est une proposition qui a
/// été payée et est maintenant active.
///
/// Fonctionnalités:
/// - Affichage de la liste des contrats
/// - Filtrage par type de produit
/// - Visualisation des détails d'un contrat
/// - Paiement des primes (mensuelles, annuelles, etc.)
/// - Téléchargement du PDF du contrat
class MesContratsPage extends StatefulWidget {
  const MesContratsPage({super.key});

  @override
  State<MesContratsPage> createState() => _MesContratsPageState();
}

class _MesContratsPageState extends State<MesContratsPage>
    with TickerProviderStateMixin {
  // ===================================
  // SERVICES ET DONNÉES
  // ===================================
  final SubscriptionService _service = SubscriptionService();
  List<Contrat> contrats = [];
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
    _setupAnimations();
    _loadContrats();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _loadContrats() async {
    setState(() => isLoading = true);
    try {
      final data = await _service.getContrats();
      setState(() {
        contrats = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ===================================
  // FILTRES
  // ===================================
  List<String> get productFilters {
    final types = {'Tous'};
    for (var contrat in contrats) {
      if (contrat.nomProduit != null && contrat.nomProduit!.isNotEmpty) {
        types.add(contrat.nomProduit!);
      } else {
        types.add('Sans type');
      }
    }
    return types.toList();
  }

  List<Contrat> get filteredContrats {
    if (selectedFilter == 'Tous') return contrats;
    return contrats.where((c) => c.nomProduit == selectedFilter).toList();
  }

  // ===================================
  // BUILD
  // ===================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: isLoading
          ? _buildLoadingState()
          : contrats.isEmpty
              ? _buildEmptyState()
              : _buildContractsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2563EB),
      title: const Text(
        'Mes Contrats',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      automaticallyImplyLeading: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${filteredContrats.length} contrat${filteredContrats.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des contrats...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de contrats actifs',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Filtres
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  for (final filter in productFilters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: selectedFilter == filter,
                        onSelected: (selected) {
                          setState(() => selectedFilter = filter);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: selectedFilter == filter
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selectedFilter == filter
                                ? const Color(0xFF2563EB)
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // List de contrats
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final contrat = filteredContrats[index];
                  return _buildContractCard(contrat);
                },
                childCount: filteredContrats.length,
              ),
            ),
          ),

          // Padding bottom
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Contrat contrat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                builder: (context) => ContratDetailPage(
                  subscriptionId: contrat.id,
                  contractNumber: contrat.id.toString(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du contrat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contrat.nomProduit ?? 'Sans titre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Contrat #${contrat.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Actif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Montant principal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prime:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_extractAmount(contrat).toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Boutons d'action
                Row(
                  children: [
                    // Bouton Détails
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContratDetailPage(
                                subscriptionId: contrat.id,
                                contractNumber: contrat.id.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bouton Payer Prime
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Payer Prime'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () =>
                            _showPaymentMethodDialog(contrat),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================
  // PAIEMENT
  // ===================================
  void _showPaymentMethodDialog(Contrat contrat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Méthode de paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Image.asset(
                'assets/images/corismoney_logo.png',
                height: 24,
              ),
              title: const Text('CORIS Money'),
              onTap: () {
                Navigator.pop(context);
                _processPayment(contrat, 'CORIS Money');
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/images/icone_wave.jpeg',
                height: 24,
              ),
              title: const Text('Wave'),
              onTap: () {
                Navigator.pop(context);
                _processPayment(contrat, 'Wave');
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/images/OrangeMoney.png',
                height: 24,
              ),
              title: const Text('Orange Money'),
              onTap: () {
                Navigator.pop(context);
                _processPayment(contrat, 'Orange Money');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment(Contrat contrat, String paymentMethod) async {
    final montant = _extractAmount(contrat);

    if (paymentMethod == 'CORIS Money') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CorisMoneyPaymentModal(
          subscriptionId: contrat.id,
          montant: montant,
          description: 'Paiement prime ${contrat.nomProduit} #${contrat.id}',
          onPaymentSuccess: () {
            // Rafraîchir la liste après paiement réussi
            _loadContrats();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Prime payée avec succès !'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
      );
    } else if (paymentMethod == 'Wave') {
      // Démarrer le paiement Wave
      try {
        await WavePaymentHandler.startPayment(
          context,
          subscriptionId: contrat.id,
          amount: montant,
          description: 'Paiement prime ${contrat.nomProduit} #${contrat.id}',
          onSuccess: () {
            _loadContrats();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Paiement Wave réussi !'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 3),
              ),
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Wave: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Orange Money - à implémenter
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$paymentMethod sera disponible bientôt'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  double _extractAmount(Contrat contrat) {
    return contrat.prime ?? 0.0;
  }
}
