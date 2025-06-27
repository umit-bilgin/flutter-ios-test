import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'ortak/splash_screen.dart';
import '/siparis/fl_sepet_sayfasi.dart';

// 🔔 Local notification eklentisi
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 🔴 Arka plan bildirimlerini yakalar
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showNotification(message);
}

// 🔔 Bildirimi göster
Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel', // kanal ID
    'Bildirimler', // kanal adı
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // benzersiz ID
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  /*// Bu satır TEST amaçlıdır 🔽
  _showNotification(RemoteMessage(
    notification: RemoteNotification(
      title: "TEST - MANUAL",
      body: "Bu manuel test bildirimi.",
    ),
  ));*/

  // 🔐 Bildirim izni iste
  await FirebaseMessaging.instance.requestPermission();

  // 🔁 Arka plan mesaj dinleyici
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🎯 Local notification ayarı
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message); // 🔔 Bildirimi göster
  });

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/fl_sepet_sayfasi': (context) => const FlSepetSayfasi(),
      },
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
