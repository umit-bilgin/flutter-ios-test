import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../siparis/widget/urun_karti.dart';
import '../siparis/service/sepet_service.dart';

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
    sepetToplamiYenile();
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

  Future<void> sepetToplamiYenile() async {
    final toplam = await SepetService.toplamFiyatiGetir();
    setState(() {
      toplamFiyat = toplam;
    });
  }

  Future<void> sepeteEkle(int urunId, int adet) async {
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

    final mesaj = await SepetService.sepeteEkle(urunId, adet);

    setState(() {
      bildirimMesajlari[urunId] = mesaj;
      adetler[urunId] = 0;
    });

    await sepetToplamiYenile();

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
          final urunId = urun['id'] ?? 0;

          return UrunKarti(
            urun: urun,
            onSepeteEklendi: () => sepetToplamiYenile(),
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
