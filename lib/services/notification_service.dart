import 'dart:io';
import 'package:flutter/widgets.dart';
// Hide firebase_messaging's NotificationSettings to avoid clash with
// the alarm package's NotificationSettings class.
import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alarm/alarm.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  // Regular (non-alarm) channel for promotions / order status updates
  static const String _normalChannelId = 'normal_channel';

  static Future<void> initialize() async {
    // ── 1. Alarm package ──────────────────────────────────────────────────────
    await Alarm.init();

    // ── 2. flutter_local_notifications (for regular notifications) ────────────
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings =
        InitializationSettings(android: initAndroid, iOS: initIOS);

    await _localNotifs.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) => stopAlarm(),
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    final androidPlugin = _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Delete old channels (clean up from previous versions)
    for (final id in ['delivery_channel', 'delivery_channel_v2', 'delivery_channel_v3']) {
      await androidPlugin?.deleteNotificationChannel(channelId: id);
    }

    // Create the standard channel for non-alarm notifications
    const AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
      _normalChannelId,
      'Notifications standard',
      description: 'Notifications générales',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(normalChannel);

    // ── 3. FCM permissions ────────────────────────────────────────────────────
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      criticalAlert: true,
      sound: true,
    );

    // ── 4. Foreground message handler ─────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ?? 'Nouvelle notification';
      final body = message.data['body'] ?? '';
      _showNotification(title, body, message.data);
    });

    // ── 5. Background / terminated message handler ────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // ─── Core dispatcher ────────────────────────────────────────────────────────
  static Future<void> _showNotification(
      String title, String body, Map<String, dynamic> data) async {
    final bool isManagerAlert =
        data['type'] == 'delivery' || data['status'] == 'En attente';

    if (isManagerAlert) {
      await _triggerAlarm(title, body);
    } else {
      await _showRegularNotification(title, body, data);
    }
  }

  // ─── Alarm (lock-screen, looping sound, foreground service) ─────────────────
  static Future<void> _triggerAlarm(String title, String body) async {
    // Use a time-based ID so multiple orders each get their own alarm slot.
    // Clamped to int32 range to satisfy the alarm package.
    final int alarmId = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000;

    final alarmSettings = AlarmSettings(
      id: alarmId,
      // Trigger almost immediately
      dateTime: DateTime.now().add(const Duration(seconds: 1)),
      // Flutter asset path (registered in pubspec.yaml → assets/audio/)
      assetAudioPath: 'assets/audio/alarm.wav',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'STOP ALARM',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  // ─── Regular local notification (non-delivery) ───────────────────────────────
  static Future<void> _showRegularNotification(
      String title, String body, Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _normalChannelId,
      'Notifications standard',
      channelDescription: 'Notifications générales',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    await _localNotifs.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: data.toString(),
    );
  }

  // ─── Public API ──────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        try {
          await _fcm.getAPNSToken();
        } catch (e) {
          debugPrint('FCM APNS Token not ready: $e');
        }
      }
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Stops ALL active alarms and dismisses any lingering local notifications.
  static Future<void> stopAlarm() async {
    await Alarm.stopAll();
    await _localNotifs.cancelAll();
  }
}

// ─── Background callbacks (top-level, separate isolate) ───────────────────────

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Can only call sync-safe code here; alarm stop is handled by the alarm
  // package's own "Stop" button action.
  NotificationService.stopAlarm();
}

/// Handles FCM messages while the app is terminated or in the background.
/// Runs in its own isolate → must re-init the alarm package before using it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = message.data;
  final bool isManagerAlert =
      data['type'] == 'delivery' || data['status'] == 'En attente';

  if (isManagerAlert) {
    // Re-init alarm in this isolate before using it
    await Alarm.init(showDebugLogs: false);

    final title = data['title'] ?? 'Nouvelle commande';
    final body = data['body'] ?? 'Vous avez une nouvelle livraison !';

    final int alarmId =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000;

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: DateTime.now().add(const Duration(seconds: 1)),
      assetAudioPath: 'assets/audio/alarm.wav',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'STOP ALARM',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }
  // Non-delivery notifications in background: FCM handles display natively
  // via the `notification` payload from the server.
}