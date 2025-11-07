import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

/// Service pour rattacher une proposition à l'utilisateur connecté
class SubscriptionAttachService {
  static const _storage = FlutterSecureStorage();
  static String get baseUrl => '${AppConfig.baseUrl}/subscriptions';

  /// Rattache une proposition par numéro de police ou ID
  static Future<Map<String, dynamic>> attachProposal({
    String? numeroPolice,
    int? id,
  }) async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('Token non trouvé');

    final response = await http.post(
      Uri.parse('$baseUrl/attach'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        if (numeroPolice != null) 'numero_police': numeroPolice,
        if (id != null) 'id': id,
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Erreur lors du rattachement');
    }
  }
}



