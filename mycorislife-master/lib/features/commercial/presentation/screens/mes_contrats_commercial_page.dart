import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/features/commercial/presentation/screens/contrat_details_page.dart';

class MesContratsCommercialPage extends StatefulWidget {
  const MesContratsCommercialPage({Key? key}) : super(key: key);

  @override
  State<MesContratsCommercialPage> createState() => _MesContratsCommercialPageState();
}

class _MesContratsCommercialPageState extends State<MesContratsCommercialPage> {
  final storage = const FlutterSecureStorage();
  List<dynamic> contrats = [];
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
  void initState() {
    super.initState();
    _loadContrats();
  }

  Future<void> _loadContrats() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/mes_contrats_commercial'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          contrats = data['contrats'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des contrats');
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

  String _formatClientName(dynamic contrat) {
    // Essayer d'abord avec prénom et nom séparés
    if (contrat['prenom'] != null && contrat['nom'] != null) {
      final prenom = contrat['prenom'].toString().trim();
      final nom = contrat['nom'].toString().trim();
      if (prenom.isNotEmpty && nom.isNotEmpty) {
        return '$prenom $nom';
      }
    }
    // Sinon utiliser nomprenom
    if (contrat['nomprenom'] != null) {
      return contrat['nomprenom'].toString().trim();
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Contrats'),
        backgroundColor: const Color(0xFF002B6B),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contrats.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun contrat trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContrats,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: contrats.length,
                    itemBuilder: (context, index) {
                      final contrat = contrats[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            'Contrat ${contrat['numepoli'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Produit: ${_getProductName(contrat['codeprod'])}'),
                              Text('Client: ${_formatClientName(contrat)}'),
                              Text('Statut: ${contrat['statut'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContratDetailsPage(contrat: contrat),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
