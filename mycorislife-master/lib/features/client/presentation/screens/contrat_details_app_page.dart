import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:mycorislife/features/client/presentation/screens/contrat_detail_page.dart';

class ContratDetailsAppPage extends StatelessWidget {
  final Map<String, dynamic> contrat;

  const ContratDetailsAppPage({super.key, required this.contrat});

  @override
  Widget build(BuildContext context) {
    final subscriptionId = int.tryParse(
      (contrat['subscription_id'] ?? contrat['id'] ?? '').toString(),
    );
    final contractNumber = (contrat['numepoli'] ?? contrat['id'] ?? 'N/A').toString();

    if (subscriptionId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Détails du contrat'),
          backgroundColor: const Color(0xFF002B6B),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: Color(0xFFEF4444)),
                SizedBox(height: context.r(12)),
                Text(
                  'Impossible de charger les détails de ce contrat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: context.sp(16), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ContratDetailPage(
      subscriptionId: subscriptionId,
      contractNumber: contractNumber,
    );
  }
}

