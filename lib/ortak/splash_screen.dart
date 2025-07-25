import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../admin/admin_panel.dart';
import '../satici/satici_panel.dart';
import '../musteri/musteri_panel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:secmarket/hizmet/MyFirebaseMessagingService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  String? _hataMesaji; // Hata olursa burada tutulacak

  @override
  void initState() {
    super.initState();
    //  MyFirebaseMessagingService.init(context); // 🔥 Push sistemi burada devreye giriyor
    // Buraya varsa yönlendirme, gecikme gibi işlemleri de eklersin
    //  _initializeNotifications();
    //  _setupFirebaseMessaging();
    kontrolEt();
  }

  /*void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🔔 Bildirime tıklandı: ${response.payload}");
        // Burada özel yönlendirme yapılabilir
      },
    );
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📲 Bildirim geldi (foreground): ${message.notification?.title}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚪 [CLICK] Bildirime tıklandı: ${message.notification?.title}");
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // 🔍 'data' öncelikli, yoksa notification kullan
    final String? title =
        message.data['title'] ?? message.notification?.title ?? 'Yeni Bildirim';
    final String? body =
        message.data['body'] ?? message.notification?.body ?? 'Mesajınız var.';

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }*/

  Future<void> kontrolEt() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final prefs = await SharedPreferences.getInstance();
      final rol = prefs.getString('rol');

      if (!mounted) return;

      Widget hedefSayfa;
      if (rol == 'admin') {
        hedefSayfa = const AdminPanelPage();
      } else if (rol == 'satici') {
        hedefSayfa = const SaticiPanel();
      } else if (rol == 'musteri') {
        hedefSayfa = const MusteriPanel();
      } else {
        hedefSayfa = const LoginPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => hedefSayfa),
      );
    } catch (e, s) {
      debugPrint("❌ Splash hata: $e\n$s");
      setState(() {
        _hataMesaji = "$e\n\n$s";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _hataMesaji == null
            ? const Text(
          'Seç Market',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        )
            : Container(
          color: Colors.red[50],
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              "⚠️ Bir hata oluştu!\n\n$_hataMesaji",
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
