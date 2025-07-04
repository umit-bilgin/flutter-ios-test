import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SaticiSiparisOzetSayfasi extends StatefulWidget {
  final String refKodu;

  const SaticiSiparisOzetSayfasi({super.key, required this.refKodu});

  @override
  State<SaticiSiparisOzetSayfasi> createState() => _SaticiSiparisOzetSayfasiState();
}

class _SaticiSiparisOzetSayfasiState extends State<SaticiSiparisOzetSayfasi> {
  Map<String, dynamic>? siparis;
  bool yukleniyor = true;
  String? seciliDurum;

  final List<String> durumlar = [
    'Hazırlanıyor',
    'Kargoya Verildi',
    'Teslim Edildi',
    'İptal Edildi',
  ];

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  Future<void> _verileriGetir() async {
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_sepet_siparis_ozet_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.refKodu}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          siparis = data['siparis'];
          yukleniyor = false;
          seciliDurum = data['siparis']['durum'];
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

  Future<void> _durumGuncelle(String yeniDurum) async {
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_sepet_siparis_durum_guncelle_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.refKodu, 'yeni_durum': yeniDurum}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Durum güncellendi.")));
        setState(() {
          seciliDurum = yeniDurum;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Hata oluştu")));
      }
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

    final urunler = List<Map<String, dynamic>>.from(siparis!['urunler']['liste']);
    final musteriAdi = siparis!['ad'] ?? "-";
    final adres = siparis!['adres'] ?? "-";
    final telefon = siparis!['telefon'] ?? "-";
    final toplam = double.tryParse(siparis!['toplam_tutar'].toString()) ?? 0.0;
    final odemeTipi = siparis!['urunler']['odeme_tipi'] ?? "-";
    final not = siparis!['urunler']['not'] ?? "-";

    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Özeti (Satıcı)")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Referans Kodu: ${widget.refKodu.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Müşteri: $musteriAdi"),
              Text("Adres: $adres"),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse("tel:$telefon")),
                child: Text("Telefon: $telefon", style: const TextStyle(color: Colors.blue)),
              ),
              Text("Ödeme Tipi: $odemeTipi"),
              Text("Not: $not"),
              const Divider(height: 24),
              const Text("Ürünler:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...urunler.map((u) {
                final adet = int.tryParse(u['adet'].toString()) ?? 1;
                final fiyat = double.tryParse(u['fiyat'].toString()) ?? 0;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(u['urun_adi'] ?? 'Ürün'),
                  subtitle: Text("$adet x ₺${fiyat.toStringAsFixed(2)}"),
                  trailing: Text("₺${(adet * fiyat).toStringAsFixed(2)}"),
                );
              }).toList(),
              const Divider(height: 24),
              Row(
                children: [
                  const Text("Sipariş Durumu:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: seciliDurum,
                    items: durumlar.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (String? yeni) {
                      if (yeni != null) _durumGuncelle(yeni);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text("Toplam Tutar: ₺${toplam.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
