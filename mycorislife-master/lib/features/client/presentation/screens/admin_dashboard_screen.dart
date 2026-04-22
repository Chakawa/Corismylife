import 'package:flutter/material.dart';
import 'package:mycorislife/services/admin_service.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/features/client/presentation/screens/pending_registrations_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const bleuCoris = Color(0xFF002B6B);
  static const rougeCoris = Color(0xFFE30613);

  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  String _adminName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Récupérer les infos utilisateur
      final userData = await AuthService.getUser();
      final stats = await AdminService.getStats();
      if (mounted) {
        setState(() {
          _adminName =
              '${userData?['prenom'] ?? ''} ${userData?['nom'] ?? ''}'.trim();
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: rougeCoris),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: bleuCoris,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Admin',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_adminName.isNotEmpty)
              Text(_adminName,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: bleuCoris,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF002B6B)))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: bleuCoris),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final totals = _stats?['totals'] ?? {};
    final totalUsers = totals['users'] ?? 0;
    final totalContracts = totals['contracts'] ?? 0;
    final totalSubscriptions = totals['subscriptions'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── En-tête bienvenue ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF002B6B), Color(0xFF0041A3)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _adminName.isNotEmpty
                          ? 'Bonjour, $_adminName'
                          : 'Tableau de bord',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const Text('Administration CORIS Assurance',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ─── Statistiques ───────────────────────────────────────────────
        const _SectionTitle('Statistiques globales'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    icon: Icons.people,
                    label: 'Clients',
                    value: '$totalUsers',
                    color: bleuCoris)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
                    icon: Icons.description,
                    label: 'Contrats',
                    value: '$totalContracts',
                    color: Colors.teal)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    icon: Icons.assignment,
                    label: 'Souscriptions',
                    value: '$totalSubscriptions',
                    color: Colors.indigo)),
            const SizedBox(width: 10),
            Expanded(child: Container()), // placeholder
          ],
        ),
        const SizedBox(height: 24),

        // ─── Actions rapides ─────────────────────────────────────────────
        const _SectionTitle('Actions rapides'),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.person_add_alt_1,
          iconColor: Colors.orange,
          title: 'Inscriptions en attente',
          subtitle: 'Utilisateurs n\'ayant pas finalisé leur inscription',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PendingRegistrationsScreen(),
            ),
          ),
          badge: null,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.people_outline,
          iconColor: bleuCoris,
          title: 'Gestion des utilisateurs',
          subtitle: 'Voir et gérer tous les comptes clients',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bientôt disponible')),
          ),
        ),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.description_outlined,
          iconColor: Colors.teal,
          title: 'Contrats',
          subtitle: 'Suivi des contrats en cours',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bientôt disponible')),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets utilitaires ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B6B)));
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
