import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mycorislife/config/app_config.dart';

/// Service pour gérer les documents (pièces d'identité)
/// Permet d'uploader, récupérer et supprimer des documents
class DocumentService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Upload de la pièce d'identité pour une souscription
  ///
  /// [subscriptionId] : ID de la souscription
  /// [imagePath] : Chemin local du fichier image/PDF
  /// Retourne les données de la souscription mise à jour
  static Future<Map<String, dynamic>> uploadIdentityCardForSubscription(
    int subscriptionId,
    String imagePath,
  ) async {
    try {
      debugPrint(
          '📤 Début upload pièce d\'identité pour souscription $subscriptionId...');

      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Fichier non trouvé: $imagePath');
      }

      final fileSize = await file.length();
      debugPrint(
          '📊 Taille du fichier: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      final uri = Uri.parse(
          '${AppConfig.baseUrl}/subscriptions/$subscriptionId/upload-document');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'document',
        imagePath,
      ));

      debugPrint('🚀 Envoi de la requête à: $uri');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Status code: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Pièce d\'identité uploadée pour la souscription');
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de l\'upload');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur serveur');
      }
    } catch (e) {
      debugPrint('❌ Erreur uploadIdentityCardForSubscription: $e');
      rethrow;
    }
  }

  /// Récupérer l'URL complète de la pièce d'identité d'une souscription
  ///
  /// [subscriptionId] : ID de la souscription
  /// [filename] : Nom du fichier
  /// Retourne l'URL complète pour afficher le document
  static String getIdentityCardUrl(int subscriptionId, String filename) {
    if (filename.isEmpty) return '';

    // Si c'est déjà une URL complète
    if (filename.startsWith('http')) {
      return filename;
    }

    // Si c'est juste le nom du fichier
    if (!filename.startsWith('/')) {
      return '${AppConfig.baseUrl}/subscriptions/$subscriptionId/document/$filename';
    }

    // Si c'est un chemin relatif et commence par /uploads/
    if (filename.startsWith('/uploads/')) {
      // Extraire le nom du fichier
      final parts = filename.split('/');
      final justFilename = parts.last;
      return '${AppConfig.baseUrl}/subscriptions/$subscriptionId/document/$justFilename';
    }

    // Si c'est un chemin relatif API
    return '${AppConfig.baseUrl}$filename';
  }

  /// Récupérer l'URL complète de la photo de profil
  ///
  /// [filename] : Nom du fichier ou URL
  /// Retourne l'URL complète pour afficher la photo
  static String getPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';

    // Si c'est déjà une URL complète
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }

    // Si c'est juste le nom du fichier
    if (!photoUrl.startsWith('/')) {
      return '${AppConfig.baseUrl}/users/photo/$photoUrl';
    }

    // Si c'est un chemin relatif
    return '${AppConfig.baseUrl}$photoUrl';
  }

  /// Télécharger un document depuis le serveur
  ///
  /// [url] : URL complète du document
  /// Retourne les bytes du fichier
  static Future<List<int>> downloadDocument(String url) async {
    try {
      debugPrint('📥 Téléchargement document: $url');

      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Document téléchargé: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        throw Exception(
            'Erreur lors du téléchargement: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur downloadDocument: $e');
      rethrow;
    }
  }

  /// Vérifier si un document existe sur le serveur
  ///
  /// [url] : URL du document à vérifier
  /// Retourne true si le document existe
  static Future<bool> documentExists(String url) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return false;

      final response = await http.head(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Erreur documentExists: $e');
      return false;
    }
  }
}
