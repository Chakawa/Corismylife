/* lib/features/souscription/presentation/widgets/success_dialog.dart
class SuccessDialog extends StatelessWidget {
  final bool isPaid;
  final String pdfUrl;

  const SuccessDialog({required this.isPaid, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(isPaid ? Icons.check_circle : Icons.description, 
              color: isPaid ? Colors.green : Colors.blue),
          SizedBox(width: 10),
          Text(isPaid ? 'Paiement réussi!' : 'Proposition sauvegardée!'),
        ],
      ),
      content: Text(isPaid
          ? 'Votre contrat a été généré avec succès.'
          : 'Vous pouvez effectuer le paiement plus tard depuis votre espace client.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer'),
        ),
        TextButton(
          onPressed: () {
            // Télécharger le PDF
            Navigator.pop(context);
          },
          child: Text('Télécharger'),
        ),
      ],
    );
  }
}*/