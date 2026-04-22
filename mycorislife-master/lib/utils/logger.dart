import 'package:flutter/foundation.dart';

/// Utilitaire de logging conditionnel pour la production

/// Les logs sont désactivés automatiquement en mode release

class AppLogger {

  static const bool _enableLogging = kDebugMode;

  /// Log une information générale (remplace print())

  static void info(String message) {

    if (_enableLogging) {

      debugPrint('ℹ️ $message');
    }

  }

  /// Log une erreur

  static void error(String message, [Object? error, StackTrace? stackTrace]) {

    if (_enableLogging) {

      debugPrint('❌ $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }

  }

  /// Log un avertissement

  static void warning(String message) {

    if (_enableLogging) {

      debugPrint('⚠️ $message');
    }

  }

  /// Log une opération réussie

  static void success(String message) {

    if (_enableLogging) {

      debugPrint('✅ $message');
    }

  }

  /// Log des données de débogage détaillées

  static void debug(String message) {

    if (_enableLogging && kDebugMode) {

      debugPrint('🔍 DEBUG: $message');
    }

  }

  /// Log de calcul (pour les simulations)

  static void calculation(String message) {

    if (_enableLogging && kDebugMode) {

      debugPrint('🧮 $message');
    }

  }

}

