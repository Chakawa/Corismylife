import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mycorislife/config/app_config.dart';

/// Page de vérification OTP pour la connexion avec 2FA activée
class TwoFALoginOtpScreen extends StatefulWidget {
  final int userId;
  final String secondaryPhone;
  final Map<String, dynamic> userData; // Données complètes de l'utilisateur pour finaliser la connexion

  const TwoFALoginOtpScreen({
    super.key,
    required this.userId,
    required this.secondaryPhone,
    required this.userData,
  });

  @override
  State<TwoFALoginOtpScreen> createState() => _TwoFALoginOtpScreenState();
}

class _TwoFALoginOtpScreenState extends State<TwoFALoginOtpScreen> {
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;
  static const Color vertAccent = Color(0xFF10B981);
  static const Color rougeCoris = Color(0xFFE30613);

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Le code OTP a déjà été envoyé depuis l'écran de connexion
  }

  /// Vérifie le code OTP
  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showMessage('Veuillez entrer le code à 6 chiffres', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-2fa-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'code': code,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        HapticFeedback.lightImpact();
        // Code vérifié, retourner les données utilisateur pour finaliser la connexion
        Navigator.pop(context, widget.userData);
      } else {
        throw Exception(data['message'] ?? 'Code invalide');
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  /// Renvoie un nouveau code OTP
  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-2fa-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': widget.userId}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showMessage('Nouveau code envoyé à ${widget.secondaryPhone}');
      } else {
        throw Exception(data['message'] ?? 'Erreur lors du renvoi');
      }
    } catch (e) {
      _showMessage(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? rougeCoris : vertAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification 2FA'),
        backgroundColor: bleuCoris,
        iconTheme: const IconThemeData(color: blanc),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icône de sécurité
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bleuCoris.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security,
                size: 64,
                color: bleuCoris,
              ),
            ),
            const SizedBox(height: 32),

            // Titre
            const Text(
              'Authentification à deux facteurs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: bleuCoris,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Un code de vérification a été envoyé au numéro:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.secondaryPhone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: bleuCoris,
              ),
            ),
            const SizedBox(height: 40),

            // Champs OTP
            const Text(
              'Entrez le code à 6 chiffres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: bleuCoris, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: bleuCoris, width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _otpFocusNodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _otpFocusNodes[i - 1].requestFocus();
                      }
                      if (i == 5 && v.isNotEmpty) {
                        _verifyOtp();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Bouton de vérification
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bleuCoris,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: blanc,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Vérifier le code',
                        style: TextStyle(fontSize: 16, color: blanc),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de renvoi du code
            TextButton.icon(
              onPressed: _isResending ? null : _resendOtp,
              icon: _isResending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Renvoyer le code'),
            ),
            const SizedBox(height: 16),

            // Lien pour annuler
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Annuler la connexion',
                style: TextStyle(color: rougeCoris),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
