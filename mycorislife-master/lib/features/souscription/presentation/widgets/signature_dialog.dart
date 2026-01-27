import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

  // GlobalKey pour capturer EXACTEMENT la zone de signature
  final GlobalKey _signatureKey = GlobalKey();

  // Liste des points dessinés
  final List<Offset?> _points = [];

  /// Efface la signature
  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  /// Valide et retourne la signature en PNG
  /// NOUVELLE APPROCHE: Créer l'image directement à partir des points (pas de capture widget)
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
      print('🎨 DÉBUT GÉNÉRATION SIGNATURE - VERSION DIRECTE CANVAS');
      
      // Dimensions FIXES de l'image (haute résolution)
      const double imageWidth = 800.0;
      const double imageHeight = 400.0;

      // Dimensions FIXES du widget signature (identique au Container dans build())
      const double widgetWidth = 400.0;  // Largeur typique du dialog
      const double widgetHeight = 200.0; // Hauteur définie dans le Container

      // Ratio pour adapter les coordonnées
      const double scaleX = imageWidth / widgetWidth;
      const double scaleY = imageHeight / widgetHeight;
      
      print('📐 Dimensions: Image=${imageWidth}x${imageHeight}, Widget=${widgetWidth}x${widgetHeight}');
      print('📐 Scale: X=${scaleX}, Y=${scaleY}');

      // Créer un PictureRecorder pour dessiner
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Dessiner le fond blanc
      final Paint backgroundPaint = Paint()..color = blanc;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        backgroundPaint,
      );
      print('✅ Fond blanc créé: ${imageWidth}x${imageHeight}');

      // Dessiner la signature avec les points
      final Paint signaturePaint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.0; // Épaisseur fixe pour haute résolution

      int linesDrawn = 0;
      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          // Adapter les coordonnées au ratio
          final Offset start = Offset(
            _points[i]!.dx * scaleX,
            _points[i]!.dy * scaleY,
          );
          final Offset end = Offset(
            _points[i + 1]!.dx * scaleX,
            _points[i + 1]!.dy * scaleY,
          );
          canvas.drawLine(start, end, signaturePaint);
          linesDrawn++;
        }
      }
      print('✅ Lignes dessinées: $linesDrawn');

      // Convertir en image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(imageWidth.toInt(), imageHeight.toInt());
      print('✅ Image créée: ${image.width}x${image.height}');

      // Convertir en PNG
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Impossible de convertir la signature en PNG');
      }

      final Uint8List signatureBytes = byteData.buffer.asUint8List();

      print('✅ Signature créée avec succès!');
      print('   - Taille: ${(signatureBytes.length / 1024).toStringAsFixed(2)} KB');
      print('   - Dimensions: ${imageWidth.toInt()}x${imageHeight.toInt()}px');
      print('   - Points dessinés: ${_points.where((p) => p != null).length}');
      print('   - AUCUN WIDGET CAPTURÉ - IMAGE PURE CANVAS');

      if (mounted) {
        Navigator.of(context).pop(signatureBytes); // retourne l'image
      }
    } catch (e) {
      print('❌ Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
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

            // Zone de signature - DÉLIMITÉE AVEC REPAINTBOUNDARY
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: bleuCoris, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 200,
                  color: blanc,
                  child: RepaintBoundary(
                    key: _signatureKey, // CLÉ POUR CAPTURE EXACTE
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
                        color: blanc, // FOND BLANC FORCÉ
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
