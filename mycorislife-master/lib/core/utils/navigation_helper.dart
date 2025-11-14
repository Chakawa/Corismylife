import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// Helper pour la navigation selon le rôle de l'utilisateur
class NavigationHelper {
  /// Vérifie si l'utilisateur est un commercial et redirige vers la sélection de client
  /// Sinon, redirige directement vers la souscription
  /// Navigue vers la page de souscription selon le rôle de l'utilisateur
  /// 
  /// [context] : BuildContext (doit être utilisé de manière synchrone)
  /// [productType] : Type de produit (ex: 'etude', 'retraite', etc.)
  /// [simulationData] : Données de simulation (optionnel)
  static Future<void> navigateToSubscription({
    required BuildContext context,
    required String productType,
    Map<String, dynamic>? simulationData,
  }) async {
    final userRole = await AuthService.getUserRole();
    
    // Vérifier que le context est toujours monté avant de naviguer
    if (!context.mounted) return;
    
    if (userRole == 'commercial') {
      // Pour les commerciaux, rediriger vers la sélection de client
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          '/commercial/select_client',
          arguments: {
            'productType': productType,
            'simulationData': simulationData,
          },
        );
      }
    } else {
      // Pour les clients, rediriger directement vers la souscription
      if (context.mounted) {
        if (simulationData != null) {
          Navigator.pushNamed(
            context,
            '/souscription_$productType',
            arguments: {'simulationData': simulationData},
          );
        } else {
          Navigator.pushNamed(context, '/souscription_$productType');
        }
      }
    }
  }
}


