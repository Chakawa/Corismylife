import 'package:flutter/material.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/features/auth/presentation/screens/two_fa_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/kyc_documents_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/attach_proposal_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/notifications_screen.dart';
import 'photo_viewer_page.dart';
import 'package:mycorislife/features/client/presentation/screens/settings_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/edit_profile_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/help_support_screen.dart';
import 'package:mycorislife/services/user_service.dart';
import 'package:mycorislife/services/auth_service.dart';

// Couleurs partagées
const Color bleuCoris = Color(0xFF002B6B);
const Color rougeCoris = Color(0xFFE30613);
const Color blanc = Colors.white;
const Color fondGris = Color(0xFFF0F4F8);
const Color vertAccent = Color(0xFF10B981);
const Color orangeAccent = Color(0xFFF59E0B);

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Données utilisateur
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Charge le profil utilisateur depuis l'API
  Future<void> _loadUserProfile() async {
    try {
      final userData = await UserService.getProfile();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    }
  }

  /// Obtient le nom complet de l'utilisateur
  String get _fullName {
    if (_userData == null) return 'Chargement...';
    final civilite = _userData!['civilite'] ?? '';
    final prenom = _userData!['prenom'] ?? '';
    final nom = _userData!['nom'] ?? '';
    return '$civilite $prenom $nom'.trim();
  }

  /// Obtient l'email de l'utilisateur
  String get _email => _userData?['email'] ?? 'email@exemple.com';

  /// Obtient l'URL de la photo de profil
  String? get _photoUrl => _userData?['photo_url'];

  /// Obtient le numéro de téléphone
  String get _telephone => _userData?['telephone'] ?? 'Non renseigné';

  /// Obtient l'adresse
  String get _adresse => _userData?['adresse'] ?? 'Non renseignée';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondGris,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: bleuCoris,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Mon Profil',
                style: TextStyle(
                  color: blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF002B6B),
                      Color(0xFF003A85),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.account_circle,
                    size: 80,
                    color: blanc,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: blanc),
                onPressed: () {
                  _showNotifications(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: blanc),
                onPressed: () {
                  _showSettings(context);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildUserProfileCard(context),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  context,
                  title: 'Gestion des Contrats',
                  icon: Icons.assignment_outlined,
                  items: [
                    ProfileMenuItem(
                      icon: Icons.add_circle_outline,
                      title: 'Rattacher un contrat',
                      subtitle: 'Associer un nouveau contrat à votre profil',
                      iconColor: vertAccent,
                      onTap: () => _showContractDialog(context),
                    ),
                    ProfileMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Rattacher une proposition',
                      subtitle: 'Lier une proposition d\'assurance',
                      iconColor: orangeAccent,
                      onTap: () => _showPropositionDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  context,
                  title: 'Informations personnelles',
                  icon: Icons.person_outline,
                  items: [
                    ProfileMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'Modifier votre profil',
                      subtitle: 'Mettre à jour vos informations',
                      onTap: () {
                        _navigateToEditProfile(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  context,
                  title: 'Sécurité & Vérification',
                  icon: Icons.security_outlined,
                  items: [
                    ProfileMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Modifier votre mot de passe',
                      subtitle: 'Changer votre mot de passe actuel',
                      onTap: () {
                        _navigateToChangePassword(context);
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Authentification à deux facteurs',
                      subtitle: 'Sécuriser davantage votre compte',
                      onTap: () {
                        _navigateTo2FA(context);
                      },
                    ),
                    ProfileMenuItem(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'Documents KYC',
                      subtitle: 'Vérification d\'identité complétée',
                      iconColor: vertAccent,
                      trailing: const Icon(Icons.check_circle,
                          color: vertAccent, size: 20),
                      onTap: () {
                        _navigateToDocuments(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  context,
                  title: 'Support & Contact',
                  icon: Icons.support_agent_outlined,
                  items: [
                    ProfileMenuItem(
                      icon: Icons.help_center_outlined,
                      title: 'Centre d\'aide',
                      subtitle: 'FAQ, guides et contact',
                      onTap: () {
                        _showHelpAndSupport(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  context,
                  items: [
                    ProfileMenuItem(
                      icon: Icons.logout_outlined,
                      title: 'Se déconnecter',
                      subtitle: 'Fermer votre session en toute sécurité',
                      iconColor: rougeCoris,
                      titleColor: rougeCoris,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(20),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _photoUrl != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoViewerPage(
                              photoUrl: _photoUrl,
                              title: 'Photo de profil',
                            ),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF002B6B), Color(0xFF003A85)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage: _photoUrl != null
                        ? NetworkImage(
                            '${AppConfig.baseUrl.replaceAll('/api', '')}$_photoUrl')
                        : null,
                    backgroundColor: const Color(0xFFF0F4F8),
                    child: _photoUrl == null
                        ? const Icon(Icons.person, size: 40, color: bleuCoris)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: vertAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: blanc, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: blanc,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: bleuCoris,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _telephone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (_adresse.isNotEmpty && _adresse != 'Non renseignée') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _adresse,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: vertAccent.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Client Vérifié',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
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

  Widget _buildSettingsSection(
    BuildContext context, {
    String? title,
    IconData? icon,
    required List<ProfileMenuItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(13),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: bleuCoris, size: 20),
                    const SizedBox(width: 8),
                  ],
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: fondGris.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    // Navigation vers la page des notifications
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // Navigation vers la page des paramètres
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  Future<void> _navigateToEditProfile(BuildContext context) async {
    // Navigation vers la page de modification du profil
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    // Recharger les données si le profil a été modifié
    if (updated == true && mounted) {
      await _loadUserProfile(); // Recharger le profil

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: vertAccent,
          ),
        );
      }
    }
  }

  void _navigateToChangePassword(BuildContext context) {
    // Ouvrir directement la boîte de dialogue de changement de mot de passe
    // (même fonctionnalité que dans SettingsScreen)
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_rounded, color: Color(0xFF002B6B), size: 24),
                SizedBox(width: 12),
                Flexible(
                    child: Text('Changer le mot de passe',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Ancien mot de passe',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: Color(0xFF002B6B)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF002B6B), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_rounded,
                          color: Color(0xFF002B6B)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF002B6B), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_clock_rounded,
                          color: Color(0xFF002B6B)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF002B6B), width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                onPressed: isChanging
                    ? null
                    : () async {
                        final oldPwd = oldPasswordController.text.trim();
                        final newPwd = newPasswordController.text.trim();
                        final confirmPwd =
                            confirmPasswordController.text.trim();

                        if (oldPwd.isEmpty ||
                            newPwd.isEmpty ||
                            confirmPwd.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Tous les champs sont requis'),
                                  backgroundColor: Colors.red));
                          return;
                        }
                        if (newPwd.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Le nouveau mot de passe doit contenir au moins 8 caractères'),
                              backgroundColor: Colors.red));
                          return;
                        }
                        if (newPwd != confirmPwd) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Les mots de passe ne correspondent pas'),
                                  backgroundColor: Colors.red));
                          return;
                        }

                        setDialogState(() => isChanging = true);
                        try {
                          await UserService.changePassword(
                              oldPassword: oldPwd, newPassword: newPwd);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Mot de passe changé avec succès'),
                                  backgroundColor: Color(0xFF10B981)));
                        } catch (e) {
                          setDialogState(() => isChanging = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red));
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002B6B)),
                child: isChanging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateTo2FA(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TwoFactorAuthScreen(identifier: _email),
      ),
    );
  }

  void _navigateToDocuments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KYCDocumentsScreen()),
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    // Navigation vers la même page que "Aide et support" dans les réglages
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  /// Effectue la déconnexion complète
  /// Supprime toutes les données sauvegardées et redirige vers la page de connexion
  Future<void> _performLogout(BuildContext context) async {
    try {
      // Déconnexion via AuthService
      await AuthService.logout();

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion effectuée avec succès'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // Rediriger vers la page de connexion et supprimer toutes les routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion : $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showContractDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.assignment_outlined, color: Color(0xFF002B6B)),
              SizedBox(width: 8),
              Text('Rattacher un Contrat'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Numéro de contrat',
                  hintText: 'Ex: CORIS-2024-001234',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Code de vérification',
                  hintText: 'Code reçu par SMS/Email',
                  prefixIcon: const Icon(Icons.verified_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Contrat rattaché avec succès !');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Rattacher', style: TextStyle(color: blanc)),
            ),
          ],
        );
      },
    );
  }

  void _showPropositionDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttachProposalScreen()),
    ).then((attached) {
      if (attached == true && mounted) {
        _showSuccessSnackBar(context, 'Proposition rattachée avec succès !');
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE30613),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  const Text('Se déconnecter', style: TextStyle(color: blanc)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: blanc),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? bleuCoris).withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? bleuCoris,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
          : null,
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
      onTap: onTap,
    );
  }
}
