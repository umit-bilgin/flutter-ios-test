import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SaticiSiparislerSayfasi extends StatefulWidget {
  const SaticiSiparislerSayfasi({super.key});

  @override
  State<SaticiSiparislerSayfasi> createState() => _SaticiSiparislerSayfasiState();
}

class _SaticiSiparislerSayfasiState extends State<SaticiSiparislerSayfasi> {
  List<dynamic> siparisler = [];

  Future<void> siparisleriGetir() async {
    final prefs = await SharedPreferences.getInstance();
    final saticiId = prefs.getInt('kullanici_id')?.toString(); // ⚠️ doğru key: kullanici_id
    debugPrint("📦 SharedPreferences'tan kullanici_id (satıcı): $saticiId");

    if (saticiId == null) {
      debugPrint("⚠️ kullanici_id bulunamadı");
      return;
    }

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/islemler/fl_satici_gelen_siparisler_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"kullanici_id": saticiId}), // ⚠️ parametre ismi düzeltildi
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        debugPrint("✅ Sipariş verisi alındı");
        setState(() {
          siparisler = data['siparisler'] ?? [];
        });
      } else {
        debugPrint("❌ API başarısız: ${data['message']}");
      }
    } else {
      debugPrint("❌ HTTP hatası: ${response.statusCode}");
      setState(() {
        siparisler = [];
      });
    }
  }



  @override
  void initState() {
    super.initState();
    siparisleriGetir();
  }

  void _ara(String telefon) async {
    final Uri url = Uri(scheme: 'tel', path: telefon);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Arama başlatılamadı")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: ListView.builder(
        itemCount: siparisler.length,
        itemBuilder: (context, index) {
          final siparis = siparisler[index]; // ❗️ Eksikti, eklendi
          final ref = siparis['ref'] ?? '-';
          final musteriAd = siparis['musteri_ad'] ?? '-';
          final musteriAdres = siparis['musteri_adres'] ?? '-';
          final musteriTel = siparis['musteri_tel'] ?? '-';
          final tarih = siparis['tarih'] ?? '-';
          final tutar = siparis['toplam_tutar'] ?? '0.00';

          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 Müşteri: $musteriAd"),
                  Text("📍 Adres: $musteriAdres"),
                  Text("📅 Tarih: $tarih"),
                  Text("💳 Tutar: ₺$tutar"),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _ara(musteriTel),
                        child: Text("📞 Telefon: $musteriTel", style: const TextStyle(color: Colors.blue)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/satici_siparis_ozet", arguments: {
                            "ref": ref,
                          });
                        },
                        child: const Text("Sipariş Detayı"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
