import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mycorislife/services/notification_service.dart';
import 'package:mycorislife/features/client/presentation/screens/notifications_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  // Nombre de notifications non lues
  int _unreadNotificationsCount = 0;

  static const bleuCoris = Color(0xFF002B6B);
  static const rougeCoris = Color(0xFFE30613);

  final List<Map<String, String>> _carouselData = [
    {
      'title': 'CORIS ETUDE',
      'subtitle': 'Investissez dans l\'éducation',
      'description': 'Financement des études supérieures',
      'image': 'assets/images/etude.png',
      'route': '/etude',
    },
    {
      'title': 'CORIS RETRAITE',
      'subtitle': 'Préparez votre retraite sereinement',
      'description': 'Complément retraite personnalisé',
      'image': 'assets/images/retraite.png',
      'route': '/retraite',
    },
    {
      'title': 'CORIS ÉPARGNE BONUS',
      'subtitle': 'Épargnez intelligemment',
      'description': 'Solutions d\'épargne adaptées à vos besoins',
      'image': 'assets/images/epargne.png',
      'route': '/epargne',
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'image': 'assets/images/etudee.png',
      'title': 'CORIS ETUDE',
      'route': '/etude',
      'isIcon': false,
    },
    {
      'image': 'assets/images/retraitee.png',
      'title': 'CORIS RETRAITE',
      'route': '/retraite',
      'isIcon': false,
    },
    {
      'image': 'assets/images/epargnee.png',
      'title': 'CORIS ÉPARGNE BONUS',
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
      'image': 'assets/images/emprunteur.png',
      'title': 'FLEX EMPRUNTEUR',
      'route': '/flex',
      'isIcon': false,
    },
    {
      'image': 'assets/images/prets.png',
      'title': 'PRETS SCOLAIRES',
      'route': '/prets',
      'isIcon': false,
    },
    {
      'image': 'assets/images/familis.png',
      'title': 'CORIS FAMILIS',
      'route': '/familis',
      'isIcon': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentCarouselIndex + 1) % _carouselData.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Charger le nombre de notifications non lues
    _loadUnreadNotificationsCount();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Charge le nombre de notifications non lues
  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    } catch (e) {
      print('Erreur chargement notifications: $e');
    }
  }

  /// Navigue vers la page des notifications
  void _goToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    // Recharger le compteur au retour
    _loadUnreadNotificationsCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 28),
                onPressed: _goToNotifications,
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE30613),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationsCount > 99
                          ? '99+'
                          : _unreadNotificationsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = MediaQuery.of(context).size.width;
          double screenHeight = MediaQuery.of(context).size.height;
          double carouselHeight = screenHeight * 0.3;
          if (carouselHeight > 250) carouselHeight = 250;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        bleuCoris,
                        Color.fromRGBO(0, 43, 107, 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chez l\'assureur qui vous rassure!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: carouselHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                    itemCount: _carouselData.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                              context, _carouselData[index]['route']!);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              children: [
                                Image.asset(
                                  _carouselData[index]['image']!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                // Gradient overlay pour améliorer la lisibilité
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.45),
                                        Colors.black.withOpacity(0.25),
                                        Colors.black.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: screenHeight * 0.05,
                                  left: screenWidth * 0.05,
                                  right: screenWidth * 0.05,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _carouselData[index]['title']!,
                                        style: TextStyle(
                                          color: const Color(0xFFE30613), // Rouge Coris
                                          fontSize: screenWidth * 0.06,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.9),
                                              offset: const Offset(2, 2),
                                              blurRadius: 6,
                                            ),
                                            Shadow(
                                              color: Colors.black.withOpacity(0.5),
                                              offset: const Offset(0, 0),
                                              blurRadius: 15,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _carouselData[index]['subtitle']!,
                                        style: TextStyle(
                                          color: const Color(0xFFFFFFFF), // Blanc pur
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.8),
                                              offset: const Offset(1, 1),
                                              blurRadius: 4,
                                            ),
                                            Shadow(
                                              color: Colors.black.withOpacity(0.4),
                                              offset: const Offset(0, 0),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _carouselData[index]['description']!,
                                        style: TextStyle(
                                          color: const Color(0xFFF0F0F0), // Blanc cassé
                                          fontSize: screenWidth * 0.03,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.8),
                                              offset: const Offset(1, 1),
                                              blurRadius: 3,
                                            ),
                                            Shadow(
                                              color: Colors.black.withOpacity(0.4),
                                              offset: const Offset(0, 0),
                                              blurRadius: 8,
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _carouselData.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentCarouselIndex == index
                            ? rougeCoris
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/souscription');
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          color: bleuCoris, size: 22),
                      label: Text(
                        'Faire une souscription',
                        style: TextStyle(
                          color: bleuCoris,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: bleuCoris, width: 2),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    'Nos Autres Produits',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: bleuCoris,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                              context, _services[index]['route']);
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
                              Image.asset(
                                _services[index]['image'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 24,
                                      color: bleuCoris,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _services[index]['title'],
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
        },
      ),
    );
  }
}
