import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController adController = TextEditingController();
  final TextEditingController telefonController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();
  final TextEditingController adresController = TextEditingController();

  String? seciliRol;
  String? hataMesaji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: adController, decoration: const InputDecoration(labelText: 'Ad Soyad')),
            TextField(controller: telefonController, decoration: const InputDecoration(labelText: 'Telefon'), keyboardType: TextInputType.phone),
            TextField(controller: sifreController, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Rol Seçiniz"),
              value: seciliRol,
              onChanged: (String? newValue) {
                setState(() {
                  seciliRol = newValue;
                });
              },
              items: ['satici', 'musteri'].map((value) {
                return DropdownMenuItem(value: value, child: Text(value));
              }).toList(),
            ),
            if (seciliRol == 'musteri')
              TextField(controller: adresController, decoration: const InputDecoration(labelText: "Adres")),
            if (hataMesaji != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(hataMesaji!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final ad = adController.text.trim();
                final telefon = telefonController.text.trim();
                final sifre = sifreController.text.trim();
                final rol = seciliRol;
                final adres = adresController.text.trim();

                if (ad.isEmpty || telefon.isEmpty || sifre.isEmpty || rol == null || (rol == 'musteri' && adres.isEmpty)) {
                  setState(() => hataMesaji = 'Tüm alanları doldurunuz.');
                  return;
                }

                final response = await http.post(
                  Uri.parse('https://www.yakauretimi.com/api/app_kullanici_register.php'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'ad': ad,
                    'telefon': telefon,
                    'sifre': sifre,
                    'rol': rol,
                    'adres': rol == 'musteri' ? adres : '',
                    'enlem': 0,
                    'boylam': 0,
                  }),
                );

                print('YANIT: ${response.body}');
                print('KOD: ${response.statusCode}');

                if (!context.mounted) return;

                if (response.headers['content-type']?.contains('application/json') == true) {
                  final data = json.decode(response.body);
                  if (data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kayıt başarılı!')),
                    );
                    final token = await FirebaseMessaging.instance.getToken();

                    await http.post(
                      Uri.parse('https://www.yakauretimi.com/api/app_token_kaydet.php'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'token': token,
                        'musteri_id': data['id'], // az önce gelen yanıt
                        'platform': 'android',
                      }),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } else {
                    setState(() => hataMesaji = data['message']);
                  }
                } else {
                  setState(() => hataMesaji = 'Beklenmeyen yanıt: ${response.body}');
                }
              },
              child: const Text('Kaydol'),
            )
          ],
        ),
      ),
    );
  }
}
