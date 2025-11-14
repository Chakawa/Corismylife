import 'package:flutter/material.dart';
import '../../domain/commercial_service.dart';

class SelectClientScreen extends StatefulWidget {
  final String productType; // Type de produit pour rediriger après sélection
  final Map<String, dynamic>? simulationData; // Données de simulation
  const SelectClientScreen({
    super.key,
    required this.productType,
    this.simulationData,
  });

  @override
  State<SelectClientScreen> createState() => _SelectClientScreenState();
}

class _SelectClientScreenState extends State<SelectClientScreen> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  static const bleuCoris = Color(0xFF002B6B);

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Récupérer les clients qui ont déjà des souscriptions
      final clients = await CommercialService.getClientsWithSubscriptions();

      if (mounted) {
        setState(() {
          _clients = clients;
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

  List<Map<String, dynamic>> get _filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }
    return _clients.where((client) {
      final name =
          '${client['nom'] ?? ''} ${client['prenom'] ?? ''}'.toLowerCase();
      final email = (client['email'] ?? '').toLowerCase();
      final phone = (client['telephone'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  void _selectClient(Map<String, dynamic> client) {
    // Naviguer vers la page de souscription avec les informations du client pour pré-remplissage
    Navigator.pushNamed(
      context,
      '/souscription_${widget.productType}',
      arguments: {
        'isCommercial': true,
        'clientInfo':
            client, // Passer les informations du client pour pré-remplissage
        'simulationData': widget.simulationData,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: bleuCoris,
        elevation: 0,
        title: const Text(
          'Sélectionner un Client',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadClients,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Bouton pour souscrire directement (le commercial ne crée plus de compte client)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                // Rediriger directement vers la souscription sans créer de compte client
                Navigator.pushNamed(
                  context,
                  '/souscription_${widget.productType}',
                  arguments: {
                    'isCommercial':
                        true, // Indique que c'est un commercial qui fait la souscription
                    'simulationData': widget.simulationData,
                  },
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Souscrire pour un nouveau client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Liste des clients
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun client trouvé'
                                  : 'Aucun client ne correspond à votre recherche',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isEmpty)
                              Text(
                                'Les clients pour lesquels vous avez déjà fait des souscriptions apparaîtront ici',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: bleuCoris,
                                  child: Text(
                                    '${client['nom']?[0] ?? ''}${client['prenom']?[0] ?? ''}'
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${client['nom'] ?? ''} ${client['prenom'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                        'Email: ${client['email'] ?? 'Non renseigné'}'),
                                    Text(
                                        'Téléphone: ${client['telephone'] ?? 'Non renseigné'}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _selectClient(client),
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
