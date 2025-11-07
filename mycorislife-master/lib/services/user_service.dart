import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mycorislife/config/app_config.dart';

/// ============================================
/// SERVICE UTILISATEUR
/// ============================================
/// Gère toutes les opérations liées au profil utilisateur

class UserService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static String get baseUrl => '${AppConfig.baseUrl}/users';

  /// ==========================================
  /// RÉCUPÉRER LE PROFIL DE L'UTILISATEUR
  /// ==========================================
  /// Récupère les informations du profil de l'utilisateur connecté depuis le serveur.
  /// Nécessite une connexion Internet et un token d'authentification valide.
  /// 
  /// Les données récupérées sont sauvegardées en cache local pour consultation offline.
  /// 
  /// @returns Map contenant toutes les données du profil utilisateur
  /// 
  /// @throws Exception avec message clair si :
  ///   - Pas de token d'authentification
  ///   - Pas de connexion Internet
  ///   - Timeout de la requête
  ///   - Erreur serveur
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      // Vérifier que l'utilisateur est authentifié
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Vous devez être connecté pour voir votre profil.');
      }

      // Vérifier la connexion Internet avant de faire la requête
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception(
              'Aucune connexion Internet. La récupération du profil nécessite une connexion Internet.');
        }
      } catch (e) {
        throw Exception(
            'Impossible de récupérer le profil. Vérifiez votre connexion Internet et réessayez.');
      }

      // Faire la requête GET avec timeout réduit à 5 secondes
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception(
              'Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet.');
        },
      );

      final data = json.decode(response.body);

      // Vérifier si la requête a réussi
      if (response.statusCode == 200 && data['success'] == true) {
        // Sauvegarder les données utilisateur en local pour consultation offline
        await _storage.write(key: 'user', value: json.encode(data['data']));
        return data['data'];
      } else {
        // Gérer les erreurs selon le code de statut
        if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception(data['message'] ?? 
              'Erreur lors de la récupération du profil. Veuillez réessayer.');
        }
      }
    } on SocketException {
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } on HttpException {
      throw Exception(
          'Erreur de communication avec le serveur. Veuillez réessayer.');
    } catch (e) {
      // Si c'est déjà une Exception avec message clair, la relancer
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors de la récupération du profil: ${e.toString()}');
    }
  }

  /// ==========================================
  /// METTRE À JOUR LE PROFIL DE L'UTILISATEUR
  /// ==========================================
  /// Met à jour les informations du profil utilisateur sur le serveur.
  /// Nécessite une connexion Internet et un token d'authentification valide.
  /// 
  /// @param civilite: La civilité (M, Mme, etc.)
  /// @param nom: Le nom de l'utilisateur
  /// @param prenom: Le prénom de l'utilisateur
  /// @param telephone: Le numéro de téléphone
  /// @param adresse: L'adresse (optionnel)
  /// @param dateNaissance: La date de naissance (optionnel)
  /// @param lieuNaissance: Le lieu de naissance (optionnel)
  /// @param pays: Le pays (optionnel)
  /// 
  /// @returns Map contenant les données du profil mis à jour
  /// 
  /// @throws Exception avec message clair si :
  ///   - Pas de token d'authentification
  ///   - Pas de connexion Internet
  ///   - Timeout de la requête
  ///   - Erreur serveur
  static Future<Map<String, dynamic>> updateProfile({
    required String civilite,
    required String nom,
    required String prenom,
    required String telephone,
    String? adresse,
    String? dateNaissance,
    String? lieuNaissance,
    String? pays,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Vous devez être connecté pour modifier votre profil.');
      }

      // Vérifier la connexion Internet
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception(
              'Aucune connexion Internet. La mise à jour du profil nécessite une connexion Internet.');
        }
      } catch (e) {
        throw Exception(
            'Impossible de mettre à jour le profil. Vérifiez votre connexion Internet.');
      }

      // Préparer le corps de la requête avec les données à mettre à jour
      final body = {
        'civilite': civilite,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        if (adresse != null) 'adresse': adresse,
        if (dateNaissance != null) 'date_naissance': dateNaissance,
        if (lieuNaissance != null) 'lieu_naissance': lieuNaissance,
        if (pays != null) 'pays': pays,
      };

      // Faire la requête PUT avec timeout réduit à 5 secondes
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception(
              'Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet.');
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour les données en cache local avec les nouvelles données
        await _storage.write(key: 'user', value: json.encode(data['data']));
        return data['data'];
      } else {
        if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception(data['message'] ?? 
              'Erreur lors de la mise à jour du profil. Veuillez réessayer.');
        }
      }
    } on SocketException {
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } catch (e) {
      if (e is Exception && 
          (e.toString().contains('Timeout') || 
           e.toString().contains('timeout') ||
           e.toString().contains('connexion') ||
           e.toString().contains('Internet'))) {
        rethrow;
      }
      throw Exception('Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
  }

  /// Change le mot de passe de l'utilisateur
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      // Faire la requête PUT avec timeout réduit à 5 secondes
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception(
              'Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet.');
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        if (response.statusCode == 401) {
          throw Exception('Ancien mot de passe incorrect. Veuillez réessayer.');
        } else if (response.statusCode == 400) {
          throw Exception(data['message'] ?? 
              'Le nouveau mot de passe ne respecte pas les critères requis.');
        } else {
          throw Exception(data['message'] ?? 
              'Erreur lors du changement de mot de passe. Veuillez réessayer.');
        }
      }
    } on SocketException {
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } catch (e) {
      if (e is Exception && 
          (e.toString().contains('Timeout') || 
           e.toString().contains('timeout') ||
           e.toString().contains('connexion') ||
           e.toString().contains('Internet'))) {
        rethrow;
      }
      throw Exception('Erreur lors du changement de mot de passe: ${e.toString()}');
    }
  }

  /// Upload une photo de profil
  static Future<String> uploadPhoto(String imagePath) async {
    try {
      final token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imagePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final photoUrl = data['data']['photo_url'];

        // Mettre à jour les données utilisateur en local
        final userJson = await _storage.read(key: 'user');
        if (userJson != null) {
          final user = json.decode(userJson);
          user['photo_url'] = photoUrl;
          await _storage.write(key: 'user', value: json.encode(user));
        }

        return photoUrl;
      } else {
        throw Exception(
            data['message'] ?? 'Erreur lors de l\'upload de la photo');
      }
    } catch (e) {
      print('❌ Erreur uploadPhoto: $e');
      rethrow;
    }
  }

  /// Récupère les données utilisateur depuis le stockage local
  static Future<Map<String, dynamic>?> getUserFromStorage() async {
    try {
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) {
        return json.decode(userJson);
      }
      return null;
    } catch (e) {
      print('❌ Erreur getUserFromStorage: $e');
      return null;
    }
  }
}






