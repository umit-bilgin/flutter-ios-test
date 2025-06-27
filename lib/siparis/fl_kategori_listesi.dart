import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../siparis/fl_urun_listesi.dart';

class FlKategoriListesi extends StatefulWidget {
  const FlKategoriListesi({super.key});

  @override
  State<FlKategoriListesi> createState() => _FlKategoriListesiState();
}

class _FlKategoriListesiState extends State<FlKategoriListesi> {
  List<dynamic> kategoriler = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    kategorileriGetir();
  }

  Future<void> kategorileriGetir() async {
    print("➡️ API çağrıldı...");

    final response = await http.get(
      Uri.parse("https://www.yakauretimi.com/urunler/api/fl_kategori_listesi_api.php"),
    );

    print("📦 Gelen veri: ${response.body}");

    if (response.statusCode == 200) {
      final veri = json.decode(response.body);
      print("✅ Decode edildi: $veri");

      setState(() {
        kategoriler = veri['kategoriler'];
        yukleniyor = false;
      });
    } else {
      setState(() {
        yukleniyor = false;
      });
      print("❌ Hata: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kategoriler alınamadı.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kategoriler")),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3 / 2,
        ),
        itemCount: kategoriler.length,
        itemBuilder: (context, index) {
          final kategori = kategoriler[index];
          final kategoriId = kategori['id'];
          final kategoriAdi = kategori['name']?.toString() ?? "Kategori";
          final gorselUrl = kategori['gorsel']?.toString() ?? "";


          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlUrunListesiSayfasi(
                    kategoriId: kategoriId.toString(),
                    kategoriAdi: kategoriAdi,
                  ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  gorselUrl != null && gorselUrl.isNotEmpty
                      ? Image.network(
                    gorselUrl,
                    height: 60,
                    fit: BoxFit.contain,
                  )
                      : const Icon(Icons.category, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    kategoriAdi,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
