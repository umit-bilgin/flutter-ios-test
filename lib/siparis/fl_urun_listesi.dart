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
  Map<int, String?> bildirimMesajlari = {};
  double toplamFiyat = 0.0;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    urunleriGetir();
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
          bildirimMesajlari[urun['id']] = null;
        }
        yukleniyor = false;
      });
    } else {
      setState(() {
        yukleniyor = false;
        bildirimMesajlari[-1] = "Ürünler alınamadı.";
      });
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          bildirimMesajlari[-1] = null;
        });
      });
    }
  }

  void adetArttir(int urunId) {
    setState(() {
      adetler[urunId] = (adetler[urunId] ?? 0) + 1;
      hesaplaToplamFiyat();
    });
  }

  void adetAzalt(int urunId) {
    if ((adetler[urunId] ?? 0) > 0) {
      setState(() {
        adetler[urunId] = adetler[urunId]! - 1;
        hesaplaToplamFiyat();
      });
    }
  }

  void hesaplaToplamFiyat() {
    double yerelToplam = 0.0;
    for (var urun in urunler) {
      final int urunId = urun['id'] ?? 0;
      final double fiyat = double.tryParse(urun['price']?.toString() ?? "0") ?? 0.0;
      yerelToplam += (adetler[urunId] ?? 0) * fiyat;
    }
    setState(() {
      toplamFiyat = yerelToplam;
    });
  }

  Future<void> sepeteEkle(int urunId, int adet, double fiyat) async {
    if (adet == 0) {
      setState(() {
        bildirimMesajlari[urunId] = "Lütfen adet seçin";
      });
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          bildirimMesajlari[urunId] = null;
        });
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final kullaniciId = prefs.getInt('kullanici_id');
    if (kullaniciId == null) return;

    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/islemler/fl_urun_adet_guncelle_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': urunId,
        'adet': adet,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          bildirimMesajlari[urunId] = data['message'];
          adetler[urunId] = 0; // Sepete eklendi, yerel adet sıfırlansın
        });
      } else {
        setState(() {
          bildirimMesajlari[urunId] = data['message'] ?? "Ekleme başarısız.";
        });
      }
    } else {
      setState(() {
        bildirimMesajlari[urunId] = "Sunucu hatası.";
      });
    }
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        bildirimMesajlari[urunId] = null;
      });
    });
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
          final double fiyat = double.tryParse(urun['price']?.toString() ?? "0") ?? 0.0;
          final int stok = urun['in_stock'] ?? 0;
          final String? bildirim = bildirimMesajlari[urunId];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("₺${fiyat.toStringAsFixed(2)}"),
                  trailing: stok == 0
                      ? const Text("Stokta yok", style: TextStyle(color: Colors.red))
                      : Row(
                    mainAxisSize: MainAxisSize.min,
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
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () => sepeteEkle(urunId, adetler[urunId] ?? 0, fiyat),
                      ),
                    ],
                  ),
                ),
                if (bildirim != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
                    child: Text(
                      bildirim,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Toplam: ₺${toplamFiyat.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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