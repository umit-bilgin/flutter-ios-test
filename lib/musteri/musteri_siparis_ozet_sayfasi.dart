import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MusteriSiparisOzetSayfasi extends StatefulWidget {
  final String ref;

  const MusteriSiparisOzetSayfasi({super.key, required this.ref});

  @override
  State<MusteriSiparisOzetSayfasi> createState() => _MusteriSiparisOzetSayfasiState();
}

class _MusteriSiparisOzetSayfasiState extends State<MusteriSiparisOzetSayfasi> {
  Map<String, dynamic>? siparis;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_musteri_siparis_ozet_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.ref}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          siparis = data['siparis'];
          yukleniyor = false;
        });
      } else {
        setState(() {
          yukleniyor = false;
        });
      }
    } else {
      setState(() {
        yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (siparis == null) {
      return const Scaffold(
        body: Center(child: Text("Sipariş bulunamadı")),
      );
    }

    final List urunler = List.from(siparis!['urunler'] ?? []);
    final String musteriAdi = siparis!['ad'] ?? "-";
    final String adres = siparis!['adres'] ?? "-";
    final String telefon = siparis!['telefon'] ?? "-";
    final String not = siparis!['not'] ?? "-";
    final String odemeTipi = siparis!['odeme_tipi'] ?? "-";
    final double toplam = double.tryParse(siparis!['toplam_tutar'].toString()) ?? 0.0;
    final String durum = siparis!['durum'] ?? "-";

    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Özeti")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Referans Kodu: ${widget.ref.toUpperCase()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text("Ad: $musteriAdi"),
              Text("Adres: $adres"),

              Text(
                "Sipariş Durumu: $durum",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const Divider(height: 24),
              const Text("Ürünler:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...urunler.map((u) {
                final adet = int.tryParse(u['adet']?.toString() ?? '1') ?? 1;
                final fiyat = double.tryParse(u['fiyat']?.toString() ?? '0') ?? 0;
                final urunAdi = u['title']?.toString() ?? 'Ürün';
                final gorsel = (u['image'] != null && u['image'].toString().isNotEmpty)
                    ? 'https://www.yakauretimi.com/products/${u['image']}'
                    : '';

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: gorsel.isNotEmpty
                          ? DecorationImage(image: NetworkImage(gorsel), fit: BoxFit.cover)
                          : null,
                    ),
                    child: gorsel.isEmpty
                        ? const Icon(Icons.image_not_supported, size: 24, color: Colors.grey)
                        : null,
                  ),
                  title: Text(urunAdi),
                  subtitle: Text(
                    "$adet x ₺${fiyat.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Text(
                    "₺${(adet * fiyat).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                );
              }).toList(),

              const Divider(height: 24),
              Text("Not: $not"),
              Text("Ödeme Tipi: $odemeTipi"),
              const SizedBox(height: 12),
              Text(
                "Toplam Tutar: ₺${toplam.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
