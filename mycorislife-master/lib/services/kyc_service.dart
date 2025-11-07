import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

/// Service pour gérer les documents KYC
class KYCService {
  static const _storage = FlutterSecureStorage();
  static String get baseUrl => '${AppConfig.baseUrl}/kyc';

  static Future<List<Map<String, dynamic>>> getRequirements() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('Token non trouvé');
    final response = await http.get(
      Uri.parse('$baseUrl/requirements'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['requirements'] ?? []);
    }
    throw Exception(data['message'] ?? 'Erreur');
  }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('Token non trouvé');
    final response = await http.get(
      Uri.parse('$baseUrl/documents'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['documents'] ?? []);
    }
    throw Exception(data['message'] ?? 'Erreur');
  }

  static Future<Map<String, dynamic>> uploadDocument(String filePath, String docKey) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('Token non trouvé');
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['doc_key'] = docKey;
    request.files.add(await http.MultipartFile.fromPath('document', filePath));
    final response = await http.Response.fromStream(await request.send());
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['document'];
    }
    throw Exception(data['message'] ?? 'Erreur upload');
  }
}



