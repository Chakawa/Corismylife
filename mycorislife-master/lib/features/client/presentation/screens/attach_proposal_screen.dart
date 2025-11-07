import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycorislife/services/subscription_service_attach.dart';

/// Écran pour rattacher une proposition à l'utilisateur connecté
class AttachProposalScreen extends StatefulWidget {
  const AttachProposalScreen({super.key});

  @override
  State<AttachProposalScreen> createState() => _AttachProposalScreenState();
}

class _AttachProposalScreenState extends State<AttachProposalScreen> {
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color vertSucces = Color(0xFF10B981);
  final TextEditingController _numeroPoliceController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;

  Future<void> _attach() async {
    final numero = _numeroPoliceController.text.trim();
    final idStr = _idController.text.trim();

    if (numero.isEmpty && idStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un numéro de police ou un ID'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SubscriptionAttachService.attachProposal(
        numeroPolice: numero.isNotEmpty ? numero : null,
        id: idStr.isNotEmpty ? (int.tryParse(idStr) ?? null) : null,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposition rattachée avec succès'), backgroundColor: vertSucces),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rattacher une proposition',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bleuCoris,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Saisissez le numéro de police ou l\'ID de la proposition', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            TextField(
              controller: _numeroPoliceController,
              decoration: const InputDecoration(
                labelText: 'Numéro de police',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            const Text('OU', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID de la proposition',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _attach,
              style: ElevatedButton.styleFrom(
                backgroundColor: bleuCoris,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Rattacher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numeroPoliceController.dispose();
    _idController.dispose();
    super.dispose();
  }
}


