import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

/// Écran d'authentification à deux facteurs (2FA) avec OTP
class TwoFactorAuthScreen extends StatefulWidget {
  final String identifier; // email ou téléphone
  const TwoFactorAuthScreen({super.key, required this.identifier});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  static const Color bleuCoris = Color(0xFF002B6B);
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isRequesting = false;
  bool _isVerifying = false;
  String? _userId;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _requestOTP();
  }

  Future<void> _requestOTP() async {
    setState(() => _isRequesting = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identifier': widget.identifier}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Récupérer userId depuis le token ou la réponse
        final token = await _storage.read(key: 'token');
        if (token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final decoded = base64.normalize(parts[1]);
              final payload = json.decode(utf8.decode(base64.decode(decoded)));
              _userId = payload['id']?.toString();
            }
          } catch (_) {
            // Si décode échoue, utiliser identifier pour trouver userId
            _userId = null; // Sera récupéré autrement
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Code OTP envoyé (vérifiez la console pour le code en dev)'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception(data['message'] ?? 'Erreur');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isRequesting = false);
    }
  }

  Future<void> _verifyOTP() async {
    final code = _digitControllers.map((c) => c.text).join();
    if (code.length != 6 || _userId == null) return;

    setState(() => _isVerifying = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': int.parse(_userId!), 'code': code}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OTP vérifié avec succès'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(data['message'] ?? 'Code invalide');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Authentification 2FA'),
          backgroundColor: bleuCoris),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: bleuCoris),
            const SizedBox(height: 24),
            const Text('Entrez le code à 6 chiffres',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  6,
                  (i) => SizedBox(
                        width: 45,
                        child: TextField(
                          controller: _digitControllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                            if (i == 5 && v.isNotEmpty) {
                              _verifyOTP();
                            }
                          },
                        ),
                      )),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                  backgroundColor: bleuCoris,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
              child: _isVerifying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Vérifier'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isRequesting ? null : _requestOTP,
              child: _isRequesting
                  ? const CircularProgressIndicator()
                  : const Text('Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _digitControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }
}
