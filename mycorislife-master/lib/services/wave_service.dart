import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/config/app_config.dart';

class WaveService {
  static String get baseUrl => AppConfig.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> createCheckoutSession({
    required int subscriptionId,
    required double amount,
    String? description,
    String? customerPhone,
    String? successUrl,
    String? errorUrl,
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
        Uri.parse('$baseUrl/payment/wave/create-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subscriptionId': subscriptionId,
          'amount': amount,
          'description': description,
          'customerPhone': customerPhone,
          if (successUrl != null) 'successUrl': successUrl,
          if (errorUrl != null) 'errorUrl': errorUrl,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Session Wave créée',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Échec création session Wave',
        'error': data['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau Wave: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCheckoutStatus({
    required String sessionId,
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

      final uri = Uri.parse('$baseUrl/payment/wave/status/$sessionId')
          .replace(queryParameters: query.isEmpty ? null : query);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Statut Wave récupéré',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Impossible de récupérer le statut Wave',
        'error': data['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau Wave: $e',
      };
    }
  }
}