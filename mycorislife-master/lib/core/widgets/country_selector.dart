import 'package:flutter/material.dart';

/// ============================================
/// SÉLECTEUR DE PAYS
/// ============================================
/// Widget permettant de sélectionner un pays avec son indicatif téléphonique
/// Affiche le drapeau et l'indicatif du pays sélectionné

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class CountrySelector extends StatelessWidget {
  final Country selectedCountry;
  final Function(Country) onCountryChanged;
  final Color? backgroundColor;
  final Color? textColor;

  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.backgroundColor,
    this.textColor,
  });

  // Liste des pays avec leurs indicatifs
  static final List<Country> countries = [
    Country(
      name: 'Côte d\'Ivoire',
      code: 'CI',
      dialCode: '+225',
      flag: '🇨🇮',
    ),
    Country(
      name: 'France',
      code: 'FR',
      dialCode: '+33',
      flag: '🇫🇷',
    ),
    Country(
      name: 'Sénégal',
      code: 'SN',
      dialCode: '+221',
      flag: '🇸🇳',
    ),
    Country(
      name: 'Mali',
      code: 'ML',
      dialCode: '+223',
      flag: '🇲🇱',
    ),
    Country(
      name: 'Burkina Faso',
      code: 'BF',
      dialCode: '+226',
      flag: '🇧🇫',
    ),
    Country(
      name: 'Bénin',
      code: 'BJ',
      dialCode: '+229',
      flag: '🇧🇯',
    ),
    Country(
      name: 'Togo',
      code: 'TG',
      dialCode: '+228',
      flag: '🇹🇬',
    ),
    Country(
      name: 'Niger',
      code: 'NE',
      dialCode: '+227',
      flag: '🇳🇪',
    ),
    Country(
      name: 'Guinée',
      code: 'GN',
      dialCode: '+224',
      flag: '🇬🇳',
    ),
    Country(
      name: 'Cameroun',
      code: 'CM',
      dialCode: '+237',
      flag: '🇨🇲',
    ),
    Country(
      name: 'Ghana',
      code: 'GH',
      dialCode: '+233',
      flag: '🇬🇭',
    ),
    Country(
      name: 'Nigeria',
      code: 'NG',
      dialCode: '+234',
      flag: '🇳🇬',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCountryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              selectedCountry.dialCode,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor ?? const Color(0xFF002B6B),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: textColor ?? const Color(0xFF002B6B),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Sélectionner un pays',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF002B6B),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Liste des pays
            Expanded(
              child: ListView.builder(
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final isSelected = country.code == selectedCountry.code;

                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF002B6B)
                            : Colors.black87,
                      ),
                    ),
                    trailing: Text(
                      country.dialCode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color:
                            isSelected ? const Color(0xFF002B6B) : Colors.grey,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF002B6B).withOpacity(0.1),
                    onTap: () {
                      onCountryChanged(country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}













