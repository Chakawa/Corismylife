import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mycorislife/config/app_config.dart';

/// Service pour gérer les questionnaires médicaux
class QuestionnaireMedicalService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Récupère la liste des questions du questionnaire médical depuis l'API
  Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/subscriptions/questionnaire-medical/questions'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['questions'] != null) {
          return List<Map<String, dynamic>>.from(data['questions']);
        }
        throw Exception('Format de réponse invalide');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des questions: $e');
      rethrow;
    }
  }

  /// Enregistre les réponses au questionnaire médical
  Future<bool> saveReponses({
    required int subscriptionId,
    required List<Map<String, dynamic>> reponses,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      print('🔐 Token présent: ${token != null}');
      
      // Convertir les réponses OUI/NON en booléens pour PostgreSQL
      final reponsesConverties = reponses.map((r) {
        final converted = Map<String, dynamic>.from(r);
        
        // Convertir reponse_oui_non de String à bool
        if (converted['reponse_oui_non'] != null) {
          final val = converted['reponse_oui_non'];
          if (val is String) {
            converted['reponse_oui_non'] = val.toUpperCase() == 'OUI';
          } else if (val is bool) {
            // Déjà un booléen, on garde tel quel
            converted['reponse_oui_non'] = val;
          }
        }
        
        return converted;
      }).toList();
      
      print('📤 Envoi des réponses pour souscription $subscriptionId: ${json.encode({'reponses': reponsesConverties})}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/subscriptions/$subscriptionId/questionnaire-medical'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reponses': reponsesConverties}),
      );

      print('📥 Réponse serveur (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('❌ Erreur lors de l\'enregistrement: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement des réponses: $e');
      return false;
    }
  }

  /// Récupère les réponses existantes d'un questionnaire médical
  Future<List<Map<String, dynamic>>?> getReponses(int subscriptionId) async {
    try {
      final token = await _secureStorage.read(key: 'token');
      
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/subscriptions/$subscriptionId/questionnaire-medical'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['reponses'] != null) {
          return List<Map<String, dynamic>>.from(data['reponses']);
        }
        return null;
      } else if (response.statusCode == 404) {
        // Pas encore de réponses enregistrées
        return null;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des réponses: $e');
      return null;
    }
  }
}
