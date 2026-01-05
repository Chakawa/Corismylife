import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';

/// Page de configuration de l'authentification à deux facteurs (2FA)
/// Permet d'activer ou désactiver la 2FA et de configurer le numéro secondaire
class TwoFASettingsScreen extends StatefulWidget {
  const TwoFASettingsScreen({super.key});

  @override
  State<TwoFASettingsScreen> createState() => _TwoFASettingsScreenState();
}

class _TwoFASettingsScreenState extends State<TwoFASettingsScreen> {
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;
  static const Color vertAccent = Color(0xFF10B981);
  static const Color rougeCoris = Color(0xFFE30613);
  
  final _storage = const FlutterSecureStorage();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = true;
  bool _is2FAEnabled = false;
  String? _secondaryPhone;
  bool _isActivating = false;
  bool _showOtpInput = false;
  bool _isVerifying = false;
  String _selectedIndicatif = '+225';
  
  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  /// Charge le statut actuel de la 2FA
  Future<void> _load2FAStatus() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token non trouvé');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/2fa-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _is2FAEnabled = data['enabled'] ?? false;
            _secondaryPhone = data['secondaryPhone'];
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement 2FA: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Active la 2FA - Envoie l'OTP au numéro secondaire
  Future<void> _activate2FA() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      _showMessage('Veuillez entrer un numéro de téléphone valide', isError: true);
      return;
    }

    setState(() => _isActivating = true);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token non trouvé');

      final fullPhone = '$_selectedIndicatif$phone';
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/activate-2fa'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'secondaryPhone': fullPhone}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() => _showOtpInput = true);
        _showMessage('Code OTP envoyé à $fullPhone');
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'activation');
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      setState(() => _isActivating = false);
    }
  }

  /// Vérifie l'OTP et finalise l'activation
  Future<void> _verifyOtpAndActivate() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      _showMessage('Veuillez entrer le code à 6 chiffres', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token non trouvé');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/verify-2fa-activation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'code': code}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        HapticFeedback.lightImpact();
        _showMessage('Authentification à deux facteurs activée avec succès !');
        await _load2FAStatus();
        setState(() {
          _showOtpInput = false;
          _phoneController.clear();
          for (var controller in _otpControllers) {
            controller.clear();
          }
        });
      } else {
        throw Exception(data['message'] ?? 'Code invalide');
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  /// Désactive la 2FA
  Future<void> _disable2FA() async {
    final confirmed = await _showConfirmDialog(
      'Désactiver la 2FA ?',
      'Voulez-vous vraiment désactiver l\'authentification à deux facteurs ? Votre compte sera moins sécurisé.',
    );
    
    if (!confirmed) return;

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token non trouvé');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/disable-2fa'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showMessage('Authentification à deux facteurs désactivée');
        await _load2FAStatus();
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la désactivation');
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
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

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: rougeCoris),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification à deux facteurs'),
        backgroundColor: bleuCoris,
        iconTheme: const IconThemeData(color: blanc),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec icône
                  Center(
                    child: Container(
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
                  ),
                  const SizedBox(height: 24),

                  // Statut actuel
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _is2FAEnabled ? Icons.check_circle : Icons.info_outline,
                                color: _is2FAEnabled ? vertAccent : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _is2FAEnabled ? 'Activée' : 'Désactivée',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _is2FAEnabled ? vertAccent : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _is2FAEnabled
                                ? 'L\'authentification à deux facteurs est active sur votre compte. Vous devrez entrer un code envoyé à votre numéro secondaire à chaque connexion.'
                                : 'Activez l\'authentification à deux facteurs pour renforcer la sécurité de votre compte.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (_is2FAEnabled && _secondaryPhone != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 20, color: bleuCoris),
                                const SizedBox(width: 8),
                                Text(
                                  'Numéro secondaire: $_secondaryPhone',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section d'activation ou désactivation
                  if (!_is2FAEnabled) ...[
                    const Text(
                      'Activer la 2FA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Entrez un numéro de téléphone secondaire qui recevra les codes de vérification lors de vos connexions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    
                    // Champ de numéro de téléphone
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedIndicatif,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: '+225', child: Text('+225')),
                              DropdownMenuItem(value: '+33', child: Text('+33')),
                              DropdownMenuItem(value: '+1', child: Text('+1')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedIndicatif = value!);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Numéro secondaire',
                              hintText: 'Ex: 0799283977',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (!_showOtpInput)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isActivating ? null : _activate2FA,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bleuCoris,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isActivating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: blanc,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Envoyer le code OTP',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),

                    // Section OTP
                    if (_showOtpInput) ...[
                      const Text(
                        'Entrez le code à 6 chiffres',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (i) => SizedBox(
                            width: 45,
                            child: TextField(
                              controller: _otpControllers[i],
                              focusNode: _otpFocusNodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 5) {
                                  _otpFocusNodes[i + 1].requestFocus();
                                } else if (v.isEmpty && i > 0) {
                                  _otpFocusNodes[i - 1].requestFocus();
                                }
                                if (i == 5 && v.isNotEmpty) {
                                  _verifyOtpAndActivate();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOtpAndActivate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vertAccent,
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
                                  'Vérifier et activer',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showOtpInput = false;
                              for (var controller in _otpControllers) {
                                controller.clear();
                              }
                            });
                          },
                          child: const Text('Annuler'),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Bouton de désactivation
                    const Text(
                      'Gérer la 2FA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vous pouvez désactiver l\'authentification à deux facteurs si vous ne souhaitez plus l\'utiliser.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _disable2FA,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rougeCoris,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Désactiver la 2FA',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
