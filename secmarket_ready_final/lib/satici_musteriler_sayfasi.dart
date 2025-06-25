import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaticiMusterilerSayfasi extends StatefulWidget {
  const SaticiMusterilerSayfasi({super.key});

  @override
  State<SaticiMusterilerSayfasi> createState() => _SaticiMusterilerSayfasiState();
}

class _SaticiMusterilerSayfasiState extends State<SaticiMusterilerSayfasi> {
  List musteriListesi = [];
  bool yukleniyor = true;

  Future<void> musterileriGetir() async {
    final response = await http.get(
      Uri.parse('https://yakauretimi.com/api/app_satici_musteriler.php'),
    );

    final data = json.decode(response.body);
    if (!mounted) return;
    setState(() {
      musteriListesi = data;
      yukleniyor = false;
    });
  }

  @override
  void initState() {
    super.initState();
    musterileriGetir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Listesi')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : musteriListesi.isEmpty
          ? const Center(child: Text('Müşteri bulunamadı.'))
          : ListView.builder(
        itemCount: musteriListesi.length,
        itemBuilder: (context, index) {
          final musteri = musteriListesi[index];
          return ListTile(
            title: Text(musteri['ad'] ?? 'İsimsiz'),
            subtitle: Text('Telefon: ${musteri['telefon']}'),
          );
        },
      ),
    );
  }
}
