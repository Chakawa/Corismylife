import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
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
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Vous devez être connecté pour voir votre profil.');
      }

      // Vérifier rapidement la résolution DNS de l'hôte API. Ne PAS lever
      // immédiatement une exception si la vérification échoue : dans des
      // environnements locaux (émulateur / 10.0.2.2) ou lorsque google.com est
      // filtré, la vérification DNS peut fausser le diagnostique. On augmente
      // le timeout et on poursuit ; l'appel HTTP réel décidera de la suite.
      try {
        final host = Uri.parse(AppConfig.baseUrl).host;
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 5));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          debugPrint(
              '⚠️ getProfile: lookup renvoyé une adresse vide pour $host');
        }
      } catch (e) {
        debugPrint('⚠️ getProfile: vérification DNS échouée (ignore): $e');
        // On n'interrompt pas l'exécution ici ; laisser l'appel HTTP gérer
        // l'absence de connectivité ou l'indisponibilité du backend.
      }

      final response = await http.get(Uri.parse('$baseUrl/profile'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 8), onTimeout: () {
        throw Exception('Le serveur met trop de temps à répondre.');
      });

      // response.body is always a String; avoid dead null-aware expression
      final bodyText = response.body;
      Map<String, dynamic> data = {};
      try {
        final parsed = json.decode(bodyText);
        if (parsed is Map<String, dynamic>) data = parsed;
      } catch (e) {
        debugPrint('⚠️ getProfile: réponse non JSON: $bodyText');
        throw Exception(
            'Réponse invalide du serveur lors de la récupération du profil.');
      }

      // Extraire l'objet utilisateur en acceptant plusieurs schémas
      Map<String, dynamic>? user;

      // 1) Cas: { success: true, data: { id, civilite, nom, prenom, ... } }
      if (data['success'] == true &&
          data['data'] != null &&
          data['data'] is Map) {
        final dataObj = data['data'] as Map<String, dynamic>;
        if (dataObj.containsKey('id') || dataObj.containsKey('email')) {
          user = dataObj;
        }
      }

      // 2) Cas: { success: true, data: { user: { id, ... } } }
      if (user == null &&
          data['success'] == true &&
          data['data'] != null &&
          data['data'] is Map &&
          data['data']['user'] != null &&
          data['data']['user'] is Map) {
        user = Map<String, dynamic>.from(data['data']['user']);
      }

      // 3) Cas: { success: true, user: { id, ... } }
      if (user == null &&
          data['success'] == true &&
          data['user'] != null &&
          data['user'] is Map) {
        user = Map<String, dynamic>.from(data['user']);
      }

      // 4) Cas: { id, civilite, nom, prenom, ... } (objet utilisateur direct)
      if (user == null && data.containsKey('id') && data.containsKey('email')) {
        user = Map<String, dynamic>.from(data);
      }

      if (response.statusCode == 200 && user != null) {
        await _storage.write(key: 'user', value: json.encode(user));
        return user;
      }

      debugPrint(
          '⚠️ getProfile: réponse inattendue (${response.statusCode}): $bodyText');

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }

      throw Exception(
          data['message'] ?? 'Erreur lors de la récupération du profil.');
    } on SocketException {
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
          'Erreur lors de la récupération du profil: ${e.toString()}');
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

      // Vérifier rapidement la résolution DNS de l'hôte API (timeout augmenté).
      // Même si cette vérification échoue, on ne bloque pas la mise à jour :
      // l'appel HTTP avec timeout produira une erreur claire si le backend
      // n'est pas accessible (meilleur signal pour l'utilisateur).
      try {
        final host = Uri.parse(AppConfig.baseUrl).host;
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 5));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          debugPrint(
              '⚠️ updateProfile: lookup renvoyé une adresse vide pour $host');
        }
      } catch (e) {
        debugPrint('⚠️ updateProfile: vérification DNS échouée (ignore): $e');
        // Ne pas lever d'exception ici ; laisser la requête HTTP gérer l'erreur.
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
      final response = await http
          .put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      )
          .timeout(
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
      throw Exception(
          'Erreur lors de la mise à jour du profil: ${e.toString()}');
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
      final response = await http
          .put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      )
          .timeout(
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
      throw Exception(
          'Erreur lors du changement de mot de passe: ${e.toString()}');
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
      debugPrint('❌ Erreur uploadPhoto: $e');
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
      debugPrint('❌ Erreur getUserFromStorage: $e');
      return null;
    }
  }
}
