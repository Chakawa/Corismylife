import 'package:url_launcher/url_launcher.dart';

/// Helper to open a URL (PDF) in the platform browser/viewer
class DownloadHelper {
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

