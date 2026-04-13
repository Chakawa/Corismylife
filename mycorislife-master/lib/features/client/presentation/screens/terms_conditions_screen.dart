import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';

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
            _buildSection(context, '1. Acceptation des conditions', 'En utilisant cette application, vous acceptez les conditions d\'utilisation suivantes.'),
            _buildSection(context, '2. Utilisation de l\'application', 'L\'application est destinée à la gestion de vos contrats d\'assurance Coris.'),
            _buildSection(context, '3. Responsabilités', 'Vous êtes responsable de la confidentialité de vos identifiants de connexion.'),
            _buildSection(context, '4. Propriété intellectuelle', 'Tous les contenus de l\'application sont la propriété de Coris Assurances Vie.'),
            _buildSection(context, '5. Modifications', 'Nous nous réservons le droit de modifier ces conditions à tout moment.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: context.sp(18), fontWeight: FontWeight.w700, color: Color(0xFF002B6B))),
          SizedBox(height: context.r(8)),
          Text(content, style: TextStyle(fontSize: context.sp(14), height: 1.5)),
        ],
      ),
    );
  }
}


