import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mycorislife/services/admin_service.dart';

class PendingRegistrationsScreen extends StatefulWidget {
  const PendingRegistrationsScreen({super.key});

  @override
  State<PendingRegistrationsScreen> createState() =>
      _PendingRegistrationsScreenState();
}

class _PendingRegistrationsScreenState
    extends State<PendingRegistrationsScreen> {
  static const bleuCoris = Color(0xFF002B6B);
  static const rougeCoris = Color(0xFFE30613);

  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await AdminService.getPendingRegistrations();
      setState(() {
        _pending = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _activate(Map<String, dynamic> user) async {
    final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Activer le compte'),
        content: Text(
          'Voulez-vous créer le compte de ${nom.isNotEmpty ? nom : user['telephone']} ?\n\n'
          'Un compte actif sera créé avec les informations enregistrées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: bleuCoris),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.activatePendingRegistration(user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Compte de ${nom.isNotEmpty ? nom : user['telephone']} créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: rougeCoris,
          ),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'inscription'),
        content: Text(
          'Supprimer l\'inscription en attente de ${nom.isNotEmpty ? nom : user['telephone']} ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: rougeCoris),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AdminService.deletePendingRegistration(user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription supprimée'),
            backgroundColor: Colors.orange,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: rougeCoris,
          ),
        );
      }
    }
  }

  void _showDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(user: user, onActivate: () {
        Navigator.pop(context);
        _activate(user);
      }, onDelete: () {
        Navigator.pop(context);
        _delete(user);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: bleuCoris,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inscriptions en attente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (!_isLoading && _error == null)
              Text('${_pending.length} utilisateur(s)',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF002B6B)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(backgroundColor: bleuCoris),
              ),
            ],
          ),
        ),
      );
    }
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 70, color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text('Aucune inscription en attente',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: bleuCoris,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pending.length,
        itemBuilder: (_, index) => _PendingCard(
          user: _pending[index],
          onTap: () => _showDetails(_pending[index]),
          onActivate: () => _activate(_pending[index]),
          onDelete: () => _delete(_pending[index]),
        ),
      ),
    );
  }
}

// ─── Carte d'inscription en attente ────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _PendingCard({
    required this.user,
    required this.onTap,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
    final telephone = user['telephone'] ?? 'Inconnu';
    final date = user['updated_at'] != null
        ? _formatDate(user['updated_at'].toString())
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF002B6B).withOpacity(0.1),
                    radius: 22,
                    child: Text(
                      nom.isNotEmpty
                          ? nom[0].toUpperCase()
                          : telephone[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002B6B),
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom.isNotEmpty ? nom : 'Nom inconnu',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(telephone,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text('En attente',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Dernière tentative : $date',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if ((user['email'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(user['email'],
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Voir', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF002B6B),
                        side: const BorderSide(color: Color(0xFF002B6B)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onActivate,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Activer', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Fiche détail (bottom sheet) ───────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _DetailSheet({
    required this.user,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nom = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF002B6B).withOpacity(0.12),
                    child: Text(
                      nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002B6B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom.isNotEmpty ? nom : 'Nom inconnu',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user['telephone'] ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              _InfoTile(Icons.badge, 'Civilité', user['civilite']),
              _InfoTile(Icons.email, 'Email', user['email']),
              _InfoTile(Icons.phone, 'Téléphone', user['telephone']),
              _InfoTile(Icons.cake, 'Date de naissance', user['date_naissance']),
              _InfoTile(Icons.location_city, 'Lieu de naissance', user['lieu_naissance']),
              _InfoTile(Icons.home, 'Adresse', user['adresse']),
              _InfoTile(Icons.flag, 'Pays', user['pays']),
              _InfoTile(Icons.work_outline, 'Profession', user['profession']),
              _InfoTile(Icons.business_center_outlined, "Secteur d'activité", user['secteur_activite']),
              const Divider(),
              const SizedBox(height: 8),
              // Actions de contact
              if ((user['telephone'] ?? '').isNotEmpty) ...[
                const Text('Contacter',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callPhone(user['telephone']),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Appeler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF002B6B),
                          side: const BorderSide(color: Color(0xFF002B6B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openWhatsApp(user['telephone']),
                        icon: Image.asset('assets/images/whatsapp.png',
                            height: 18,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.message, size: 18)),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade400),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Actions principales
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onActivate,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Activer le compte',
                      style: TextStyle(fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Supprimer l\'inscription',
                      style: TextStyle(color: Colors.red, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    // Enlever les espaces et le + pour WhatsApp
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;

  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF002B6B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(text,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
