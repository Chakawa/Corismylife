class AppConfig {
  // IMPORTANT: à laisser à false hors tests contrôlés.
  static const bool TEST_MODE_FORCE_10_XOF = false;

  // TEST LOCAL (emulateur Android)
  // static const String baseUrl = 'http://10.0.2.2:5000/api';

  // SERVEUR EN LIGNE (actif pour generation APK)
  static const String baseUrl = 'https://www.mycorislife.com/api';

  // Coordonnées support CORIS Assurance Vie CI (utilisées dans les actions de contact)
  static const String supportEmail = 'corisvie-ci@coris-assurances.ci';
  static const String supportPhone = '+2250778685858';
}
