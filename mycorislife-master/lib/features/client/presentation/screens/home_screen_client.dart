import 'package:flutter/material.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'home_content.dart';
import 'mes_propositions_page.dart';
import 'mes_contrats_client_page.dart';
import 'profil_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isCheckingRole = true;

  // Couleurs de la charte graphique
  static const rougeCoris = Color(0xFFE30613);

  // Liste des widgets pour chaque onglet de la barre de navigation
  static const List<Widget> _pages = <Widget>[
    HomeContent(), // Onglet 0: Accueil
    PropositionsPage(), // Onglet 1: Propositions
    SizedBox.shrink(), // Onglet 2: Placeholder pour Simuler
    MesContratsClientPage(), // Onglet 3: Contrats
    ProfilPage(), // Onglet 4: Profil
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final userRole = await AuthService.getUserRole();
      if (mounted) {
        if (userRole == 'commercial') {
          // Rediriger le commercial vers sa page d'accueil
          Navigator.pushReplacementNamed(context, '/commercial_home');
          return;
        }
        setState(() {
          _isCheckingRole = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingRole = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    // Cas spécial pour le bouton "Simuler" qui navigue vers une autre page
    if (index == 2) {
      Navigator.pushNamed(context, '/simulation');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
        // L'AppBar est maintenant spécifique à chaque page pour plus de flexibilité
        // Nous la retirons d'ici et la plaçons dans chaque page respective.
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: rougeCoris,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 24),
              label: "Accueil",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded, size: 24),
              label: "Propositions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate, size: 24),
              label: "Simuler",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in_rounded, size: 24),
              label: "Contrats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 24),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }
}
