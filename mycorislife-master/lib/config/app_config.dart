import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool TEST_MODE_FORCE_10_XOF = false;

  static const String productionBaseUrl = 'https://mycorislife.com/api';
  static const String localhostBaseUrl = 'http://localhost:5000/api';
  static const String localEmulatorBaseUrl = 'http://10.0.2.2:5000/api';

  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get defaultBaseUrl {
    // 🔥 EN PRODUCTION → FORCER URL PROD
    if (kReleaseMode) {
      return productionBaseUrl;
    }

    // 🔧 DEV uniquement
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

    // ❌ PAS DE FALLBACK LOCAL EN PROD
    if (!kReleaseMode) {
      if (baseUrl != localEmulatorBaseUrl) {
        urls.add(localEmulatorBaseUrl);
      }

      if (baseUrl != localhostBaseUrl) {
        urls.add(localhostBaseUrl);
      }
    }

    return urls;
  }

  static List<String> get allBaseUrls => [baseUrl, ...fallbackBaseUrls];

  static const String supportEmail = 'corisvie-ci@coris-assurances.ci';
  static const String supportPhone = '+2250778685858';
}