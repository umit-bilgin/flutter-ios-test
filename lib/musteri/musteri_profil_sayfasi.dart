import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MusteriProfilSayfasi extends StatefulWidget {
  const MusteriProfilSayfasi({super.key});

  @override
  State<MusteriProfilSayfasi> createState() => _MusteriProfilSayfasiState();
}

class _MusteriProfilSayfasiState extends State<MusteriProfilSayfasi> {
  final TextEditingController sifreController = TextEditingController();
  final TextEditingController adresController = TextEditingController();
  String adSoyad = '';
  String? mesaj;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final musteriId = prefs.getString('musteri_id') ?? '';
    debugPrint("📦 SharedPreferences'tan musteri_id: $musteriId");

    // Önce localden (hızlı açılış için)
    final localAd = prefs.getString('ad') ?? '';
    final localAdres = prefs.getString('adres') ?? '';
    debugPrint("📦 Local 'ad': $localAd");
    debugPrint("📦 Local 'adres': $localAdres");

    setState(() {
      adSoyad = localAd;
      adresController.text = localAdres;
    });

    // 🔄 API'den güncel veri çek
    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/api/app_musteri_bilgileri.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'musteri_id': musteriId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final yeniAd = data['ad'] ?? '';
      final yeniAdres = data['adres'] ?? '';

      debugPrint("🌐 API'den gelen ad: $yeniAd");
      debugPrint("🌐 API'den gelen adres: $yeniAdres");

      setState(() {
        adSoyad = yeniAd;
        adresController.text = yeniAdres;
      });

      // Lokal veriyi güncelle
      await prefs.setString('ad', yeniAd);
      await prefs.setString('adres', yeniAdres);

      debugPrint("💾 SharedPreferences'a yazıldı: ad = $yeniAd | adres = $yeniAdres");
    }

    debugPrint("🧪 Kontrol (tekrar oku): ad = ${prefs.getString('ad')} | adres = ${prefs.getString('adres')}");
  }

  Future<void> guncelle() async {
    final prefs = await SharedPreferences.getInstance();
    final musteriId = prefs.getString('musteri_id');

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/api/app_musteri_profil_guncelle.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'musteri_id': musteriId,
        'sifre': sifreController.text.trim(),
        'adres': adresController.text.trim(),
      }),
    );

    final data = json.decode(response.body);
    if (!mounted) return;

    setState(() => mesaj = data['message'] ?? 'Güncelleme tamamlandı');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DEBUG: $adSoyad'),

            // Hoşgeldiniz mesajı
            Text(
              'Hoşgeldiniz, $adSoyad',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Şifre alanı
            const Text('Yeni Şifre:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: sifreController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Yeni şifre'),
            ),
            const SizedBox(height: 12),
            // Adres alanı
            const Text('Adres:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: adresController,
              decoration: const InputDecoration(hintText: 'Adres'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: guncelle,
              child: const Text('Güncelle'),
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


