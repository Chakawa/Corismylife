class AppConfig {
  // IMPORTANT: à laisser à false hors tests contrôlés.

  static const bool TEST_MODE_FORCE_10_XOF = false;

  static const String defaultBaseUrl = 'https://www.mycorislife.com/api';
  static const String localEmulatorBaseUrl = 'http://10.0.2.2:5000/api';

  // Override possible au lancement:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl);

  static List<String> get fallbackBaseUrls {
    final urls = <String>['https://mycorislife.com/api'];
    if (baseUrl != defaultBaseUrl) {
      urls.add(defaultBaseUrl);
    }
    return urls;
  }

  static List<String> get allBaseUrls => [baseUrl, ...fallbackBaseUrls];

  // Coordonnées support CORIS Assurance Vie CI (utilisées dans les actions de contact)

  static const String supportEmail = 'corisvie-ci@coris-assurances.ci';

  static const String supportPhone = '+2250778685858';
}
