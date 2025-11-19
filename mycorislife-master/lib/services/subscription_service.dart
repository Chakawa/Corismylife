import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mycorislife/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/models/subscription.dart';

class SubscriptionService {
  static String get baseUrl => AppConfig.baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Crée une nouvelle souscription
  ///
  /// [subscriptionData] : Données de la souscription (product_type, capital, prime, etc.)
  /// Si client_id est présent dans subscriptionData, la souscription sera créée pour ce client
  /// (cas d'une souscription commerciale)
  Future<http.Response> createSubscription(
      Map<String, dynamic> subscriptionData) async {
    final token = await storage.read(key: 'token');

    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(subscriptionData),
    );

    return response;
  }

  /// Met à jour une souscription existante (proposition)
  ///
  /// [subscriptionId] : ID de la souscription à modifier
  /// [subscriptionData] : Nouvelles données de la souscription
  Future<http.Response> updateSubscription(
      int subscriptionId, Map<String, dynamic> subscriptionData) async {
    final token = await storage.read(key: 'token');

    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/$subscriptionId/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(subscriptionData),
    );

    return response;
  }

  // Mettre à jour le statut après paiement
  Future<http.Response> updatePaymentStatus(
      int subscriptionId, bool paymentSuccess,
      {String? paymentMethod, String? transactionId}) async {
    final token = await storage.read(key: 'token');

    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/$subscriptionId/payment-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payment_success': paymentSuccess,
        'payment_method': paymentMethod ?? 'simulation',
        'transaction_id': transactionId ??
            'simulated_${DateTime.now().millisecondsSinceEpoch}',
      }),
    );

    return response;
  }

  // Mettre à jour le statut d'une souscription
  Future<http.Response> updateSubscriptionStatus(
      int subscriptionId, String status) async {
    final token = await storage.read(key: 'token');

    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/$subscriptionId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    return response;
  }

  // Récupérer les propositions
  Future<List<Subscription>> getPropositions() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/user/propositions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((item) => Subscription.fromJson(item))
            .toList();
      }
    }
    throw Exception("Erreur lors de la récupération des propositions");
  }

  // Récupérer les contrats
  Future<List<Subscription>> getContrats() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/user/contrats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((item) => Subscription.fromJson(item))
            .toList();
      }
    }
    throw Exception("Erreur lors de la récupération des contrats");
  }

  // Récupérer toutes les souscriptions (combine propositions et contrats)
  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      // Récupérer les propositions et les contrats, puis les combiner
      final propositions = await getPropositions();
      final contrats = await getContrats();
      return [...propositions, ...contrats];
    } catch (e) {
      throw Exception("Erreur lors de la récupération des souscriptions: $e");
    }
  }

  // Uploader un document
  Future<http.Response> uploadDocument(
      int subscriptionId, String filePath) async {
    final token = await storage.read(key: 'token');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/subscriptions/$subscriptionId/upload-document'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'document',
      filePath,
    ));

    var response = await http.Response.fromStream(await request.send());
    return response;
  }

  // Récupérer les détails d'une souscription
  Future<Map<String, dynamic>> getSubscriptionDetail(int subscriptionId) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']; // Retourne {subscription: ..., user: ...}
        } else {
          throw Exception(data['message'] ?? 'Erreur inconnue');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Récupérer une souscription simple
  Future<Subscription> getSubscription(int subscriptionId) async {
    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Subscription.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Erreur inconnue');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}
