import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AdminService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Récupère les inscriptions en attente (SMS non reçu / compte non finalisé)
  static Future<List<Map<String, dynamic>>> getPendingRegistrations() async {
    final token = await _getToken();
    if (token == null) throw Exception('Session expirée. Veuillez vous reconnecter.');

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/pending-registrations'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception(data['message'] ?? 'Erreur serveur');
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      throw Exception('Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion Internet.');
    }
  }

  /// Active le compte d'une inscription en attente (l'admin crée le compte)
  static Future<Map<String, dynamic>> activatePendingRegistration(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Session expirée. Veuillez vous reconnecter.');

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/admin/pending-registrations/$id/activate'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 201) return data;
      throw Exception(data['message'] ?? 'Erreur lors de l\'activation');
    } on SocketException {
      throw Exception('Pas de connexion Internet.');
    }
  }

  /// Supprime une inscription en attente
  static Future<void> deletePendingRegistration(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Session expirée. Veuillez vous reconnecter.');

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/admin/pending-registrations/$id'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return;
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Erreur lors de la suppression');
    } on SocketException {
      throw Exception('Pas de connexion Internet.');
    }
  }

  /// Récupère les statistiques globales du dashboard admin
  static Future<Map<String, dynamic>> getStats() async {
    final token = await _getToken();
    if (token == null) throw Exception('Session expirée. Veuillez vous reconnecter.');

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/admin/stats'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) return data['stats'];
        throw Exception(data['message'] ?? 'Erreur serveur');
      }
      throw Exception('Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion Internet.');
    }
  }
}
