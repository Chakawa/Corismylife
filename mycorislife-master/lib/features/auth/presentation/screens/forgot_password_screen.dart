import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:mycorislife/config/app_config.dart';

/// Page de réinitialisation de mot de passe
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Étapes du flux
  final int STEP_PHONE = 0;
  final int STEP_OTP = 1;
  final int STEP_NEW_PASSWORD = 2;

  int _currentStep = 0; // Commencer à l'étape du téléphone
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  // Variables pour la visibilité des mots de passe
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // 📞 Liste des indicatifs téléphoniques
  final List<String> _indicatifs = [
    '+225', // Côte d'Ivoire
    '+226', // Burkina Faso
    '+237', // Cameroun
    '+228', // Togo
    '+229', // Bénin
    '+234'  // Nigeria
  ];
  String _selectedIndicatif = '+225';

  // Variables pour le compteur OTP
  late Timer _timer;
  int _secondsRemaining = 0;
  String? _storedTelephone;
  int? _storedUserId;

  // Couleurs CORIS
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color blanc = Colors.white;
  static const Color grisTexte = Color(0xFF64748B);

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer.cancel();
    super.dispose();
  }

  /// ÉTAPE 1: Vérifier le téléphone et envoyer l'OTP
  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre numéro de téléphone');
      return;
    }

    // 📞 Combiner indicatif + numéro
    final phoneComplet = '$_selectedIndicatif$phone';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': phoneComplet}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _storedTelephone = phoneComplet;
          _successMessage = data['message'] ?? 'Code OTP envoyé avec succès';
          _currentStep = STEP_OTP;
          _isLoading = false;
          _secondsRemaining = 300; // 5 minutes
          _startTimer();
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Erreur lors de la demande';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  /// ÉTAPE 2: Vérifier l'OTP
  Future<void> _submitOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 5) {
      setState(() => _errorMessage = 'Veuillez entrer un code OTP valide');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': _storedTelephone,
          'otpCode': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _storedUserId = data['userId'];
          _successMessage = 'Code OTP vérifié. Entrez votre nouveau mot de passe.';
          _currentStep = STEP_NEW_PASSWORD;
          _isLoading = false;
          _timer.cancel();
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Code OTP incorrect';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  /// ÉTAPE 3: Réinitialiser le mot de passe
  Future<void> _submitNewPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Tous les champs sont requis');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'telephone': _storedTelephone,
          'userId': _storedUserId,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Succès! Rediriger vers la page d'accueil avec message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mot de passe réinitialisé avec succès'),
              backgroundColor: vertSucces,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Erreur lors de la réinitialisation';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  /// Renvoyer le code OTP
  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/resend-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': _storedTelephone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Annuler l'ancien timer s'il existe
        if (_timer.isActive) {
          _timer.cancel();
        }
        
        setState(() {
          _successMessage = 'Un nouveau code a été envoyé';
          _secondsRemaining = 300; // Réinitialiser le compteur à 5 minutes
          _isLoading = false;
          _otpController.clear(); // Vider le champ OTP pour saisir le nouveau code
        });
        
        // Redémarrer le compteur avec le nouveau code
        _startTimer();
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Erreur lors du renvoi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  /// Démarrer le compteur de 5 minutes
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  /// Format du temps restant (MM:SS)
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bleuCoris,
        foregroundColor: blanc,
        title: const Text('Réinitialiser le mot de passe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur d'étape
            _buildStepIndicator(),
            const SizedBox(height: 30),

            // Contenu selon l'étape
            if (_currentStep == STEP_PHONE) _buildPhoneStep(),
            if (_currentStep == STEP_OTP) _buildOtpStep(),
            if (_currentStep == STEP_NEW_PASSWORD) _buildNewPasswordStep(),

            // Messages d'erreur/succès
            if (_errorMessage != null)
              _buildMessage(_errorMessage!, Colors.red, Icons.error_outline),
            if (_successMessage != null)
              _buildMessage(_successMessage!, vertSucces, Icons.check_circle),
          ],
        ),
      ),
    );
  }

  /// Indicateur d'étape
  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepDot(0, _currentStep >= 0),
            Expanded(
              child: Container(
                height: 2,
                color: _currentStep >= 1 ? vertSucces : Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepDot(1, _currentStep >= 1),
            Expanded(
              child: Container(
                height: 2,
                color: _currentStep >= 2 ? vertSucces : Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            _buildStepDot(2, _currentStep >= 2),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Téléphone',
              style: TextStyle(
                fontSize: 12,
                color: _currentStep >= 0 ? bleuCoris : Colors.grey,
              ),
            ),
            Text(
              'Vérification',
              style: TextStyle(
                fontSize: 12,
                color: _currentStep >= 1 ? bleuCoris : Colors.grey,
              ),
            ),
            Text(
              'Nouveau mot de passe',
              style: TextStyle(
                fontSize: 12,
                color: _currentStep >= 2 ? bleuCoris : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Point d'étape
  Widget _buildStepDot(int step, bool active) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? vertSucces : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: active ? blanc : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ÉTAPE 1: Saisie du téléphone
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Entrez votre numéro de téléphone',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nous vous enverrons un code de vérification à ce numéro.',
          style: TextStyle(color: grisTexte),
        ),
        const SizedBox(height: 24),
        // 📞 Row avec Dropdown indicatif + TextField numéro
        Row(
          children: [
            // Dropdown pour l'indicatif
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIndicatif,
                  icon: const Icon(Icons.arrow_drop_down, color: bleuCoris),
                  style: const TextStyle(
                    color: bleuCoris,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedIndicatif = newValue;
                      });
                    }
                  },
                  items: _indicatifs.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // TextField pour le numéro
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'XXXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone, color: bleuCoris),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: bleuCoris, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitPhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: bleuCoris,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(blanc),
                    ),
                  )
                : const Text(
                    'Continuer',
                    style: TextStyle(color: blanc, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  /// ÉTAPE 2: Vérification OTP
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Entrez le code de vérification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nous avons envoyé un code à $_storedTelephone',
          style: const TextStyle(color: grisTexte),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 5,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '00000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Compteur et bouton renvoyer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _secondsRemaining > 0
                  ? 'Code expire dans ${_formatTime(_secondsRemaining)}'
                  : 'Code expiré',
              style: TextStyle(
                color: _secondsRemaining > 0 ? grisTexte : rougeCoris,
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: Text(
                'Renvoyer le code',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : bleuCoris,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: bleuCoris,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(blanc),
                    ),
                  )
                : const Text(
                    'Continuer',
                    style: TextStyle(color: blanc, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  /// ÉTAPE 3: Nouveau mot de passe
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créez un nouveau mot de passe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Entrez votre nouveau mot de passe ci-dessous.',
          style: TextStyle(color: grisTexte),
        ),
        const SizedBox(height: 24),

        // Nouveau mot de passe
        TextField(
          controller: _newPasswordController,
          obscureText: !_showNewPassword,
          decoration: InputDecoration(
            hintText: 'Nouveau mot de passe',
            prefixIcon: const Icon(Icons.lock, color: bleuCoris),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword ? Icons.visibility : Icons.visibility_off,
                            color: bleuCoris,
                          ),
                          onPressed: () {
                            setState(() {
                              _showNewPassword = !_showNewPassword;
                            });
                          },
                        ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirmer mot de passe
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            hintText: 'Confirmez le mot de passe',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: bleuCoris,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
            prefixIcon: const Icon(Icons.lock, color: bleuCoris),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: vertSucces,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(blanc),
                    ),
                  )
                : const Text(
                    'Réinitialiser le mot de passe',
                    style: TextStyle(color: blanc, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  /// Message d'erreur/succès
  Widget _buildMessage(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
