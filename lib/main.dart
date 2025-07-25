import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'ortak/splash_screen.dart';
import '../satici/satici_siparis_ozet_sayfasi.dart';
import '../musteri/musteri_siparis_ozet_sayfasi.dart';
import '../musteri/musteri_siparislerim.dart';
import '../musteri/musteri_panel.dart';
import '../siparis/fl_sepet_sayfasi.dart';

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

  // --- iOS Firebase başlatma ve local notification izinleri ---
  await Firebase.initializeApp();

  // Bildirim izni (özellikle iOS için)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // iOS foreground notification gösterme ayarı
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Arka plan mesaj dinleyici
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notification ayarı
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message); // Bildirimi göster
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/musteri_siparis_ozet': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MusteriSiparisOzetSayfasi(ref: args['ref']);
        },
        '/satici_siparis_ozet': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SaticiSiparisOzetSayfasi(ref: args['ref']);
        },
        '/fl_sepet_sayfasi': (context) => FlSepetSayfasi(),
        '/musteri_siparislerim': (context) => MusteriSiparislerimSayfasi(),
        '/musteri_panel': (context) => MusteriPanel(),
      },
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
