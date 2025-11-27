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
    print('👥 [LISTE CLIENTS] ========== DÉBUT CHARGEMENT ==========');
    setState(() => isLoading = true);
    
    try {
      final token = await storage.read(key: 'token');
      print('🔑 [LISTE CLIENTS] Token: ${token != null ? "✅ OK" : "❌ Manquant"}');
      
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final url = '${AppConfig.baseUrl}/commercial/liste_clients';
      print('🌐 [LISTE CLIENTS] URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 [LISTE CLIENTS] Status: ${response.statusCode}');
      print('📦 [LISTE CLIENTS] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [LISTE CLIENTS] Données décodées: ${data.keys}');
        
        setState(() {
          clients = data['clients'] ?? [];
          isLoading = false;
        });
        
        print('📋 [LISTE CLIENTS] ${clients.length} clients chargés');
      } else {
        print('❌ [LISTE CLIENTS] Erreur HTTP ${response.statusCode}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ [LISTE CLIENTS] EXCEPTION: $e');
      print('📍 [LISTE CLIENTS] Stack: $stackTrace');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    print('👥 [LISTE CLIENTS] ========== FIN CHARGEMENT ==========');
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
