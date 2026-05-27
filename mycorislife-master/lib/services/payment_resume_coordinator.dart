import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mycorislife/services/orange_money_service.dart';

typedef PaymentResumeCallback = FutureOr<void> Function(PaymentResumeResult result);

enum PaymentResumeStatus { success, failed, pending, cancelled }

class PaymentResumeResult {
  final PaymentResumeStatus status;
  final String message;
  final String? provider;

  const PaymentResumeResult({
    required this.status,
    required this.message,
    this.provider,
  });
}

/// Suit un paiement Orange/Wave en cours et vérifie le statut au retour dans l'app.
class PaymentResumeCoordinator {
  PaymentResumeCoordinator._();
  static final PaymentResumeCoordinator instance = PaymentResumeCoordinator._();

  int? _subscriptionId;
  String? _payToken;
  String? _transactionId;
  String? _provider;
  PaymentResumeCallback? _onComplete;
  bool _checking = false;

  bool get hasPendingPayment => _payToken != null && _payToken!.isNotEmpty;

  void registerOrange({
    required int? subscriptionId,
    required String payToken,
    String? transactionId,
    PaymentResumeCallback? onComplete,
  }) {
    _subscriptionId = subscriptionId;
    _payToken = payToken;
    _transactionId = transactionId;
    _provider = 'orange';
    _onComplete = onComplete;
  }

  void registerWave({
    required int? subscriptionId,
    required String sessionId,
    String? transactionId,
    PaymentResumeCallback? onComplete,
  }) {
    _subscriptionId = subscriptionId;
    _payToken = sessionId;
    _transactionId = transactionId;
    _provider = 'wave';
    _onComplete = onComplete;
  }

  void clear() {
    _subscriptionId = null;
    _payToken = null;
    _transactionId = null;
    _provider = null;
    _onComplete = null;
    _checking = false;
  }

  Future<void> checkOnAppResume() async {
    if (!hasPendingPayment || _checking) return;
    _checking = true;

    try {
      if (_provider == 'orange') {
        await _checkOrange();
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkOrange() async {
    final payToken = _payToken;
    if (payToken == null || payToken.isEmpty) return;

    final service = OrangeMoneyService();
    for (var attempt = 0; attempt < 12; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }

      final statusResult = await service.getPaymentStatus(
        payToken: payToken,
        subscriptionId: _subscriptionId,
        transactionId: _transactionId,
      );

      if (statusResult['success'] != true) continue;

      final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
      final status = (statusData['status'] ?? '').toString().toUpperCase();

      if (status == 'SUCCESS') {
        if (_subscriptionId != null) {
          await service.confirmPayment(
            subscriptionId: _subscriptionId!,
            payToken: payToken,
            transactionId: _transactionId,
          );
        }

        final callback = _onComplete;
        clear();
        if (callback != null) {
          await callback(
            const PaymentResumeResult(
              status: PaymentResumeStatus.success,
              message: 'Paiement reçu avec succès.',
              provider: 'Orange Money',
            ),
          );
        }
        return;
      }

      if (status == 'FAILED') {
        final callback = _onComplete;
        clear();
        if (callback != null) {
          await callback(
            const PaymentResumeResult(
              status: PaymentResumeStatus.failed,
              message: 'Paiement échoué ou annulé.',
              provider: 'Orange Money',
            ),
          );
        }
        return;
      }
    }

    final callback = _onComplete;
    if (callback != null) {
      await callback(
        const PaymentResumeResult(
          status: PaymentResumeStatus.pending,
          message:
              'Paiement en cours de vérification. La liste des contrats sera mise à jour.',
          provider: 'Orange Money',
        ),
      );
    }
  }

  static void showResultSnackBar(BuildContext context, PaymentResumeResult result) {
    if (!context.mounted) return;

    Color bg;
    String title;
    switch (result.status) {
      case PaymentResumeStatus.success:
        bg = const Color(0xFF10B981);
        title = 'Paiement reçu';
        break;
      case PaymentResumeStatus.failed:
        bg = const Color(0xFFEF4444);
        title = 'Paiement échoué';
        break;
      case PaymentResumeStatus.cancelled:
        bg = const Color(0xFFEF4444);
        title = 'Paiement annulé';
        break;
      case PaymentResumeStatus.pending:
        bg = const Color(0xFFFF9800);
        title = 'Paiement en cours';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(result.message, style: const TextStyle(fontSize: 13)),
            if (result.provider != null)
              Text(
                'Démarche : ${result.provider}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
