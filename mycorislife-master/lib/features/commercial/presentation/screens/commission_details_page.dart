import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';

class CommissionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> commission;

  const CommissionDetailsPage({
    super.key,
    required this.commission,
  });

  @override
  Widget build(BuildContext context) {
    final montantCommission = commission['montant_commission'] ?? 0;
    final montantEncaisse = commission['montant_encaisse_reference'] ?? 0;
    final numeroPolice = commission['numero_police'] ?? 'N/A';
    final dateCalcul = commission['date_calcul'] ?? '';
    final dateReception = commission['date_reception'];
    final statut = commission['statut_reception'] ?? 'En attente';
    final notes = commission['notes'];
    final codeApporteur = commission['code_apporteur'] ?? 'N/A';

    final Color bleuCoris = const Color(0xFF002B6B);
    final Color vertSucces = const Color(0xFF10B981);
    final Color orangeCoris = const Color(0xFFFF9500);
    final Color rougeErreur = const Color(0xFFEF4444);

    final statutColor = statut == 'Reçue' 
        ? vertSucces 
        : statut == 'Rejetée' 
        ? rougeErreur 
        : orangeCoris;

    // Calculer le pourcentage de commission
    final tauxCommission = montantEncaisse > 0 
        ? ((montantCommission / montantEncaisse) * 100).toStringAsFixed(2)
        : '0.00';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Détails de la commission'),
        backgroundColor: bleuCoris,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            // Header avec gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bleuCoris, bleuCoris.withOpacity(0.8)],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.2),
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statut,
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: context.r(16)),
                  Text(
                    'Montant de la Commission',
                    style: TextStyle(
                      fontSize: context.sp(14),
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: context.r(8)),
                  Text(
                    '$montantCommission FCFA',
                    style: TextStyle(
                      fontSize: context.sp(36),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: context.r(4)),
                  Text(
                    'Soit $tauxCommission% du montant encaissé',
                    style: TextStyle(
                      fontSize: context.sp(13),
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Détails
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCard(
                    context: context,
                    title: 'Informations du contrat',
                    icon: Icons.description_outlined,
                    color: bleuCoris,
                    children: [
                      _buildInfoRow(context, 'Numéro de police', numeroPolice),
                      _buildInfoRow(context, 'Code apporteur', codeApporteur),
                      _buildInfoRow(context, 'Montant encaissé', '$montantEncaisse FCFA'),
                      _buildInfoRow(context, 'Taux de Commission', '$tauxCommission%'),
                    ],
                  ),
                  SizedBox(height: context.r(16)),
                  _buildCard(
                    context: context,
                    title: 'Dates importantes',
                    icon: Icons.calendar_today_outlined,
                    color: bleuCoris,
                    children: [
                      _buildInfoRow(context, 'Date de Calcul', _formatDate(dateCalcul)),
                      if (dateReception != null)
                        _buildInfoRow(context, 'Date de réception', _formatDate(dateReception)),
                    ],
                  ),
                  SizedBox(height: context.r(16)),
                  _buildCard(
                    context: context,
                    title: 'Statut de réception',
                    icon: Icons.info_outline,
                    color: statutColor,
                    children: [
                      _buildInfoRow(context, 'Statut Actuel', statut, valueColor: statutColor),
                      if (notes != null && notes.isNotEmpty)
                        _buildInfoRow(context, 'Notes', notes, maxLines: 3),
                    ],
                  ),
                  SizedBox(height: context.r(16)),
                  _buildCard(
                    context: context,
                    title: 'Calcul de la Commission',
                    icon: Icons.calculate_outlined,
                    color: vertSucces,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: vertSucces.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: vertSucces.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalculRow('Montant encaissé', '$montantEncaisse FCFA'),
                            SizedBox(height: context.r(8)),
                            _buildCalculRow('Taux de Commission', '5%'),
                            const Divider(height: 24),
                            _buildCalculRow(
                              'Commission = $montantEncaisse é— 5%',
                              '$montantCommission FCFA',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.r(100)),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: context.r(12)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.sp(16),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.r(16)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: context.sp(14),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: context.sp(14),
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF002B6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF002B6B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

