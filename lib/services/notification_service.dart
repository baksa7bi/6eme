import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();

  // Channel ID bumped to v2 — forces Android to register a fresh channel
  // with correct sound settings (old channel config is immutable once created).
  static const String _channelId = 'delivery_channel_v2';

  static Future<void> initialize() async {
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
      onDidReceiveNotificationResponse: (response) {
        stopAlarm();
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    final androidPlugin = _localNotifs
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Delete stale channels so their immutable sound/importance settings
    // don't silently override what we set below.
    await androidPlugin?.deleteNotificationChannel(channelId: 'delivery_channel');
    await androidPlugin?.deleteNotificationChannel(channelId: 'delivery_channel_v2');

    // Re-create channel fresh with sound + max importance.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'Nouvelles Livraisons',
      description: 'Alarmes pour les nouvelles commandes de livraison',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(channel);

    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Foreground message handler — show local notification with alarm
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ?? 'Nouvelle commande';
      final body = message.data['body'] ?? 'Vous avez une livraison en attente !';
      _showLocalNotification(title, body, message.data);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _showLocalNotification(
      String title, String body, Map<String, dynamic> data) async {
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        'stop_alarm',
        'STOP ALARM',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      'Nouvelles Livraisons',
      channelDescription: 'Alarmes pour les nouvelles commandes de livraison',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      // Do NOT set a custom sound URI here — let the channel default play.
      // A wrong/missing sound URI silently falls back to no sound.
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: loops sound until cancelled
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ongoing: false,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      actions: actions,
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifs.show(
      id: 888,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: data.toString(),
    );
  }

  static Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        try {
          await _fcm.getAPNSToken();
        } catch (e) {
          debugPrint("FCM APNS Token not ready: $e");
        }
      }
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Stops the alarm by cancelling the notification.
  /// FLAG_INSISTENT sound is owned by the OS — cancelling the notification
  /// is the only reliable way to stop the looping sound.
  static Future<void> stopAlarm() async {
    await _localNotifs.cancel(id: 888);
  }
}

// Called when user taps the notification or STOP ALARM action in the background.
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  NotificationService.stopAlarm();
}

// Called when a Firebase message arrives while the app is terminated/background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final title = message.data['title'] ?? 'Nouvelle commande';
  final body = message.data['body'] ?? 'Vous avez une livraison en attente !';
  NotificationService._showLocalNotification(title, body, message.data);
}