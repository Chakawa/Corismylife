import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/models/contrat.dart';

class ContratService {
  final storage = const FlutterSecureStorage();

  /// Récupère tous les contrats de l'utilisateur connecté
  /// Pour CLIENT: via numéro de téléphone (avec gestion +225)
  /// Pour COMMERCIAL: via code_apporteur
  Future<List<Contrat>> getContrats() async {
    try {
      final token = await storage.read(key: 'token');
      print('🔑 ContratService.getContrats - Token: ${token != null ? "Trouvé" : "NULL"}');
      if (token == null) {
        throw Exception('Vous devez vous connecter pour accéder à vos contrats');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrats/mes-contrats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Data décodé: ${data.keys}');
        
        final List<dynamic> contratsJson = data['contrats'] ?? [];
        print('📋 Nombre de contrats JSON: ${contratsJson.length}');
        
        if (contratsJson.isEmpty) {
          return [];
        }
        
        try {
          final contrats = contratsJson.map((json) {
            print('🔄 Parsing contrat: ${json['numepoli']}');
            return Contrat.fromJson(json);
          }).toList();
          print('✅ ${contrats.length} contrat(s) parsé(s) avec succès');
          return contrats;
        } catch (e) {
          print('❌ Erreur lors du parsing des contrats: $e');
          rethrow;
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('❌ Body: ${response.body}');
        throw Exception('Erreur lors de la récupération des contrats: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getContrats: $e');
      rethrow;
    }
  }

  /// Récupère les détails d'un contrat spécifique
  Future<Contrat> getContratDetails(int id) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Vous devez vous connecter pour accéder aux détails');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrats/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Contrat.fromJson(data['contrat']);
      } else {
        throw Exception('Erreur lors de la récupération du contrat: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getContratDetails: $e');
      rethrow;
    }
  }
}
