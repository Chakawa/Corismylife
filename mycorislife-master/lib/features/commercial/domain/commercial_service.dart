import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';

/// ==========================================
/// SERVICE COMMERCIAL
/// ==========================================
/// Gère toutes les opérations liées aux commerciaux :
/// - Statistiques commerciales
/// - Gestion des clients
/// - Suivi des souscriptions
/// - Commissions

class CommercialService {
  static const _storage = FlutterSecureStorage();

  /// Récupère le token JWT depuis le stockage sécurisé
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  /// Récupère les statistiques du commercial
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ??
              'Erreur lors de la récupération des statistiques');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Erreur lors de la récupération des statistiques');
      }
    } on SocketException {
      throw Exception('Pas de connexion Internet. Vérifiez votre connexion.');
    } on HttpException {
      throw Exception('Erreur de communication avec le serveur.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Récupère la liste des clients du commercial
  static Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/clients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(
              data['message'] ?? 'Erreur lors de la récupération des clients');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Erreur lors de la récupération des clients');
      }
    } on SocketException {
      throw Exception('Pas de connexion Internet. Vérifiez votre connexion.');
    } on HttpException {
      throw Exception('Erreur de communication avec le serveur.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Crée un nouveau client avec le code apporteur du commercial
  /// Le code apporteur est automatiquement ajouté par le backend
  /// 
  /// [clientData] : Données du client à créer (email, password, nom, prenom, etc.)
  /// Retourne : Les données du client créé avec son ID
  static Future<Map<String, dynamic>> createClient(
      Map<String, dynamic> clientData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé. Veuillez vous connecter.');
      }

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/commercial/clients'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(clientData),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseBody['success'] == true) {
          // Le backend retourne { success: true, data: { id, email, nom, prenom, ... } }
          final client = responseBody['data'] ?? {};
          
          // S'assurer que l'ID est présent
          if (client['id'] == null) {
            throw Exception('Erreur: Le client a été créé mais l\'ID n\'a pas été retourné');
          }
          
          return client;
        } else {
          throw Exception(
              responseBody['message'] ?? 'Erreur lors de la création du client');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 400) {
        // Erreur de validation
        throw Exception(
            responseBody['message'] ?? 'Données invalides. Vérifiez les informations saisies.');
      } else {
        throw Exception(
            responseBody['message'] ?? 'Erreur lors de la création du client (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Pas de connexion Internet. Vérifiez votre connexion.');
    } on HttpException {
      throw Exception('Erreur de communication avec le serveur.');
    } catch (e) {
      // Si c'est déjà une Exception, la relancer
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  /// Récupère les souscriptions des clients du commercial
  static Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ??
              'Erreur lors de la récupération des souscriptions');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Erreur lors de la récupération des souscriptions');
      }
    } on SocketException {
      throw Exception('Pas de connexion Internet. Vérifiez votre connexion.');
    } on HttpException {
      throw Exception('Erreur de communication avec le serveur.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Récupère les bordereaux de commissions du commercial depuis l'API externe
  /// 
  /// Retourne un Map contenant:
  /// - 'data': Liste des bordereaux de commissions
  /// - 'total': Montant total de toutes les commissions
  /// - 'totalFormate': Montant total formaté (ex: "722 314 FCFA")
  /// - 'count': Nombre de bordereaux
  static Future<Map<String, dynamic>> getCommissions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/commissions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'data': List<Map<String, dynamic>>.from(data['data'] ?? []),
            'total': data['total'] ?? 0.0,
            'totalFormate': data['totalFormate'] ?? '0 FCFA',
            'count': data['count'] ?? 0,
          };
        } else {
          throw Exception(data['message'] ??
              'Erreur lors de la récupération des commissions');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 503) {
        throw Exception('Service de commissions temporairement indisponible. Veuillez réessayer plus tard.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Erreur lors de la récupération des commissions');
      }
    } on SocketException {
      throw Exception('Pas de connexion Internet. Vérifiez votre connexion.');
    } on HttpException {
      throw Exception('Erreur de communication avec le serveur.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Récupère la liste unique des clients qui ont des souscriptions
  static Future<List<Map<String, dynamic>>> getClientsWithSubscriptions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé. Veuillez vous connecter.');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/clients-with-subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ??
              'Erreur lors de la récupération des clients');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Erreur lors de la récupération des clients');
      }
    } on SocketException {
      throw Exception('Pas de connexion Internet. Vérifiez votre connexion.');
    } on HttpException {
      throw Exception('Erreur de communication avec le serveur.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

