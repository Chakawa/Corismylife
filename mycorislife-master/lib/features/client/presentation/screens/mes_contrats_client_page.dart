import 'package:flutter/material.dart';
import 'package:mycorislife/services/contrat_service.dart';
import 'package:mycorislife/models/contrat.dart';

class MesContratsClientPage extends StatefulWidget {
  const MesContratsClientPage({super.key});

  @override
  State<MesContratsClientPage> createState() => _MesContratsClientPageState();
}

class _MesContratsClientPageState extends State<MesContratsClientPage> {
  final ContratService _service = ContratService();
  List<Contrat> contrats = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContrats();
  }

  Future<void> _loadContrats() async {
    print('🔄 _loadContrats appelé');
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('📞 Appel du service getContrats...');
      final result = await _service.getContrats();
      print('✅ Service retourné ${result.length} contrat(s)');
      
      if (!mounted) return;

      setState(() {
        contrats = result;
        isLoading = false;
      });
      print('✅ État mis à jour avec ${contrats.length} contrat(s)');
    } catch (e, stackTrace) {
      print('❌ Erreur dans _loadContrats: $e');
      print('📍 StackTrace: $stackTrace');
      
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'N/A';
      }
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return 'N/A';
    }
  }

  String _getProductName(String? codeprod) {
    if (codeprod == null) return 'Produit CORIS';
    
    switch (codeprod) {
      case '242':
        return 'ÉPARGNE BONUS';
      case '202':
        return 'CORIS SÉRÉNITÉ';
      case '200':
        return 'CORIS FAMILIS';
      case '240':
        return 'CORIS RETRAITE';
      case '225':
        return 'CORIS SOLIDARITÉ';
      case '246':
        return 'CORIS ÉTUDE';
      case '205':
        return 'CORIS FLEX EMPRUNTEUR';
      default:
        return 'Produit CORIS $codeprod';
    }
  }

  Color _getProductColor(String? codeprod) {
    if (codeprod == null) return const Color(0xFF002B6B);
    
    switch (codeprod) {
      case '225':
        return const Color(0xFF002B6B); // Bleu CORIS
      case '205':
        return const Color(0xFFE30613); // Rouge
      case '242':
        return const Color(0xFF8B5CF6); // Violet
      case '240':
        return const Color(0xFF10B981); // Vert
      case '202':
        return const Color(0xFFF59E0B); // Orange
      case '246':
        return const Color(0xFF6366F1); // Indigo
      case '200':
        return const Color(0xFFEC4899); // Rose
      default:
        return const Color(0xFF002B6B);
    }
  }

  String _formatClientName(Contrat contrat) {
    return contrat.clientName;
  }

  String _getStatutDisplay(Contrat contrat) {
    if (contrat.etat == null) return 'Inconnu';
    final statut = contrat.etat!.toLowerCase();
    
    if (statut.contains('actif') || statut.contains('active')) {
      return 'ACTIF';
    } else if (statut.contains('suspendu')) {
      return 'SUSPENDU';
    } else if (statut.contains('résili') || statut.contains('resili')) {
      return 'RÉSILIÉ';
    } else if (statut.contains('échu') || statut.contains('echu')) {
      return 'ÉCHU';
    }
    return statut.toUpperCase();
  }

  Color _getStatutColor(Contrat contrat) {
    final statut = _getStatutDisplay(contrat);
    
    switch (statut) {
      case 'ACTIF':
        return Colors.green;
      case 'SUSPENDU':
        return Colors.orange;
      case 'RÉSILIÉ':
      case 'ÉCHU':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(double? number) {
    if (number == null) return 'N/A';
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mes Contrats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF002B6B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContrats,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002B6B)),
              ),
            )
          : errorMessage != null
              ? _buildErrorState()
              : contrats.isEmpty
                  ? _buildEmptyState()
                  : _buildContratsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Une erreur est survenue',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadContrats,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Réessayer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 80,
              color: Color(0xFF002B6B),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Aucun contrat",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
              "Vos contrats d'assurance\napparaîtront ici",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContratsList() {
    return RefreshIndicator(
      onRefresh: _loadContrats,
      color: const Color(0xFF002B6B),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contrats.length,
        itemBuilder: (context, index) {
          final contrat = contrats[index];
          return _buildContratCard(contrat);
        },
      ),
    );
  }

  Widget _buildContratCard(Contrat contrat) {
    final productColor = _getProductColor(contrat.codeprod);
    final productName = _getProductName(contrat.codeprod);
    final clientName = _formatClientName(contrat);
    // Afficher uniquement le numéro de police sans le codeinte
    final numepoli = contrat.numepoli ?? 'N/A';
    final dateeffet = _formatDate(contrat.dateeffet);
    final dateeche = _formatDate(contrat.dateeche);
    final prime = _formatNumber(contrat.prime);
    final capital = _formatNumber(contrat.capital);
    final statut = _getStatutDisplay(contrat);
    final statutColor = _getStatutColor(contrat);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: productColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          print('🔗 [CLIENT CONTRATS] Navigation vers détails');
          print('📄 [CLIENT CONTRATS] Numéro de police: ${contrat.numepoli}');
          print('📦 [CLIENT CONTRATS] Données contrat: ${contrat.toJson()}');
          Navigator.pushNamed(
            context,
            '/contrat_details',
            arguments: contrat.toJson(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icône + Numéro de police + Badge statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          productColor,
                          productColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: productColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          numepoli,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: productColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statutColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statut,
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
              // Nom du produit
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: productColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: productColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Assuré
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Informations financières
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: productColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prime',
                            style: TextStyle(
                              fontSize: 11,
                              color: productColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$prime FCFA',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: productColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capital',
                            style: TextStyle(
                              fontSize: 11,
                              color: productColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$capital FCFA',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Dates
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Effet: $dateeffet',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (dateeche != 'N/A') ...[
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.event_busy,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Échéance: $dateeche',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
