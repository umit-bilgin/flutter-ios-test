import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';

import '../ortak/login_page.dart';
import 'musteri_profil_sayfasi.dart';
import 'musteri_siparislerim.dart';
import 'musteri_bildirimlerim_sayfasi.dart';
import '../siparis/fl_kategori_listesi.dart';

class MusteriPanel extends StatelessWidget {
  const MusteriPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Paneli')),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.shopping_cart_checkout),
            title: const Text('Yeni Sipariş Ver'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FlKategoriListesi()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Siparişlerim'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MusteriSiparislerimSayfasi()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Bildirimlerim"),
            onTap: () {
              SharedPreferences.getInstance().then((prefs) {
                final id = prefs.getInt('kullanici_id');
                if (id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BildirimlerimPage(kullaniciId: id),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kullanıcı ID bulunamadı")),
                  );
                }
              });
            },
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Düzenle'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MusteriProfilSayfasi()),
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
            },
          ),
        ],
      ),
    );
  }
}
