import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import '../../../../config/app_config.dart';

class PhotoViewerPage extends StatelessWidget {
  final String? photoUrl;
  final File? localFile;
  final String? title;

  // Constantes de couleur
  static const Color blanc = Colors.white;
  static const Color bleuCoris = Color(0xFF002B6B);

  const PhotoViewerPage({
    Key? key,
    this.photoUrl,
    this.localFile,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title ?? 'Photo de profil',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: localFile != null
            ? PhotoView(
                imageProvider: FileImage(localFile!),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            (event.expectedTotalBytes ?? 1),
                    color: const Color(0xFF002B6B),
                  ),
                ),
              )
            : photoUrl != null
                ? PhotoView(
                    imageProvider: NetworkImage(
                      photoUrl!.startsWith('http')
                          ? photoUrl!
                          : '${AppConfig.baseUrl.replaceAll('/api', '')}$photoUrl',
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    loadingBuilder: (context, event) => Center(
                      child: CircularProgressIndicator(
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                (event.expectedTotalBytes ?? 1),
                        color: const Color(0xFF002B6B),
                      ),
                    ),
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Impossible de charger la photo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo, color: Colors.grey, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Aucune photo disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
