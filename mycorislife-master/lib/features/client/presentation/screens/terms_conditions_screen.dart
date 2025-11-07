import 'package:flutter/material.dart';

/// Page des conditions d'utilisation
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conditions d\'Utilisation',
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
            _buildSection('1. Acceptation des conditions', 'En utilisant cette application, vous acceptez les conditions d\'utilisation suivantes.'),
            _buildSection('2. Utilisation de l\'application', 'L\'application est destinée à la gestion de vos contrats d\'assurance Coris.'),
            _buildSection('3. Responsabilités', 'Vous êtes responsable de la confidentialité de vos identifiants de connexion.'),
            _buildSection('4. Propriété intellectuelle', 'Tous les contenus de l\'application sont la propriété de Coris Assurances Vie.'),
            _buildSection('5. Modifications', 'Nous nous réservons le droit de modifier ces conditions à tout moment.'),
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


