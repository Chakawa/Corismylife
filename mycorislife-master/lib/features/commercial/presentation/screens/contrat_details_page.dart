import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:mycorislife/services/contrat_pdf_service.dart';
import 'package:mycorislife/features/commercial/presentation/screens/contrat_pdf_viewer_page.dart';

class ContratDetailsPage extends StatefulWidget {
  final Map<String, dynamic> contrat;

  const ContratDetailsPage({Key? key, required this.contrat}) : super(key: key);

  @override
  State<ContratDetailsPage> createState() => _ContratDetailsPageState();
}

class _ContratDetailsPageState extends State<ContratDetailsPage> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? contratDetails;
  bool isLoading = true;
  bool showProfessionalView = false;

  // Mapping des codes produits vers les noms de produits
  final Map<String, String> productNames = {
    '225': 'SOLIDARITÉ',
    '205': 'FLEX',
    '242': 'ÉPARGNE',
    '240': 'RETRAITE',
    '202': 'SÉRÉNITÉ',
    '246': 'ÉTUDE',
    '200': 'FAMILIS',
  };

  @override
  void initState() {
    super.initState();
    _loadContratDetails();
  }

  List<Map<String, dynamic>> beneficiaires = [];

  Future<void> _loadContratDetails() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('Token non trouvé');

      final numepoli = widget.contrat['numepoli'];
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/commercial/contrat_details/$numepoli'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          contratDetails = data['contrat'];
          beneficiaires =
              List<Map<String, dynamic>>.from(data['beneficiaires'] ?? []);
          isLoading = false;
        });
      } else {
        throw Exception('Erreur lors du chargement des détails');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _getProductName(String? codeProd) {
    if (codeProd == null) return 'Produit inconnu';
    return productNames[codeProd] ?? 'Produit $codeProd';
  }

  String _formatClientName() {
    if (contratDetails == null) return 'N/A';

    // Essayer avec prénom et nom séparés
    if (contratDetails!['prenom'] != null && contratDetails!['nom'] != null) {
      final prenom = contratDetails!['prenom'].toString().trim();
      final nom = contratDetails!['nom'].toString().trim();
      if (prenom.isNotEmpty && nom.isNotEmpty) {
        return '$prenom $nom';
      }
    }

    // Sinon utiliser nom_prenom
    if (contratDetails!['nom_prenom'] != null) {
      return contratDetails!['nom_prenom'].toString().trim();
    }

    return 'N/A';
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date;
    }
  }

  String _getBeneficiaireType(String? type) {
    if (type == null) return 'N/A';
    switch (type.toUpperCase()) {
      case 'D':
        return 'Décès';
      case 'V':
        return 'Vie';
      default:
        return type;
    }
  }

  /// Ouvre la visionneuse PDF du contrat
  Future<void> _viewPDF() async {
    if (contratDetails == null) return;

    final numepoli = contratDetails!['numepoli'];
    if (numepoli == null) {
      _showMessage('Numéro de police non disponible', isError: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContratPdfViewerPage(
          numepoli: numepoli,
          clientName: _formatClientName(),
        ),
      ),
    );
  }

  /// Partage le PDF du contrat
  Future<void> _generateAndSharePDF() async {
    if (contratDetails == null) return;

    final numepoli = contratDetails!['numepoli'];
    if (numepoli == null) {
      _showMessage('Numéro de police non disponible', isError: true);
      return;
    }

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF002B6B)),
        ),
      );

      await ContratPdfService.downloadAndSharePdf(numepoli);

      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog
      _showMessage('PDF prêt à partager');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog
      _showMessage('Erreur lors du partage: $e', isError: true);
    }
  }

  /// Télécharge le PDF du contrat
  Future<void> _downloadPDF() async {
    if (contratDetails == null) return;

    final numepoli = contratDetails!['numepoli'];
    if (numepoli == null) {
      _showMessage('Numéro de police non disponible', isError: true);
      return;
    }

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF002B6B)),
        ),
      );

      final path = await ContratPdfService.downloadContratPdf(numepoli);

      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog
      _showMessage('PDF téléchargé avec succès!\n$path');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog
      _showMessage('Erreur lors du téléchargement: $e', isError: true);
    }
  }

  /// Affiche un message à l'utilisateur
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
        duration: Duration(seconds: isError ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Contrat'),
        backgroundColor: const Color(0xFF002B6B),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Voir PDF',
            onPressed: contratDetails != null ? _viewPDF : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: contratDetails != null ? _generateAndSharePDF : null,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Télécharger PDF',
            onPressed: contratDetails != null ? _downloadPDF : null,
          ),
          IconButton(
            icon: Icon(
                showProfessionalView ? Icons.visibility_off : Icons.visibility),
            tooltip:
                showProfessionalView ? 'Vue Client' : 'Vue Professionnelle',
            onPressed: () {
              setState(() {
                showProfessionalView = !showProfessionalView;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF002B6B)))
          : contratDetails == null
              ? const Center(
                  child: Text(
                    'Aucune information disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadContratDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête du contrat
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: const Color(0xFF002B6B).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          color: const Color(0xFF002B6B).withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.description,
                                        size: 32, color: Color(0xFF002B6B)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'N° de Police',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                          // Row(
                                          //   children: [
                                          //     Expanded(
                                          //       child: Text(
                                          //         contratDetails?['numepoli'] ??
                                          //             'N/A',
                                          //         style: const TextStyle(
                                          //           fontSize: 20,
                                          //           fontWeight: FontWeight.bold,
                                          //         ),
                                          //       ),
                                          //     ),
                                          //     IconButton(
                                          //       icon: const Icon(Icons.copy,
                                          //           size: 20),
                                          //       onPressed: () =>
                                          //           _copyToClipboard(
                                          //               contratDetails?[
                                          //                       'numepoli'] ??
                                          //                   ''),
                                          //     ),
                                          //   ],
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                _buildInfoChip(
                                  'Statut',
                                  contratDetails?['statut'] ?? 'N/A',
                                  (contratDetails?['statut']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'actif')
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Informations du contrat
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
                                const Text(
                                  'Informations du contrat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  'Produit',
                                  _getProductName(contratDetails?['codeprod']),
                                  Icons.inventory_2,
                                ),
                                _buildDetailRow(
                                  'Client',
                                  _formatClientName(),
                                  Icons.person,
                                ),
                                _buildDetailRow(
                                  'Date de souscription',
                                  _formatDate(contratDetails?['datesous']),
                                  Icons.calendar_today,
                                ),
                                if (contratDetails?['datenaissance'] != null)
                                  _buildDetailRow(
                                    'Date de naissance',
                                    _formatDate(
                                        contratDetails?['datenaissance']),
                                    Icons.cake,
                                  ),
                                if (contratDetails?['dateeffet'] != null)
                                  _buildDetailRow(
                                    'Date d\'effet',
                                    _formatDate(contratDetails?['dateeffet']),
                                    Icons.event_available,
                                  ),
                                if (contratDetails?['dateecheance'] != null)
                                  _buildDetailRow(
                                    'Date d\'échéance',
                                    _formatDate(
                                        contratDetails?['dateecheance']),
                                    Icons.event_busy,
                                  ),
                                if (contratDetails?['telephone1'] != null)
                                  _buildDetailRow(
                                    'Téléphone 1',
                                    contratDetails?['telephone1'] ?? 'N/A',
                                    Icons.phone,
                                    canCopy: true,
                                  ),
                                if (contratDetails?['telephone2'] != null)
                                  _buildDetailRow(
                                    'Téléphone 2',
                                    contratDetails?['telephone2'] ?? 'N/A',
                                    Icons.phone_android,
                                    canCopy: true,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Informations financières
                        if (contratDetails?['capital'] != null ||
                            contratDetails?['prime'] != null ||
                            contratDetails?['rente'] != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations financières',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(),
                                  if (contratDetails?['capital'] != null)
                                    _buildDetailRow(
                                      'Capital',
                                      '${contratDetails?['capital']} FCFA',
                                      Icons.account_balance_wallet,
                                    ),
                                  if (contratDetails?['prime'] != null)
                                    _buildDetailRow(
                                      'Prime',
                                      '${contratDetails?['prime']} FCFA',
                                      Icons.payments,
                                    ),
                                  if (contratDetails?['rente'] != null)
                                    _buildDetailRow(
                                      'Rente',
                                      '${contratDetails?['rente']} FCFA',
                                      Icons.trending_up,
                                    ),
                                  if (contratDetails?['montant_encaisse'] !=
                                      null)
                                    _buildDetailRow(
                                      'Montant encaissé',
                                      '${contratDetails?['montant_encaisse']} FCFA',
                                      Icons.receipt_long,
                                    ),
                                  if (contratDetails?['duree'] != null)
                                    _buildDetailRow(
                                      'Durée',
                                      '${contratDetails?['duree']} ans',
                                      Icons.schedule,
                                    ),
                                  if (contratDetails?['periodicite'] != null)
                                    _buildDetailRow(
                                      'Périodicité',
                                      contratDetails?['periodicite'] ?? 'N/A',
                                      Icons.repeat,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Bénéficiaires
                        if (beneficiaires.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bénéficiaires',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(),
                                  ...beneficiaires.map((benef) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    const Color(0xFF002B6B),
                                                child: Text(
                                                  benef['nom_benef']
                                                          ?.toString()
                                                          .substring(0, 1)
                                                          .toUpperCase() ??
                                                      'B',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      benef['nom_benef'] ??
                                                          'N/A',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      _getBeneficiaireType(benef[
                                                          'type_beneficiaires']),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Vue professionnelle (visible uniquement si activée)
                        if (showProfessionalView) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.amber.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.admin_panel_settings,
                                          color: Colors.orange),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Informations Professionnelles',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildDetailRow(
                                    'Code produit',
                                    contratDetails?['codeprod'] ?? 'N/A',
                                    Icons.qr_code,
                                    canCopy: true,
                                  ),
                                  _buildDetailRow(
                                    'Code intermédiaire',
                                    contratDetails?['codeinte'] ?? 'N/A',
                                    Icons.business,
                                    canCopy: true,
                                  ),
                                  _buildDetailRow(
                                    'Code apporteur',
                                    contratDetails?['code_apporteur']
                                            ?.toString() ??
                                        'N/A',
                                    Icons.badge,
                                    canCopy: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: const Icon(Icons.circle, color: Colors.white, size: 12),
      ),
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF002B6B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (canCopy)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyToClipboard(value),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
