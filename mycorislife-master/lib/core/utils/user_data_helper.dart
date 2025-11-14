import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

/// ============================================
/// HELPER POUR CHARGER LES DONNÉES UTILISATEUR
/// ============================================
/// Cette classe fournit des méthodes utilitaires pour charger les données utilisateur
/// avec support pour les souscriptions commerciales (affiche commercial ET client)
/// ============================================

class UserDataHelper {
  static const _storage = FlutterSecureStorage();

  /// Charge les données utilisateur pour le récapitulatif
  /// Gère à la fois le cas d'un client normal et d'une souscription par commercial
  /// 
  /// [clientId] : ID du client si souscription par commercial (optionnel)
  /// [clientData] : Données du client si disponibles (optionnel)
  /// 
  /// Retourne : Map contenant :
  ///   - 'commercial' : Données du commercial (utilisateur connecté)
  ///   - 'client' : Données du client (si souscription par commercial)
  ///   - 'isCommercialSubscription' : true si c'est une souscription commerciale
  static Future<Map<String, dynamic>> loadUserDataForRecap({
    String? clientId,
    Map<String, dynamic>? clientData,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      // Si un client est fourni (souscription par commercial), charger les données du client
      Map<String, dynamic>? finalClientData;
      if (clientId != null || clientData != null) {
        if (clientData != null) {
          finalClientData = clientData;
        } else if (clientId != null) {
          // Charger les données du client depuis l'API
          final clientResponse = await http.get(
            Uri.parse('${AppConfig.baseUrl}/users/$clientId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (clientResponse.statusCode == 200) {
            final clientJson = json.decode(clientResponse.body);
            if (clientJson['success'] == true) {
              finalClientData = clientJson['user'];
            }
          }
        }
      }

      // Charger les données du commercial (utilisateur connecté)
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final commercialData = data['user'];
          
          // Calculer l'âge si date_naissance existe
          if (commercialData['date_naissance'] != null) {
            final dateNaissance = DateTime.parse(commercialData['date_naissance']);
            final maintenant = DateTime.now();
            int age = maintenant.year - dateNaissance.year;
            if (maintenant.month < dateNaissance.month ||
                (maintenant.month == dateNaissance.month &&
                    maintenant.day < dateNaissance.day)) {
              age--;
            }
            commercialData['age'] = age;
          }

          // Calculer l'âge du client si date_naissance existe
          if (finalClientData != null && finalClientData['date_naissance'] != null) {
            final dateNaissance = DateTime.parse(finalClientData['date_naissance']);
            final maintenant = DateTime.now();
            int age = maintenant.year - dateNaissance.year;
            if (maintenant.month < dateNaissance.month ||
                (maintenant.month == dateNaissance.month &&
                    maintenant.day < dateNaissance.day)) {
              age--;
            }
            finalClientData['age'] = age;
          }

          // Retourner les deux ensembles de données
          return {
            'commercial': commercialData,
            'client': finalClientData,
            'isCommercialSubscription': finalClientData != null,
          };
        } else {
          throw Exception(
              data['message'] ?? 'Erreur lors de la récupération des données');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      // En cas d'erreur, retourner un map vide plutôt que de lancer une exception
      // pour permettre à l'UI de gérer gracieusement
      return {
        'commercial': {},
        'client': null,
        'isCommercialSubscription': false,
      };
    }
  }

  /// Charge les données utilisateur de base (pour les formulaires)
  /// Utilise les données du client si fournies, sinon charge le profil de l'utilisateur connecté
  /// 
  /// [clientId] : ID du client si souscription par commercial (optionnel)
  /// [clientData] : Données du client si disponibles (optionnel)
  /// 
  /// Retourne : Map contenant les données utilisateur
  static Future<Map<String, dynamic>> loadUserData({
    String? clientId,
    Map<String, dynamic>? clientData,
  }) async {
    try {
      // Si des données client sont fournies, les utiliser directement
      if (clientData != null) {
        return clientData;
      }

      // Si un clientId est fourni, charger depuis l'API
      if (clientId != null) {
        final token = await _storage.read(key: 'token');
        if (token == null) {
          throw Exception('Token non trouvé');
        }

        final clientResponse = await http.get(
          Uri.parse('${AppConfig.baseUrl}/users/$clientId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (clientResponse.statusCode == 200) {
          final clientJson = json.decode(clientResponse.body);
          if (clientJson['success'] == true) {
            return clientJson['user'];
          }
        }
      }

      // Sinon, charger le profil de l'utilisateur connecté
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return {};
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['user'];
        }
      }

      return {};
    } catch (e) {
      return {};
    }
  }
}

