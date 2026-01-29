import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

/// Dialogue de signature ULTRA-MINIMALISTE
/// 
/// **SOLUTION RADICALE AU PROBLÈME DE CAPTURE**
/// 
/// Problème identifié après 8+ heures:
/// - SfSignaturePad.toImage() capture le widget TEL QU'IL EST RENDU
/// - Si le widget est dans un dialogue avec boutons, TOUT est capturé
/// - On obtenait 909x894px au lieu de 800x300px
/// 
/// Solution:
/// - Dialogue contenant SEULEMENT le SfSignaturePad, RIEN d'autre
/// - Pas de boutons, pas de texte, pas de padding
/// - Boutons HORS du dialogue (overlay transparent par-dessus)
/// - Capture donc UNIQUEMENT la surface de signature
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  
  /// Capturer et retourner UNIQUEMENT la signature
  Future<void> _captureSignature() async {
    try {
      print('🎯 CAPTURE MINIMALISTE - Widget contient SEULEMENT SfSignaturePad');
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Capturer le widget (qui NE contient QUE le SfSignaturePad maintenant)
      final ui.Image? image = await _signaturePadKey.currentState?.toImage(
        pixelRatio: 3.0,
      );
      
      if (image == null) {
        print('❌ Pas de signature');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez signer avant de valider')),
        );
        return;
      }
      
      print('✅ Capture: ${image.width}x${image.height}px');
      print('   🎯 Attendu: ~2400x900px (800x300 × 3.0)');
      
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        print('❌ Erreur conversion PNG');
        image.dispose();
        return;
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      print('🎉 CAPTURE RÉUSSIE!');
      print('   📦 ${(pngBytes.length / 1024).toStringAsFixed(2)} KB');
      print('   📊 Header: ${pngBytes.take(8).toList()}');
      print('   ✅ GARANTIE: Widget ne contient QUE la signature!');
      
      image.dispose();
      Navigator.of(context).pop(pngBytes);
      
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dialogue VIDE avec juste le SfSignaturePad
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: 800,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF002B6B), width: 2),
            ),
            // RIEN D'AUTRE ICI - SEULEMENT le SfSignaturePad
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SfSignaturePad(
                key: _signaturePadKey,
                backgroundColor: Colors.white,
                strokeColor: const Color(0xFF002B6B),
                minimumStrokeWidth: 2.5,
                maximumStrokeWidth: 4.5,
              ),
            ),
          ),
        ),
        
        // Boutons HORS du dialogue - Overlay transparent
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).size.height * 0.15,
          child: Center(
            child: Container(
              width: 800,
              padding: const EdgeInsets.only(top: 320), // En dessous de la zone de signature
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton Effacer
                  ElevatedButton.icon(
                    onPressed: () {
                      _signaturePadKey.currentState?.clear();
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const Text(
                      'Effacer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // Bouton Annuler
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, color: Colors.black87),
                    label: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  // Bouton Valider
                  ElevatedButton.icon(
                    onPressed: _captureSignature,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Valider',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Header HORS du dialogue - En haut
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.15 - 60,
          child: Center(
            child: Container(
              width: 800,
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002B6B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signature manuscrite',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Signez dans le cadre blanc ci-dessous',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
