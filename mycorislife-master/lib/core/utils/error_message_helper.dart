import 'package:flutter/foundation.dart';

/// Messages utilisateur sûrs : aucune URL, IP, chemin API ou détail technique.
class ErrorMessageHelper {
  static const String generic =
      'Une erreur est survenue. Veuillez réessayer plus tard.';
  static const String network =
      'Connexion impossible. Vérifiez votre réseau et réessayez.';
  static const String server =
      'Service temporairement indisponible. Réessayez dans quelques instants.';
  static const String invalidCredentials =
      'Identifiants incorrects. Vérifiez votre email/téléphone et mot de passe.';
  static const String sessionExpired =
      'Votre session a expiré. Veuillez vous reconnecter.';
  static const String paymentFailed =
      'Le paiement n\'a pas pu être lancé. Réessayez ou choisissez un autre mode.';
  static const String paymentIncomplete =
      'Réponse de paiement incomplète. Réessayez dans quelques instants.';

  static final RegExp _urlPattern = RegExp(
    r'https?://[^\s]+|www\.[^\s]+',
    caseSensitive: false,
  );
  static final RegExp _ipPattern = RegExp(
    r'\b\d{1,3}(?:\.\d{1,3}){3}\b',
  );

  /// Transforme une erreur brute en message affichable à l'utilisateur.
  static String forUser(
    Object? error, {
    String fallback = generic,
    String? context,
  }) {
    if (error == null) return fallback;

    final raw = _extractMessage(error);
    if (raw.isEmpty) return fallback;

    if (kDebugMode) {
      final prefix = context != null ? '[$context] ' : '';
      debugPrint('$prefix$error');
    }

    final normalized = raw.toLowerCase();

    if (_looksLikeInvalidCredentials(normalized)) {
      return invalidCredentials;
    }
    if (_looksLikeNetworkIssue(normalized)) {
      return network;
    }
    if (_looksLikeServerIssue(normalized)) {
      return server;
    }
    if (_looksLikeSessionIssue(normalized)) {
      return sessionExpired;
    }
    if (_looksLikePaymentIssue(normalized)) {
      return paymentFailed;
    }

    final sanitized = _stripSensitiveData(raw);
    if (sanitized.isEmpty || _containsSensitiveData(sanitized)) {
      return fallback;
    }

    if (sanitized.length > 160) {
      return fallback;
    }

    return sanitized;
  }

  /// Nettoie un message serveur avant affichage.
  static String sanitizeServerMessage(
    String? message, {
    String fallback = generic,
  }) {
    if (message == null || message.trim().isEmpty) return fallback;

    final sanitized = _stripSensitiveData(message.trim());
    if (sanitized.isEmpty || _containsSensitiveData(sanitized)) {
      return fallback;
    }

    return forUser(sanitized, fallback: fallback);
  }

  static String _extractMessage(Object error) {
    if (error is String) return error.trim();

    final text = error.toString().trim();
    const prefixes = ['Exception: ', 'Error: ', 'FormatException: '];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        return text.substring(prefix.length).trim();
      }
    }
    return text;
  }

  static bool _looksLikeInvalidCredentials(String value) {
    return value.contains('incorrect') ||
        value.contains('identifiant') ||
        value.contains('mot de passe') ||
        value.contains('password') ||
        value.contains('unauthorized') ||
        value.contains('401');
  }

  static bool _looksLikeNetworkIssue(String value) {
    return value.contains('socket') ||
        value.contains('internet') ||
        value.contains('connexion') ||
        value.contains('network') ||
        value.contains('timeout') ||
        value.contains('temps') ||
        value.contains('host lookup') ||
        value.contains('failed host') ||
        value.contains('handshake') ||
        value.contains('certificate') ||
        value.contains('certificate_verify_failed');
  }

  static bool _looksLikeServerIssue(String value) {
    return value.contains('serveur') ||
        value.contains('server') ||
        value.contains('502') ||
        value.contains('503') ||
        value.contains('504') ||
        value.contains('500') ||
        value.contains('non-json') ||
        value.contains('réponse inattendue') ||
        value.contains('réponse invalide');
  }

  static bool _looksLikeSessionIssue(String value) {
    return value.contains('session expirée') ||
        value.contains('token') ||
        value.contains('reconnecter');
  }

  static bool _looksLikePaymentIssue(String value) {
    return value.contains('wave') ||
        value.contains('orange money') ||
        value.contains('paiement') ||
        value.contains('checkout') ||
        value.contains('launchurl') ||
        value.contains('payment');
  }

  static bool _containsSensitiveData(String value) {
    final lower = value.toLowerCase();
    return _urlPattern.hasMatch(lower) ||
        _ipPattern.hasMatch(lower) ||
        lower.contains('/api/') ||
        lower.contains('localhost') ||
        lower.contains('10.0.2.2') ||
        lower.contains('mycorislife.com') ||
        lower.contains('détail:') ||
        lower.contains('detail:') ||
        lower.contains('stacktrace') ||
        lower.contains('dart:') ||
        lower.contains('package:');
  }

  static String _stripSensitiveData(String value) {
    var result = value;
    result = result.replaceAll(_urlPattern, '');
    result = result.replaceAll(_ipPattern, '');
    result = result.replaceAll(RegExp(r'/api/\S+'), '');
    result = result.replaceAll(RegExp(r'\bDétail:\s*.*', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'\bDetail:\s*.*', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'URL:\s*\S+', caseSensitive: false), '');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
