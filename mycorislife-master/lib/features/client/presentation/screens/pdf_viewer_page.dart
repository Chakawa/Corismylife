import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:mycorislife/services/pdf_service.dart';

class PdfViewerPage extends StatefulWidget {
  final int subscriptionId;
  final bool excludeQuestionnaire;
  const PdfViewerPage({super.key, required this.subscriptionId, this.excludeQuestionnaire = false});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  File? _file;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f = await PdfService.fetchToTemp(widget.subscriptionId, excludeQuestionnaire: widget.excludeQuestionnaire == true);
      if (!mounted) return;
      setState(() { _file = f; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _download() async {
    if (_file == null) return;
    try {
      final saved = await PdfService.saveToDownloads(_file!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargé: ${saved.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de téléchargement: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu PDF'),
        actions: [
          IconButton(onPressed: _download, icon: const Icon(Icons.download)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : PDFView(filePath: _file!.path),
    );
  }
}





