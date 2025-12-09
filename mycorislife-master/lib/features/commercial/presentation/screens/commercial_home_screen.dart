import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/commercial_service.dart';
import 'mes_clients_screen.dart';
import 'mes_commissions_screen.dart';

class CommercialHomePage extends StatefulWidget {
  const CommercialHomePage({super.key});

  @override
  State<CommercialHomePage> createState() => _CommercialHomePageState();
}

class _CommercialHomePageState extends State<CommercialHomePage> {
  int _selectedIndex = 0;
  static const bleuCoris = Color(0xFF002B6B);
  static const rougeCoris = Color(0xFFE30613);

  // Gestion des onglets produits
  String _selectedProductTab =
      'particuliers'; // 'particuliers' ou 'entreprises'

  // Statistiques
  int _nbClients = 0;
  int _nbContrats = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoadingStats = true;
      });

      final stats = await CommercialService.getStats();

      if (mounted) {
        setState(() {
          _nbClients = stats['nbClients'] ?? 0;
          _nbContrats = stats['nbContrats'] ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
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

  // Produits pour particuliers
  final List<Map<String, dynamic>> _produitsParticuliers = [
    {
      'image': 'assets/images/etudee.png',
      'title': 'CORIS ETUDE',
      'route': '/etude',
      'isIcon': false,
    },
    {
      'image': 'assets/images/epargnee.png',
      'title': 'CORIS EPARGNE BONUS',
      'route': '/epargne',
      'isIcon': false,
    },
    {
      'image': 'assets/images/serenite.png',
      'title': 'CORIS SERENITE PLUS',
      'route': '/serenite',
      'isIcon': false,
    },
    {
      'image': 'assets/images/solidarite.png',
      'title': 'CORIS SOLIDARITE',
      'route': '/solidarite',
      'isIcon': false,
    },
    {
      'image': 'assets/images/familis.png',
      'title': 'CORIS FAMILIS',
      'route': '/familis',
      'isIcon': false,
    },
    // PRODUITS AFFICHÉS (souscription désactivée dans les détails)
    {
      'image': 'assets/images/emprunteur.png',
      'title': 'FLEX EMPRUNTEUR',
      'route': '/flex',
      'isIcon': false,
    },
    {
      'image': 'assets/images/bon_plan_coris.jpg',
      'title': 'MON BON PLAN CORIS',
      'route': '/bon-plan',
      'isIcon': false,
    },
    {
      'image': 'assets/images/coris_assure_prestige.jpg',
      'title': 'CORIS ASSURE PRESTIGE',
      'route': '/assure-prestige',
      'isIcon': false,
    },
  ];

  // Produits pour entreprises
  final List<Map<String, dynamic>> _produitsEntreprises = [
    {
      'image': 'assets/images/IFC_indemnite_fin_carriere.jpg',
      'title': 'IFC - Indemnité Fin de Carrière',
      'route': '/ifc',
      'isIcon': false,
    },
    {
      'image': 'assets/images/retraite_complementaire_entreprise.jpg',
      'title': 'Retraite Complementaire Entreprise',
      'route': '/retraite-collective',
      'isIcon': false,
    },
    {
      'image': 'assets/images/prevoyance_social_entreprise.jpg',
      'title': 'Prevoyance Sociale Entreprise',
      'route': '/prevoyance-collective',
      'isIcon': false,
    },
    {
      'image': 'assets/images/homme_cle.jpg',
      'title': 'Homme Clé',
      'route': '/homme-cle',
      'isIcon': false,
    },
  ];

  final List<Widget> _pages = [
    SizedBox.shrink(),
    const MesClientsScreen(),
    SizedBox.shrink(),
    const MesCommissionsScreen(),
    SizedBox.shrink(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Si on essaie de revenir en arrière, rester sur la page d'accueil
        // Ne pas permettre de revenir à la page de connexion
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          // Si on ne peut pas revenir en arrière, rester sur la page d'accueil
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: bleuCoris,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'MyCorisLife',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
        ),
        body: _selectedIndex == 0 ? _buildHomePage() : _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: rougeCoris,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 11,
          onTap: (int index) {
            if (index == 2) {
              Navigator.pushNamed(context, '/souscription');
            } else if (index == 4) {
              Navigator.pushNamed(context, '/profileCommercial');
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Accueil",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Mes Clients",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_add),
              label: "Souscrire",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on),
              label: "Mes Commissions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(screenWidth, screenHeight),
          const SizedBox(height: 25),

          // Simulation
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bleuCoris, bleuCoris.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: bleuCoris.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, '/simulation');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calculate,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Faire une simulation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Simulez rapidement pour vos clients',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Voir mes contrats
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bleuCoris, bleuCoris.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: bleuCoris.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, '/mes_contrats_commercial');
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voir mes contrats',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Consultez tous vos contrats',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Boutons onglets Particuliers / Entreprises
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedProductTab = 'particuliers';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedProductTab == 'particuliers'
                          ? bleuCoris
                          : Colors.grey[300],
                      foregroundColor: _selectedProductTab == 'particuliers'
                          ? Colors.white
                          : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _selectedProductTab == 'particuliers' ? 4 : 1,
                    ),
                    child: Text(
                      'Nos produits aux particuliers',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedProductTab = 'entreprises';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedProductTab == 'entreprises'
                          ? bleuCoris
                          : Colors.grey[300],
                      foregroundColor: _selectedProductTab == 'entreprises'
                          ? Colors.white
                          : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _selectedProductTab == 'entreprises' ? 4 : 1,
                    ),
                    child: Text(
                      'Nos produits aux entreprises',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: screenWidth > 400 ? 2.8 : 2.2,
              ),
              itemCount: _selectedProductTab == 'particuliers'
                  ? _produitsParticuliers.length
                  : _produitsEntreprises.length,
              itemBuilder: (context, index) {
                final products = _selectedProductTab == 'particuliers'
                    ? _produitsParticuliers
                    : _produitsEntreprises;
                final product = products[index];

                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, product['route']);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (product['isIcon'] == true)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: (product['iconColor'] as Color)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              product['icon'],
                              size: 24,
                              color: product['iconColor'],
                            ),
                          )
                        else
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                product['image'],
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            product['title'],
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              fontWeight: FontWeight.w600,
                              color: bleuCoris,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bleuCoris,
            bleuCoris.withValues(alpha: 0.9),
            const Color(0xFF1E4A8C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rougeCoris.withValues(alpha: 0.2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.business_center,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mon Espace',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'CORIS ASSURANCES VIE CI',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/liste_clients');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _buildQuickStat(
                          icon: Icons.people_outline,
                          value:
                              _isLoadingStats ? "..." : _nbClients.toString(),
                          label: "Clients",
                          screenWidth: screenWidth,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/contrats_actifs');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _buildQuickStat(
                          icon: Icons.assignment_turned_in,
                          value:
                              _isLoadingStats ? "..." : _nbContrats.toString(),
                          label: "Contrats actifs",
                          screenWidth: screenWidth,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String value,
    required String label,
    required double screenWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.042,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: screenWidth * 0.032,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
