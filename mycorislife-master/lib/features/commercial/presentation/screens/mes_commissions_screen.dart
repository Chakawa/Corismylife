import 'package:flutter/material.dart';
import '../../domain/commercial_service.dart';
import 'commission_detail_screen.dart';
import 'commissions_page.dart'; // Import pour les commissions en instance

/// ===============================================
/// PAGE DES COMMISSIONS COMMERCIAL
/// ===============================================
///
/// Affiche la liste des bordereaux de commissions du commercial
/// avec un design moderne et coloré.
///
/// FONCTIONNALITÉS :
/// - Affichage de la liste des bordereaux de commissions
/// - Calcul et affichage du total des commissions
/// - Design moderne avec icônes et couleurs
/// - Navigation vers les détails d'un bordereau
/// - Pull-to-refresh pour actualiser les données
/// - Accès aux commissions en instance
class MesCommissionsScreen extends StatefulWidget {
  const MesCommissionsScreen({super.key});

  @override
  State<MesCommissionsScreen> createState() => _MesCommissionsScreenState();
}

class _MesCommissionsScreenState extends State<MesCommissionsScreen> {
  // ============================================
  // CHARTE GRAPHIQUE CORIS
  // ============================================
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color orangeWarning = Color(0xFFF59E0B);
  static const Color blanc = Colors.white;
  static const Color fondCarte = Color(0xFFF8FAFC);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color grisLeger = Color(0xFFF1F5F9);

  // ============================================
  // ÉTAT DE LA PAGE
  // ============================================
  List<Map<String, dynamic>> _bordereaux = [];
  String _totalFormate = '0 FCFA';
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = ''; // Requête de recherche pour filtrer les bordereaux
  bool _showSearchBar = false; // Contrôle l'affichage de la barre de recherche

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  /// Charge les bordereaux de commissions depuis l'API
  Future<void> _loadCommissions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await CommercialService.getCommissions();

      if (mounted) {
        setState(() {
          _bordereaux = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _totalFormate = result['totalFormate'] ?? '0 FCFA';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${_errorMessage}'),
            backgroundColor: rougeCoris,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Formate un montant en FCFA avec séparateurs de milliers
  String _formatMoney(dynamic value) {
    if (value == null) return '0 FCFA';
    final numValue =
        value is num ? value : double.tryParse(value.toString()) ?? 0;
    return '${numValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  /// Formate une date au format DD/MM/YYYY
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Non renseigné';
    
    // Si la date contient déjà le bon format DD/MM/YYYY, la retourner telle quelle
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(date)) {
      return date;
    }
    
    // Sinon, parser et formater proprement (enlever les timestamps)
    try {
      // Supprimer les timestamps et heures si présents
      String cleanDate = date.split('T')[0].split(' ')[0];
      
      // Parser la date
      DateTime parsedDate;
      if (cleanDate.contains('-')) {
        // Format ISO 8601 : YYYY-MM-DD
        parsedDate = DateTime.parse(cleanDate);
      } else if (cleanDate.contains('/')) {
        // Format déjà DD/MM/YYYY ou MM/DD/YYYY
        final parts = cleanDate.split('/');
        if (parts.length == 3) {
          // Assumer DD/MM/YYYY si le premier nombre est <= 31
          if (int.parse(parts[0]) <= 31) {
            parsedDate = DateTime(
              int.parse(parts[2]), // année
              int.parse(parts[1]), // mois
              int.parse(parts[0]), // jour
            );
          } else {
            // MM/DD/YYYY
            parsedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        } else {
          return date;
        }
      } else {
        return date;
      }
      
      // Formater au format DD/MM/YYYY
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      // En cas d'erreur, retourner la date telle quelle
      return date;
    }
  }

  /// Filtre les bordereaux selon la requête de recherche
  /// Recherche par numéro de bordereau
  List<Map<String, dynamic>> get _filteredBordereaux {
    if (_searchQuery.isEmpty) {
      return _bordereaux;
    }
    final query = _searchQuery.toLowerCase();
    return _bordereaux.where((bordereau) {
      final numeroBordereau =
          (bordereau['numeroBordereau'] ?? '').toString().toLowerCase();
      final exercice = (bordereau['exercice'] ?? '').toString().toLowerCase();
      // Rechercher dans le numéro de bordereau ou l'exercice
      return numeroBordereau.contains(query) || exercice.contains(query);
    }).toList();
  }

  /// Obtient la couleur selon l'état du bordereau
  Color _getEtatColor(String? etat) {
    if (etat == null) return grisTexte;
    final etatLower = etat.toLowerCase();
    if (etatLower.contains('payé') || etatLower.contains('payee')) {
      return vertSucces;
    } else if (etatLower.contains('en attente') ||
        etatLower.contains('attente')) {
      return orangeWarning;
    } else {
      return grisTexte;
    }
  }

  /// Obtient l'icône selon l'état du bordereau
  IconData _getEtatIcon(String? etat) {
    if (etat == null) return Icons.help_outline;
    final etatLower = etat.toLowerCase();
    if (etatLower.contains('payé') || etatLower.contains('payee')) {
      return Icons.check_circle;
    } else if (etatLower.contains('en attente') ||
        etatLower.contains('attente')) {
      return Icons.pending;
    } else {
      return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grisLeger,
      appBar: AppBar(
        backgroundColor: bleuCoris,
        elevation: 0,
        title: const Text(
          'Mes Commissions',
          style: TextStyle(
            color: blanc,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: blanc),
        actions: [
          // Icône de recherche pour afficher/masquer la barre de recherche
          IconButton(
            icon:
                Icon(_showSearchBar ? Icons.close : Icons.search, color: blanc),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  // Si on ferme la barre de recherche, réinitialiser la requête
                  _searchQuery = '';
                }
              });
            },
            tooltip: _showSearchBar ? 'Fermer la recherche' : 'Rechercher',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: blanc),
            onPressed: _loadCommissions,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: bleuCoris,
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // Barre de recherche conditionnelle
                    if (_showSearchBar)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: blanc,
                        child: TextField(
                          autofocus: true,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Rechercher par numéro de bordereau ou exercice...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: grisLeger,
                          ),
                        ),
                      ),
                    // Liste des bordereaux avec carte du total (scrollable)
                    Expanded(
                      child: _filteredBordereaux.isEmpty && _searchQuery.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              onRefresh: _loadCommissions,
                              color: bleuCoris,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                itemCount: _filteredBordereaux.length +
                                    1, // +1 pour la carte du total
                                itemBuilder: (context, index) {
                                  // Premier élément : carte du total
                                  if (index == 0) {
                                    return Column(
                                      children: [
                                        _buildTotalCard(),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }
                                  // Autres éléments : bordereaux
                                  final bordereau =
                                      _filteredBordereaux[index - 1];
                                  return _buildBordereauCard(bordereau);
                                },
                              ),
                            ),
                    ),
                  ],
                ),      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 64,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/commissions');
            },
            backgroundColor: bleuCoris,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(Icons.calculate_outlined, color: blanc, size: 28),
            label: const Text(
              'Mes Commissions en Instance',
              style: TextStyle(
                color: blanc,
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,    );
  }

  /// Construit la carte affichant le total des commissions
  Widget _buildTotalCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bleuCoris, bleuCoris.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: blanc.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: blanc,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Total des Commissions',
                style: TextStyle(
                  color: blanc,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _totalFormate,
            style: const TextStyle(
              color: blanc,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_searchQuery.isEmpty ? _bordereaux.length : _filteredBordereaux.length} bordereau${(_searchQuery.isEmpty ? _bordereaux.length : _filteredBordereaux.length) > 1 ? 'x' : ''}',
            style: TextStyle(
              color: blanc.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte pour un bordereau de commission
  Widget _buildBordereauCard(Map<String, dynamic> bordereau) {
    final etat = bordereau['etat'] ?? '';
    final etatColor = _getEtatColor(etat);
    final etatIcon = _getEtatIcon(etat);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CommissionDetailScreen(bordereau: bordereau),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec numéro et exercice
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bleuCoris.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: bleuCoris,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bordereau N° ${bordereau['numeroBordereau'] ?? 'N/A'}/${bordereau['exercice'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: bleuCoris,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge d'état
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: etatColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: etatColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            etatIcon,
                            size: 16,
                            color: etatColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            etat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: etatColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Période
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fondCarte,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 20,
                        color: bleuCoris,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Période',
                              style: TextStyle(
                                fontSize: 12,
                                color: grisTexte,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(bordereau['dateDebut'])} - ${_formatDate(bordereau['dateFin'])}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: bleuCoris,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Montant
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: vertSucces.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: vertSucces,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Montant',
                              style: TextStyle(
                                fontSize: 12,
                                color: grisTexte,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bordereau['montantFormate'] ??
                                  _formatMoney(bordereau['montant']),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: vertSucces,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: grisTexte,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit la vue vide quand il n'y a pas de bordereaux
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bleuCoris.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: bleuCoris.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun bordereau de commission',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: grisTexte,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos bordereaux de commissions\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: grisTexte.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la vue d'erreur
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: rougeCoris,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: grisTexte,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: grisTexte.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCommissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: bleuCoris,
                foregroundColor: blanc,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
