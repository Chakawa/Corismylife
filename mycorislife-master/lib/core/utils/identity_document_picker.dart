import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IdentityDocumentPickerResult {
  final List<File> files;
  final List<String> labels;

  IdentityDocumentPickerResult({
    required this.files,
    required this.labels,
  });
}

class IdentityDocumentPicker {
  IdentityDocumentPicker._();

  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<IdentityDocumentPickerResult?> pickDocuments(
    BuildContext context,
  ) async {
    final source = await _showSourceChoice(context);
    if (source == null) return null;

    if (source == _DocumentSource.files) {
      return _pickFromFiles(context);
    }

    return _pickFromCameraRectoVerso(context);
  }

  static Future<_DocumentSource?> _showSourceChoice(BuildContext context) {
    return showModalBottomSheet<_DocumentSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ajouter une piece d\'identite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choisissez votre source pour importer le document',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOptionCard(
                      context,
                      icon: Icons.folder_open_rounded,
                      title: 'Fichiers',
                      subtitle: 'PDF, JPG, PNG',
                      accent: const Color(0xFF0F766E),
                      onTap: () => Navigator.pop(context, _DocumentSource.files),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceOptionCard(
                      context,
                      icon: Icons.photo_camera_rounded,
                      title: 'Appareil photo',
                      subtitle: 'Recto / Verso guide',
                      accent: const Color(0xFF1E3A8A),
                      onTap: () => Navigator.pop(context, _DocumentSource.camera),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: const Color(0xFF334155),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSourceOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.2),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<IdentityDocumentPickerResult?> _pickFromFiles(
    BuildContext context,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result == null) return null;

    final files = <File>[];
    final labels = <String>[];

    for (final item in result.files) {
      if (item.path == null) continue;
      final file = File(item.path!);

      final fileSize = await file.length();
      if (fileSize > _maxFileSizeBytes) {
        if (!context.mounted) return null;
        await _showInfoDialog(
          context,
          title: 'Fichier trop volumineux',
          message:
              'Le fichier ${item.name} depasse 5 Mo. Merci de choisir un fichier plus leger.',
        );
        return null;
      }

      final isImage = _isImageFile(file.path);
      if (isImage) {
        final quality = await _checkImageQuality(file);
        if (!quality.ok) {
          if (!context.mounted) return null;
          await _showInfoDialog(
            context,
            title: 'Photo non lisible',
            message:
                'Le fichier ${item.name} ne peut pas etre lu correctement (${quality.reason}). Choisissez un document plus net.',
          );
          return null;
        }
      }

      files.add(file);
      labels.add(item.name);
    }

    if (files.isEmpty) return null;

    return IdentityDocumentPickerResult(files: files, labels: labels);
  }

  static Future<IdentityDocumentPickerResult?> _pickFromCameraRectoVerso(
    BuildContext context,
  ) async {
    final files = <File>[];
    final labels = <String>[];

    final sides = ['Recto', 'Verso'];

    for (final side in sides) {
      var validated = false;

      while (!validated) {
        if (!context.mounted) return null;

        await _showInfoDialog(
          context,
          title: 'Capture $side',
          message:
              'Prenez la photo du $side de la piece d\'identite dans un environnement bien eclaire.',
        );

        final shot = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 95,
          maxWidth: 2500,
        );

        if (shot == null) {
          if (!context.mounted) return null;
          final shouldCancel = await _confirmCancel(context, side);
          if (shouldCancel) return null;
          continue;
        }

        final file = File(shot.path);

        final fileSize = await file.length();
        if (fileSize > _maxFileSizeBytes) {
          if (!context.mounted) return null;
          await _showInfoDialog(
            context,
            title: 'Photo trop volumineuse',
            message:
                'La photo du $side depasse 5 Mo. Reprenez une photo plus legere.',
          );
          continue;
        }

        final quality = await _checkImageQuality(file);
        if (!quality.ok) {
          if (!context.mounted) return null;
          await _showInfoDialog(
            context,
            title: 'Photo insuffisante',
            message:
                'Le $side ne peut pas etre lu correctement (${quality.reason}). Reprenez la photo avec une meilleure nettete.',
          );
          continue;
        }

        if (!context.mounted) return null;
        final readable = await _confirmReadable(context, file, side);
        if (!readable) {
          await _showInfoDialog(
            context,
            title: 'Reprise necessaire',
            message:
                'Veuillez reprendre une photo plus nette afin que les ecritures soient lisibles.',
          );
          continue;
        }

        files.add(file);
        labels.add('Piece identite - $side');
        validated = true;
      }
    }

    return IdentityDocumentPickerResult(files: files, labels: labels);
  }

  static Future<bool> _confirmReadable(
    BuildContext context,
    File file,
    String side,
  ) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          'Verifier la lisibilite - $side',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Les ecritures sont-elles bien lisibles ?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Reprendre'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, lisible'),
          ),
        ],
      ),
    );

    return answer ?? false;
  }

  static Future<bool> _confirmCancel(BuildContext context, String side) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: const Text('Capture interrompue'),
        content: Text('La capture du $side a ete annulee. Voulez-vous quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return answer ?? false;
  }

  static Future<void> _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF1E3A8A),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.35),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  static bool _isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.png');
  }

  static Future<_ImageQualityResult> _checkImageQuality(File file) async {
    try {
      final bytes = await file.readAsBytes();
      await _decodeImage(bytes);
      return const _ImageQualityResult(true, null);
    } catch (_) {
      return const _ImageQualityResult(false, 'image invalide ou illisible');
    }
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (result) {
      completer.complete(result);
    });
    return completer.future;
  }
}

class _ImageQualityResult {
  final bool ok;
  final String? reason;

  const _ImageQualityResult(this.ok, this.reason);
}

enum _DocumentSource {
  files,
  camera,
}
