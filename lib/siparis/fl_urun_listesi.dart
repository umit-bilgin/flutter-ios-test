import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class FlUrunListesiSayfasi extends StatefulWidget {
  final String kategoriId;
  final String kategoriAdi;

  const FlUrunListesiSayfasi({
    super.key,
    required this.kategoriId,
    required this.kategoriAdi,
  });

  @override
  State<FlUrunListesiSayfasi> createState() => _FlUrunListesiSayfasiState();
}

class _FlUrunListesiSayfasiState extends State<FlUrunListesiSayfasi> {
  List<dynamic> urunler = [];
  Map<int, int> adetler = {};
  double toplamFiyat = 0;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    urunleriGetir();
    toplamFiyatiGetir(); // sepetteki toplam fiyatı al
  }
  Future<void> getSepetToplami() async {
    final prefs = await SharedPreferences.getInstance();
    final kullaniciId = prefs.getInt('kullanici_id');
    if (kullaniciId == null) return;

    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_sepet_toplam_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'kullanici_id': kullaniciId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        toplamFiyat = double.tryParse(data['toplam'].toString()) ?? 0;
      });
    }
  }

  Future<void> urunleriGetir() async {
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/urunler/api/fl_urun_listesi_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'kategori_id': widget.kategoriId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        urunler = data['urunler'];
        for (var urun in urunler) {
          adetler[urun['id']] = 0;
        }
        yukleniyor = false;
      });
    } else {
      setState(() {
        yukleniyor = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ürünler alınamadı.")),
      );
    }
  }

  void adetArttir(int urunId) {
    setState(() {
      adetler[urunId] = (adetler[urunId] ?? 0) + 1;
    });
  }

  void adetAzalt(int urunId) {
    if ((adetler[urunId] ?? 0) > 0) {
      setState(() {
        adetler[urunId] = adetler[urunId]! - 1;
      });
    }
  }


  Future<void> sepeteEkle(int urunId, int adet, double fiyat) async {
    if (adet == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen adet seçin")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final kullaniciId = prefs.getInt('kullanici_id');
    if (kullaniciId == null) return;

    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_urun_sepete_ekle_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': urunId,
        'adet': adet,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        adetler[urunId] = 0;
      });
      await toplamFiyatiGetir(); // Toplam fiyatı güncelle
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ürün sepete eklendi")),
      );
    }
  }
  Future<void> toplamFiyatiGetir() async {
    final prefs = await SharedPreferences.getInstance();
    final kullaniciId = prefs.getInt('kullanici_id');
    if (kullaniciId == null) return;

    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_sepet_toplam_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'kullanici_id': kullaniciId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['toplam'] != null) {
        setState(() {
          toplamFiyat = double.tryParse(data['toplam'].toString()) ?? 0;
        });
      }
    } else {
      print("🔴 Toplam API başarısız: ${response.statusCode}");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.kategoriAdi)),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: urunler.length,
          itemBuilder: (context, index) {
            final urun = urunler[index];
            final int urunId = urun['id'] ?? 0;
            final String ad = urun['title']?.toString() ?? "Ürün adı";
            final String gorsel = urun['image'] != null && urun['image'].toString().isNotEmpty
                ? 'https://www.yakauretimi.com/products/${urun['image']}'
                : '';
            final double fiyat = double.tryParse(urun['price']?.toString() ?? "0") ?? 0;
            final int stok = urun['in_stock'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SizedBox(
                height: 120, // Genel yüksekliği kontrol etmek için
                child: Row(
                  children: [
                    // Görsel kısmı
                    AspectRatio(
                      aspectRatio: 1, // Kareye yakın tutar ama esner
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        child: Image.network(
                          gorsel,
                          fit: BoxFit.cover, // 🔥 Buradaki kilit nokta bu
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, size: 40, color: Colors.grey);
                          },
                        ),
                      ),
                    ),

                    // Ürün detayları
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("₺${fiyat.toStringAsFixed(2)}"),
                            const SizedBox(height: 4),
                            stok == 0
                                ? const Text("Stokta yok", style: TextStyle(color: Colors.red))
                                : Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => adetAzalt(urunId),
                                ),
                                Text('${adetler[urunId]}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => adetArttir(urunId),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sepete ekle ikonu
                    stok == 0
                        ? const SizedBox(width: 48)
                        : IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => sepeteEkle(urunId, adetler[urunId] ?? 0, fiyat),
                    ),
                  ],
                ),
              ),
            );
          }
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Toplam: ₺${toplamFiyat.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/fl_sepet_sayfasi");
              },
              child: const Text("Sepete Git"),
            ),
          ],
        ),
      ),
    );
  }
}
