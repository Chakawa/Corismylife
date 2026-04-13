import 'package:flutter/material.dart';
import 'package:mycorislife/services/user_service.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/features/auth/presentation/screens/login_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/help_support_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/privacy_policy_screen.dart';
import 'package:mycorislife/features/client/presentation/screens/terms_conditions_screen.dart';
import 'package:mycorislife/core/utils/responsive.dart';

/// Page de paramètres de l'application
/// Permet à l'utilisateur de configurer l'application et gérer son compte
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ===================================
  // CONSTANTES DE COULEURS
  // ===================================
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;
  static const Color fondGris = Color(0xFFF0F4F8);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color rougeCoris = Color(0xFFE30613);

  // ===================================
  // VARIABLES D'ÉTAT POUR LES PARAMÈTRES
  // ===================================
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _biometricEnabled = false;
  bool _isChangingPassword = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ===================================
  // INITIALISATION
  // ===================================
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Charge les paramètres sauvegardés
  Future<void> _loadSettings() async {
    // TODO: Charger les paramètres depuis le stockage local ou l'API
  }

  /// Sauvegarde un paramètre
  Future<void> _saveSetting(String key, bool value) async {
    await _storage.write(key: key, value: value.toString());
  }

  /// Déconnecte l'utilisateur
  Future<void> _logout() async {
    try {
      await AuthService.logout();

      if (!mounted) return;

      // Rediriger vers la page de connexion et supprimer toutes les routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  /// Affiche la boîte de dialogue de confirmation de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: rougeCoris),
            SizedBox(width: 8),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: rougeCoris,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ===================================
  // INTERFACE UTILISATEUR
  // ===================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondGris,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(color: blanc, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bleuCoris,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: blanc),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Notifications
          _buildSectionHeader('Notifications'),
          _buildSettingCard(
            icon: Icons.notifications_outlined,
            title: 'Activer les notifications',
            subtitle: 'Recevoir des alertes sur vos contrats',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications_enabled', value);
              },
              activeThumbColor: vertSucces,
            ),
          ),
          if (_notificationsEnabled) ...[
            _buildSettingCard(
              icon: Icons.email_outlined,
              title: 'Notifications par email',
              subtitle: 'Recevoir des notifications par email',
              trailing: Switch(
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  _saveSetting('email_notifications', value);
                },
                activeThumbColor: vertSucces,
              ),
            ),
            _buildSettingCard(
              icon: Icons.sms_outlined,
              title: 'Notifications par SMS',
              subtitle: 'Recevoir des notifications par SMS',
              trailing: Switch(
                value: _smsNotifications,
                onChanged: (value) {
                  setState(() => _smsNotifications = value);
                  _saveSetting('sms_notifications', value);
                },
                activeThumbColor: vertSucces,
              ),
            ),
          ],

            SizedBox(height: context.r(20)),

          // Section Sécurité
          _buildSectionHeader('Sécurité'),
          _buildSettingCard(
            icon: Icons.fingerprint,
            title: 'Authentification biométrique',
            subtitle: 'Utiliser Touch ID ou Face ID',
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() => _biometricEnabled = value);
                _saveSetting('biometric_enabled', value);
              },
              activeThumbColor: vertSucces,
            ),
          ),
          _buildSettingCard(
            icon: Icons.lock_outline,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe de connexion',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showChangePasswordDialog();
            },
          ),

            SizedBox(height: context.r(20)),

          // Section Compte
          _buildSectionHeader('Compte'),
          _buildSettingCard(
            icon: Icons.help_outline,
            title: 'Aide et support',
            subtitle: 'Centre d\'aide et FAQ',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Confidentialité',
            subtitle: 'Politique de confidentialité',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            subtitle: 'Termes et conditions',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TermsConditionsScreen()),
              );
            },
          ),
          _buildSettingCard(
            icon: Icons.info_outline,
            title: 'À propos',
            subtitle: 'Version 1.0.0',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog();
            },
          ),

            SizedBox(height: context.r(20)),

          // Bouton de déconnexion
          _buildLogoutButton(),

            SizedBox(height: context.r(28)),
        ],
      ),
    );
  }

  /// Construit un en-tête de section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.sp(17),
          fontWeight: FontWeight.w700,
          color: bleuCoris,
        ),
      ),
    );
  }

  /// Construit une carte de paramètre
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: context.r(44),
          height: context.r(44),
          decoration: BoxDecoration(
            color: bleuCoris.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: bleuCoris, size: context.r(21)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: context.sp(15),
            fontWeight: FontWeight.w600,
            color: bleuCoris,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: context.sp(13),
            color: grisTexte,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  /// Construit le bouton de déconnexion
  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: _showLogoutDialog,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: context.r(44),
          height: context.r(44),
          decoration: BoxDecoration(
            color: rougeCoris.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.logout, color: rougeCoris, size: context.r(21)),
        ),
        title: Text(
          'Déconnexion',
          style: TextStyle(
            fontSize: context.sp(15),
            fontWeight: FontWeight.w600,
            color: rougeCoris,
          ),
        ),
        subtitle: Text(
          'Se déconnecter de l\'application',
          style: TextStyle(
            fontSize: context.sp(13),
            color: grisTexte,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: rougeCoris),
      ),
    );
  }

  /// Affiche la boîte de dialogue de changement de mot de passe
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bleuCoris.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_rounded, color: bleuCoris, size: context.r(22)),
            ),
            SizedBox(width: context.r(10)),
            Flexible(
              child: Text(
                'Changer le mot de passe',
                style: TextStyle(
                  fontSize: context.sp(17),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: bleuCoris),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: bleuCoris, width: 2),
                  ),
                ),
              ),
              SizedBox(height: context.r(14)),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded, color: bleuCoris),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: bleuCoris, width: 2),
                  ),
                ),
              ),
              SizedBox(height: context.r(14)),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_clock_rounded, color: bleuCoris),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: bleuCoris, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) {
              return ElevatedButton(
                onPressed: _isChangingPassword
                    ? null
                    : () async {
                        final oldPwd = oldPasswordController.text.trim();
                        final newPwd = newPasswordController.text.trim();
                        final confirmPwd = confirmPasswordController.text.trim();

                        if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tous les champs sont requis'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (newPwd.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Le nouveau mot de passe doit contenir au moins 8 caractères'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (newPwd != confirmPwd) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Les mots de passe ne correspondent pas'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setState(() => _isChangingPassword = true);
                        setDialogState(() {});
                        try {
                          await UserService.changePassword(oldPassword: oldPwd, newPassword: newPwd);
                          if (!context.mounted) return;
                          setState(() => _isChangingPassword = false);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe changé avec succès'),
                              backgroundColor: vertSucces,
                            ),
                          );
                        } catch (e) {
                          setState(() => _isChangingPassword = false);
                          setDialogState(() {});
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: bleuCoris),
                child: _isChangingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirmer'),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Affiche la boîte de dialogue "À propos"
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MyCorisLife',
              style: TextStyle(
                fontSize: context.sp(18),
                fontWeight: FontWeight.w700,
                color: bleuCoris,
              ),
            ),
            SizedBox(height: context.r(8)),
            const Text('Version 1.0.0'),
            SizedBox(height: context.r(14)),
            Text(
              'Application mobile de gestion des contrats d\'assurance CORIS.',
              style: TextStyle(
                color: grisTexte,
                height: 1.5,
              ),
            ),
            SizedBox(height: context.r(14)),
            Text(
              '© 2025 CORIS. Tous droits réservés.',
              style: TextStyle(fontSize: context.sp(11)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
