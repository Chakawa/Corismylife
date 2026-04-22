import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PdfService {
  static const _storage = FlutterSecureStorage();

  static String subscriptionPdfUrl(int subscriptionId) {
    return '${AppConfig.baseUrl}/subscriptions/$subscriptionId/pdf';
  }

  static Future<File> fetchToTemp(int subscriptionId, {bool excludeQuestionnaire = false}) async {
    final token = await _storage.read(key: 'token');
    var url = subscriptionPdfUrl(subscriptionId);
    if (excludeQuestionnaire) {
      // Add a query param to request a PDF without the questionnaire if supported by the backend
      url = '$url?exclude_questionnaire=1';
    }
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode != 200) {
      throw Exception('Erreur téléchargement PDF (${response.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/proposition_$subscriptionId.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  static Future<File> downloadToDownloadsWithProgress(
    int subscriptionId, {
    bool excludeQuestionnaire = false,
    void Function(int progress)? onProgress,
  }) async {
    final token = await _storage.read(key: 'token');
    var url = subscriptionPdfUrl(subscriptionId);
    if (excludeQuestionnaire) {
      url = '$url?exclude_questionnaire=1';
    }

    Directory? downloads;
    if (Platform.isAndroid) {
      downloads = await getExternalStorageDirectory();
    } else {
      downloads = await getApplicationDocumentsDirectory();
    }

    if (downloads == null) {
      throw Exception('Dossier de destination introuvable');
    }

    final fileName =
        'contrat_${subscriptionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final target = File('${downloads.path}/$fileName');
    final request = http.Request('GET', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    final client = http.Client();
    try {
      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        throw Exception('Erreur téléchargement PDF (${streamed.statusCode})');
      }

      final sink = target.openWrite();
      final total = streamed.contentLength ?? 0;
      var received = 0;
      var lastProgress = -1;
      await for (final chunk in streamed.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0 && onProgress != null) {
          final progress = ((received / total) * 100).floor().clamp(0, 100);
          if (progress != lastProgress) {
            lastProgress = progress;
            onProgress(progress);
          }
        }
      }

      await sink.flush();
      await sink.close();
      onProgress?.call(100);
      return target;
    } finally {
      client.close();
    }
  }

  static Future<File> saveToDownloads(File tempFile) async {
    // Obtenir un dossier sûr sans permission spéciale.
    Directory? downloads;
    if (Platform.isAndroid) {
      downloads = await getExternalStorageDirectory();
    } else {
      // Pour iOS
      downloads = await getApplicationDocumentsDirectory();
    }

    final fileName = tempFile.uri.pathSegments.last;
    final target = File('${downloads!.path}/$fileName');
    // Copier le fichier
    await tempFile.copy(target.path);
    return target;
  }
}
