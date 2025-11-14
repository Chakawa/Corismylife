import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycorislife/core/widgets/country_selector.dart';

/// ============================================
/// CHAMP DE SAISIE TÉLÉPHONE AVEC SÉLECTEUR DE PAYS
/// ============================================
/// Widget personnalisé qui combine un sélecteur de pays et un champ de saisie
/// pour les numéros de téléphone

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final Country selectedCountry;
  final Function(Country) onCountryChanged;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.validator,
    this.labelText = 'Numéro de téléphone',
    this.hintText = '01 02 03 04 05',
    this.enabled = true,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              widget.labelText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Row(
            children: [
              // Sélecteur de pays
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 12),
                child: CountrySelector(
                  selectedCountry: widget.selectedCountry,
                  onCountryChanged: widget.onCountryChanged,
                  backgroundColor: Colors.transparent,
                ),
              ),
              // Séparateur vertical
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                color: Colors.grey.shade300,
              ),
              // Champ de saisie du numéro
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                    _PhoneNumberFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(
                      right: 16,
                      bottom: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF002B6B),
                  ),
                  validator: widget.validator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formateur pour ajouter automatiquement des espaces dans le numéro
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Retirer tous les espaces
    final digitsOnly = text.replaceAll(' ', '');

    // Ajouter des espaces tous les 2 chiffres
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Helper pour obtenir le numéro complet avec indicatif
String getFullPhoneNumber(Country country, String phoneNumber) {
  final digitsOnly = phoneNumber.replaceAll(' ', '');
  return '${country.dialCode}$digitsOnly';
}
















