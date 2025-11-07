import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mycorislife/config/app_config.dart';

/// Page d'aide et support
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aide et Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF002B6B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadSupportInfo(),
        builder: (context, snapshot) {
          final phone = snapshot.data?['phone'] ?? '+2250700000000';
          final email = snapshot.data?['email'] ?? 'support@coris.ci';
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                'Contactez-nous',
                [
                  _buildContactTile(Icons.phone, 'Téléphone', phone, () => launchUrl(Uri.parse('tel:$phone'))),
                  _buildContactTile(Icons.email, 'Email', email, () => launchUrl(Uri.parse('mailto:$email'))),
                ],
              ),
              _buildSection(
                'FAQ',
                [
                  _buildFAQItem('Comment créer une souscription ?', 'Allez dans la section Souscription et choisissez votre produit.'),
                  _buildFAQItem('Comment modifier ma proposition ?', 'Allez dans Mes Propositions et cliquez sur Modifier.'),
                  _buildFAQItem('Comment payer ma proposition ?', 'Dans Mes Propositions, cliquez sur Payer maintenant.'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadSupportInfo() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl.replaceAll('/api', '')}/config/support'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      }
    } catch (_) {}
    return {};
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF002B6B))),
        ),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF002B6B)),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [Padding(padding: const EdgeInsets.all(16), child: Text(answer))],
      ),
    );
  }
}


