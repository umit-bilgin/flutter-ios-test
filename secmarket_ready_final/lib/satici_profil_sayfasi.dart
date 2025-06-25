import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SaticiProfilSayfasi extends StatefulWidget {
  const SaticiProfilSayfasi({super.key});

  @override
  State<SaticiProfilSayfasi> createState() => _SaticiProfilSayfasiState();
}

class _SaticiProfilSayfasiState extends State<SaticiProfilSayfasi> {
  final TextEditingController sifreController = TextEditingController();
  String? mesaj;

  Future<void> sifreGuncelle() async {
    final prefs = await SharedPreferences.getInstance();
    final saticiId = prefs.getString('musteri_id');
    final yeniSifre = sifreController.text.trim();

    if (yeniSifre.isEmpty) {
      setState(() => mesaj = 'Şifre boş olamaz');
      return;
    }

    final response = await http.post(
      Uri.parse('https://yakauretimi.com/api/app_satici_sifre_guncelle.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'musteri_id': saticiId, 'sifre': yeniSifre}),
    );

    final data = json.decode(response.body);

    if (!mounted) return;
    setState(() => mesaj = data['message'] ?? 'İşlem tamamlandı');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Bilgileri')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yeni Şifre:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Yeni şifre'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: sifreGuncelle,
              child: const Text('Şifreyi Güncelle'),
            ),
            if (mesaj != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(mesaj!, style: const TextStyle(color: Colors.green)),
              )
          ],
        ),
      ),
    );
  }
}
