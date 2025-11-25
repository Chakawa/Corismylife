import 'package:flutter/material.dart';
import 'package:mycorislife/features/auth/presentation/screens/login_screen.dart';
import 'package:mycorislife/features/auth/presentation/screens/register_screen.dart';
import 'package:mycorislife/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/home_screen_client.dart';
import 'package:mycorislife/features/commercial/presentation/screens/commercial_home_screen.dart';
import 'package:mycorislife/features/produit/presentation/screens/produits_screen.dart';
import 'package:mycorislife/features/simulation/presentation/screens/simulation_etude_screen.dart';
import 'package:mycorislife/features/simulation/presentation/screens/simulation_retraite_screen.dart';
import 'package:mycorislife/features/simulation/presentation/screens/simulation_serenite_screen.dart';
import 'package:mycorislife/features/simulation/presentation/screens/simulation_solidarite_screen.dart';
import 'package:mycorislife/features/simulation/presentation/screens/simulation_familis_screen.dart';
import 'package:mycorislife/features/simulation/presentation/screens/flex_emprunteur_page.dart';
import 'package:mycorislife/features/client/presentation/screens/profil_screen.dart';
import 'package:mycorislife/features/souscription/presentation/screens/home_souscription.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_epargne.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_etude.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_familis.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_flex.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_prets_scolaire.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_retraite.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_serenite.dart';
import 'package:mycorislife/features/souscription/presentation/screens/sousription_solidarite.dart';
import 'package:mycorislife/features/produit/presentation/screens/desciption_epargne.dart';
import 'package:mycorislife/features/produit/presentation/screens/desciption_retraite.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_solidarite.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_familis.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_serenite.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_flex.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_etude.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_prets.dart';
import 'package:mycorislife/features/commercial/presentation/screens/profile_commercial.dart';
import 'package:mycorislife/features/commercial/presentation/screens/select_client_screen.dart';
import 'package:mycorislife/features/commercial/presentation/screens/create_client_screen.dart';
import 'package:mycorislife/features/commercial/presentation/screens/register_client_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/notifications_screen.dart';

//import 'package:mycorislife/features/client/presentation/screens/contrats_screen.dart';
//import 'package:mycorislife/features/client/presentation/screens/propositions_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // publiccc
  '/': (context) => const LoginScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/reset_password': (context) => const ResetPasswordScreen(),

  // client route
  '/client_home': (context) => const HomePage(),
  '/clientHome': (context) => HomePage(),
  '/client/dashboard': (context) => const HomePage(),

  // Simulations Client
  '/simulation_etude': (context) => const SimulationEtudeScreen(),
  '/simulation_retraite': (context) => const CorisRetraiteScreen(),
  '/simulation_emprunteur': (context) => const FlexEmprunteurPage(),
  '/simulation_serenite': (context) => const SimulationSereniteScreen(),
  '/simulation_solidarite': (context) => const SolidariteSimulationPage(),
  '/simulation_familis': (context) => const SimulationFamilisScreen(),
  '/simulation': (context) => ProduitsPage(),

  // Souscriptions Client
  '/souscription': (context) => HomeSouscriptionPage(),
  '/souscription_epargne': (context) => SouscriptionEpargnePage(),
  '/souscription_etude': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionEtudePage(
      clientId: args?['client_id'],
      clientData: args?['client'],
      ageParent: args?['simulationData']?['ageParent'],
      ageEnfant: args?['simulationData']?['ageEnfant'],
      prime: args?['simulationData']?['prime'],
      rente: args?['simulationData']?['rente'],
      periodicite: args?['simulationData']?['periodicite'],
    );
  },
  '/souscription_familis': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionFamilisPage(
      simulationData: args?['simulationData'],
      clientId: args?['client_id'],
      clientData: args?['client'],
    );
  },
  '/souscription_emprunteur': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionFlexPage(
      simulationData: args?['simulationData'],
      clientId: args?['client_id'],
      clientData: args?['client'],
    );
  },
  '/souscription_flex': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionFlexPage(
      simulationData: args?['simulationData'],
      clientId: args?['client_id'],
      clientData: args?['client'],
    );
  },
  '/souscription_prets': (context) => const SouscriptionPretsScolairePage(),
  '/souscription_retraite': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionRetraitePage(
      simulationData: args?['simulationData'],
      clientId: args?['client_id'],
      clientData: args?['client'],
    );
  },
  '/souscription_serenite': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionSerenitePage(
      simulationData: args?['simulationData'],
      clientId: args?['client_id'],
      clientData: args?['client'],
    );
  },
  '/souscription_solidarite': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionSolidaritePage(
      capital: args?['simulationData']?['capital'],
      periodicite: args?['simulationData']?['periodicite'],
      nbConjoints: args?['simulationData']?['nbConjoints'],
      nbEnfants: args?['simulationData']?['nbEnfants'],
      nbAscendants: args?['simulationData']?['nbAscendants'],
      clientId: args?['client_id'],
      clientData: args?['client'],
      subscriptionId: args?['subscriptionId'],
      existingData: args?['existingData'],
    );
  },

  // commercial route
  '/commercial_home': (context) => const CommercialHomePage(),
  '/commercialHome': (context) => CommercialHomePage(),
  '/profileCommercial': (context) => CommercialProfile(),
  '/commercial/create_client': (context) => const CreateClientScreen(),
  '/commercial/select_client': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    return SelectClientScreen(
      productType: args?['productType'] ?? '',
      simulationData: args?['simulationData'],
      subscriptionId: args?['subscriptionId'], // Support de la modification
    );
  },
  '/commercial/register_client': (context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    return RegisterClientScreen(
      productType: args?['productType'],
      simulationData: args?['simulationData'],
    );
  },

  // adminroute

  // description
  '/produits': (context) => HomeSouscriptionPage(),
  '/serenite': (context) => const DescriptionSerenitePage(),
  '/solidarite': (context) => const DescriptionSolidaritePage(),
  '/flex': (context) => const DescriptionFlexPage(),
  '/prets': (context) => const DescriptionPretsPage(),
  '/familis': (context) => const DescriptionFamilisPage(),
  '/etude': (context) => const DescriptionEtudePage(),
  '/retraite': (context) => const DescriptionRetraitePage(),
  '/epargne': (context) => const DescriptionEpargnePage(),

  // profil
  '/profile': (context) => const ProfilPage(),
  '/commercial-profile': (context) => const CommercialProfile(),

  // notifications
  '/notifications': (context) => const NotificationsScreen(),
};
