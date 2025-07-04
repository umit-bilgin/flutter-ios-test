import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MusteriSiparislerimSayfasi extends StatefulWidget {
  const MusteriSiparislerimSayfasi({super.key});

  @override
  State<MusteriSiparislerimSayfasi> createState() => _MusteriSiparislerimSayfasiState();
}

class _MusteriSiparislerimSayfasiState extends State<MusteriSiparislerimSayfasi> {
  List<dynamic> siparisler = [];

  Future<void> siparisleriGetir() async {
    final prefs = await SharedPreferences.getInstance();
    final musteriId = prefs.getString('musteri_id');
    debugPrint("📦 SharedPreferences'tan musteri_id: $musteriId");

    if (musteriId == null) return;

    final response = await http.get(
      Uri.parse('https://www.yakauretimi.com/api/app_musteri_siparisler.php?musteri_id=$musteriId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        siparisler = data['siparisler'] ?? [];
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: ListView.builder(
        itemCount: siparisler.length,
        itemBuilder: (context, index) {
          final siparis = siparisler[index];
          final ref = siparis['ref'];
          final tutar = siparis['toplam_tutar'];
          final tarih = siparis['created_at'] ?? '';

          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🧾 Sipariş No: ${siparis['ref'] ?? 'Yok'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("📅 Tarih: ${siparis['created_at'] ?? 'Tarih yok'}"),
                  const SizedBox(height: 4),
                  Text("💳 Tutar: ${siparis['toplam_tutar']} ₺"),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/musteri_siparis_ozet", arguments: {
                          "ref": ref,
                        });
                      },
                      child: const Text("Sipariş Detayı"),
                    ),
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
