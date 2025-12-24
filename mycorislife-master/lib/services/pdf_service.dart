import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  static Future<File> saveToDownloads(File tempFile) async {
    Directory? downloads;
    try {
      downloads = await getDownloadsDirectory();
    } catch (_) {}
    downloads ??= await getExternalStorageDirectory();
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
    final target = File('${downloads!.path}/${tempFile.uri.pathSegments.last}');
    return await tempFile.copy(target.path);
  }
}
