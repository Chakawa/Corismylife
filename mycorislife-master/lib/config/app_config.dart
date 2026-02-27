class AppConfig {
  // PRODUCTION - Serveur déployé
  //static const String baseUrl = 'http://185.98.138.168:5000/api';

  // DÉVELOPPEMENT - émulateur Android
  static const bool TEST_MODE_FORCE_10_XOF = true;
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // DÉVELOPPEMENT - téléphone sur même réseau local
  //static const String baseUrl = 'http://192.168.78.19:5000/api';
}

// /* endpoints
//   static const saveSubscription = '$baseUrl/subscriptions/save';
//   static const generateProposition = '$baseUrl/propositions/generate';
//   static const generateContract = '$baseUrl/contracts/generate';
//   static const listPropositions = '$baseUrl/propositions/client';
//   static const listContracts = '$baseUrl/contracts/client';

//   */

// // ...existing code...
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;

// /// Configuration dynamique de l'API selon la plateforme.
// /// - Android emulator -> 10.0.2.2
// /// - iOS simulator / desktop / web -> localhost
// class AppConfig {
//   // Mode test: remplace les montants réels par 10 XOF pour validation paiement
//   // À DÉSACTIVER en production (false)
//   static const bool TEST_MODE_FORCE_10_XOF = true;

//   static String get baseUrl {
//     if (!kIsWeb && Platform.isAndroid) return 'https://www.testmobile.online/api';
//     return 'https://www.testmobile.online/api';
//   }
// }
// // ...existing code...
