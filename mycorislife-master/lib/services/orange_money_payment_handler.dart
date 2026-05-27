import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mycorislife/services/orange_money_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrangeMoneyPaymentHandler {
  /// Lance un paiement Orange Money de bout en bout depuis l'UI.
  static Future<bool> startPayment(
    BuildContext context, {
    required int subscriptionId,
    required double amount,
    required String description,
    FutureOr<void> Function()? onSuccess,
  }) async {
    try {
      final service = OrangeMoneyService();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initialisation du paiement Orange Money...'),
          backgroundColor: Colors.orange,
        ),
      );

      // Sanitize description client-side to avoid invalid chars (e.g. '#')
      String _sanitizeReference(String raw) {
        if (raw == null) return 'PaiementCORIS';
        var s = raw.replaceAll(RegExp(r'[^A-Za-z0-9 \-_.]'), ' ');
        s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (s.isEmpty) return 'PaiementCORIS';
        if (s.length > 30) s = s.substring(0, 30);
        return s;
      }

      final sanitizedDescription = _sanitizeReference(description);

      // Use backend default success/cancel URLs (no mobile deep-links)
      final createResult = await service.createPaymentSession(
        subscriptionId: subscriptionId,
        amount: amount,
        description: sanitizedDescription,
      );

      if (!(createResult['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createResult['message']?.toString() ??
                  'Impossible de démarrer le paiement Orange Money.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final data = createResult['data'] as Map<String, dynamic>? ?? {};
      final paymentUrlValue = data['payment_url']?.toString();
      final payToken = data['pay_token']?.toString() ?? '';
      final transactionId = data['txnid']?.toString();

      if (paymentUrlValue == null ||
          paymentUrlValue.isEmpty ||
          payToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Réponse Orange Money incomplète. Détail: ${createResult['message'] ?? 'n/a'}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      final uri = Uri.tryParse(paymentUrlValue);
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL Orange Money invalide.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      bool launched = false;
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir Orange Money. URL: $paymentUrlValue'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '🔄 Paiement Orange Money lancé. Retournez à l\'application après paiement pour confirmation automatique.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );

      for (int attempt = 0; attempt < 40; attempt++) {
        await Future.delayed(const Duration(seconds: 3));

        final statusResult = await service.getPaymentStatus(
          payToken: payToken,
          subscriptionId: subscriptionId,
          transactionId: transactionId,
        );

        if (!(statusResult['success'] == true)) {
          continue;
        }

        final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
        final status = (statusData['status'] ?? '').toString().toUpperCase();

        if (status == 'SUCCESS') {
          try {
            final confirmResult = await service.confirmPayment(
              subscriptionId: subscriptionId,
              payToken: payToken,
              transactionId: transactionId,
            );

            if (confirmResult['success'] == true) {
              final confirmData = confirmResult['data'] as Map<String, dynamic>? ?? {};

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Paiement Orange Money confirmé avec succès !',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Montant: ${confirmData['montant'] ?? amount} FCFA',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 8),
                ),
              );

              if (onSuccess != null) {
                await onSuccess();
              }

              return true;
            } else {
              if (onSuccess != null) {
                await onSuccess();
              }
              return true;
            }
          } catch (confirmError) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '✅ Paiement réussi. Vérifiez vos contrats pour la confirmation.'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 5),
              ),
            );
            if (onSuccess != null) {
              await onSuccess();
            }

            return true;
          }
        }

        if (status == 'FAILED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Paiement Orange Money échoué ou annulé.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return false;
        }
      }

      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur paiement Orange Money: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }
  }
}
