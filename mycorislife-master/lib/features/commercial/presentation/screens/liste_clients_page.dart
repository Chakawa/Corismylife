import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

class ListeClientsPage extends StatefulWidget {
  const ListeClientsPage({Key? key}) : super(key: key);

  @override
  State<ListeClientsPage> createState() => _ListeClientsPageState();
}

class _ListeClientsPageState extends State<ListeClientsPage> {
  final storage = const FlutterSecureStorage();
  List<dynamic> clients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/liste_clients'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          clients = data['clients'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des clients');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Clients'),
        backgroundColor: const Color(0xFF002B6B),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun client trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClients,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF002B6B),
                            child: Text(
                              (client['prenom']?.toString().isNotEmpty == true 
                                  ? client['prenom'].toString().substring(0, 1).toUpperCase()
                                  : client['nom']?.toString().isNotEmpty == true
                                      ? client['nom'].toString().substring(0, 1).toUpperCase()
                                      : 'C'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${client['prenom']?.toString().trim() ?? ''} ${client['nom']?.toString().trim() ?? ''}'.trim().isEmpty
                                ? 'Client sans nom'
                                : '${client['prenom']?.toString().trim() ?? ''} ${client['nom']?.toString().trim() ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${client['email'] ?? 'N/A'}'),
                              Text('Tél: ${client['telephone'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/details_client',
                              arguments: {'client_id': client['id']},
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
