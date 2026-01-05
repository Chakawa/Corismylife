/**
 * ===============================================
 * PAGE - DÉTAILS CONTRAT UNIFIÉ
 * ===============================================
 * 
 * Page unifiée permettant d'afficher les détails d'un contrat
 * accessible à la fois par les commerciaux ET les clients.
 * 
 * FONCTIONNALITÉS :
 * - Affichage complet des informations du contrat
 * - Affichage du badge de statut (Actif/Inactif)
 * - Navigation vers le PDF du contrat
 * - Compatible commercial et client (vérification backend)
 * 
 * ⚠️ UNIFORMISATION DES CHAMPS (IMPORTANT) :
 * ==========================================
 * Cette page utilise UNIQUEMENT le champ 'etat' depuis l'API backend :
 * - Accès via: contratDetails['etat']
 * - Valeurs possibles: 'Actif', 'Inactif', 'Suspendu'
 * - Ne PAS utiliser contratDetails['statut'] (ancienne convention, maintenant dépréciée)
 * 
 * SÉCURITÉ :
 * - Les commerciaux voient les contrats via leur code_apporteur
 * - Les clients voient les contrats via leur numéro de téléphone
 * - Le backend vérifie automatiquement les droits d'accès
 * 
 * DESIGN :
 * - Header bleu CORIS uniforme avec badge de statut
 * - Cards modernes avec informations groupées
 * - Bouton d'action flottant pour accéder au PDF
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

class ContratDetailsUnifiedPage extends StatefulWidget {
  final Map<String, dynamic> contrat;

  const ContratDetailsUnifiedPage({Key? key, required this.contrat})
      : super(key: key);

  @override
  State<ContratDetailsUnifiedPage> createState() =>
      _ContratDetailsUnifiedPageState();
}

class _ContratDetailsUnifiedPageState extends State<ContratDetailsUnifiedPage>
    with TickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? contratDetails;
  List<Map<String, dynamic>> beneficiaires = [];
  bool isLoading = true;
  String? userRole;

  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mapping des codes produits
  final Map<String, Map<String, dynamic>> productConfig = {
    '242': {
      'name': 'ÉPARGNE BONUS',
      'icon': Icons.savings,
      'color': Color(0xFF8B5CF6),
      'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    },
    '202': {
      'name': 'CORIS SÉRÉNITÉ',
      'icon': Icons.health_and_safety,
      'color': Color(0xFF002B6B),
      'gradient': [Color(0xFF002B6B), Color(0xFF004080)],
    },
    '200': {
      'name': 'CORIS FAMILIS',
      'icon': Icons.family_restroom,
      'color': Color(0xFFF59E0B),
      'gradient': [Color(0xFFF59E0B), Color(0xFFEA8800)],
    },
    '240': {
      'name': 'CORIS RETRAITE',
      'icon': Icons.elderly,
      'color': Color(0xFF10B981),
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
    },
    '225': {
      'name': 'CORIS SOLIDARITÉ',
      'icon': Icons.volunteer_activism,
      'color': Color(0xFF002B6B),
      'gradient': [Color(0xFF002B6B), Color(0xFF004080)],
    },
    '246': {
      'name': 'CORIS ÉTUDE',
      'icon': Icons.school,
      'color': Color(0xFF8B5CF6),
      'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    },
    '205': {
      'name': 'CORIS FLEX EMPRUNTEUR',
      'icon': Icons.home,
      'color': Color(0xFFEF4444),
      'gradient': [Color(0xFFEF4444), Color(0xFFDC2626)],
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadContratDetails();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _loadContratDetails() async {
    print('🔍 [DETAILS] ========== DÉBUT CHARGEMENT ==========');

    try {
      final token = await storage.read(key: 'token');
      final role = await storage.read(key: 'role');

      print('🔑 [DETAILS] Token: ${token != null ? "✅ Présent" : "❌ Absent"}');
      print('👤 [DETAILS] Rôle: $role');

      if (token == null) throw Exception('Token non trouvé');

      setState(() {
        userRole = role;
        isLoading = true;
      });

      final numepoli = widget.contrat['numepoli'];
      print('📄 [DETAILS] Numéro de police: $numepoli');
      print('📦 [DETAILS] Contrat complet: ${widget.contrat}');

      final url = '${AppConfig.baseUrl}/commercial/contrat_details/$numepoli';
      print('🌐 [DETAILS] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 [DETAILS] Status HTTP: ${response.statusCode}');
      print('📨 [DETAILS] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [DETAILS] Données décodées: ${data.keys}');
        print('📋 [DETAILS] Contrat: ${data['contrat']}');
        print('👥 [DETAILS] Bénéficiaires: ${data['beneficiaires']}');

        setState(() {
          contratDetails = data['contrat'];
          beneficiaires =
              List<Map<String, dynamic>>.from(data['beneficiaires'] ?? []);
          isLoading = false;
        });

        print('✅ [DETAILS] Chargement terminé avec succès');
        _headerAnimationController.forward();
        _contentAnimationController.forward();
      } else {
        print('❌ [DETAILS] Erreur HTTP ${response.statusCode}');
        print('📄 [DETAILS] Body erreur: ${response.body}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ [DETAILS] EXCEPTION: $e');
      print('📍 [DETAILS] Stack trace: $stackTrace');
      setState(() => isLoading = false);
      _showError('Erreur: $e');
    }

    print('🔍 [DETAILS] ========== FIN CHARGEMENT ==========');
  }

  Map<String, dynamic> _getProductConfig() {
    final codeprod = contratDetails?['codeprod']?.toString();
    return productConfig[codeprod] ??
        {
          'name': 'Produit $codeprod',
          'icon': Icons.description,
          'color': Color(0xFF002B6B),
          'gradient': [Color(0xFF002B6B), Color(0xFF004080)],
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

  String _formatMontant(dynamic montant) {
    if (montant == null) return '0 FCFA';
    final num = double.tryParse(montant.toString()) ?? 0;
    return '${num.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Copié !'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF002B6B).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chargement des détails...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (contratDetails == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF002B6B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Détails du contrat'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final config = _getProductConfig();
    // Utilisation du champ 'etat' depuis la base de données (uniformisation)
    print('🔍 [ETAT] contratDetails etat: ${contratDetails?['etat']}');
    print('🔍 [ETAT] toLowerCase: ${contratDetails?['etat']?.toString().toLowerCase()}');
    final isActif =
        contratDetails?['etat']?.toString().toLowerCase() == 'actif';
    print('🔍 [ETAT] isActif: $isActif');
    final liaisonpolice = "-";
    final numpolice = contratDetails?['numepoli'] +
        liaisonpolice +
        contratDetails?['codeinte'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header bleu CORIS simplifié (sans badge fixé)
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF002B6B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF002B6B),
                ),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Icône du produit
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        config['icon'],
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Numéro de police
                    Text(
                      numpolice ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    // Nom du produit
                    Text(
                      config['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenu avec animations
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations du contrat (avec état intégré)
                      _buildModernCard(
                        title: 'Informations du Contrat',
                        icon: Icons.description_outlined,
                        color: config['color'],
                        children: [
                          _buildInfoRow(
                            'Numéro de police',
                            numpolice ?? 'N/A',
                            Icons.receipt_long,
                            canCopy: true,
                          ),
                          _buildInfoRow(
                            'Produit',
                            config['name'],
                            Icons.category,
                          ),
                          // État intégré dans les informations du contrat
                          _buildStatusRow(
                            'État du contrat',
                            contratDetails?['etat'] ?? 'Inactif',
                            isActif,
                          ),
                          if (contratDetails?['datesous'] != null)
                            _buildInfoRow(
                              'Date de souscription',
                              _formatDate(contratDetails?['datesous']),
                              Icons.edit_calendar,
                            ),
                          if (contratDetails?['dateeffet'] != null)
                            _buildInfoRow(
                              'Date d\'effet',
                              _formatDate(contratDetails?['dateeffet']),
                              Icons.calendar_today,
                            ),
                          if (contratDetails?['dateeffet'] != null &&
                              (contratDetails?['dateeche'] != null || contratDetails?['dateecheance'] != null))
                            _buildInfoRow(
                              'Durée du contrat',
                              _calculateDuree(
                                contratDetails?['dateeffet'],
                                contratDetails?['dateeche'] ?? contratDetails?['dateecheance'],
                              ),
                              Icons.schedule,
                            ),
                          if (contratDetails?['dateeche'] != null || contratDetails?['dateecheance'] != null)
                            _buildInfoRow(
                              'Date d\'échéance',
                              _formatDate(contratDetails?['dateeche'] ?? contratDetails?['dateecheance']),
                              Icons.event_busy,
                            ),
                          if (contratDetails?['periodicite'] != null)
                            _buildInfoRow(
                              'Périodicité',
                              contratDetails?['periodicite'],
                              Icons.repeat,
                            ),
                          if (contratDetails?['domiciliation'] != null)
                            _buildInfoRow(
                              'Domiciliation',
                              contratDetails?['domiciliation'],
                              Icons.account_balance,
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Informations client
                      _buildModernCard(
                        title: 'Informations Client',
                        icon: Icons.person_outline,
                        color: const Color(0xFF002B6B),
                        children: [
                          _buildInfoRow(
                            'Client',
                            contratDetails?['nom_prenom'] ?? 'N/A',
                            Icons.badge,
                          ),
                          _buildInfoRow(
                            'Téléphone 1',
                            contratDetails?['telephone1'] ?? 'N/A',
                            Icons.phone,
                            canCopy: true,
                          ),
                          if (contratDetails?['telephone2'] != null && contratDetails!['telephone2'].toString().trim().isNotEmpty)
                            _buildInfoRow(
                              'Téléphone 2',
                              contratDetails!['telephone2'].toString(),
                              Icons.phone_android,
                              canCopy: true,
                            ),
                          if (contratDetails?['datenaissance'] != null)
                            _buildInfoRow(
                              'Date de naissance',
                              _formatDate(contratDetails?['datenaissance']),
                              Icons.cake,
                            ),
                          if (contratDetails?['code_apporteur'] != null)
                            _buildInfoRow(
                              'Code du commercial',
                              contratDetails!['code_apporteur'].toString(),
                              Icons.badge_outlined,
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Informations financières
                      _buildModernCard(
                        title: 'Informations Financières',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF002B6B),
                        children: [
                          if (contratDetails?['capital'] != null)
                            _buildInfoRow(
                              'Capital',
                              _formatMontant(contratDetails?['capital']),
                              Icons.trending_up,
                            ),
                          // Afficher Prime OU Rente selon ce qui est disponible
                          if (contratDetails?['prime'] != null && 
                              (contratDetails?['prime'].toString() != '0' && 
                               contratDetails?['prime'].toString() != '0.0'))
                            _buildInfoRow(
                              'Prime',
                              _formatMontant(contratDetails?['prime']),
                              Icons.payments,
                            ),
                          if (contratDetails?['rente'] != null && 
                              (contratDetails?['rente'].toString() != '0' && 
                               contratDetails?['rente'].toString() != '0.0'))
                            _buildInfoRow(
                              'Rente',
                              _formatMontant(contratDetails?['rente']),
                              Icons.account_balance,
                            ),
                          _buildInfoRow(
                            'Montant Encaissé',
                            _formatMontant(contratDetails?['montant_encaisse'] ?? 0),
                            Icons.money,
                          ),
                          _buildInfoRow(
                            'Impayé',
                            _formatMontant(contratDetails?['impaye'] ?? 0),
                            Icons.warning_amber,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Bénéficiaires
                      if (beneficiaires.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildModernCard(
                          title: 'Bénéficiaires',
                          icon: Icons.people_outline,
                          color: const Color(0xFF002B6B),
                          children: beneficiaires.map((benef) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Color(0xFF002B6B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          benef['nom_benef'] ?? benef['nom'] ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF002B6B).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _getBeneficiaireType(benef['type_beneficiaires']),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF002B6B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Informations professionnelles (commercial uniquement)
                      if (userRole == 'commercial') ...[
                        const SizedBox(height: 16),
                        _buildModernCard(
                          title: 'Informations Professionnelles',
                          icon: Icons.admin_panel_settings,
                          color: const Color(0xFF002B6B),
                          children: [
                            _buildInfoRow(
                              'Code produit',
                              contratDetails?['codeprod'] ?? 'N/A',
                              Icons.qr_code,
                              canCopy: true,
                            ),
                            if (contratDetails?['codeinte'] != null)
                              _buildInfoRow(
                                'Code intermédiaire',
                                contratDetails?['codeinte'],
                                Icons.business,
                                canCopy: true,
                              ),
                            if (contratDetails?['codeappo'] != null)
                              _buildInfoRow(
                                'Code du commercial',
                                contratDetails?['codeappo'],
                                Icons.badge,
                                canCopy: true,
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Boutons d'action flottants
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingActions(config['color']),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002B6B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002B6B),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.2,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () => _copyToClipboard(value),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _getBeneficiaireType(String? type) {
    if (type == null) return 'N/A';
    switch (type.toUpperCase()) {
      case 'D':
        return 'Décès';
      case 'V':
        return 'Vie';
      default:
        return type;
    }
  }

  // Calcul de la durée entre la date d'effet et la date d'échéance (en mois)
  String _calculateDuree(dynamic dateEffet, dynamic dateEcheance) {
    print('📊 [DUREE] dateEffet: $dateEffet (${dateEffet.runtimeType})');
    print('📊 [DUREE] dateEcheance: $dateEcheance (${dateEcheance.runtimeType})');
    
    if (dateEffet == null || dateEcheance == null) {
      print('❌ [DUREE] Une des dates est null');
      return 'N/A';
    }
    
    try {
      DateTime debut;
      DateTime fin;
      
      if (dateEffet is String) {
        debut = DateTime.parse(dateEffet);
      } else if (dateEffet is DateTime) {
        debut = dateEffet;
      } else {
        debut = DateTime.parse(dateEffet.toString());
      }
      
      if (dateEcheance is String) {
        fin = DateTime.parse(dateEcheance);
      } else if (dateEcheance is DateTime) {
        fin = dateEcheance;
      } else {
        fin = DateTime.parse(dateEcheance.toString());
      }
      
      // Calculer la différence en mois
      int moisTotal = (fin.year - debut.year) * 12 + (fin.month - debut.month);
      
      // Ajuster si le jour d'échéance est avant le jour d'effet
      if (fin.day < debut.day) {
        moisTotal--;
      }
      
      print('✅ [DUREE] Résultat: $moisTotal mois');
      return '$moisTotal mois';
    } catch (e) {
      print('❌ [DUREE] Erreur: $e');
      return 'N/A';
    }
  }

  // Widget pour afficher le statut du contrat avec badge
  Widget _buildStatusRow(String label, String etat, bool isActif) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isActif ? Icons.check_circle : Icons.cancel,
              size: 20,
              color: isActif ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActif
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActif
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFFF59E0B).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    etat.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isActif
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      letterSpacing: 0.5,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActions(Color color) {
    // Plus de boutons dans les détails de contrats
    return null;
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, bool isPrimary) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label en cours...'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side:
              isPrimary ? BorderSide.none : BorderSide(color: color, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
