import 'package:flutter/material.dart';
import 'package:mycorislife/config/theme.dart';

/// Classe pour gérer les contrôleurs de modes de paiement
class PaymentMethodControllers {
  final TextEditingController banque = TextEditingController();
  final TextEditingController ribUnified = TextEditingController();
  final TextEditingController numeroMobileMoney = TextEditingController();
  final TextEditingController nomStructure = TextEditingController();
  final TextEditingController numeroMatricule = TextEditingController();
  final TextEditingController corisMoneyPhone = TextEditingController();

  void dispose() {
    banque.dispose();
    ribUnified.dispose();
    numeroMobileMoney.dispose();
    nomStructure.dispose();
    numeroMatricule.dispose();
    corisMoneyPhone.dispose();
  }

  void clearAll() {
    banque.clear();
    ribUnified.clear();
    numeroMobileMoney.clear();
    nomStructure.clear();
    numeroMatricule.clear();
    corisMoneyPhone.clear();
  }
}

/// Liste des modes de paiement disponibles
class PaymentMethods {
  static const List<String> all = [
    'Virement',
    'Wave',
    'Orange Money',
    'Prélèvement à la source',
    'CORIS Money',
  ];

  static IconData getIcon(String mode) {
    if (mode.toLowerCase().contains('virement')) {
      return Icons.account_balance;
    } else if (mode.toLowerCase().contains('wave')) {
      return Icons.water_drop;
    } else if (mode.toLowerCase().contains('orange')) {
      return Icons.phone_android;
    } else if (mode.toLowerCase().contains('prélèvement') || 
               mode.toLowerCase().contains('prelevement')) {
      return Icons.business;
    } else if (mode.toLowerCase().contains('coris money')) {
      return Icons.account_balance_wallet;
    }
    return Icons.payment;
  }

  static Color getColor(String mode) {
    if (mode.toLowerCase().contains('virement')) {
      return bleuCoris;
    } else if (mode.toLowerCase().contains('wave')) {
      return const Color(0xFF00BFFF);
    } else if (mode.toLowerCase().contains('orange')) {
      return Colors.orange;
    } else if (mode.toLowerCase().contains('prélèvement') || 
               mode.toLowerCase().contains('prelevement')) {
      return Colors.green;
    } else if (mode.toLowerCase().contains('coris money')) {
      return const Color(0xFF1E3A8A);
    }
    return bleuCoris;
  }
}

/// Validation des modes de paiement
class PaymentMethodValidator {
  /// Valide les champs selon le mode de paiement sélectionné
  static String? validate(
    String modePaiement,
    PaymentMethodControllers controllers,
  ) {
    if (modePaiement == 'Virement') {
      if (controllers.banque.text.trim().isEmpty) {
        return 'Veuillez sélectionner une banque';
      }
      if (controllers.ribUnified.text.trim().isEmpty) {
        return 'Veuillez saisir votre RIB complet';
      }
      if (controllers.ribUnified.text.trim().length < 23) {
        return 'Le RIB doit contenir au moins 23 caractères';
      }
    } else if (modePaiement == 'Wave' || modePaiement == 'Orange Money') {
      final phone = controllers.numeroMobileMoney.text.trim();
      if (phone.isEmpty) {
        return 'Veuillez saisir le numéro $modePaiement';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        return 'Le numéro doit contenir uniquement des chiffres';
      }
      if (phone.length < 8) {
        return 'Le numéro doit contenir au moins 8 chiffres';
      }
      if (modePaiement == 'Orange Money' && !phone.startsWith('07')) {
        return 'Le numéro Orange Money doit commencer par 07';
      }
    } else if (modePaiement == 'Prélèvement à la source') {
      if (controllers.nomStructure.text.trim().isEmpty) {
        return 'Veuillez saisir le nom de la structure';
      }
      if (controllers.numeroMatricule.text.trim().isEmpty) {
        return 'Veuillez saisir votre numéro de matricule';
      }
    } else if (modePaiement == 'CORIS Money') {
      final phone = controllers.corisMoneyPhone.text.trim();
      if (phone.isEmpty) {
        return 'Veuillez saisir le numéro CORIS Money';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        return 'Le numéro doit contenir uniquement des chiffres';
      }
      if (phone.length < 8) {
        return 'Le numéro doit contenir au moins 8 chiffres';
      }
    }
    return null;
  }
}

/// Widget pour la sélection du mode de paiement
class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMode;
  final List<String> availableModes;
  final Function(String?) onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMode,
    this.availableModes = PaymentMethods.all,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selectedMode != null ? bleuCoris : grisLeger),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMode,
          hint: Row(
            children: [
              Icon(Icons.payment, size: 20, color: grisTexte),
              const SizedBox(width: 12),
              Text(
                'Sélectionnez le mode de paiement',
                style: TextStyle(color: grisTexte, fontSize: 14),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: bleuCoris),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          items: availableModes.map((String mode) {
            return DropdownMenuItem<String>(
              value: mode,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PaymentMethods.getColor(mode).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PaymentMethods.getIcon(mode),
                      color: PaymentMethods.getColor(mode),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(mode, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Widget pour les champs de paiement selon le mode sélectionné
class PaymentMethodFields extends StatelessWidget {
  final String modePaiement;
  final PaymentMethodControllers controllers;
  final List<String> banques;

  const PaymentMethodFields({
    super.key,
    required this.modePaiement,
    required this.controllers,
    this.banques = const ['BSIC', 'SGCI', 'BNI', 'ECOBANK', 'UBA', 'Autre'],
  });

  @override
  Widget build(BuildContext context) {
    if (modePaiement == 'Virement') {
      return _buildVirementFields();
    } else if (modePaiement == 'Wave' || modePaiement == 'Orange Money') {
      return _buildMobileMoneyFields();
    } else if (modePaiement == 'Prélèvement à la source') {
      return _buildPrelevementFields();
    } else if (modePaiement == 'CORIS Money') {
      return _buildCorisMoneyFields();
    }
    return const SizedBox.shrink();
  }

  Widget _buildVirementFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Banque',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: blanc,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: grisLeger),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controllers.banque.text.isNotEmpty ? controllers.banque.text : null,
              hint: Row(
                children: [
                  Icon(Icons.account_balance, size: 20, color: grisTexte),
                  const SizedBox(width: 12),
                  Text(
                    'Sélectionnez votre banque',
                    style: TextStyle(color: grisTexte, fontSize: 14),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: bleuCoris),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              items: banques.map((String banque) {
                return DropdownMenuItem<String>(
                  value: banque,
                  child: Text(banque, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  controllers.banque.text = newValue;
                } else {
                  controllers.banque.text = '';
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'RIB Complet',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.ribUnified,
          decoration: InputDecoration(
            hintText: 'CI XX XXXXX XXXXXXXXXX XX',
            prefixIcon: Icon(Icons.credit_card, color: bleuCoris),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.text,
          maxLength: 26,
        ),
      ],
    );
  }

  Widget _buildMobileMoneyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Numéro $modePaiement',
          style: const TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.numeroMobileMoney,
          decoration: InputDecoration(
            hintText: modePaiement == 'Orange Money' ? '07 XX XX XX XX' : 'XX XX XX XX XX',
            prefixIcon: Icon(
              PaymentMethods.getIcon(modePaiement),
              color: PaymentMethods.getColor(modePaiement),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildPrelevementFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Nom de la structure',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.nomStructure,
          decoration: InputDecoration(
            hintText: 'Ex: Ministère de la Santé',
            prefixIcon: Icon(Icons.business, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        const Text(
          'Numéro de matricule',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.numeroMatricule,
          decoration: InputDecoration(
            hintText: 'Votre numéro de matricule',
            prefixIcon: Icon(Icons.badge, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildCorisMoneyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Numéro CORIS Money',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.corisMoneyPhone,
          decoration: InputDecoration(
            hintText: 'XX XX XX XX XX',
            prefixIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF1E3A8A)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

/// Bottom sheet pour les options de paiement final
class PaymentBottomSheet extends StatelessWidget {
  final Function(String) onPayNow;
  final VoidCallback onPayLater;

  const PaymentBottomSheet({
    super.key,
    required this.onPayNow,
    required this.onPayLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.payment, color: Color(0xFF002B6B), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Options de Paiement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF002B6B),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              _buildPaymentOption(
                'Wave',
                Icons.waves,
                Colors.blue,
                'Paiement mobile sécurisé',
                () => onPayNow('Wave'),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'Orange Money',
                Icons.phone_android,
                Colors.orange,
                'Paiement mobile Orange',
                () => onPayNow('Orange Money'),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'CORIS Money',
                Icons.account_balance_wallet,
                Color(0xFF1E3A8A),
                'Paiement par CORIS Money',
                () => onPayNow('CORIS Money'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300]))
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPayLater,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF002B6B), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF002B6B), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payer plus tard',
                        style: TextStyle(
                          color: Color(0xFF002B6B),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002B6B),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Helper pour construire les données de paiement à envoyer au serveur
class PaymentDataBuilder {
  static Map<String, dynamic>? build(
    String modePaiement,
    PaymentMethodControllers controllers,
  ) {
    if (modePaiement == 'Virement') {
      return {
        'banque': controllers.banque.text.trim(),
        ...?_parseRibUnified(controllers.ribUnified.text.trim()),
      };
    } else if (modePaiement == 'Wave' || modePaiement == 'Orange Money') {
      return {
        'numero_telephone': controllers.numeroMobileMoney.text.trim(),
      };
    } else if (modePaiement == 'Prélèvement à la source') {
      return {
        'nom_structure': controllers.nomStructure.text.trim(),
        'numero_matricule': controllers.numeroMatricule.text.trim(),
      };
    } else if (modePaiement == 'CORIS Money') {
      return {
        'numero_telephone': controllers.corisMoneyPhone.text.trim(),
      };
    }
    return null;
  }

  static Map<String, String>? _parseRibUnified(String rib) {
    if (rib.isEmpty) return null;
    final cleaned = rib.replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if (cleaned.length >= 23) {
      return {
        'code_guichet': cleaned.substring(4, 9),
        'numero_compte': cleaned.substring(9, 20),
        'cle_rib': cleaned.substring(20, 22),
      };
    }
    return null;
  }
}
