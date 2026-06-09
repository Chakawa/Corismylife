import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mycorislife/services/orange_money_service.dart';
import 'package:mycorislife/services/payment_resume_coordinator.dart';
import 'package:url_launcher/url_launcher.dart';

class OrangeMoneyPaymentHandler {
  /// Lance un paiement Orange Money de bout en bout depuis l'UI.
  static Future<bool> startPayment(
    BuildContext context, {
    int? subscriptionId,
    required double amount,
    required String description,
    String? numeroPolice,
    String? numepoli,
    String? codeinte,
    FutureOr<void> Function()? onSuccess,
    PaymentResumeCallback? onResumeResult,
  }) async {
    try {
      final service = OrangeMoneyService();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initialisation du paiement Orange Money...'),
          backgroundColor: Colors.orange,
        ),
      );

      String sanitizeReference(String raw) {
        var s = raw.replaceAll(RegExp(r'[^A-Za-z0-9 \-_.]'), ' ');
        s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (s.isEmpty) return 'PaiementCORIS';
        if (s.length > 30) s = s.substring(0, 30);
        return s;
      }

      final sanitizedDescription = sanitizeReference(description);

      final createResult = await service.createPaymentSession(
        subscriptionId: subscriptionId,
        amount: amount,
        description: sanitizedDescription,
        numeroPolice: numeroPolice,
        numepoli: numepoli,
        codeinte: codeinte,
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
      final transactionId =
          data['txnid']?.toString() ?? data['transactionId']?.toString();

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

      PaymentResumeCoordinator.instance.registerOrange(
        subscriptionId: subscriptionId,
        payToken: payToken,
        transactionId: transactionId,
        onComplete: (result) async {
          if (context.mounted) {
            PaymentResumeCoordinator.showResultSnackBar(context, result);
          }
          if (result.status == PaymentResumeStatus.success) {
            if (onSuccess != null) await onSuccess();
          }
          if (onResumeResult != null) {
            await onResumeResult(result);
          }
        },
      );

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

      var launched = false;
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
        PaymentResumeCoordinator.instance.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Impossible d\'ouvrir Orange Money. Vérifiez que l\'application est installée.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Paiement Orange Money lancé. Revenez à l\'application après paiement pour confirmation.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );

      return true;
    } catch (e) {
      PaymentResumeCoordinator.instance.clear();
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
