import 'package:flutter/material.dart';

/// ===============================================
/// PAGE DE DÉTAILS D'UN BORDEREAU DE COMMISSION
/// ===============================================
///
/// Affiche les détails complets d'un bordereau de commission
/// avec toutes les informations pertinentes.
///
/// INFORMATIONS AFFICHÉES :
/// - Numéro du bordereau et exercice
/// - Référence (nom du commercial)
/// - Période (date début et date fin)
/// - État du bordereau
/// - Montant de la commission
/// - Type d'apporteur (A = Commercial/Apporteur, B = Intermédiaire)
/// - Code apporteur
class CommissionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bordereau;

  const CommissionDetailScreen({
    super.key,
    required this.bordereau,
  });

  // ============================================
  // CHARTE GRAPHIQUE CORIS
  // ============================================
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color orangeWarning = Color(0xFFF59E0B);
  static const Color blanc = Colors.white;
  static const Color fondCarte = Color(0xFFF8FAFC);
  static const Color grisTexte = Color(0xFF64748B);
  static const Color grisLeger = Color(0xFFF1F5F9);

  /// Formate une date au format DD/MM/YYYY
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Non renseigné';
    
    // Si la date contient déjà le bon format DD/MM/YYYY, la retourner telle quelle
    if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(date)) {
      return date;
    }
    
    // Sinon, parser et formater proprement (enlever les timestamps)
    try {
      // Supprimer les timestamps et heures si présents
      String cleanDate = date.split('T')[0].split(' ')[0];
      
      // Parser la date
      DateTime parsedDate;
      if (cleanDate.contains('-')) {
        // Format ISO 8601 : YYYY-MM-DD
        parsedDate = DateTime.parse(cleanDate);
      } else if (cleanDate.contains('/')) {
        // Format déjà DD/MM/YYYY ou MM/DD/YYYY
        final parts = cleanDate.split('/');
        if (parts.length == 3) {
          // Assumer DD/MM/YYYY si le premier nombre est <= 31
          if (int.parse(parts[0]) <= 31) {
            parsedDate = DateTime(
              int.parse(parts[2]), // année
              int.parse(parts[1]), // mois
              int.parse(parts[0]), // jour
            );
          } else {
            // MM/DD/YYYY
            parsedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        } else {
          return date;
        }
      } else {
        return date;
      }
      
      // Formater au format DD/MM/YYYY
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      // En cas d'erreur, retourner la date telle quelle
      return date;
    }
  }

  /// Formate un montant en FCFA
  String _formatMoney(dynamic value) {
    if (value == null) return '0 FCFA';
    final numValue =
        value is num ? value : double.tryParse(value.toString()) ?? 0;
    return '${numValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  /// Obtient la couleur selon l'état du bordereau
  Color _getEtatColor(String? etat) {
    if (etat == null) return grisTexte;
    final etatLower = etat.toLowerCase();
    if (etatLower.contains('payé') || etatLower.contains('payee')) {
      return vertSucces;
    } else if (etatLower.contains('en attente') ||
        etatLower.contains('attente')) {
      return orangeWarning;
    } else {
      return grisTexte;
    }
  }

  /// Obtient l'icône selon l'état du bordereau
  IconData _getEtatIcon(String? etat) {
    if (etat == null) return Icons.help_outline;
    final etatLower = etat.toLowerCase();
    if (etatLower.contains('payé') || etatLower.contains('payee')) {
      return Icons.check_circle;
    } else if (etatLower.contains('en attente') ||
        etatLower.contains('attente')) {
      return Icons.pending;
    } else {
      return Icons.info_outline;
    }
  }

  /// Obtient la couleur selon le type d'apporteur
  Color _getTypeApporteurColor(String? type) {
    if (type == null) return grisTexte;
    if (type == 'A') {
      return bleuCoris; // Commercial/Apporteur
    } else if (type == 'B') {
      return orangeWarning; // Intermédiaire
    } else {
      return grisTexte;
    }
  }

  /// Obtient l'icône selon le type d'apporteur
  IconData _getTypeApporteurIcon(String? type) {
    if (type == null) return Icons.person_outline;
    if (type == 'A') {
      return Icons.person; // Commercial/Apporteur
    } else if (type == 'B') {
      return Icons.business; // Intermédiaire
    } else {
      return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = bordereau['etat'] ?? '';
    final typeApporteur = bordereau['typeApporteur'] ?? 'A';
    final typeApporteurLabel = bordereau['typeApporteurLabel'] ?? 'Non défini';

    return Scaffold(
      backgroundColor: grisLeger,
      appBar: AppBar(
        backgroundColor: bleuCoris,
        elevation: 0,
        title: const Text(
          'Détails du Bordereau',
          style: TextStyle(
            color: blanc,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: blanc),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte principale avec numéro et exercice
              _buildMainCard(),
              const SizedBox(height: 16),
              // Informations générales
              _buildInfoSection(
                'Informations Générales',
                Icons.info_outline,
                [
                  _buildInfoRow(
                    'Référence',
                    bordereau['reference'] ?? 'Non renseigné',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Code Apporteur',
                    bordereau['codeApporteur'] ?? 'Non renseigné',
                    Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Type d\'Apporteur',
                    typeApporteurLabel,
                    _getTypeApporteurIcon(typeApporteur),
                    color: _getTypeApporteurColor(typeApporteur),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Période
              _buildInfoSection(
                'Période',
                Icons.date_range,
                [
                  _buildInfoRow(
                    'Date de début',
                    _formatDate(bordereau['dateDebut']),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Date de fin',
                    _formatDate(bordereau['dateFin']),
                    Icons.event,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Montant et état
              _buildInfoSection(
                'Montant et État',
                Icons.monetization_on,
                [
                  _buildInfoRow(
                    'Montant',
                    bordereau['montantFormate'] ??
                        _formatMoney(bordereau['montant']),
                    Icons.account_balance_wallet,
                    color: vertSucces,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'État',
                    etat,
                    _getEtatIcon(etat),
                    color: _getEtatColor(etat),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit la carte principale avec le numéro et l'exercice
  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bleuCoris, bleuCoris.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bleuCoris.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: blanc.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: blanc,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bordereau N° ${bordereau['numeroBordereau'] ?? 'N/A'}/${bordereau['exercice'] ?? 'N/A'}',
            style: const TextStyle(
              color: blanc,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit une section d'informations
  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bleuCoris.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: bleuCoris,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bleuCoris,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Construit une ligne d'information
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool isBold = false,
  }) {
    final displayColor = color ?? grisTexte;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: displayColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: grisTexte,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: displayColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
