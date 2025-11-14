import 'package:flutter/material.dart';
import '../../domain/commercial_service.dart';
import 'subscription_detail_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/pdf_viewer_page.dart';

class MesClientsScreen extends StatefulWidget {
  const MesClientsScreen({super.key});

  @override
  State<MesClientsScreen> createState() => _MesClientsScreenState();
}

class _MesClientsScreenState extends State<MesClientsScreen> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showSearchBar = false; // Contrôle l'affichage de la barre de recherche
  
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

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final subscriptions = await CommercialService.getSubscriptions();

      if (mounted) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSubscriptions {
    if (_searchQuery.isEmpty) {
      return _subscriptions;
    }
    final query = _searchQuery.toLowerCase();
    return _subscriptions.where((sub) {
      final nom = (sub['nom'] ?? '').toLowerCase();
      final prenom = (sub['prenom'] ?? '').toLowerCase();
      final fullName = '$nom $prenom';
      final produit = (sub['produit_nom'] ?? '').toLowerCase();
      final numeroPolice = (sub['numero_police'] ?? '').toLowerCase();
      return fullName.contains(query) || 
             produit.contains(query) || 
             numeroPolice.contains(query);
    }).toList();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Non renseigné';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatProductName(String productName) {
    if (productName.isEmpty || productName == 'Non renseigné') return productName;
    // Convertir coris_retraite -> Coris Retraite
    return productName
        .split('_')
        .map((word) => word.isEmpty 
            ? '' 
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _getStatusLabel(String? statut) {
    switch (statut) {
      case 'contrat':
        return 'Contrat';
      case 'proposition':
        return 'Proposition';
      default:
        return statut ?? 'Inconnu';
    }
  }

  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'contrat':
        return vertSucces; // Vert pour les contrats payés
      case 'proposition':
        return orangeWarning; // Orange pour les propositions en attente
      default:
        return grisTexte; // Gris pour les autres statuts
    }
  }

  void _viewSubscriptionDetail(Map<String, dynamic> subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionDetailScreen(subscription: subscription),
      ),
    );
  }

  /// Construit un chip d'information avec icône
  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: grisTexte,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grisLeger,
      appBar: AppBar(
        backgroundColor: bleuCoris,
        elevation: 0,
        title: const Text(
          'Mes Clients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            /**
             * MODIFICATION: Correction du bouton retour pour éviter la déconnexion
             * 
             * PROBLÈME RÉSOLU:
             * - Avant: Le bouton retour déconnectait l'utilisateur ou le ramenait à la page de connexion
             * - Maintenant: Le bouton retour ramène directement à la page d'accueil commercial
             * 
             * MÉTHODE UTILISÉE:
             * - Navigator.pushReplacementNamed : Remplace la page actuelle par la page d'accueil
             * - Cela évite d'empiler les pages dans la pile de navigation
             * - L'utilisateur reste connecté et peut continuer à utiliser l'application
             */
            Navigator.pushReplacementNamed(context, '/commercial_home');
          },
        ),
        actions: [
          /**
           * MODIFICATION: Remplacer la barre de recherche toujours visible par une icône
           * 
           * FONCTIONNEMENT:
           * - Par défaut, la barre de recherche est cachée (_showSearchBar = false)
           * - L'icône de recherche est affichée dans les actions de l'AppBar
           * - Quand on clique sur l'icône, _showSearchBar devient true et la barre s'affiche
           * - La barre de recherche s'affiche conditionnellement dans le body
           */
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search, color: Colors.white),
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSubscriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          /**
           * BARRE DE RECHERCHE CONDITIONNELLE
           * 
           * AFFICHAGE:
           * - S'affiche uniquement si _showSearchBar = true
           * - S'affiche avec une animation de slide pour une meilleure UX
           * - Permet de rechercher par nom de client, produit ou numéro de police
           */
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                autofocus: true, // Focus automatique quand la barre s'affiche
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom de client, produit ou numéro de police...',
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
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
          
          // Liste des propositions/contrats
          Expanded(
            child: _isLoading
          ? const Center(child: CircularProgressIndicator())
                : _filteredSubscriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                              Icons.description_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                              _searchQuery.isEmpty
                                  ? 'Aucune proposition/contrat trouvé'
                                  : 'Aucun résultat ne correspond à votre recherche',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                            if (_searchQuery.isEmpty)
                      Text(
                                'Vos propositions et contrats apparaîtront ici',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                        onRefresh: _loadSubscriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                          itemCount: _filteredSubscriptions.length,
                    itemBuilder: (context, index) {
                            final subscription = _filteredSubscriptions[index];
                            final clientName = '${subscription['nom'] ?? ''} ${subscription['prenom'] ?? ''}'.trim();
                            final clientNameDisplay = clientName.isEmpty ? 'Client non renseigné' : clientName;
                            
                      // Couleurs pour le design amélioré
                      final statusColor = _getStatusColor(subscription['statut']);
                      final isContrat = subscription['statut'] == 'contrat';
                      
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
                            onTap: () => _viewSubscriptionDetail(subscription),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // En-tête avec avatar et nom
                                  Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              bleuCoris,
                                              bleuCoris.withValues(alpha: 0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: bleuCoris.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            clientNameDisplay.isNotEmpty 
                                                ? clientNameDisplay[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: blanc,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              clientNameDisplay,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: bleuCoris,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Badge de statut
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: statusColor.withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isContrat ? Icons.check_circle : Icons.pending,
                                                    size: 14,
                                                    color: statusColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _getStatusLabel(subscription['statut']),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: bleuCoris.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.picture_as_pdf,
                                            color: bleuCoris,
                                            size: 20,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PdfViewerPage(
                                                subscriptionId: subscription['id'],
                                              ),
                                            ),
                                          );
                                        },
                                        tooltip: 'Voir le PDF',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Informations du produit
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: fondCarte,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: bleuCoris.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_outlined,
                                            color: bleuCoris,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Produit',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: grisTexte,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatProductName(subscription['produit_nom'] ?? 'Non renseigné'),
                                                style: const TextStyle(
                                                  fontSize: 15,
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
                                  const SizedBox(height: 12),
                                  // Informations complémentaires
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoChip(
                                          Icons.receipt_long,
                                          'N° Police',
                                          subscription['numero_police'] ?? 'N/A',
                                          bleuCoris,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildInfoChip(
                                          Icons.calendar_today,
                                          'Date',
                                          _formatDate(subscription['date_creation']?.toString()),
                                          orangeWarning,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Flèche de navigation
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Voir les détails',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: bleuCoris,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: bleuCoris,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
