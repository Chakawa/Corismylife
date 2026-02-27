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
    try {
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
          SnackBar(
            content: Text(
                'Réponse Wave incomplète (URL/session). Détail: ${createResult['message'] ?? 'n/a'}'),
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
            content: Text('Impossible d\'ouvrir Wave. URL: $launchUrlValue'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Paiement Wave lancé. Retournez à l\'application après paiement pour confirmation automatique.'),
          backgroundColor: Color(0xFF002B6B),
          duration: Duration(seconds: 5),
        ),
      );

      // 🔄 POLLING AMÉLIORÉ: Essayer pendant 2 minutes (40 tentatives × 3s)
      for (int attempt = 0; attempt < 40; attempt++) {
        await Future.delayed(const Duration(seconds: 3));

        final statusResult = await service.getCheckoutStatus(
          sessionId: sessionId,
          subscriptionId: subscriptionId,
          transactionId: transactionId,
        );

        if (!(statusResult['success'] == true)) {
          debugPrint('⏳ Tentative ${attempt + 1}/40: Statut non récupéré, réessai...');
          continue;
        }

        final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
        final status = (statusData['status'] ?? '').toString().toUpperCase();

        debugPrint('📊 Tentative ${attempt + 1}/40: Statut Wave = $status');

        if (status == 'SUCCESS') {
          // 🎉 PAIEMENT RÉUSSI - Convertir la proposition/souscription en contrat + envoyer SMS
          try {
            final confirmResult = await service.confirmWavePayment(subscriptionId);
            
            if (confirmResult['success'] == true) {
              final confirmData = confirmResult['data'] as Map<String, dynamic>? ?? {};
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '✅ Paiement Wave confirmé avec succès !',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Montant: ${confirmData['montant'] ?? amount} FCFA',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '🎉 Votre souscription est maintenant un CONTRAT valide.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '📱 Un SMS de confirmation a été envoyé.',
                        style: TextStyle(fontSize: 12),
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
              // Erreur confirmation mais paiement réussi
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Paiement réussi. ${confirmResult['message']?.toString() ?? 'Vérifiez vos contrats.'}',
                  ),
                  backgroundColor: const Color(0xFFF59E0B),
                  duration: const Duration(seconds: 5),
                ),
              );
              if (onSuccess != null) {
                await onSuccess();
              }
              return true;
            }
          } catch (confirmError) {
            debugPrint('⚠️ Erreur confirmation: $confirmError');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Paiement réussi. Vérifiez vos contrats pour la confirmation.'),
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
              content: Text('❌ Paiement Wave échoué ou annulé.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return false;
        }

        // Si PENDING, continuer à attendre
        if (status == 'PENDING') {
          debugPrint('⏳ Paiement en attente (PENDING), continue le polling...');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⏳ Vérification du paiement en cours. Vérifiez "Mes Contrats" pour voir le statut.'),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 6),
        ),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur Wave: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}
