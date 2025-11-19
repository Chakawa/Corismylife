import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color bleuCoris = Color(0xFF002B6B);
const Color grisTexte = Color(0xFF64748B);

class DocumentViewerPage extends StatefulWidget {
  final String? documentName;
  final File? localFile;
  final int? subscriptionId;

  const DocumentViewerPage({
    super.key,
    this.documentName,
    this.localFile,
    this.subscriptionId,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  bool _isLoading = true;
  String? _errorMessage;
  File? _documentFile;
  String? _fileExtension;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      if (widget.localFile != null) {
        // Fichier local (pendant la souscription)
        setState(() {
          _documentFile = widget.localFile;
          _fileExtension = widget.localFile!.path.split('.').last.toLowerCase();
          _isLoading = false;
        });
      } else if (widget.documentName != null && widget.subscriptionId != null) {
        // Télécharger le fichier depuis le serveur
        await _downloadDocument();
      } else {
        setState(() {
          _errorMessage = 'Aucun document à afficher';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadDocument() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      final url = '${AppConfig.baseUrl}/subscriptions/${widget.subscriptionId}/document/${widget.documentName}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.documentName}');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _documentFile = file;
          _fileExtension = widget.documentName!.split('.').last.toLowerCase();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossible de télécharger le document';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur réseau: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pièce d\'identité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: bleuCoris,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(bleuCoris),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement du document...',
              style: TextStyle(
                fontSize: 14,
                color: grisTexte,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: grisTexte,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: bleuCoris,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_documentFile == null) {
      return const Center(
        child: Text('Aucun document disponible'),
      );
    }

    // Afficher selon le type de fichier
    if (_fileExtension == 'pdf') {
      return _buildPdfViewer();
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(_fileExtension)) {
      return _buildImageViewer();
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description,
                size: 64,
                color: bleuCoris,
              ),
              const SizedBox(height: 16),
              Text(
                widget.documentName ?? _documentFile!.path.split('/').last,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type de fichier: ${_fileExtension?.toUpperCase() ?? 'Inconnu'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: grisTexte,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Prévisualisation non disponible pour ce type de fichier',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: grisTexte,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPdfViewer() {
    return PDFView(
      filePath: _documentFile!.path,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {});
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Erreur lors de l\'affichage du PDF: $error';
        });
      },
      onPageError: (page, error) {
        setState(() {
          _errorMessage = 'Erreur page $page: $error';
        });
      },
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          _documentFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Impossible d\'afficher l\'image',
                  style: const TextStyle(
                    fontSize: 14,
                    color: grisTexte,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
