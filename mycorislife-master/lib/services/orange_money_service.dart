import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/utils/test_mode_helper.dart';

class OrangeMoneyService {
  static String get baseUrl => AppConfig.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Map<String, dynamic> _safeDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return <String, dynamic>{'raw': decoded};
    } catch (e) {
      return <String, dynamic>{'error': 'JSON decode error: $e'};
    }
  }

  String _extractPaymentToken(Map<String, dynamic> payload) {
    return (payload['pay_token'] ??
            payload['payment_token'] ??
            payload['token'] ??
            payload['reference'] ??
            '')
        .toString();
  }

  String _extractPaymentUrl(Map<String, dynamic> payload) {
    return (payload['payment_url'] ??
            payload['paymentUrl'] ??
            payload['url'] ??
            payload['redirectUrl'] ??
            '')
        .toString();
  }

  Future<Map<String, dynamic>> createPaymentSession({
    int? subscriptionId,
    required double amount,
    String? description,
    String? customerPhone,
    String? successUrl,
    String? errorUrl,
    String? numeroPolice,
    String? numepoli,
    String? codeinte,
  }) async {
    try {
      final effectiveAmount = TestModeHelper.applyTestModeIfNeeded(
        amount,
        context: 'OrangeMoneyService.createPaymentSession',
      );

      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payment/orange-money/create-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (subscriptionId != null) 'subscriptionId': subscriptionId,
          'amount': effectiveAmount.round(),
          'description': description,
          'customerPhone': customerPhone,
          if (successUrl != null) 'successUrl': successUrl,
          if (errorUrl != null) 'errorUrl': errorUrl,
          if (numeroPolice != null && numeroPolice.isNotEmpty)
            'numeroPolice': numeroPolice,
          if (numepoli != null && numepoli.isNotEmpty) 'numepoli': numepoli,
          if (codeinte != null && codeinte.isNotEmpty) 'codeinte': codeinte,
        }),
      );

      final data = _safeDecodeMap(response.body);
      final payload = (data['data'] is Map<String, dynamic>)
          ? data['data'] as Map<String, dynamic>
          : (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'])
              : data;

      final normalizedPaymentToken = _extractPaymentToken(payload);
      final normalizedPaymentUrl = _extractPaymentUrl(payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': {
            ...payload,
            'pay_token': normalizedPaymentToken,
            'payment_url': normalizedPaymentUrl,
          },
          'message': data['message'] ?? 'Session Orange Money créée',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Échec création session Orange Money',
        'error': data['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau Orange Money: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus({
    required String payToken,
    int? subscriptionId,
    String? transactionId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
        };
      }

      final query = <String, String>{
        if (subscriptionId != null) 'subscriptionId': '$subscriptionId',
        if (transactionId != null && transactionId.isNotEmpty)
          'transactionId': transactionId,
      };

      final uri = Uri.parse('$baseUrl/payment/orange-money/status/$payToken')
          .replace(queryParameters: query.isEmpty ? null : query);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Statut récupéré',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Impossible de récupérer le statut',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau Orange Money: $e',
      };
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required int subscriptionId,
    required String payToken,
    String? transactionId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
        };
      }

      final response = await http.post(
        Uri.parse(
            '$baseUrl/payment/confirm-orange-money-payment/$subscriptionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payToken': payToken,
          if (transactionId != null && transactionId.isNotEmpty)
            'transactionId': transactionId,
        }),
      );

      final data = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Paiement Orange Money confirmé',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Impossible de confirmer le paiement',
        'error': data['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau Orange Money: $e',
      };
    }
  }
}
