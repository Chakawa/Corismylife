import 'package:flutter/material.dart';

/// Page de politique de confidentialité
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Politique de Confidentialité',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF002B6B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Collecte des informations', 'Nous collectons les informations que vous nous fournissez lors de la création de votre compte et de vos souscriptions.'),
            _buildSection('2. Utilisation des données', 'Vos données sont utilisées pour gérer vos contrats d\'assurance et améliorer nos services.'),
            _buildSection('3. Protection des données', 'Nous mettons en place des mesures de sécurité pour protéger vos informations personnelles.'),
            _buildSection('4. Partage des données', 'Nous ne partageons vos données qu\'avec votre consentement ou lorsque la loi l\'exige.'),
            _buildSection('5. Vos droits', 'Vous avez le droit d\'accéder, de modifier ou de supprimer vos données personnelles à tout moment.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF002B6B))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}


