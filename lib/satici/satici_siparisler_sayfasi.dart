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
    final musteriId = prefs.getString('musteri_id');
    debugPrint("📦 SharedPreferences'tan musteri_id: $musteriId");

    if (musteriId == null) return;

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/islemler/fl_musteri_siparislerim_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"kullanici_id": musteriId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          siparisler = data['siparisler'] ?? [];
        });
      }
    } else {
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
          final siparis = siparisler[index];
          final ref = siparis['ref'];
          final tarih = siparis['tarih'] ?? '';
          final tutar = siparis['toplam_tutar'] ?? '';
          final satici = siparis['satici_ad'] ?? 'Satıcı';
          final saticiTel = siparis['satici_tel'] ?? '';

          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🧾 Sipariş No: $ref", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("📅 Tarih: $tarih"),
                  const SizedBox(height: 4),
                  Text("💳 Tutar: $tutar ₺"),
                  const SizedBox(height: 4),
                  Text("🏪 Satıcı: $satici"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: saticiTel.isNotEmpty ? () => _ara(saticiTel) : null,
                        icon: const Icon(Icons.phone),
                        label: const Text("Ara"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/musteri_siparis_ozet", arguments: {
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
