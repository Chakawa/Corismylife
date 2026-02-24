import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mycorislife/services/wave_service.dart';
import 'package:url_launcher/url_launcher.dart';

class WavePaymentHandler {
  static Future<bool> startPayment(
    BuildContext context, {
    required int subscriptionId,
    required double amount,
    required String description,
    FutureOr<void> Function()? onSuccess,
  }) async {
    final service = WaveService();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Initialisation du paiement Wave...'),
        backgroundColor: Color(0xFF002B6B),
      ),
    );

    final createResult = await service.createCheckoutSession(
      subscriptionId: subscriptionId,
      amount: amount,
      description: description,
    );

    if (!(createResult['success'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createResult['message']?.toString() ??
                'Impossible de démarrer le paiement Wave.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final data = createResult['data'] as Map<String, dynamic>? ?? {};
    final launchUrlValue = data['launchUrl']?.toString();
    final sessionId = data['sessionId']?.toString() ?? '';
    final transactionId = data['transactionId']?.toString();

    if (launchUrlValue == null || launchUrlValue.isEmpty || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Réponse Wave incomplète (URL/session). Vérifiez la configuration backend.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final uri = Uri.tryParse(launchUrlValue);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL Wave invalide.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir Wave.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiement Wave lancé. Vérification du statut en cours...'),
        backgroundColor: Color(0xFF002B6B),
      ),
    );

    for (int attempt = 0; attempt < 8; attempt++) {
      await Future.delayed(const Duration(seconds: 3));

      final statusResult = await service.getCheckoutStatus(
        sessionId: sessionId,
        subscriptionId: subscriptionId,
        transactionId: transactionId,
      );

      if (!(statusResult['success'] == true)) {
        continue;
      }

      final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
      final status = (statusData['status'] ?? '').toString().toUpperCase();

      if (status == 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement Wave confirmé avec succès.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        if (onSuccess != null) {
          await onSuccess();
        }
        return true;
      }

      if (status == 'FAILED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Paiement Wave échoué ou annulé.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Paiement initié. Confirmation en attente, vérifiez à nouveau dans quelques instants.'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
    return false;
  }
}
