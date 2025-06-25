import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'satici_panel.dart';
import 'musteri_panel.dart';
import 'admin_panel.dart';
import 'register_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController telefonController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();
  String? seciliRol;
  String? hataMesaji;

  String? fcmToken;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        fcmToken = token;
        debugPrint("🔑 Uygulama başında alınan token: $fcmToken");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: telefonController,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Rol Seçiniz"),
              value: seciliRol,
              onChanged: (String? newValue) {
                setState(() {
                  seciliRol = newValue;
                });
              },
              items: ['admin', 'satici', 'musteri'].map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
            ),
            if (hataMesaji != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(hataMesaji!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final telefon = telefonController.text.trim();
                final sifre = sifreController.text.trim();
                final rol = seciliRol;

                if (telefon.isEmpty || sifre.isEmpty || rol == null || rol.isEmpty) {
                  debugPrint('❌ Telefon, şifre veya rol eksik');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Telefon, şifre ve rol doldurulmalı')),
                  );
                  return;
                }

                debugPrint('📡 Giden veri: $telefon / $sifre / $rol');
                final response = await http.post(
                  Uri.parse('https://www.yakauretimi.com/api/app_login.php'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'telefon': telefon, 'sifre': sifre, 'rol': rol}),
                );

                if (!context.mounted) return;

                debugPrint('📥 Gelen response: ${response.body}');
                final data = json.decode(response.body);

                if (data['success'] == true) {
                  debugPrint('✅ Login başarılı, id: ${data['id']} / ad: ${data['ad']}');

                  final prefs = await SharedPreferences.getInstance();
                  // await prefs.clear(); ❌ bunu şimdilik kapat!
                  // Sadece ilgili anahtarları temizle
                  await prefs.remove('kullanici_id');
                  await prefs.remove('ad');
                  await prefs.remove('rol');
                  await prefs.remove('musteri_id');

                  await prefs.setInt('kullanici_id', data['id']);
                  print("✅ KULLANICI ID YAZILDI: ${data['id']}");

                  await prefs.setString('musteri_id', data['id'].toString());
                  await prefs.setString('rol', rol);
                  await prefs.setString('ad', data['ad'] ?? '');
                  await prefs.setInt('kullanici_id', data['id']);

                  final testAd = prefs.getString('ad');
                  debugPrint("🧪 SharedPreferences 'ad': $testAd");

                  final fcmToken = await FirebaseMessaging.instance.getToken();
                  if (fcmToken != null) {
                    await prefs.setString('token', fcmToken);
                    debugPrint("📤 Token kayıt ediliyor: $fcmToken");
                    await http.post(
                      Uri.parse('https://www.yakauretimi.com/api/app_token_kaydet.php'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'token': fcmToken,
                        'kullanici_id': data['id'],
                        'platform': 'android',
                      }),
                    );
                  } else {
                    debugPrint("⚠️ Token alınamadı");
                  }

                  if (!context.mounted) return;
                  Widget hedef;
                  if (rol == 'admin') {
                    hedef = const AdminPanelPage();
                  } else if (rol == 'satici') {
                    hedef = const SaticiPanel();
                  } else {
                    hedef = const MusteriPanel();
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => hedef),
                  );
                } else {
                  debugPrint('❌ Giriş reddedildi: ${data['message']}');
                  setState(() => hataMesaji = data['message']);
                }
              },
              child: const Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: const Text(
                'KAYDOLMAK İÇİN DOKUNUN',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
