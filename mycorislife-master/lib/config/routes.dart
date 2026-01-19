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
// ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
// import 'package:mycorislife/features/simulation/presentation/screens/flex_emprunteur_page.dart';
import 'package:mycorislife/features/client/presentation/screens/profil_screen.dart';
import 'package:mycorislife/features/souscription/presentation/screens/home_souscription.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_epargne.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_etude.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_familis.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_assure_prestige.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_mon_bon_plan.dart';
// ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
// import 'package:mycorislife/features/souscription/presentation/screens/souscription_flex.dart';
// ❌ PRODUIT DÉSACTIVÉ - PRETS SCOLAIRE
// import 'package:mycorislife/features/souscription/presentation/screens/souscription_prets_scolaire.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_retraite.dart';
import 'package:mycorislife/features/souscription/presentation/screens/souscription_serenite.dart';
import 'package:mycorislife/features/souscription/presentation/screens/sousription_solidarite.dart';
import 'package:mycorislife/features/produit/presentation/screens/desciption_epargne.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_solidarite.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_familis.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_serenite.dart';
// ℹ️ PRODUIT AFFICHÉ (souscription désactivée)
import 'package:mycorislife/features/produit/presentation/screens/description_flex.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_etude.dart';
// ℹ️ PRODUIT AFFICHÉ (souscription désactivée)
import 'package:mycorislife/features/produit/presentation/screens/description_prets.dart';
// ℹ️ NOUVEAU PRODUIT (bientôt disponible)
import 'package:mycorislife/features/produit/presentation/screens/description_pret_scolaire.dart';
// ℹ️ NOUVEAUX PRODUITS (souscription désactivée)
import 'package:mycorislife/features/produit/presentation/screens/description_bon_plan.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_assure_prestige.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_retraite.dart';
// ℹ️ NOUVEAUX PRODUITS COLLECTIFS (souscription désactivée)
import 'package:mycorislife/features/produit/presentation/screens/description_homme_cle.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_ifc.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_retraite_collective.dart';
import 'package:mycorislife/features/produit/presentation/screens/description_prevoyance_collective.dart';
import 'package:mycorislife/features/commercial/presentation/screens/profile_commercial.dart';
import 'package:mycorislife/features/commercial/presentation/screens/select_client_screen.dart';
import 'package:mycorislife/features/commercial/presentation/screens/commissions_page.dart';
import 'package:mycorislife/features/commercial/presentation/screens/create_client_screen.dart';
import 'package:mycorislife/features/commercial/presentation/screens/register_client_screen.dart';
import 'package:mycorislife/features/commercial/presentation/screens/mes_contrats_commercial_page.dart';
import 'package:mycorislife/features/commercial/presentation/screens/liste_clients_page.dart';
import 'package:mycorislife/features/commercial/presentation/screens/contrats_actifs_page.dart';
import 'package:mycorislife/features/commercial/presentation/screens/details_client_page.dart';
import 'package:mycorislife/features/shared/presentation/screens/contrat_details_unified_page.dart';
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
  // ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
  // '/simulation_emprunteur': (context) => const FlexEmprunteurPage(),
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
  // ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
  // '/souscription_emprunteur': (context) {
  //   final args =
  //       ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  //   return SouscriptionFlexPage(
  //     simulationData: args?['simulationData'],
  //     clientId: args?['client_id'],
  //     clientData: args?['client'],
  //   );
  // },
  // ❌ PRODUIT DÉSACTIVÉ - FLEX EMPRUNTEUR
  // '/souscription_flex': (context) {
  //   final args =
  //       ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  //   return SouscriptionFlexPage(
  //     simulationData: args?['simulationData'],
  //     clientId: args?['client_id'],
  //     clientData: args?['client'],
  //   );
  // },
  // ❌ PRODUIT DÉSACTIVÉ - PRETS SCOLAIRE
  // '/souscription_prets': (context) => const SouscriptionPretsScolairePage(),
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
  '/souscription_assure_prestige': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionPrestigePage(
      subscriptionId: args?['subscriptionId'],
      existingData: args?['existingData'],
    );
  },
  '/souscription_mon_bon_plan': (context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return SouscriptionBonPlanPage(
      subscriptionId: args?['subscriptionId'],
      existingData: args?['existingData'],
    );
  },

  // commercial route
  '/commercial_home': (context) => const CommercialHomePage(),
  '/commercialHome': (context) => CommercialHomePage(),
  '/profileCommercial': (context) => CommercialProfile(),
  '/mes_contrats_commercial': (context) => const MesContratsCommercialPage(),
  '/commissions': (context) => const CommissionsPage(),
  '/liste_clients': (context) => const ListeClientsPage(),
  '/contrats_actifs': (context) => const ContratsActifsPage(),
  '/details_client': (context) => const DetailsClientPage(),
  '/contrat_details': (context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    // Si args est déjà un Map<String, dynamic> (contrat direct), on l'utilise
    // Sinon on essaie d'extraire args['contrat']
    final contrat = args is Map<String, dynamic>
        ? (args.containsKey('contrat') ? args['contrat'] : args)
        : args as Map<String, dynamic>;
    return ContratDetailsUnifiedPage(contrat: contrat);
  },
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
  '/familis': (context) => const DescriptionFamilisPage(),
  '/etude': (context) => const DescriptionEtudePage(),
  '/retraite': (context) => const DescriptionRetraitePage(),
  '/epargne': (context) => const DescriptionEpargnePage(),
  // PRODUITS AFFICHÉS (souscription désactivée)
  '/flex': (context) => const DescriptionFlexPage(),
  '/prets': (context) => const DescriptionPretsPage(),
  // PRÊT SCOLAIRE (bientôt disponible)
  '/description_pret_scolaire': (context) =>
      const DescriptionPretScolairePage(),
  // NOUVEAUX PRODUITS (souscription désactivée)
  '/bon-plan': (context) => const DescriptionBonPlanPage(),
  '/assure-prestige': (context) => const DescriptionAssurePrestigePage(),
  // NOUVEAUX PRODUITS COLLECTIFS (souscription désactivée)
  '/homme-cle': (context) => const DescriptionHommeClePage(),
  '/ifc': (context) => const DescriptionIfcPage(),
  '/retraite-collective': (context) =>
      const DescriptionRetraiteCollectivePage(),
  '/prevoyance-collective': (context) =>
      const DescriptionPrevoyanceCollectivePage(),

  // profil
  '/profile': (context) => const ProfilPage(),
  '/commercial-profile': (context) => const CommercialProfile(),

  // notifications
  '/notifications': (context) => const NotificationsScreen(),
};
