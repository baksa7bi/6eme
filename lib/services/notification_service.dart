import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize Local Notifications
    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: initAndroid, iOS: initIOS);
    await _localNotifs.initialize(settings: initSettings);

    // Create Notification Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'delivery_channel',
      'Nouvelles Livraisons',
      description: 'Alarmes pour les nouvelles commandes de livraison',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    
    await _localNotifs.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions for iOS / Android 13+
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ?? 'Nouvelle commande';
      final body = message.data['body'] ?? 'Vous avez une livraison en attente !';
      
      _showLocalNotification(title, body, message.data);

      // NO ALARM HERE: User requested standard notification ONLY while already in-app
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'delivery_channel',
      'Nouvelles Livraisons',
      channelDescription: 'Alarmes pour les nouvelles commandes de livraison',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ongoing: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
    );
    NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
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

  static void stopAlarm() {
    FlutterRingtonePlayer().stop();
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final title = message.data['title'] ?? 'Nouvelle commande';
  final body = message.data['body'] ?? 'Vous avez une livraison en attente !';
  
  NotificationService._showLocalNotification(title, body, message.data);

  // Play a ringing sound that ignores silent mode (on some devices) and loops
  if (message.data['type'] == 'delivery' || message.data['status'] == 'En attente') {
    FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true,
      volume: 1.0,
      asAlarm: true,
    );
  }
}
