import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'satici_profil_sayfasi.dart';
import 'satici_siparisler_sayfasi.dart';
import 'satici_musteriler_sayfasi.dart';
import 'login_page.dart';

class SaticiPanel extends StatelessWidget {
  const SaticiPanel({super.key});

  Future<void> _cikisYap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satıcı Paneli')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Bilgileri'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaticiProfilSayfasi()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Gelen Siparişler'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaticiSiparislerSayfasi()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Müşteri Listesi'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaticiMusterilerSayfasi()),
              );
            },
          ),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                final fcmToken = await FirebaseMessaging.instance.getToken();

                if (fcmToken != null) {
                  await http.post(
                    Uri.parse('https://www.yakauretimi.com/api/app_token_sil.php'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'token': fcmToken}),
                  );
                }

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
          ),
        ],
      ),
    );
  }
}
