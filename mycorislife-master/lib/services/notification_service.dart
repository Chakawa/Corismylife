import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

/// ============================================
/// SERVICE NOTIFICATIONS
/// ============================================
/// Gère toutes les opérations liées aux notifications de l'application.
///
/// Fonctionnalités :
/// - Récupérer toutes les notifications de l'utilisateur
/// - Compter les notifications non lues
/// - Marquer une notification comme lue
/// - Marquer toutes les notifications comme lues
///
/// Toutes ces opérations nécessitent une connexion Internet et un token d'authentification valide.

class NotificationService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String get baseUrl => '${AppConfig.baseUrl}/notifications';

  /// ==========================================
  /// RÉCUPÉRER TOUTES LES NOTIFICATIONS
  /// ==========================================
  /// Récupère toutes les notifications de l'utilisateur connecté depuis le serveur.
  /// Nécessite une connexion Internet et un token d'authentification valide.
  ///
  /// @returns Map contenant les notifications et métadonnées
  ///
  /// @throws Exception avec message clair si :
  ///   - Pas de token d'authentification
  ///   - Pas de connexion Internet
  ///   - Timeout de la requête
  ///   - Erreur serveur
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      // Vérifier que l'utilisateur est authentifié
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception(
            'Vous devez être connecté pour voir vos notifications.');
      }

      // Vérifier la connexion Internet
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception(
              'Aucune connexion Internet. La récupération des notifications nécessite une connexion Internet.');
        }
      } catch (e) {
        throw Exception(
            'Impossible de récupérer les notifications. Vérifiez votre connexion Internet.');
      }

      // Faire la requête GET avec timeout réduit à 5 secondes
      final response = await http.get(
        Uri.parse(baseUrl),
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

      // Gérer le cas où la réponse est vide ou invalide
      if (response.body.isEmpty) {
        return {
          'notifications': [],
          'unread_count': 0
        };
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Gérer différents formats de réponse du backend
        if (data['success'] == true) {
          // Format standard: { success: true, notifications: [...], unread_count: ... }
          return {
            'notifications': data['notifications'] ?? data['data']?['notifications'] ?? [],
            'unread_count': data['unread_count'] ?? data['data']?['unread_count'] ?? 0
          };
        } else if (data['notifications'] != null) {
          // Format alternatif: { notifications: [...], unread_count: ... }
          return {
            'notifications': data['notifications'] is List ? data['notifications'] : [],
            'unread_count': data['unread_count'] ?? 0
          };
        } else {
          // Pas de notifications
          return {
            'notifications': [],
            'unread_count': 0
          };
        }
      } else {
        if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la récupération des notifications. Veuillez réessayer.');
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
          'Erreur lors de la récupération des notifications: ${e.toString()}');
    }
  }

  /// ==========================================
  /// COMPTER LES NOTIFICATIONS NON LUES
  /// ==========================================
  /// Récupère le nombre de notifications non lues de l'utilisateur.
  /// Nécessite une connexion Internet et un token d'authentification.
  ///
  /// En cas d'erreur (pas d'Internet, serveur inaccessible), retourne 0
  /// pour ne pas bloquer l'interface utilisateur.
  ///
  /// @returns Le nombre de notifications non lues (int), ou 0 en cas d'erreur
  static Future<int> getUnreadCount() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return 0; // Pas connecté = pas de notifications
      }

      // Vérifier la connexion Internet
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          return 0; // Pas d'Internet, retourner 0 silencieusement
        }
      } catch (e) {
        return 0; // Pas d'Internet, retourner 0 silencieusement
      }

      // Faire la requête GET avec timeout réduit à 5 secondes
      final response = await http.get(
        Uri.parse('$baseUrl/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout'); // Timeout, retourner 0 via catch
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']['unreadCount'] ?? 0;
      } else {
        return 0; // Erreur serveur, retourner 0 silencieusement
      }
    } catch (e) {
      // En cas d'erreur quelconque, retourner 0 pour ne pas bloquer l'UI
      return 0;
    }
  }

  /// Marque une notification comme lue
  static Future<void> markAsRead(int notificationId) async {
    try {
      final token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(
            data['message'] ?? 'Erreur lors du marquage de la notification');
      }
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
      rethrow;
    }
  }

  /// Marque toutes les notifications comme lues
  static Future<void> markAllAsRead() async {
    try {
      final token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(
            data['message'] ?? 'Erreur lors du marquage des notifications');
      }
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
      rethrow;
    }
  }
}
