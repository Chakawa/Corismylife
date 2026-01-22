// class AppConfig {
//   // émulateur
//   static const String baseUrl = 'http://10.0.2.2:5000/api';
// // telephone
//   //static const String baseUrl = 'http://192.168.78.19:5000/api';
// }

// /* endpoints
//   static const saveSubscription = '$baseUrl/subscriptions/save';
//   static const generateProposition = '$baseUrl/propositions/generate';
//   static const generateContract = '$baseUrl/contracts/generate';
//   static const listPropositions = '$baseUrl/propositions/client';
//   static const listContracts = '$baseUrl/contracts/client';

//   */

// ...existing code...
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration dynamique de l'API selon la plateforme.
/// - Android emulator -> 10.0.2.2
/// - iOS simulator / desktop / web -> localhost
class AppConfig {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://185.98.138.168/api';
    return 'http://185.98.138.168/api';
  }
}
// ...existing code...
