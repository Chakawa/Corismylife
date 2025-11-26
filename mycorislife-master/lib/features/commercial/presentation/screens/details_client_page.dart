import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

class DetailsClientPage extends StatefulWidget {
  const DetailsClientPage({Key? key}) : super(key: key);

  @override
  State<DetailsClientPage> createState() => _DetailsClientPageState();
}

class _DetailsClientPageState extends State<DetailsClientPage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? clientDetails;
  bool isLoading = true;

  // Mapping des codes produits vers les noms de produits
  final Map<String, String> productNames = {
    '225': 'SOLIDARITÉ',
    '205': 'FLEX',
    '242': 'ÉPARGNE',
    '240': 'RETRAITE',
    '202': 'SÉRÉNITÉ',
    '246': 'ÉTUDE',
    '200': 'FAMILIS',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['client_id'] != null) {
      _loadClientDetails(args['client_id']);
    }
  }

  Future<void> _loadClientDetails(int clientId) async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/details_client/$clientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          clientDetails = data;
          isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des détails');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _getProductName(String? codeProd) {
    if (codeProd == null) return 'Produit inconnu';
    return productNames[codeProd] ?? 'Produit $codeProd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Client'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clientDetails == null
              ? const Center(
                  child: Text(
                    'Aucune information disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du client
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informations personnelles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow('Nom', clientDetails!['client']?['nom']),
                              _buildInfoRow('Prénom', clientDetails!['client']?['prenom']),
                              _buildInfoRow('Email', clientDetails!['client']?['email']),
                              _buildInfoRow('Téléphone', clientDetails!['client']?['telephone']),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Liste des contrats
                      const Text(
                        'Contrats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (clientDetails!['contrats'] != null &&
                          (clientDetails!['contrats'] as List).isNotEmpty)
                        ...(clientDetails!['contrats'] as List).map((contrat) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text('Contrat ${contrat['numepoli'] ?? 'N/A'}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Produit: ${_getProductName(contrat['codeprod'])}'),
                                  Text('Statut: ${contrat['statut'] ?? 'N/A'}'),
                                ],
                              ),
                            ),
                          );
                        }).toList()
                      else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucun contrat trouvé'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
