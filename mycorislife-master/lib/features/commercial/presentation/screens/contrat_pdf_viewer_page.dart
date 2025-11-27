import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:mycorislife/services/contrat_pdf_service.dart';

/// Page pour visualiser le PDF d'un contrat
/// Permet de voir, télécharger et partager le PDF
class ContratPdfViewerPage extends StatefulWidget {
  final String numepoli;
  final String? clientName;

  const ContratPdfViewerPage({
    super.key,
    required this.numepoli,
    this.clientName,
  });

  @override
  State<ContratPdfViewerPage> createState() => _ContratPdfViewerPageState();
}

class _ContratPdfViewerPageState extends State<ContratPdfViewerPage> {
  // Charte graphique CORIS
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color vertSucces = Color(0xFF10B981);
  static const Color blanc = Colors.white;

  File? _file;
  bool _loading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final file = await ContratPdfService.fetchToTemp(widget.numepoli);
      if (!mounted) return;
      setState(() {
        _file = file;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_file == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: bleuCoris),
        ),
      );

      final savedFile = await ContratPdfService.saveToDownloads(_file!);

      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: blanc, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PDF téléchargé avec succès!\n${savedFile.path}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: vertSucces,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: blanc, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_file == null) return;

    try {
      await ContratPdfService.sharePdf(_file!, widget.numepoli);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contrat CORIS',
              style: TextStyle(
                color: blanc,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Police: ${widget.numepoli}',
              style: const TextStyle(
                color: blanc,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: bleuCoris,
        elevation: 0,
        iconTheme: const IconThemeData(color: blanc),
        actions: [
          if (_file != null) ...[
            IconButton(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share, color: blanc),
              tooltip: 'Partager',
            ),
            IconButton(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download, color: blanc),
              tooltip: 'Télécharger',
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: bleuCoris),
                  SizedBox(height: 16),
                  Text(
                    'Chargement du PDF...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
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
                        const Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadPdf,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bleuCoris,
                            foregroundColor: blanc,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Indicateur de page
                    if (_totalPages > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: bleuCoris,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: blanc, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Page ${_currentPage + 1} / $_totalPages',
                              style: const TextStyle(
                                color: blanc,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Viewer PDF
                    Expanded(
                      child: PDFView(
                        filePath: _file!.path,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                        pageSnap: true,
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages ?? 0;
                          });
                        },
                        onPageChanged: (page, total) {
                          setState(() {
                            _currentPage = page ?? 0;
                          });
                        },
                        onError: (error) {
                          setState(() {
                            _error = error.toString();
                          });
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
