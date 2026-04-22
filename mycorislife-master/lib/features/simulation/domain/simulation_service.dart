import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/config/app_config.dart';

class SimulationService {

  /// Enregistrer une simulation

  static Future<bool> saveSimulation({

    required String produitNom,
    required String typeSimulation,
    int? age,
    String? dateNaissance,
    double? capital,
    double? prime,
    int? dureeMois,
    String? periodicite,
    double? resultatPrime,
    double? resultatCapital,
  }) async {

    try {

      // Récupérer le token si l'utilisateur est connecté
      final token = await AuthService.getToken();

      final headers = {

        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({

        'produit_nom': produitNom,
        'type_simulation': typeSimulation,
        if (age != null) 'age': age,
        if (dateNaissance != null) 'date_naissance': dateNaissance,
        if (capital != null) 'capital': capital,
        if (prime != null) 'prime': prime,
        if (dureeMois != null) 'duree_mois': dureeMois,
        if (periodicite != null) 'periodicite': periodicite,
        if (resultatPrime != null) 'resultat_prime': resultatPrime,
        if (resultatCapital != null) 'resultat_capital': resultatCapital,
      });

      print('📊 Enregistrement simulation: $produitNom - $typeSimulation');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/simulations'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {

        print('✅ Simulation enregistrée avec succès');
        return true;
      } else {

        print('❌ Erreur enregistrement simulation: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }

    } catch (e) {

      print('❌ Exception lors de l\'enregistrement de la simulation: $e');
      return false;
    }

  }

  /// Récupérer les simulations de l'utilisateur connecté

  static Future<List<Map<String, dynamic>>> getUserSimulations() async {

    try {

      final token = await AuthService.getToken();

      if (token == null) {

        print('⚠️ Utilisateur non connecté');
        return [];
      }

      final headers = {

        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/simulations/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        if (data['success'] == true) {

          return List<Map<String, dynamic>>.from(data['data']);
        }

      }

      return [];
    } catch (e) {

      print('❌ Erreur lors de la récupération des simulations: $e');
      return [];
    }

  }

}

