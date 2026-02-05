import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les contrats d'assurance
class ContractService {
  // URL de base de l'API - À configurer selon l'environnement
  static const String baseUrl = 'http://localhost:5000'; // PROD: https://api.mycoris.com
  
  /// Récupère le token d'authentification
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Récupère tous les contrats de l'utilisateur connecté
  Future<Map<String, dynamic>> getContracts() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Non authentifié',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/contracts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'contracts': data['data'] ?? [],
          'total': data['total'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur lors de la récupération des contrats',
        };
      }
    } catch (e) {
      print('Erreur getContracts: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
      };
    }
  }

  /// Récupère les détails d'un contrat spécifique
  Future<Map<String, dynamic>> getContractDetails(int contractId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Non authentifié',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/contracts/$contractId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'contract': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur lors de la récupération du contrat',
        };
      }
    } catch (e) {
      print('Erreur getContractDetails: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur',
      };
    }
  }

  /// Formatte la périodicité pour l'affichage
  String formatPeriodicite(String? periodicite) {
    if (periodicite == null) return 'Non spécifié';
    
    switch (periodicite.toLowerCase()) {
      case 'mensuelle':
      case 'mensuel':
        return 'Mensuel';
      case 'trimestrielle':
      case 'trimestriel':
        return 'Trimestriel';
      case 'semestrielle':
      case 'semestriel':
        return 'Semestriel';
      case 'annuelle':
      case 'annuel':
        return 'Annuel';
      case 'unique':
        return 'Paiement unique';
      default:
        return periodicite;
    }
  }

  /// Formatte le statut du contrat pour l'affichage
  String formatStatus(String? status) {
    if (status == null) return 'Inconnu';
    
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'suspended':
        return 'Suspendu';
      case 'expired':
        return 'Expiré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  /// Formatte le statut de paiement pour l'affichage avec couleur
  Map<String, dynamic> formatPaymentStatus(String? paymentStatus) {
    if (paymentStatus == null) {
      return {
        'text': 'Inconnu',
        'color': 0xFF9E9E9E, // Gris
      };
    }
    
    switch (paymentStatus) {
      case 'Paiement unique effectué':
        return {
          'text': 'Paiement unique effectué',
          'color': 0xFF4CAF50, // Vert
        };
      case 'À jour':
        return {
          'text': 'À jour',
          'color': 0xFF4CAF50, // Vert
        };
      case 'Échéance proche':
        return {
          'text': 'Échéance proche (7 jours)',
          'color': 0xFFFF9800, // Orange
        };
      case 'En retard':
        return {
          'text': 'En retard',
          'color': 0xFFF44336, // Rouge
        };
      default:
        return {
          'text': paymentStatus,
          'color': 0xFF9E9E9E, // Gris
        };
    }
  }

  /// Formatte une date pour l'affichage (ex: "15 mars 2026")
  String formatDate(String? dateString) {
    if (dateString == null) return 'Non spécifié';
    
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Formatte un montant en FCFA
  String formatAmount(dynamic amount) {
    if (amount == null) return '0 FCFA';
    
    try {
      final numAmount = double.parse(amount.toString());
      return '${numAmount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      )} FCFA';
    } catch (e) {
      return '$amount FCFA';
    }
  }

  /// Calcule le nombre de jours avant la prochaine échéance
  int? daysUntilNextPayment(String? nextPaymentDate) {
    if (nextPaymentDate == null) return null;
    
    try {
      final nextDate = DateTime.parse(nextPaymentDate);
      final now = DateTime.now();
      return nextDate.difference(now).inDays;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un contrat est expiré
  bool isExpired(String? endDate) {
    if (endDate == null) return false;
    
    try {
      final expiry = DateTime.parse(endDate);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Calcule le pourcentage de durée écoulée du contrat
  double getContractProgress(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 0.0;
    
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      
      final totalDuration = end.difference(start).inDays;
      final elapsedDuration = now.difference(start).inDays;
      
      if (totalDuration <= 0) return 0.0;
      
      final progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
      return progress;
    } catch (e) {
      return 0.0;
    }
  }
}
