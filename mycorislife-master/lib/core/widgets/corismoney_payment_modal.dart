import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycorislife/services/corismoney_service.dart';

/// ============================================
/// MODAL DE PAIEMENT CORISMONEY
/// ============================================
/// Widget modal pour effectuer un paiement via CorisMoney
/// 
/// Flux en 3 étapes:
/// 1. Saisie du numéro de téléphone
/// 2. Saisie du code OTP reçu par SMS
/// 3. Confirmation et traitement du paiement
/// 
/// Utilisation:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => CorisMoneyPaymentModal(
///     subscriptionId: subscription['id'],
///     montant: primeValue,
///     onPaymentSuccess: () {
///       // Rafraîchir la page ou naviguer
///     },
///   ),
/// );
/// ```
class CorisMoneyPaymentModal extends StatefulWidget {
  final int subscriptionId;
  final double montant;
  final String? description;
  final VoidCallback onPaymentSuccess;

  const CorisMoneyPaymentModal({
    Key? key,
    required this.subscriptionId,
    required this.montant,
    this.description,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<CorisMoneyPaymentModal> createState() => _CorisMoneyPaymentModalState();
}

class _CorisMoneyPaymentModalState extends State<CorisMoneyPaymentModal> {
  final CorisMoneyService _paymentService = CorisMoneyService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  int _currentStep = 1; // 1: Téléphone, 2: OTP, 3: Traitement
  bool _isLoading = false;
  String? _errorMessage;
  String _codePays = '225'; // Code pays par défaut: +225 (Côte d'Ivoire)

  // Liste des codes pays disponibles
  static const Map<String, String> _codesPays = {
    '225': '🇨🇮 Côte d\'Ivoire (+225)',
    '226': '🇧🇫 Burkina Faso (+226)',
    '223': '🇲🇱 Mali (+223)',
    '221': '🇸🇳 Sénégal (+221)',
    '228': '🇹🇬 Togo (+228)',
    '229': '🇧🇯 Bénin (+229)',
    '224': '🇬🇳 Guinée (+224)',
    '227': '🇳🇪 Niger (+227)',
    '237': '🇨🇲 Cameroun (+237)',
    '33': '🇫🇷 France (+33)',
  };

  // Couleurs CORIS
  static const Color bleuCoris = Color(0xFF002B6B); // Bleu CORIS officiel
  static const Color bleuSecondaire = Color(0xFF1E4A8C); // Bleu secondaire
  static const Color vertSucces = Color(0xFF10B981); // Vert succès
  static const Color rouge = Color(0xFFEF4444); // Rouge erreur
  static const Color fondBlanc = Color(0xFFFFFFFF); // Fond blanc
  static const Color bordure = Color(0xFFE5E7EB); // Bordure grise claire

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Envoie le code OTP au numéro saisi
  Future<void> _sendOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir votre numéro de téléphone';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Le numéro doit conserver le 0 initial (ex: 0799283976)
    // L'API CorisMoney nécessite: 225 + 0799283976 = 2250799283976
    String numeroNettoye = _phoneController.text.trim();

    final result = await _paymentService.sendOTP(
      codePays: _codePays, // Utilise directement le code téléphonique (ex: "225")
      telephone: numeroNettoye,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      setState(() {
        _currentStep = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code OTP envoyé par SMS'),
          backgroundColor: vertSucces,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Erreur lors de l\'envoi du code OTP';
      });
    }
  }

  /// Traite le paiement avec le code OTP saisi
  Future<void> _processPayment() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir le code OTP reçu par SMS';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentStep = 3;
    });

    // Le numéro doit conserver le 0 initial (ex: 0799283976)
    // L'API CorisMoney nécessite: 225 + 0799283976 = 2250799283976
    String numeroNettoye = _phoneController.text.trim();

    final result = await _paymentService.processPayment(
      subscriptionId: widget.subscriptionId,
      codePays: _codePays,
      telephone: numeroNettoye,
      montant: widget.montant,
      codeOTP: _otpController.text.trim(),
      description: widget.description,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // Paiement réussi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paiement effectué avec succès !'),
          backgroundColor: vertSucces,
          duration: Duration(seconds: 3),
        ),
      );

      // Attendre 1 seconde puis fermer et appeler le callback
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      
      Navigator.of(context).pop();
      widget.onPaymentSuccess();
    } else {
      setState(() {
        _currentStep = 2; // Retourner à l'étape OTP
        _errorMessage = result['error'] ?? 'Erreur lors du paiement';
      });
    }
  }

  /// Formate le montant en FCFA avec espaces
  String _formatMontant(double montant) {
    return "${montant.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} FCFA";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bleuCoris, bleuSecondaire],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bleuCoris.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paiement CorisMoney',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Paiement sécurisé',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Contenu du modal
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Affichage du montant
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fondBlanc,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: bordure, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Montant à payer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMontant(widget.montant),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: bleuCoris,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: rouge.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rouge.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: rouge, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: rouge, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Étape 1: Numéro de téléphone
                  if (_currentStep == 1) ...[
                    const Text(
                      'Numéro de téléphone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Un code OTP sera envoyé à ce numéro pour confirmer le paiement',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sélecteur de code pays
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _codePays,
                        decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.flag, color: bleuCoris),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: Colors.white,
                        items: _codesPays.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _codePays = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ téléphone
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, color: bleuCoris),
                        hintText: _codePays == '225' ? '07 00 00 00 00' : 'Numéro de téléphone',
                        helperText: 'Sans l\'indicatif pays',
                        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: bleuCoris, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bleuCoris,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          shadowColor: bleuCoris.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Envoyer le code OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // Étape 2: Code OTP
                  if (_currentStep == 2) ...[
                    const Text(
                      'Code OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saisissez le code reçu par SMS',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: bleuCoris),
                        hintText: '000000',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: bleuCoris, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentStep = 1;
                                _errorMessage = null;
                              });
                            },
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text(
                              'Modifier',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: _isLoading ? null : _sendOTP,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'Renvoyer',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vertSucces,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Confirmer le paiement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // Étape 3: Traitement en cours
                  if (_currentStep == 3) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: fondBlanc,
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          color: bleuCoris,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Traitement du paiement en cours...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Veuillez patienter',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
