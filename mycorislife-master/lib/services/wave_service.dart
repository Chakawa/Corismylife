import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/config/app_config.dart';

class WaveService {
  static String get baseUrl => AppConfig.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Convertit de manière sûre une réponse JSON en Map.
  ///
  /// Pourquoi: certains endpoints peuvent renvoyer des structures inattendues.
  /// Cette méthode évite les crashs de parsing et permet de remonter un message
  /// d'erreur exploitable à l'UI.
  Map<String, dynamic> _safeDecodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{'raw': decoded};
  }

  /// Extrait l'identifiant de session Wave depuis plusieurs variantes de payload.
  ///
  /// Pourquoi: Wave / backend peuvent renvoyer `sessionId`, `id`,
  /// `session_id`, etc. On normalise pour le reste du flux.
  String _extractSessionId(Map<String, dynamic> payload) {
    return (payload['sessionId'] ??
            payload['session_id'] ??
            payload['id'] ??
            payload['checkout_session_id'] ??
            payload['reference'] ??
            '')
        .toString();
  }

  /// Extrait l'URL de lancement Wave depuis plusieurs clés possibles.
  ///
  /// Pourquoi: selon la version/provider, l'URL peut être dans `launchUrl`,
  /// `wave_launch_url`, `checkout_url`, etc.
  String _extractLaunchUrl(Map<String, dynamic> payload) {
    return (payload['launchUrl'] ??
            payload['wave_launch_url'] ??
            payload['launch_url'] ??
            payload['checkout_url'] ??
            payload['url'] ??
            '')
        .toString();
  }

  /// Crée une session de paiement Wave et renvoie une réponse normalisée.
  ///
  /// Retourne toujours `data.sessionId` et `data.launchUrl` quand disponible,
  /// afin que les écrans Flutter n'aient pas à gérer plusieurs formats.
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

      final data = _safeDecodeMap(response.body);
      final payload = (data['data'] is Map<String, dynamic>)
          ? data['data'] as Map<String, dynamic>
          : (data['data'] is Map)
              ? Map<String, dynamic>.from(data['data'])
              : data;
      final normalizedSessionId = _extractSessionId(payload);
      final normalizedLaunchUrl = _extractLaunchUrl(payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': {
            ...payload,
            'sessionId': normalizedSessionId,
            'launchUrl': normalizedLaunchUrl,
          },
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

  /// Vérifie le statut d'une session Wave.
  ///
  /// Cette méthode sert au polling côté app après ouverture de Wave,
  /// et permet de déclencher la confirmation du contrat quand le statut passe à SUCCESS.
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

      final data = _safeDecodeMap(response.body);

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

  /// 🎉 Finaliser le paiement Wave réussi:
  /// 1. Convertit la proposition en contrat
  /// 2. Envoie un SMS de confirmation au client
  /// @param subscriptionId - ID de la souscription
  /// @returns {success, message, data{subscriptionId, statut, montant, client}}
  Future<Map<String, dynamic>> confirmWavePayment(int subscriptionId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payment/confirm-wave-payment/$subscriptionId'),
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
          'message': data['message'] ?? 'Paiement confirmé avec succès',
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
        'message': 'Erreur réseau lors de la confirmation: $e',
      };
    }
  }

  /// Réconcilie les paiements Wave en attente pour l'utilisateur connecté.
  ///
  /// Utile lorsque l'utilisateur revient plus tard dans l'app: on récupère les
  /// paiements qui auraient pu être confirmés pendant que l'app était en arrière-plan.
  Future<Map<String, dynamic>> reconcileWavePayments() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Session expirée. Veuillez vous reconnecter.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payment/wave/reconcile'),
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
          'message': data['message'] ?? 'Réconciliation Wave terminée',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Échec réconciliation Wave',
        'error': data['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau réconciliation Wave: $e',
      };
    }
  }
}