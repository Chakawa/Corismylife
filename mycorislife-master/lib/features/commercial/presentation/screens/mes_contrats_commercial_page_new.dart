import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

class MesContratsCommercialPageNew extends StatefulWidget {
  const MesContratsCommercialPageNew({Key? key}) : super(key: key);

  @override
  State<MesContratsCommercialPageNew> createState() =>
      _MesContratsCommercialPageNewState();
}

class _MesContratsCommercialPageNewState
    extends State<MesContratsCommercialPageNew>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  List<dynamic> contrats = [];
  List<dynamic> filteredContrats = [];
  bool isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'tous';
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
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF002B6B),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF002B6B), Color(0xFF004080)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(painter: _PatternPainter()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Mes Contrats',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${contrats.length} contrat${contrats.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: const Text('Mes Contrats'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(),
              ),
            ],
          ),

          // Stats cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          '${contrats.length}',
                          Icons.folder,
                          const Color(0xFF002B6B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Actifs',
                          '$actifsCount',
                          Icons.check_circle,
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barre de recherche
                  Container(
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
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _filterContrats();
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un contrat...',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF002B6B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des contrats
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
                ),
              ),
            )
          else if (filteredContrats.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun contrat trouvé',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final contrat = filteredContrats[index];
                    return _buildContratCard(contrat, index);
                  },
                  childCount: filteredContrats.length,
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContratCard(Map<String, dynamic> contrat, int index) {
    final config = _getProductConfig(contrat['codeprod']?.toString());
    final isActif = (contrat['etat'] ?? '').toString().toLowerCase() == 'actif';

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
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              config['color'],
                              config['color'].withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: config['color'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child:
                            Icon(config['icon'], color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'hhhhhhh',
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
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActif
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                contrat['etat'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
                      Icon(Icons.shield_outlined,
                          size: 18, color: config['color']),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          config['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: config['color'],
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
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _loadContrats(),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF002B6B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF002B6B), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/contrats_actifs');
              },
              icon: const Icon(Icons.bar_chart, size: 20),
              label: const Text('Contrats Actifs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B6B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
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

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3 + i * 30),
        20 + i * 10,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
