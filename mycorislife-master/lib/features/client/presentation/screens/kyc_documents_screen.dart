import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mycorislife/services/kyc_service.dart';
import 'package:mycorislife/config/app_config.dart';

/// Écran de gestion des documents KYC
class KYCDocumentsScreen extends StatefulWidget {
  const KYCDocumentsScreen({super.key});

  @override
  State<KYCDocumentsScreen> createState() => _KYCDocumentsScreenState();
}

class _KYCDocumentsScreenState extends State<KYCDocumentsScreen> {
  static const Color bleuCoris = Color(0xFF002B6B);
  List<Map<String, dynamic>> _requirements = [];
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reqs = await KYCService.getRequirements();
      final docs = await KYCService.getDocuments();
      setState(() {
        _requirements = reqs;
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadDocument(String docKey, String label) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      await KYCService.uploadDocument(image.path, docKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label uploadé avec succès'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents KYC'), backgroundColor: bleuCoris),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Documents requis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ..._requirements.map((req) {
                  final key = req['key'] as String;
                  final label = req['label'] as String;
                  final doc = _documents.firstWhere((d) => d['doc_key'] == key, orElse: () => {});
                  final hasDoc = doc.isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(hasDoc ? Icons.check_circle : Icons.upload_file, color: hasDoc ? Colors.green : bleuCoris),
                      title: Text(label),
                      subtitle: hasDoc ? Text('Uploadé le ${doc['created_at']}') : const Text('Non uploadé'),
                      trailing: hasDoc ? null : IconButton(
                        icon: const Icon(Icons.upload),
                        onPressed: () => _uploadDocument(key, label),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
