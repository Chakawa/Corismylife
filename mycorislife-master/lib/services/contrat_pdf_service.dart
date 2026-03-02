import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mycorislife/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

/// Service pour gérer les PDF des contrats
/// Fonctionnalités: Télécharger, Sauvegarder, Partager
class ContratPdfService {
  static const _storage = FlutterSecureStorage();

  /// Génère l'URL pour télécharger le PDF d'un contrat
  static String contratPdfUrl(String numepoli) {
    return '${AppConfig.baseUrl}/contrats/pdf/$numepoli';
  }

  /// Télécharge le PDF du contrat dans le dossier temporaire
  /// [numepoli] : Numéro de police du contrat
  /// Returns: File contenant le PDF
  static Future<File> fetchToTemp(String numepoli) async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token d\'authentification non trouvé');
    }

    final url = contratPdfUrl(numepoli);
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Erreur téléchargement PDF du contrat (${response.statusCode})');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/contrat_$numepoli.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  /// Sauvegarde le PDF dans le dossier Téléchargements
  /// [tempFile] : Fichier temporaire à sauvegarder
  /// Returns: File sauvegardé
  static Future<File> saveToDownloads(File tempFile) async {
    Directory? downloads;

    // Essayer d'obtenir le dossier Téléchargements
    try {
      downloads = await getDownloadsDirectory();
    } catch (_) {
      // Si échec, utiliser le stockage externe
      downloads = await getExternalStorageDirectory();
    }

    // Demander la permission sur Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Permission de stockage refusée');
      }
    }

    if (downloads == null) {
      throw Exception('Impossible d\'accéder au dossier de téléchargements');
    }

    // Créer le nom du fichier avec timestamp pour éviter les doublons
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = path.basename(tempFile.path);
    final newName = originalName.replaceFirst('.pdf', '_$timestamp.pdf');
    final target = File('${downloads.path}/$newName');

    return await tempFile.copy(target.path);
  }

  /// Partage le PDF du contrat via les applications disponibles
  /// [file] : Fichier PDF à partager
  /// [numepoli] : Numéro de police pour le message de partage
  static Future<void> sharePdf(File file, String numepoli) async {
    // Partage natif Android/iOS via le plugin share_plus.
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Contrat CORIS $numepoli',
      text: 'Veuillez trouver ci-joint le contrat CORIS $numepoli.',
    );
  }

  /// Télécharge et sauvegarde directement le PDF
  /// [numepoli] : Numéro de police du contrat
  /// Returns: Chemin du fichier sauvegardé
  static Future<String> downloadContratPdf(String numepoli) async {
    final tempFile = await fetchToTemp(numepoli);
    final savedFile = await saveToDownloads(tempFile);
    return savedFile.path;
  }

  /// Télécharge et partage le PDF
  /// [numepoli] : Numéro de police du contrat
  static Future<void> downloadAndSharePdf(String numepoli) async {
    final tempFile = await fetchToTemp(numepoli);
    await sharePdf(tempFile, numepoli);
  }
}
