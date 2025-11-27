import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/features/shared/presentation/screens/contrat_details_unified_page.dart';

class ContratsActifsPage extends StatefulWidget {
  const ContratsActifsPage({Key? key}) : super(key: key);

  @override
  State<ContratsActifsPage> createState() => _ContratsActifsPageState();
}

class _ContratsActifsPageState extends State<ContratsActifsPage> {
  final storage = const FlutterSecureStorage();
  List<dynamic> allContrats = [];
  bool isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Mapping des codes produits vers les noms de produits
  final Map<String, String> productNames = {
    '242': 'ÉPARGNE BONUS',
    '202': 'CORIS SÉRÉNITÉ',
    '200': 'CORIS FAMILIS',
    '240': 'CORIS RETRAITE',
    '225': 'CORIS SOLIDARITÉ',
    '246': 'CORIS ÉTUDE',
    '205': 'CORIS FLEX EMPRUNTEUR',
  };

  // Mapping des icônes par produit
  final Map<String, IconData> productIcons = {
    '242': Icons.savings,
    '202': Icons.health_and_safety,
    '200': Icons.family_restroom,
    '240': Icons.elderly,
    '225': Icons.volunteer_activism,
    '246': Icons.school,
    '205': Icons.home,
  };
  
  // Filtrer pour ne garder QUE les contrats actifs
  List<dynamic> get contratsActifs {
    return allContrats.where((contrat) {
      final etat = (contrat['etat'] ?? '').toString().toLowerCase();
      return etat == 'actif';
    }).toList();
  }

  // Filtrer les contrats actifs selon la recherche
  List<dynamic> _filterContrats() {
    if (_searchController.text.isEmpty) return contratsActifs;
    final query = _searchController.text.toLowerCase();
    return contratsActifs.where((contrat) {
      final numepoli = (contrat['numepoli'] ?? '').toString().toLowerCase();
      final client = _formatClientName(contrat).toLowerCase();
      return numepoli.contains(query) || client.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadContratsActifs();
  }

  Future<void> _loadContratsActifs() async {
    print('📋 [CONTRATS ACTIFS] Début chargement...');
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      print('🔑 [CONTRATS ACTIFS] Token récupéré');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/mes_contrats_commercial'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [CONTRATS ACTIFS] Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [CONTRATS ACTIFS] ${(data['contrats'] ?? []).length} contrats reçus');
        setState(() {
          allContrats = data['contrats'] ?? [];
          isLoading = false;
        });
        print('✅ [CONTRATS ACTIFS] ${contratsActifs.length} contrats actifs filtrés');
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [CONTRATS ACTIFS] Erreur: $e');
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // Sinon utiliser nom_prenom
    if (contrat['nom_prenom'] != null) {
      return contrat['nom_prenom'].toString().trim();
    }
    return 'N/A';
  }
  
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredContrats = _filterContrats();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF002B6B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text(
                'Contrats Actifs',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _loadContratsActifs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF002B6B)))
          : Column(
              children: [
                // Stat card pour afficher le nombre de contrats actifs
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${contratsActifs.length}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF002B6B),
                            ),
                          ),
                          const Text(
                            'Contrats Actifs',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredContrats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isEmpty
                                    ? Icons.folder_open
                                    : Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Aucun contrat actif'
                                    : 'Aucun résultat',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadContratsActifs,
                          color: const Color(0xFF002B6B),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredContrats.length,
                            itemBuilder: (context, index) {
                              final contrat = filteredContrats[index];
                              final String etat = (contrat['etat'] ?? '').toString().toLowerCase();
                              final String displayStatus = etat.isNotEmpty && etat != 'null' ? etat.toUpperCase() : 'INACTIF';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    print('🔍 [CONTRATS ACTIFS] Navigation vers détails: ${contrat['numepoli']}');
                                    Navigator.pushNamed(
                                      context,
                                      '/contrat_details',
                                      arguments: contrat,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF002B6B).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                productIcons[contrat['codeprod']] ?? Icons.description,
                                                color: const Color(0xFF002B6B),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    contrat['numepoli'] ?? 'N/A',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF002B6B),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      displayStatus,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Color(0xFF002B6B),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 16,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _getProductName(contrat['codeprod']),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 16,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _formatClientName(contrat),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (contrat['dateeffet'] != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Effet: ${_formatDate(contrat['dateeffet'])}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF64748B),
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
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
