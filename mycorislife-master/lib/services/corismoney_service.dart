import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

/// ============================================
/// SERVICE CORISMONEY
/// ============================================
/// Service pour gérer les paiements via l'API CorisMoney
/// 
/// Fonctionnalités:
/// - Envoi de code OTP pour validation paiement
/// - Traitement du paiement avec OTP
/// - Récupération du statut de transaction
/// - Historique des paiements
/// 
/// Flux de paiement:
/// 1. sendOTP() - Envoie un code OTP au numéro du client
/// 2. processPayment() - Confirme le paiement avec le code OTP reçu
/// 3. getTransactionStatus() - Vérifie le statut du paiement
class CorisMoneyService {
  static String get baseUrl => AppConfig.baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Envoie un code OTP au numéro de téléphone du client
  /// 
  /// [codePays] : Code pays (ex: "CI" pour Côte d'Ivoire)
  /// [telephone] : Numéro de téléphone (format: +22507XXXXXXXX)
  /// 
  /// Retourne la réponse de l'API avec le statut de l'envoi OTP
  Future<Map<String, dynamic>> sendOTP({
    required String codePays,
    required String telephone,
  }) async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'codePays': codePays,
          'telephone': telephone,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Erreur lors de l\'envoi du code OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Traite le paiement avec le code OTP reçu
  /// 
  /// [subscriptionId] : ID de la souscription à payer
  /// [codePays] : Code pays (ex: "CI")
  /// [telephone] : Numéro de téléphone du client
  /// [montant] : Montant à payer (en FCFA)
  /// [codeOTP] : Code OTP reçu par SMS
  /// [description] : Description du paiement (optionnel)
  /// 
  /// Retourne la réponse avec le statut du paiement et l'ID de transaction
  Future<Map<String, dynamic>> processPayment({
    required int subscriptionId,
    required String codePays,
    required String telephone,
    required double montant,
    required String codeOTP,
    String? description,
  }) async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/process-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subscriptionId': subscriptionId,
          'codePays': codePays,
          'telephone': telephone,
          'montant': montant,
          'codeOTP': codeOTP,
          'description': description ?? 'Paiement souscription #$subscriptionId',
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Erreur lors du traitement du paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupère le statut d'une transaction CorisMoney
  /// 
  /// [transactionId] : ID de la transaction CorisMoney
  /// 
  /// Retourne les détails de la transaction (statut, montant, etc.)
  Future<Map<String, dynamic>> getTransactionStatus(String transactionId) async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('$baseUrl/payment/transaction-status/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Transaction introuvable',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupère l'historique des paiements de l'utilisateur
  /// 
  /// Retourne la liste des transactions effectuées
  Future<Map<String, dynamic>> getPaymentHistory() async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('$baseUrl/payment/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'transactions': jsonDecode(response.body)['transactions'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Impossible de charger l\'historique',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }

  /// Récupère les informations du client CorisMoney
  /// (Utilisé pour vérifier la configuration de l'API)
  Future<Map<String, dynamic>> getClientInfo() async {
    try {
      final token = await storage.read(key: 'token');

      final response = await http.get(
        Uri.parse('$baseUrl/payment/client-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Impossible de récupérer les informations client',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }
}
