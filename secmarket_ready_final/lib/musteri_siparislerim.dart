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
          return Card(
            child: ListTile(
              title: Text("#${siparis['ref'] ?? 'Referans Yok'}"),
              subtitle: Text("Tutar: ${siparis['toplam_tutar']} ₺\nÜrünler: ${siparis['urunler']}"),
            ),
          );
        },
      ),
    );
  }
}
