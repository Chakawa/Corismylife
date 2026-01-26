import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// ===============================================
/// DIALOGUE DE SIGNATURE MANUSCRITE
/// ===============================================
///
/// Permet au client de signer électroniquement
/// lors de la finalisation de sa souscription.
///
/// FONCTIONNALITÉS:
/// - Canvas de signature tactile
/// - Bouton effacer pour recommencer
/// - Validation de signature non vide
/// - Export en image (Uint8List)
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  // Couleurs CORIS
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color blanc = Colors.white;
  static const Color grisLeger = Color(0xFFF1F5F9);
  static const Color grisTexte = Color(0xFF64748B);

  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white, // Fond blanc pour l'export
      exportPenColor: Colors.black, // Stylo noir pour l'export
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Efface la signature
  void _clearSignature() {
    _controller.clear();
  }

  /// Valide et retourne la signature
  Future<void> _validateSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez signer avant de valider'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      print('📸 Capture de la signature via controller.toPngBytes()...');
      
      // Utiliser la méthode native du controller pour capturer UNIQUEMENT le canvas de signature
      final Uint8List? signatureBytes = await _controller.toPngBytes();
      
      if (signatureBytes == null) {
        throw Exception('Échec de la capture - toPngBytes() a retourné null');
      }
      
      print('✅ Signature capturée avec succès!');
      print('   - Taille fichier: ${signatureBytes.length} bytes (${(signatureBytes.length / 1024).toStringAsFixed(2)} KB)');
      
      if (mounted) {
        Navigator.of(context).pop(signatureBytes);
      }
    } catch (e, stackTrace) {
      print('❌ Erreur capture signature: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la capture: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: blanc,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bleuCoris.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.draw,
                    color: bleuCoris,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signature du Contrat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: bleuCoris,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Signez dans le cadre ci-dessous',
                        style: TextStyle(
                          fontSize: 12,
                          color: grisTexte,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: grisTexte),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Zone de signature
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: blanc,
                border: Border.all(color: bleuCoris, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: _controller,
                  backgroundColor: blanc,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Instructions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bleuCoris.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bleuCoris.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: bleuCoris, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre signature sera apposée sur le contrat PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: bleuCoris,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                // Bouton Effacer
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearSignature,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Effacer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: grisTexte,
                      side: BorderSide(color: grisTexte.withOpacity(0.5), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton Valider
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _validateSignature,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Valider la Signature'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bleuCoris,
                      foregroundColor: blanc,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
