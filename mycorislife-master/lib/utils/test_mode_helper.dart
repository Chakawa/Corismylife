import 'package:flutter/foundation.dart';
import 'package:mycorislife/config/app_config.dart';

/// Utilitaire pour gérer le mode test des montants de paiement
class TestModeHelper {
  /// Applique la logique de test mode si activée
  /// Retourne 10 XOF si TEST_MODE_FORCE_10_XOF = true, sinon retourne le montant original
  static double applyTestModeIfNeeded(double originalAmount, {String context = ''}) {
    if (AppConfig.TEST_MODE_FORCE_10_XOF) {
      debugPrint('[TEST MODE] Montant forcé à 10 XOF au lieu de $originalAmount (contexte: $context)');
      return 10.0;
    }
    return originalAmount;
  }
}
