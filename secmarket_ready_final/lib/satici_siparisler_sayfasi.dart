import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaticiSiparislerSayfasi extends StatefulWidget {
  const SaticiSiparislerSayfasi({super.key});

  @override
  State<SaticiSiparislerSayfasi> createState() => _SaticiSiparislerSayfasiState();
}

class _SaticiSiparislerSayfasiState extends State<SaticiSiparislerSayfasi> {
  List siparisler = [];
  bool yukleniyor = true;

  Future<void> siparisleriGetir() async {
    final prefs = await SharedPreferences.getInstance();
    final saticiId = prefs.getString('musteri_id') ?? '';

    final response = await http.get(
      Uri.parse('https://www.yakauretimi.com/api/app_satici_siparisler.php?satici_id=$saticiId'),
    );

    final data = json.decode(response.body);
    if (!mounted) return;
    setState(() {
      siparisler = data;
      yukleniyor = false;
    });
  }

  @override
  void initState() {
    super.initState();
    siparisleriGetir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gelen Siparişler')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : siparisler.isEmpty
          ? const Center(child: Text('Hiç sipariş bulunamadı.'))
          : ListView.builder(
        itemCount: siparisler.length,
        itemBuilder: (context, index) {
          final siparis = siparisler[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('#${siparis['ref']} - ${siparis['toplam_tutar']} ₺'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Müşteri: ${siparis['musteri_id']}'),
                  Text('Ürünler: ${siparis['urunler']}'),
                  Text('Durum: ${siparis['durum']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
