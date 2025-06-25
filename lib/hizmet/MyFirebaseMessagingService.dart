import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../musteri_panel.dart'; // ← gerektiği gibi import et
import '../satici_panel.dart';  // ← gerekiyorsa
import '../login_page.dart';  // ← gerekiyorsa
import '../splash_screen.dart';  // ← gerekiyorsa

class MyFirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init(BuildContext context) async {
    // 🔔 Bildirim izinleri
    await _firebaseMessaging.requestPermission();

    // 🔄 Token al
    String? token = await _firebaseMessaging.getToken();
    debugPrint("🔑 FCM Token: $token");

    // 📩 Foreground mesajları
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // 🕒 Bildirime tıklanarak açıldığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleClickAction(context, message);
    });

    // ✅ Local notification init
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (payload) {
        if (payload.payload != null) {
          _handleClickAction(context,
              RemoteMessage(data: {'click_action': payload.payload!}));
        }
      },
    );
  }

  static void _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      platformDetails,
      payload: message.data['click_action'] ?? '',
    );
  }

  static void _handleClickAction(BuildContext context, RemoteMessage message) {
    final String? clickAction = message.data['click_action'];

    if (clickAction == 'musteri_panel') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    } else if (clickAction == 'satici_panel') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    }
    // 🔁 Diğer yönlendirmeler burada eklenebilir
  }
}
