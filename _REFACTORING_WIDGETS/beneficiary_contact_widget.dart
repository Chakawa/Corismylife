import 'package:flutter/material.dart';
import 'package:mycorislife/config/theme.dart';

/// Classe pour gérer les contrôleurs de bénéficiaires et contacts d'urgence
class BeneficiaryContactControllers {
  // Bénéficiaire
  final TextEditingController beneficiaireNom = TextEditingController();
  final TextEditingController beneficiaireContact = TextEditingController();
  String? selectedBeneficiaireIndicatif = '+225';
  String? selectedLienParente;

  // Contact d'urgence
  final TextEditingController personneContactNom = TextEditingController();
  final TextEditingController personneContactTel = TextEditingController();
  String? selectedContactIndicatif = '+225';
  String? selectedLienParenteUrgence;

  // Liste des liens de parenté disponibles
  static const List<String> liensParente = [
    'Conjoint(e)',
    'Enfant',
    'Parent',
    'Frère/Sœur',
    'Oncle/Tante',
    'Cousin(e)',
    'Ami(e)',
    'Autre',
  ];

  // Liste des indicatifs téléphoniques
  static const List<String> indicatifs = [
    '+225', // Côte d'Ivoire
    '+33',  // France
    '+1',   // USA/Canada
    '+44',  // UK
    '+221', // Sénégal
    '+226', // Burkina Faso
    '+223', // Mali
    '+229', // Bénin
    '+228', // Togo
    '+234', // Nigeria
  ];

  void dispose() {
    beneficiaireNom.dispose();
    beneficiaireContact.dispose();
    personneContactNom.dispose();
    personneContactTel.dispose();
  }

  void clearAll() {
    beneficiaireNom.clear();
    beneficiaireContact.clear();
    personneContactNom.clear();
    personneContactTel.clear();
    selectedBeneficiaireIndicatif = '+225';
    selectedLienParente = null;
    selectedContactIndicatif = '+225';
    selectedLienParenteUrgence = null;
  }

  /// Charge les données existantes
  void loadFromData(Map<String, dynamic> data) {
    // Charger bénéficiaire
    if (data['beneficiaire'] != null) {
      final benef = data['beneficiaire'];
      beneficiaireNom.text = benef['nom']?.toString() ?? '';
      
      // Parser le contact pour extraire indicatif et numéro
      final contact = benef['contact']?.toString() ?? '';
      if (contact.isNotEmpty) {
        final parts = contact.split(' ');
        if (parts.length >= 2) {
          selectedBeneficiaireIndicatif = parts[0];
          beneficiaireContact.text = parts.sublist(1).join(' ');
        } else {
          beneficiaireContact.text = contact;
        }
      }
      
      selectedLienParente = benef['lien_parente']?.toString();
    }

    // Charger contact d'urgence
    if (data['contact_urgence'] != null) {
      final contact = data['contact_urgence'];
      personneContactNom.text = contact['nom']?.toString() ?? '';
      
      // Parser le contact pour extraire indicatif et numéro
      final tel = contact['contact']?.toString() ?? '';
      if (tel.isNotEmpty) {
        final parts = tel.split(' ');
        if (parts.length >= 2) {
          selectedContactIndicatif = parts[0];
          personneContactTel.text = parts.sublist(1).join(' ');
        } else {
          personneContactTel.text = tel;
        }
      }
      
      selectedLienParenteUrgence = contact['lien_parente']?.toString();
    }
  }
}

/// Validation des bénéficiaires et contacts
class BeneficiaryContactValidator {
  /// Valide les champs du bénéficiaire et du contact d'urgence
  static String? validate(BeneficiaryContactControllers controllers) {
    // Validation bénéficiaire
    if (controllers.beneficiaireNom.text.trim().isEmpty) {
      return 'Veuillez saisir le nom du bénéficiaire';
    }
    if (controllers.beneficiaireNom.text.trim().length < 3) {
      return 'Le nom du bénéficiaire doit contenir au moins 3 caractères';
    }
    if (controllers.beneficiaireContact.text.trim().isEmpty) {
      return 'Veuillez saisir le contact du bénéficiaire';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(controllers.beneficiaireContact.text.trim())) {
      return 'Le contact du bénéficiaire doit contenir uniquement des chiffres';
    }
    if (controllers.beneficiaireContact.text.trim().length < 8) {
      return 'Le contact du bénéficiaire doit contenir au moins 8 chiffres';
    }
    if (controllers.selectedLienParente == null) {
      return 'Veuillez sélectionner le lien de parenté avec le bénéficiaire';
    }

    // Validation contact d'urgence
    if (controllers.personneContactNom.text.trim().isEmpty) {
      return 'Veuillez saisir le nom de la personne à contacter';
    }
    if (controllers.personneContactNom.text.trim().length < 3) {
      return 'Le nom de la personne à contacter doit contenir au moins 3 caractères';
    }
    if (controllers.personneContactTel.text.trim().isEmpty) {
      return 'Veuillez saisir le numéro de la personne à contacter';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(controllers.personneContactTel.text.trim())) {
      return 'Le contact d\'urgence doit contenir uniquement des chiffres';
    }
    if (controllers.personneContactTel.text.trim().length < 8) {
      return 'Le contact d\'urgence doit contenir au moins 8 chiffres';
    }
    if (controllers.selectedLienParenteUrgence == null) {
      return 'Veuillez sélectionner le lien de parenté avec la personne à contacter';
    }

    return null;
  }
}

/// Widget pour le formulaire du bénéficiaire
class BeneficiaryFormFields extends StatefulWidget {
  final BeneficiaryContactControllers controllers;
  final void Function(void Function()) onUpdate;

  const BeneficiaryFormFields({
    super.key,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  State<BeneficiaryFormFields> createState() => _BeneficiaryFormFieldsState();
}

class _BeneficiaryFormFieldsState extends State<BeneficiaryFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BÉNÉFICIAIRE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        
        // Nom complet
        const Text(
          'Nom complet',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controllers.beneficiaireNom,
          decoration: InputDecoration(
            hintText: 'Nom et prénom(s) du bénéficiaire',
            prefixIcon: Icon(Icons.person, color: bleuCoris),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),

        // Contact
        const Text(
          'Contact',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Indicatif
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: blanc,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: grisLeger),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.controllers.selectedBeneficiaireIndicatif,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: BeneficiaryContactControllers.indicatifs.map((String ind) {
                    return DropdownMenuItem<String>(
                      value: ind,
                      child: Text(ind, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    widget.onUpdate(() {
                      widget.controllers.selectedBeneficiaireIndicatif = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Numéro
            Expanded(
              child: TextField(
                controller: widget.controllers.beneficiaireContact,
                decoration: InputDecoration(
                  hintText: 'XX XX XX XX XX',
                  prefixIcon: Icon(Icons.phone, color: bleuCoris),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: blanc,
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lien de parenté
        const Text(
          'Lien de parenté',
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
              value: widget.controllers.selectedLienParente,
              hint: Row(
                children: [
                  Icon(Icons.people, size: 20, color: grisTexte),
                  const SizedBox(width: 12),
                  Text(
                    'Sélectionnez le lien de parenté',
                    style: TextStyle(color: grisTexte, fontSize: 14),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: bleuCoris),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              items: BeneficiaryContactControllers.liensParente.map((String lien) {
                return DropdownMenuItem<String>(
                  value: lien,
                  child: Text(lien, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                widget.onUpdate(() {
                  widget.controllers.selectedLienParente = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour le formulaire du contact d'urgence
class EmergencyContactFormFields extends StatefulWidget {
  final BeneficiaryContactControllers controllers;
  final void Function(void Function()) onUpdate;

  const EmergencyContactFormFields({
    super.key,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  State<EmergencyContactFormFields> createState() => _EmergencyContactFormFieldsState();
}

class _EmergencyContactFormFieldsState extends State<EmergencyContactFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONNE À CONTACTER EN CAS D\'URGENCE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: bleuCoris,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        
        // Nom complet
        const Text(
          'Nom complet',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controllers.personneContactNom,
          decoration: InputDecoration(
            hintText: 'Nom et prénom(s) de la personne',
            prefixIcon: Icon(Icons.person_outline, color: bleuCoris),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: blanc,
          ),
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 16),

        // Contact
        const Text(
          'Contact',
          style: TextStyle(fontWeight: FontWeight.w600, color: bleuCoris),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Indicatif
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: blanc,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: grisLeger),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.controllers.selectedContactIndicatif,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: BeneficiaryContactControllers.indicatifs.map((String ind) {
                    return DropdownMenuItem<String>(
                      value: ind,
                      child: Text(ind, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    widget.onUpdate(() {
                      widget.controllers.selectedContactIndicatif = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Numéro
            Expanded(
              child: TextField(
                controller: widget.controllers.personneContactTel,
                decoration: InputDecoration(
                  hintText: 'XX XX XX XX XX',
                  prefixIcon: Icon(Icons.phone, color: bleuCoris),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: blanc,
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lien de parenté
        const Text(
          'Lien de parenté',
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
              value: widget.controllers.selectedLienParenteUrgence,
              hint: Row(
                children: [
                  Icon(Icons.people, size: 20, color: grisTexte),
                  const SizedBox(width: 12),
                  Text(
                    'Sélectionnez le lien de parenté',
                    style: TextStyle(color: grisTexte, fontSize: 14),
                  ),
                ],
              ),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: bleuCoris),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              items: BeneficiaryContactControllers.liensParente.map((String lien) {
                return DropdownMenuItem<String>(
                  value: lien,
                  child: Text(lien, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                widget.onUpdate(() {
                  widget.controllers.selectedLienParenteUrgence = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper pour construire les données de bénéficiaire et contact à envoyer au serveur
class BeneficiaryContactDataBuilder {
  /// Construit les données du bénéficiaire
  static Map<String, dynamic> buildBeneficiaryData(BeneficiaryContactControllers controllers) {
    return {
      'nom': controllers.beneficiaireNom.text.trim(),
      'contact': '${controllers.selectedBeneficiaireIndicatif} ${controllers.beneficiaireContact.text.trim()}',
      'lien_parente': controllers.selectedLienParente,
    };
  }

  /// Construit les données du contact d'urgence
  static Map<String, dynamic> buildEmergencyContactData(BeneficiaryContactControllers controllers) {
    return {
      'nom': controllers.personneContactNom.text.trim(),
      'contact': '${controllers.selectedContactIndicatif} ${controllers.personneContactTel.text.trim()}',
      'lien_parente': controllers.selectedLienParenteUrgence,
    };
  }
}
