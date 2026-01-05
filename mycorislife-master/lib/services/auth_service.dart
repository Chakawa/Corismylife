import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// ==========================================
/// SERVICE D'AUTHENTIFICATION
/// ==========================================
/// Gère toutes les opérations liées à l'authentification des utilisateurs :
/// - Connexion (login)
/// - Inscription (register)
/// - Gestion du token JWT
/// - Gestion des données utilisateur en cache local
///
/// Ce service utilise un stockage sécurisé (FlutterSecureStorage) pour
/// sauvegarder les informations sensibles (token, données utilisateur).
class AuthService {
  // Instance du stockage sécurisé pour sauvegarder les données sensibles
  static const _storage = FlutterSecureStorage();

  // Clés utilisées pour le stockage sécurisé
  static const _tokenKey = 'token'; // Clé pour stocker le token JWT
  static const _userKey =
      'user_data'; // Clé pour stocker les données utilisateur

  /// ==========================================
  /// CONNEXION D'UN UTILISATEUR
  /// ==========================================
  /// Cette fonction permet à un utilisateur de se connecter avec son email/téléphone
  /// et son mot de passe.
  ///
  /// @param email: L'email ou le numéro de téléphone de l'utilisateur
  /// @param password: Le mot de passe de l'utilisateur
  ///
  /// @returns Map contenant:
  ///   - success: booléen indiquant si la connexion a réussi
  ///   - token: le token JWT pour les requêtes authentifiées
  ///   - user: les données de l'utilisateur connecté
  ///
  /// @throws Exception avec message clair si :
  ///   - L'email/mot de passe est incorrect
  ///   - Pas de connexion Internet
  ///   - Le serveur n'est pas accessible
  ///   - Timeout de la requête
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      // Faire la requête POST vers l'endpoint de connexion
      // Timeout porté à 15 secondes pour mieux tolérer les réseaux lents
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
              'Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet ou réessayez plus tard.');
        },
      );

      // Décoder la réponse JSON
      final data = jsonDecode(response.body);

      // Vérifier si la connexion a réussi (code 200 et success = true)
      if (response.statusCode == 200 && data['success']) {
        // Sauvegarder le token JWT de manière sécurisée
        await _storage.write(key: _tokenKey, value: data['token']);

        // Sauvegarder les données utilisateur de manière sécurisée
        await _storage.write(key: _userKey, value: jsonEncode(data['user']));

        // Sauvegarder le code_apporteur si présent (pour les commerciaux)
        if (data['user'] != null && data['user']['code_apporteur'] != null) {
          await _storage.write(key: 'code_apporteur', value: data['user']['code_apporteur'].toString());
        }

        return data;
      } else {
        // Gérer les différents codes d'erreur du serveur
        if (response.statusCode == 401) {
          throw Exception(
              'Email ou mot de passe incorrect. Veuillez vérifier vos identifiants.');
        } else if (response.statusCode == 404) {
          throw Exception(
              'Serveur non trouvé. Veuillez vérifier votre connexion Internet.');
        } else if (response.statusCode >= 500) {
          throw Exception('Erreur du serveur. Veuillez réessayer plus tard.');
        } else {
          // Utiliser le message d'erreur du serveur s'il existe
          throw Exception(data['message'] ??
              'Échec de la connexion. Veuillez vérifier vos identifiants.');
        }
      }
    } on SocketException {
      // Erreur de connexion réseau (pas de serveur accessible)
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet et réessayez.');
    } on HttpException {
      // Erreur HTTP
      throw Exception(
          'Erreur de communication avec le serveur. Veuillez réessayer.');
    } on FormatException {
      // Erreur de format de réponse
      throw Exception('Réponse invalide du serveur. Veuillez réessayer.');
    } catch (e) {
      // Si le message d'erreur est déjà clair, le retourner tel quel
      if (e.toString().contains('connexion') ||
          e.toString().contains('Internet') ||
          e.toString().contains('timeout')) {
        rethrow;
      }
      // Sinon, créer un message d'erreur générique mais informatif
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  /// ==========================================
  /// VÉRIFIER SI UN TÉLÉPHONE EXISTE DÉJÀ
  /// ==========================================
  /// Vérifie si un numéro de téléphone est déjà utilisé par un autre compte
  ///
  /// @param telephone Le numéro de téléphone à vérifier
  /// @returns true si le téléphone existe déjà, false sinon
  static Future<bool> checkPhoneExists(String telephone) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/check-phone'),
        body: jsonEncode({'telephone': telephone}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      // En cas d'erreur, on retourne false pour ne pas bloquer l'inscription
      return false;
    }
  }

  /// ==========================================
  /// VÉRIFIER SI UN EMAIL EXISTE DÉJÀ
  /// ==========================================
  /// Vérifie si un email est déjà utilisé par un autre compte
  ///
  /// @param email L'email à vérifier
  /// @returns true si l'email existe déjà, false sinon
  static Future<bool> checkEmailExists(String email) async {
    if (email.isEmpty) return false;
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/check-email'),
        body: jsonEncode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      // En cas d'erreur, on retourne false pour ne pas bloquer l'inscription
      return false;
    }
  }

  /// ==========================================
  /// ENVOYER UN CODE OTP PAR SMS
  /// ==========================================
  /// Envoie un code OTP de 5 chiffres au numéro de téléphone
  ///
  /// @param telephone Le numéro de téléphone
  /// @param userData Les données utilisateur à stocker temporairement
  /// @returns Le code OTP (en développement seulement)
  static Future<String?> sendOtp(String telephone, Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/send-otp'),
        body: jsonEncode({
          'telephone': telephone,
          'userData': userData,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // En développement, le serveur peut retourner le code OTP
          return data['otpCode'];
        }
      }
      
      throw Exception('Erreur lors de l\'envoi du code OTP');
    } catch (e) {
      throw Exception('Impossible d\'envoyer le code OTP: ${e.toString()}');
    }
  }

  /// ==========================================
  /// VÉRIFIER LE CODE OTP ET CRÉER LE COMPTE
  /// ==========================================
  /// Vérifie le code OTP et crée le compte si le code est correct
  ///
  /// @param telephone Le numéro de téléphone
  /// @param otpCode Le code OTP à vérifier
  static Future<void> verifyOtpAndRegister(String telephone, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
        body: jsonEncode({
          'telephone': telephone,
          'otpCode': otpCode,
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        return; // Succès
      } else {
        throw Exception(data['message'] ?? 'Code OTP incorrect');
      }
    } catch (e) {
      if (e.toString().contains('Code OTP')) {
        rethrow;
      }
      throw Exception('Erreur lors de la vérification du code OTP');
    }
  }

  /// ==========================================
  /// INSCRIPTION D'UN NOUVEAU CLIENT
  /// ==========================================
  /// Cette fonction permet d'inscrire un nouveau client dans le système.
  ///
  /// @param userData: Map contenant les données du client à inscrire :
  ///   - email: email du client
  ///   - password: mot de passe
  ///   - nom: nom du client
  ///   - prenom: prénom du client
  ///   - telephone: numéro de téléphone
  ///   - autres champs optionnels
  ///
  /// @throws Exception avec message clair si :
  ///   - Pas de connexion Internet
  ///   - Email déjà utilisé
  ///   - Données invalides
  ///   - Erreur serveur
  static Future<void> registerClient(Map<String, dynamic> userData) async {
    // Vérifier d'abord la connexion Internet
    try {
      // Timeout augmenté à 5s pour réseaux lents
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception(
            'Aucune connexion Internet. L\'inscription nécessite une connexion Internet.');
      }
    } catch (e) {
      throw Exception(
          'Impossible de s\'inscrire. Vérifiez votre connexion Internet et réessayez.');
    }

    try {
      // Faire la requête POST vers l'endpoint d'inscription
      // Timeout porté à 10 secondes
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/register'),
        body: jsonEncode(userData),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet.');
        },
      );

      final data = jsonDecode(response.body);

      // Vérifier si l'inscription a réussi (code 201 et success = true)
      if (response.statusCode != 201 || !data['success']) {
        // Gérer les erreurs spécifiques
        if (response.statusCode == 409) {
          throw Exception(
              'Cet email est déjà utilisé. Veuillez utiliser un autre email.');
        } else if (response.statusCode == 400) {
          throw Exception(data['message'] ??
              'Données invalides. Veuillez vérifier les informations saisies.');
        } else {
          throw Exception(data['message'] ??
              'Échec de l\'inscription. Veuillez réessayer.');
        }
      }
    } on SocketException {
      throw Exception(
          'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.');
    } catch (e) {
      if (e.toString().contains('connexion') ||
          e.toString().contains('Internet') ||
          e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  /// ==========================================
  /// RÉCUPÉRER LE RÔLE DE L'UTILISATEUR
  /// ==========================================
  /// Récupère le rôle de l'utilisateur actuellement connecté depuis le cache local.
  /// Les rôles possibles sont : 'client', 'commercial', 'admin'
  ///
  /// @returns Le rôle de l'utilisateur (String) ou null si aucun utilisateur n'est connecté
  static Future<String?> getUserRole() async {
    // Lire les données utilisateur depuis le stockage sécurisé
    final userJson = await _storage.read(key: _userKey);

    // Si des données existent, extraire et retourner le rôle
    if (userJson != null) {
      final user = jsonDecode(userJson);
      return user['role']; // Retourne 'client', 'commercial', ou 'admin'
    }

    // Aucun utilisateur connecté
    return null;
  }

  /// ==========================================
  /// RÉCUPÉRER LES DONNÉES DE L'UTILISATEUR
  /// ==========================================
  /// Récupère toutes les données de l'utilisateur actuellement connecté
  /// depuis le cache local (pas besoin de connexion Internet).
  ///
  /// @returns Map contenant toutes les données utilisateur ou null si non connecté
  static Future<Map<String, dynamic>?> getUser() async {
    // Lire les données utilisateur depuis le stockage sécurisé
    final userJson = await _storage.read(key: _userKey);

    // Si des données existent, les décoder et les retourner
    // Sinon retourner null (aucun utilisateur connecté)
    return userJson != null ? jsonDecode(userJson) : null;
  }

  /// ==========================================
  /// RÉCUPÉRER LE TOKEN JWT
  /// ==========================================
  /// Récupère le token JWT de l'utilisateur actuellement connecté.
  /// Ce token est utilisé pour authentifier les requêtes API.
  ///
  /// @returns Le token JWT (String) ou null si aucun utilisateur n'est connecté
  static Future<String?> getToken() async {
    // Lire le token depuis le stockage sécurisé
    return await _storage.read(key: _tokenKey);
  }

  /// ==========================================
  /// DÉCONNEXION DE L'UTILISATEUR
  /// ==========================================
  /// Déconnecte l'utilisateur en supprimant le token et les données utilisateur
  /// du stockage sécurisé. Cette opération est locale et ne nécessite pas Internet.
  static Future<void> logout() async {
    // Supprimer le token JWT
    await _storage.delete(key: _tokenKey);

    // Supprimer les données utilisateur
    await _storage.delete(key: _userKey);
  }
}
