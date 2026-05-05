import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  // IMPORTANT: à laisser à false hors tests contrôlés.

  static const bool TEST_MODE_FORCE_10_XOF = false;

  static const String productionBaseUrl = 'https://mycorislife.com/api';
  static const String localhostBaseUrl = 'http://localhost:5000/api';
  static const String localEmulatorBaseUrl = 'http://10.0.2.2:5000/api';
  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Override possible au lancement:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return localhostBaseUrl;
    }

    if (Platform.isAndroid) {
      return localEmulatorBaseUrl;
    }

    return localhostBaseUrl;
  }

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    return defaultBaseUrl;
  }

  static List<String> get fallbackBaseUrls {
    final urls = <String>[productionBaseUrl];

    if (baseUrl != localEmulatorBaseUrl) {
      urls.add(localEmulatorBaseUrl);
    }

    if (baseUrl != localhostBaseUrl) {
      urls.add(localhostBaseUrl);
    }

    return urls;
  }

  static List<String> get allBaseUrls => [baseUrl, ...fallbackBaseUrls];

  // Coordonnées support CORIS Assurance Vie CI (utilisées dans les actions de contact)

  static const String supportEmail = 'corisvie-ci@coris-assurances.ci';

  static const String supportPhone = '+2250778685858';
}
