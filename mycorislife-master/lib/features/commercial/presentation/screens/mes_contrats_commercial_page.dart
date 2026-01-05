/**
 * ===============================================
 * PAGE - MES CONTRATS COMMERCIAL
 * ===============================================
 * 
 * Cette page affiche la liste complète des contrats d'un commercial.
 * 
 * FONCTIONNALITÉS :
 * - Affichage de statistiques (Total contrats, Contrats actifs)
 * - Liste des contrats avec recherche et filtres
 * - Navigation vers les détails d'un contrat
 * - Filtrage par statut (Tous, Actif, Inactif)
 * - Recherche par numéro de police ou nom client
 * 
 * ⚠️ UNIFORMISATION DES CHAMPS (IMPORTANT) :
 * ==========================================
 * Cette page utilise UNIQUEMENT le champ 'etat' depuis l'API backend :
 * - Accès via: contrat['etat']
 * - Valeurs possibles: 'Actif', 'Inactif', 'Suspendu'
 * - Ne PAS utiliser contrat['statut'] (ancienne convention, maintenant dépréciée)
 * 
 * DESIGN :
 * - Couleur principale: CORIS Blue #002B6B
 * - Actif: Vert #10B981
 * - Inactif: Orange #F59E0B
 * - Fond: Gris clair #F8FAFC
 */

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

class MesContratsCommercialPage extends StatefulWidget {
  const MesContratsCommercialPage({Key? key}) : super(key: key);

  @override
  State<MesContratsCommercialPage> createState() =>
      _MesContratsCommercialPageState();
}

class _MesContratsCommercialPageState extends State<MesContratsCommercialPage>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  List<dynamic> contrats = [];
  List<dynamic> filteredContrats = [];
  bool isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'tous';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  final Map<String, Map<String, dynamic>> productConfig = {
    '242': {
      'name': 'ÉPARGNE BONUS',
      'color': Color(0xFF8B5CF6),
      'icon': Icons.savings
    },
    '202': {
      'name': 'CORIS SÉRÉNITÉ',
      'color': Color(0xFF002B6B),
      'icon': Icons.health_and_safety
    },
    '200': {
      'name': 'CORIS FAMILIS',
      'color': Color(0xFFF59E0B),
      'icon': Icons.family_restroom
    },
    '240': {
      'name': 'CORIS RETRAITE',
      'color': Color(0xFF10B981),
      'icon': Icons.elderly
    },
    '225': {
      'name': 'CORIS SOLIDARITÉ',
      'color': Color(0xFF002B6B),
      'icon': Icons.volunteer_activism
    },
    '246': {
      'name': 'CORIS ÉTUDE',
      'color': Color(0xFF8B5CF6),
      'icon': Icons.school
    },
    '205': {
      'name': 'CORIS FLEX EMPRUNTEUR',
      'color': Color(0xFFEF4444),
      'icon': Icons.home
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadContrats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContrats() async {
    print('📡 [COMMERCIAL CONTRATS] Début chargement...');
    setState(() => isLoading = true);

    try {
      final token = await storage.read(key: 'token');
      print(
          '🔑 [COMMERCIAL CONTRATS] Token: ${token != null ? "✅ OK" : "❌ Manquant"}');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final url = '${AppConfig.baseUrl}/commercial/mes_contrats_commercial';
      print('🌐 [COMMERCIAL CONTRATS] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 [COMMERCIAL CONTRATS] Status: ${response.statusCode}');
      print('📦 [COMMERCIAL CONTRATS] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [COMMERCIAL CONTRATS] Données décodées: ${data.keys}');

        setState(() {
          contrats = data['contrats'] ?? [];
          filteredContrats = contrats;
          isLoading = false;
        });

        print('📋 [COMMERCIAL CONTRATS] ${contrats.length} contrats chargés');
        _animationController.forward();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [COMMERCIAL CONTRATS] Erreur: $e');
      print('📍 [COMMERCIAL CONTRATS] Stack: $stackTrace');

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

  void _filterContrats() {
    setState(() {
      filteredContrats = contrats.where((contrat) {
        final matchesSearch = _searchQuery.isEmpty ||
            contrat['numepoli']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (contrat['nom_prenom'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesStatus = _filterStatus == 'tous' ||
            (contrat['etat'] ?? '').toString().toLowerCase() ==
                _filterStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Map<String, dynamic> _getProductConfig(String? codeprod) {
    return productConfig[codeprod] ??
        {
          'name': 'Produit $codeprod',
          'color': Color(0xFF64748B),
          'icon': Icons.description,
        };
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actifsCount = contrats
        .where((c) => (c['etat'] ?? '').toString().toLowerCase() == 'actif')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B6B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _filterContrats();
                },
              )
            : const Text(
                'Mes Contrats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        actions: [
          // Icône de recherche maintenant blanche pour être visible
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filterContrats();
                }
              });
            },
          ),
          // Icône de filtrage maintenant blanche pour être visible
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques déplacées SOUS la navbar (plus dans la navbar)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${contrats.length}',
                    Icons.description_outlined,
                    const Color(0xFFF8FAFC),
                    const Color(0xFF002B6B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Actifs',
                    '$actifsCount',
                    Icons.check_circle_outline,
                    const Color(0xFFF0FDF4),
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),

          // Liste des contrats
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
                    ),
                  )
                : filteredContrats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucun contrat trouvé'
                                  : 'Aucun contrat disponible',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadContrats,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredContrats.length,
                          itemBuilder: (context, index) {
                            final contrat = filteredContrats[index];
                            return _buildContratCard(contrat, index);
                          },
                        ),
                      ),
          ),
        ],
      ),

      // Boutons flottants en bas
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      Color backgroundColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
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

  Widget _buildContratCard(Map<String, dynamic> contrat, int index) {
    final config = _getProductConfig(contrat['codeprod']?.toString());
    // Utilisation du champ 'etat' depuis la base de données (uniformisation)
    final etat = contrat['etat']?.toString() ?? 'Inconnu';
    final liaisonpolice = "-";
    final numpolice = contrat['numepoli'] + liaisonpolice + contrat['codeinte'];
    final isActif = etat.toLowerCase() == 'actif';
    final displayStatus = etat.isNotEmpty && etat != 'null' ? etat : 'Inactif';

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.1,
            (index * 0.1) + 0.3,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              print('🔗 [NAVIGATION] Vers détails: ${contrat['numepoli']}');
              Navigator.pushNamed(
                context,
                '/contrat_details',
                arguments: {'contrat': contrat},
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF002B6B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(config['icon'], color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              numpolice ?? 'N/A',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: config['color'],
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isActif
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                displayStatus.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),

                  const Divider(
                      height: 24, thickness: 1, color: Color(0xFFE2E8F0)),

                  // Produit
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 18, color: Color(0xFF002B6B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          config['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF002B6B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Client
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          contrat['nom_prenom'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'Effet: ${_formatDate(contrat['dateeffet'])}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/contrats_actifs');
          },
          icon: const Icon(Icons.bar_chart, size: 20),
          label: const Text(
            'Contrats Actifs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Tous'),
              value: 'tous',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value.toString());
                _filterContrats();
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Actif'),
              value: 'actif',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value.toString());
                _filterContrats();
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Inactif'),
              value: 'inactif',
              groupValue: _filterStatus,
              onChanged: (value) {
                setState(() => _filterStatus = value.toString());
                _filterContrats();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
