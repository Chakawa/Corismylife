import 'package:flutter/material.dart';
import 'package:mycorislife/services/auth_service.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:mycorislife/core/widgets/country_selector.dart';
import 'package:mycorislife/core/widgets/phone_input_field.dart';

/// ============================================
/// PAGE DE CONNEXION
/// ============================================
/// Cette page permet à l'utilisateur de se connecter à son compte.
/// L'authentification peut se faire avec :
/// - Un email (ex: utilisateur@exemple.com)
/// - Un numéro de téléphone (ex: +225 01 02 03 04 05)
///
/// Fonctionnalités:
/// - Validation des champs de saisie
/// - Authentification sécurisée avec JWT
/// - Animations fluides à l'affichage
/// - Gestion des erreurs de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ===================================
  // CONTRÔLEURS ET ÉTAT DU FORMULAIRE
  // ===================================
  final emailController = TextEditingController(); // Pour l'email
  final phoneController =
      TextEditingController(); // Pour le numéro de téléphone
  final passwordController = TextEditingController();
  bool passwordVisible = false; // Pour afficher/masquer le mot de passe
  bool isLoading = false; // Indicateur de chargement pendant la connexion
  final _formKey =
      GlobalKey<FormState>(); // Clé pour la validation du formulaire

  // Type de connexion : 'phone' ou 'email'
  String loginType = 'phone';

  // Pays sélectionné pour le téléphone (par défaut Côte d'Ivoire)
  late Country selectedCountry;

  // ===================================
  // ANIMATIONS
  // ===================================

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser le pays par défaut (Côte d'Ivoire)
    selectedCountry = CountrySelector.countries.firstWhere(
      (country) => country.code == 'CI',
      orElse: () => CountrySelector.countries.first,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// ==========================================
  /// GÉRER LA CONNEXION DE L'UTILISATEUR
  /// ==========================================
  /// Cette fonction gère le processus de connexion complet :
  /// 1. Valide le formulaire
  /// 2. Détermine l'identifiant (email ou téléphone selon le type de connexion)
  /// 3. Appelle le service d'authentification
  /// 4. Redirige l'utilisateur selon son rôle en cas de succès
  /// 5. Affiche des messages d'erreur clairs en cas d'échec
  /// 
  /// Les erreurs possibles sont :
  /// - Email/mot de passe incorrect
  /// - Pas de connexion Internet
  /// - Serveur inaccessible
  /// - Timeout de la requête
  Future<void> _login() async {
    // Valider le formulaire avant de continuer
    if (!_formKey.currentState!.validate()) return;

    // Activer l'indicateur de chargement
    setState(() => isLoading = true);

    try {
      // Déterminer l'identifiant selon le type de connexion choisi
      String identifier;
      if (loginType == 'phone') {
        // Si connexion par téléphone, construire le numéro complet avec l'indicatif du pays
        identifier = getFullPhoneNumber(selectedCountry, phoneController.text);
      } else {
        // Si connexion par email, utiliser l'email saisi (trim pour supprimer les espaces)
        identifier = emailController.text.trim();
      }

      // Appeler le service d'authentification pour se connecter
      // Le service gère déjà les vérifications Internet et les timeouts
      final result = await AuthService.login(
        identifier,
        passwordController.text,
      );

      // Vérifier que le widget est toujours monté avant de faire des mises à jour UI
      if (!mounted) return;

      // Vérifier si la connexion a réussi
      if (result['success'] == true) {
        // Extraire les données utilisateur depuis la réponse
        final user = result['user'];
        final role = user['role'] ?? 'client'; // Par défaut 'client' si le rôle n'est pas défini

        // Rediriger l'utilisateur vers la page appropriée selon son rôle
        final route = _getRouteForRole(role);
        Navigator.pushReplacementNamed(context, route);
        
        // Afficher un message de succès
        _showSuccessSnackbar();
      } else {
        // La connexion a échoué, afficher le message d'erreur du serveur
        _showErrorSnackbar(result['message'] ?? 
            'Échec de la connexion. Veuillez vérifier vos identifiants.');
      }
    } catch (e) {
      // Gérer les erreurs avec des messages clairs pour l'utilisateur
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        
        // Extraire le message d'erreur et le rendre plus lisible
        final errorString = e.toString();
        
        // Vérifier le type d'erreur pour afficher un message approprié
        if (errorString.contains('Email ou mot de passe incorrect') ||
            errorString.contains('incorrect')) {
          errorMessage = 
              'Email ou mot de passe incorrect. Veuillez vérifier vos identifiants et réessayer.';
        } else if (errorString.contains('connexion Internet') ||
                   errorString.contains('Internet') ||
                   errorString.contains('Impossible de se connecter')) {
          errorMessage = 
              'Aucune connexion Internet. Veuillez vérifier votre connexion réseau et réessayer.';
        } else if (errorString.contains('Timeout') ||
                   errorString.contains('temps') ||
                   errorString.contains('trop de temps')) {
          errorMessage = 
              'Le serveur met trop de temps à répondre. Vérifiez votre connexion Internet et réessayez.';
        } else if (errorString.contains('serveur') || 
                   errorString.contains('Serveur')) {
          errorMessage = 
              'Serveur inaccessible. Veuillez réessayer plus tard.';
        } else {
          // Message générique avec l'erreur technique
          errorMessage = 'Erreur lors de la connexion. ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        _showErrorSnackbar(errorMessage);
      }
    } finally {
      // Désactiver l'indicateur de chargement dans tous les cas (succès ou échec)
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '/adminDashboard';
      case 'commercial':
        return '/commercial_home';
      case 'client':
      default:
        return '/client_home';
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Connexion réussie"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// ==========================================
  /// AFFICHER UN MESSAGE D'ERREUR
  /// ==========================================
  /// Affiche un message d'erreur sous forme de SnackBar en bas de l'écran.
  /// 
  /// Le message est affiché avec :
  /// - Fond rouge pour indiquer l'erreur
  /// - Durée d'affichage de 4 secondes
  /// - Un style flottant pour une meilleure visibilité
  /// 
  /// @param message: Le message d'erreur à afficher à l'utilisateur
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Construit le sélecteur de type de connexion (Téléphone ou Email)
  Widget _buildLoginTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => loginType = 'phone'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: loginType == 'phone' ? bleuCoris : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      color: loginType == 'phone' ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Téléphone',
                      style: TextStyle(
                        color:
                            loginType == 'phone' ? Colors.white : Colors.grey,
                        fontWeight: loginType == 'phone'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => loginType = 'email'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: loginType == 'email' ? bleuCoris : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_rounded,
                      color: loginType == 'email' ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: TextStyle(
                        color:
                            loginType == 'email' ? Colors.white : Colors.grey,
                        fontWeight: loginType == 'email'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !passwordVisible,
        keyboardType: keyboardType ??
            (isPassword ? TextInputType.text : TextInputType.text),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: bleuCoris,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bleuCoris.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(prefixIcon, color: bleuCoris, size: 20),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: bleuCoris.withValues(alpha: 0.7),
                  ),
                  onPressed: () =>
                      setState(() => passwordVisible = !passwordVisible),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: rougeCoris, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: rougeCoris, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: rougeCoris, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bleuCoris.withValues(alpha: 0.05),
              Colors.white,
              bleuCoris.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? size.width * 0.2 : 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 400 : double.infinity,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 70,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            "Bienvenue",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 36 : 32,
                              fontWeight: FontWeight.bold,
                              color: bleuCoris,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Connectez-vous à votre espace Coris",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: isTablet ? 40 : 32),

                          // Sélecteur du type de connexion
                          _buildLoginTypeSelector(),

                          const SizedBox(height: 24),

                          // Champ téléphone ou email selon le type sélectionné
                          if (loginType == 'phone')
                            PhoneInputField(
                              controller: phoneController,
                              selectedCountry: selectedCountry,
                              onCountryChanged: (country) {
                                setState(() {
                                  selectedCountry = country;
                                });
                              },
                              labelText: 'Numéro de téléphone',
                              hintText: '01 02 03 04 05',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Veuillez entrer votre numéro de téléphone";
                                }
                                final digitsOnly = value.replaceAll(' ', '');
                                if (digitsOnly.length < 8) {
                                  return "Numéro de téléphone invalide";
                                }
                                return null;
                              },
                            )
                          else
                            _buildTextField(
                              controller: emailController,
                              labelText: "Email",
                              prefixIcon: Icons.email_rounded,
                              hintText: "exemple@email.com",
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Veuillez entrer votre email";
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)) {
                                  return "Email invalide";
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: passwordController,
                            labelText: "Mot de passe",
                            prefixIcon: Icons.lock_rounded,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Veuillez entrer votre mot de passe";
                              }
                              if (value.length < 8) {
                                return "Le mot de passe doit contenir au moins 8 caractères";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/reset_password');
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: rougeCoris,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                              child: const Text(
                                "Mot de passe oublié ?",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 40 : 32),
                          SizedBox(
                            width: double.infinity,
                            height: isTablet ? 60 : 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bleuCoris,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: bleuCoris.withValues(alpha: 0.4),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      "Se connecter",
                                      style: TextStyle(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 40 : 32),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Pas encore de compte ? ",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: Text(
                                  "Créer un compte",
                                  style: TextStyle(
                                    color: rougeCoris,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
