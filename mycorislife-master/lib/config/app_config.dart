// ...existing code...
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration dynamique de l'API selon la plateforme.
/// - Android emulator -> 10.0.2.2
/// - iOS simulator / desktop / web -> localhost
class AppConfig {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    return 'http://localhost:5000/api';
  }
}
// ...existing code...
