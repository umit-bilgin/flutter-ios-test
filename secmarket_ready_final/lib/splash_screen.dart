import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'admin_panel.dart';
import 'satici_panel.dart';
import 'musteri_panel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    kontrolEt();
  }

  Future<void> kontrolEt() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Seç Market',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
