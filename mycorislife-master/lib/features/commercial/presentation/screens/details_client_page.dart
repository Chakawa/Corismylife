import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:intl/intl.dart';

class DetailsClientPage extends StatefulWidget {
  const DetailsClientPage({Key? key}) : super(key: key);

  @override
  State<DetailsClientPage> createState() => _DetailsClientPageState();
}

class _DetailsClientPageState extends State<DetailsClientPage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? clientInfo;
  List<dynamic> clientSubscriptions = [];
  bool isLoading = true;
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      // Récupérer les infos client passées en argument
      if (args['client'] != null) {
        clientInfo = args['client'];
        _loadClientSubscriptions();
      }
    }
  }

  Future<void> _loadClientSubscriptions() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      // Récupérer toutes les souscriptions du commercial
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/subscriptions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allSubs = data['data'] as List;
        
        // Filtrer les souscriptions de ce client par téléphone
        final clientPhone = clientInfo?['telephone'];
        final filteredSubs = allSubs.where((sub) {
          final subClientInfo = sub['souscriptiondata']?['client_info'];
          return subClientInfo?['telephone'] == clientPhone;
        }).toList();
        
        // Utiliser les infos complètes de la première souscription (la plus récente)
        // car elle contient TOUTES les informations du client
        if (filteredSubs.isNotEmpty && filteredSubs[0]['souscriptiondata']?['client_info'] != null) {
          clientInfo = Map<String, dynamic>.from(
            filteredSubs[0]['souscriptiondata']['client_info']
          );
        }
        
        setState(() {
          clientSubscriptions = filteredSubs;
          isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des souscriptions');
      }
    } catch (e) {
      print('Erreur: $e');
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
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatutColor(String? statut) {
    if (statut == null) return 'grey';
    final s = statut.toLowerCase();
    if (s.contains('payé') || s.contains('paye')) return 'green';
    if (s.contains('attente')) return 'orange';
    if (s.contains('refusé') || s.contains('refuse')) return 'red';
    return 'grey';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Détails Client',
          style: TextStyle(color: blanc, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bleuCoris,
        iconTheme: const IconThemeData(color: blanc),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: bleuCoris))
          : clientInfo == null
              ? const Center(
                  child: Text(
                    'Aucune information disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClientSubscriptions,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête client
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [bleuCoris, bleuCoris.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: blanc,
                                  child: Text(
                                    '${clientInfo!['prenom']?.toString().substring(0, 1).toUpperCase() ?? 'C'}${clientInfo!['nom']?.toString().substring(0, 1).toUpperCase() ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: bleuCoris,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${clientInfo!['prenom'] ?? ''} ${clientInfo!['nom'] ?? ''}'.trim(),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: blanc,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Informations personnelles
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                    color: bleuCoris,
                                  ),
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(Icons.person, 'Civilité', clientInfo!['civilite']),
                                _buildInfoRow(Icons.email, 'Email', clientInfo!['email']),
                                _buildInfoRow(Icons.phone, 'Téléphone', clientInfo!['telephone']),
                                _buildInfoRow(Icons.cake, 'Date de naissance', _formatDate(clientInfo!['date_naissance'])),
                                _buildInfoRow(Icons.location_city, 'Lieu de naissance', clientInfo!['lieu_naissance']),
                                _buildInfoRow(Icons.home, 'Adresse', clientInfo!['adresse']),
                                _buildInfoRow(Icons.badge, 'N° Pièce d\'identité', clientInfo!['numero_piece_identite']),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Liste des souscriptions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Souscriptions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: bleuCoris,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: bleuCoris,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${clientSubscriptions.length}',
                                style: const TextStyle(
                                  color: blanc,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (clientSubscriptions.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Aucune souscription trouvée',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ...clientSubscriptions.map((sub) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/commercial/subscription_detail',
                                    arguments: {'subscription': sub},
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sub['produit_nom'] ?? 'Produit inconnu',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: bleuCoris,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatutColor(sub['statut']) == 'green' 
                                                  ? Colors.green 
                                                  : _getStatutColor(sub['statut']) == 'orange'
                                                      ? Colors.orange
                                                      : _getStatutColor(sub['statut']) == 'red'
                                                          ? Colors.red
                                                          : Colors.grey,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              sub['statut'] ?? 'En attente',
                                              style: const TextStyle(
                                                color: blanc,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Créée le ${_formatDate(sub['date_creation'])}',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      if (sub['montant_total'] != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Montant: ${sub['montant_total']} FCFA',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: bleuCoris,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: bleuCoris),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
