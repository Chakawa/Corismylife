import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycorislife/config/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int currentStep = 0; // 0: Email, 1: Code, 2: Nouveau mot de passe
  String? devCode; // Pour le développement
  
  static const String baseUrl = 'http://192.168.1.32:5000/api/password-reset';

  // Étape 1: Demander le code de vérification
  Future<void> _requestCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': emailController.text.trim()}),
        );

        final data = jsonDecode(response.body);

        if (mounted) {
          if (data['success']) {
            // Stocker le code de développement s'il est fourni
            devCode = data['devCode'];
            
            setState(() => currentStep = 1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message']),
                backgroundColor: vertSucces,
                duration: const Duration(seconds: 4),
              ),
            );
            
            // Afficher le code en mode développement
            if (devCode != null) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('🔐 Code de développement'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Votre code de vérification :'),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bleuCoris.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              devCode!,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Erreur'),
                backgroundColor: rougeCoris,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de connexion: $e'),
              backgroundColor: rougeCoris,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  // Étape 2: Vérifier le code
  Future<void> _verifyCode() async {
    if (codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le code à 6 chiffres'),
          backgroundColor: rougeCoris,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'code': codeController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        if (data['success']) {
          setState(() => currentStep = 2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code vérifié avec succès!'),
              backgroundColor: vertSucces,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Code incorrect'),
              backgroundColor: rougeCoris,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: rougeCoris,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Étape 3: Réinitialiser le mot de passe
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/reset'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': emailController.text.trim(),
            'code': codeController.text.trim(),
            'newPassword': newPasswordController.text,
          }),
        );

        final data = jsonDecode(response.body);

        if (mounted) {
          if (data['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mot de passe réinitialisé avec succès!'),
                backgroundColor: vertSucces,
                duration: Duration(seconds: 3),
              ),
            );
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Erreur'),
                backgroundColor: rougeCoris,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: rougeCoris,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bleuCoris,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: currentStep == 0 
            ? () => Navigator.pop(context)
            : () => setState(() => currentStep -= 1),
        ),
        title: const Text(
          "Réinitialiser le mot de passe",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F4F8), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Indicateur d'étapes
                  _buildStepIndicator(),
                  const SizedBox(height: 40),
                  
                  // Contenu selon l'étape
                  if (currentStep == 0) _buildEmailStep(),
                  if (currentStep == 1) _buildCodeStep(),
                  if (currentStep == 2) _buildPasswordStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(0, 'Email'),
        Expanded(child: Container(height: 2, color: currentStep > 0 ? vertSucces : Colors.grey[300])),
        _buildStepCircle(1, 'Code'),
        Expanded(child: Container(height: 2, color: currentStep > 1 ? vertSucces : Colors.grey[300])),
        _buildStepCircle(2, 'Mot de passe'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    bool isActive = currentStep >= step;
    bool isCurrent = currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? (isCurrent ? bleuCoris : vertSucces) : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isCurrent ? [
              BoxShadow(
                color: bleuCoris.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Center(
            child: isActive && !isCurrent
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  '${step + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? bleuCoris : Colors.grey[600],
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.email_outlined, size: 60, color: bleuCoris),
        const SizedBox(height: 16),
        const Text(
          "Entrez votre email",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Nous vous enverrons un code de vérification à 6 chiffres",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Adresse e-mail",
            hintText: "exemple@email.com",
            prefixIcon: const Icon(Icons.email, color: bleuCoris),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _requestCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: bleuCoris,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Envoyer le code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 60, color: bleuCoris),
        const SizedBox(height: 16),
        const Text(
          "Entrez le code",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Un code à 6 chiffres a été envoyé à\n${emailController.text}",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 16,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: "000000",
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : _requestCode,
            child: const Text('Renvoyer le code'),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: bleuCoris,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Vérifier le code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, size: 60, color: vertSucces),
        const SizedBox(height: 16),
        const Text(
          "Nouveau mot de passe",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Créez un mot de passe sécurisé",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: newPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Nouveau mot de passe",
            prefixIcon: const Icon(Icons.lock, color: bleuCoris),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: "Confirmer le mot de passe",
            prefixIcon: const Icon(Icons.lock_outline, color: bleuCoris),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCoris, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer votre mot de passe';
            }
            if (value != newPasswordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: vertSucces,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Réinitialiser le mot de passe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}