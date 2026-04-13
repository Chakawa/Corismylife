import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// NOUVELLE APPROCHE RADICALE: Dessiner dans un vrai Canvas offscreen
/// sans aucun widget Flutter pour éviter tout risque de capture d'UI
class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  // Couleurs personnalisées
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color blanc = Colors.white;
  static const Color grisTexte = Color(0xFF64748B);

  // Liste des points dessinés
  final List<Offset?> _points = [];
  
  // GlobalKey juste pour obtenir les dimensions, PAS pour capturer
  final GlobalKey _containerKey = GlobalKey();

  /// Efface la signature
  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  /// Valide et retourne la signature en PNG
  /// APPROCHE DÉFINITIVE: Création pure d'image sans passer par aucun widget
  Future<void> _validateSignature() async {
    if (_points.isEmpty || _points.every((p) => p == null)) {
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
      print('🎨🎨🎨 NOUVELLE APPROCHE: CRÉATION PURE D\'IMAGE OFFSCREEN');
      
      // DIMENSIONS FIXES - Aucune dépendance aux widgets
      const int outputWidth = 800;
      const int outputHeight = 400;
      
      // Obtenir les dimensions du widget pour le ratio
      final RenderBox? box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      final double inputWidth = box?.size.width ?? 400.0;
      final double inputHeight = box?.size.height ?? 200.0;
      
      print('📏 Input: ${inputWidth}x$inputHeight → Output: ${outputWidth}x$outputHeight');
      
      final double scaleX = outputWidth / inputWidth;
      final double scaleY = outputHeight / inputHeight;

      // Créer un PictureRecorder - C'est un objet OFFSCREEN, pas un widget!
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Fond blanc
      canvas.drawRect(
        Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
        Paint()..color = Colors.white,
      );
      print('✅ Fond blanc dessiné');

      // Dessiner les traits de signature
      final paint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.0;

      int strokeCount = 0;
      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(
            Offset(_points[i]!.dx * scaleX, _points[i]!.dy * scaleY),
            Offset(_points[i + 1]!.dx * scaleX, _points[i + 1]!.dy * scaleY),
            paint,
          );
          strokeCount++;
        }
      }
      print('✅ $strokeCount traits dessinés');

      // Convertir en image (OFFSCREEN - pas de widget UI capturé)
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(outputWidth, outputHeight);
      print('✅ Image générée: ${image.width}x${image.height}px');

      // Encoder en PNG
      final ByteData? pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngBytes == null) {
        throw Exception('Échec encodage PNG');
      }

      final Uint8List bytes = pngBytes.buffer.asUint8List();
      
      print('🎉 SUCCÈS TOTAL!');
      print('   📦 Taille: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      print('   🖼️ Format: PNG ${outputWidth}x$outputHeight');
      print('   ✍️ Points: ${_points.where((p) => p != null).length}');
      print('   🚫 ZÉRO widget capturé - Image pure offscreen');
      print('   📊 Header PNG: ${bytes.take(8).toList()}');

      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e, stack) {
      print('❌ ERREUR GÉNÉRATION: $e');
      print('   Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur génération: $e'),
            backgroundColor: Colors.red,
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

            // Zone de signature avec Container Key
            Container(
              key: _containerKey, // Pour obtenir les dimensions réelles
              decoration: BoxDecoration(
                border: Border.all(color: bleuCoris, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 200,
                  color: blanc,
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _points.add(null); // Séparateur de lignes
                      });
                    },
                    child: Container(
                      color: blanc,
                      width: double.infinity,
                      height: double.infinity,
                      child: CustomPaint(
                        painter: SignaturePainter(
                          points: _points,
                          penColor: Colors.black,
                          strokeWidth: 3.0,
                        ),
                      ),
                    ),
                  ),
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

/// CustomPainter pour dessiner la signature
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color penColor;
  final double strokeWidth;

  SignaturePainter({
    required this.points,
    required this.penColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // NE PAS dessiner de fond ici - le Container blanc le fait déjà
    
    // Dessine la signature
    final paint = Paint()
      ..color = penColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
