import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

class DownloadNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const String _channelId = 'download_channel';
  static const String _channelName = 'Downloads';
  static const String _channelDescription =
      'Notifications de progression et fin des telechargements';

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          await OpenFilex.open(payload);
        }
      },
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    if (Platform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static Future<void> showProgress(
    int id, {
    required String title,
    required int progress,
  }) async {
    await initialize();

    final safeProgress = progress.clamp(0, 100);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: 100,
        progress: safeProgress,
        ongoing: safeProgress < 100,
        autoCancel: false,
      ),
    );

    await _plugin.show(
      id,
      title,
      'Progression: $safeProgress%',
      details,
    );
  }

  static Future<void> showCompleted(
    int id, {
    required String title,
    required String filePath,
  }) async {
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        onlyAlertOnce: true,
        ongoing: false,
        autoCancel: true,
      ),
    );

    await _plugin.show(
      id,
      title,
      'Touchez pour ouvrir le fichier',
      details,
      payload: filePath,
    );
  }

  static Future<void> showFailed(
    int id, {
    required String title,
    required String message,
  }) async {
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(id, title, message, details);
  }
}
