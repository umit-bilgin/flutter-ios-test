import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SaticiSiparisOzetSayfasi extends StatefulWidget {
  final String ref;

  const SaticiSiparisOzetSayfasi({super.key, required this.ref});

  @override
  State<SaticiSiparisOzetSayfasi> createState() => _SaticiSiparisOzetSayfasiState();
}

class _SaticiSiparisOzetSayfasiState extends State<SaticiSiparisOzetSayfasi> {
  Map<String, dynamic>? siparis;
  bool yukleniyor = true;
  String? seciliDurum;
  List<dynamic> gecmis = [];

  final Map<String, String> durumlar = {
    'beklemede': 'Beklemede',
    'onaylandı': 'Onaylandı',
    'hazir_yolda': 'Hazır Yolda',
    'iptal': 'İptal',
  };

  @override
  void initState() {
    super.initState();
    print("🔄 initState çalıştı, veriler getiriliyor...");
    _verileriGetir();
    _gecmisGetir();
  }

  Future<void> _verileriGetir() async {
    print("📦 Sipariş verisi çekiliyor...");
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_satici_siparis_ozet_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.ref}),
    );

    print("📦 GET yanıt kodu: ${response.statusCode}");
    print("📦 Yanıt içeriği: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          siparis = data['siparis'];
          seciliDurum = data['siparis']['durum'];
          yukleniyor = false;
        });
        print("✅ Sipariş başarıyla yüklendi. Durum: $seciliDurum");
      } else {
        print("❌ Başarısız: ${data['message']}");
        setState(() => yukleniyor = false);
      }
    } else {
      print("❌ Sunucu hatası");
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _gecmisGetir() async {
    print("📜 Durum geçmişi çekiliyor...");
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_siparis_durum_gecmisi_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.ref}),
    );

    print("📜 GEÇMİŞ yanıt kodu: ${response.statusCode}");
    print("📜 Geçmiş içeriği: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          gecmis = data['gecmis'];
        });
        print("✅ Geçmiş başarıyla yüklendi, ${gecmis.length} kayıt");
      } else {
        print("❌ Geçmiş yüklenemedi: ${data['message']}");
      }
    }
  }

  Future<void> _durumGuncelle(String yeniDurum) async {
    print("📤 Durum güncelleme başlatıldı: $yeniDurum");
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/sepet/api/fl_sepet_siparis_durum_guncelle_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.ref, 'yeni_durum': yeniDurum}),
    );

    print("📤 GÜNCELLE yanıt kodu: ${response.statusCode}");
    print("📤 Yanıt: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ '${durumlar[yeniDurum]}' olarak güncellendi.")),
        );
        setState(() {
          seciliDurum = yeniDurum;
          siparis!['durum'] = yeniDurum;
        });
        _gecmisGetir();
        print("✅ Güncelleme tamamlandı.");
      } else {
        print("❌ API başarısız: ${data['message']}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${data['message']}")),
        );
      }
    } else {
      print("❌ HTTP hatası: ${response.statusCode}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Sunucuya ulaşılamadı")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (siparis == null) {
      return const Scaffold(body: Center(child: Text("❌ Sipariş bulunamadı")));
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
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Referans: ${widget.ref.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("👤 Müşteri: $musteriAdi"),
              const SizedBox(height: 4),
              Text("📍 Adres: $adres"),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse("tel:$telefon")),
                child: Text("📞 Telefon: $telefon", style: const TextStyle(color: Colors.blue)),
              ),
              const SizedBox(height: 4),
              Text("📝 Not: $not"),
              Text("💳 Ödeme Tipi: $odemeTipi"),
              const Divider(height: 30),
              ...urunler.map((u) {
                final adet = int.tryParse(u['adet'].toString()) ?? 1;
                final fiyat = double.tryParse(u['fiyat'].toString()) ?? 0;
                final urunAdi = u['urun_adi'] ?? 'Ürün';
                final gorsel = u['gorsel'] ?? '';
                final url = gorsel.isNotEmpty ? 'https://www.yakauretimi.com/products/$gorsel' : '';

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: url.isNotEmpty
                        ? Image.network(url, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported),
                  ),
                  title: Text(urunAdi),
                  subtitle: Text("$adet x ₺${fiyat.toStringAsFixed(2)}"),
                  trailing: Text("₺${(adet * fiyat).toStringAsFixed(2)}"),
                );
              }).toList(),

              const Divider(height: 30),
              Row(
                children: [
                  const Text("📦 Sipariş Durumu:"),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: seciliDurum,
                    items: durumlar.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (yeni) {
                      if (yeni != null && yeni != seciliDurum) {
                        _durumGuncelle(yeni);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text("🧾 Toplam Tutar: ₺${toplam.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 30),
              if (gecmis.isNotEmpty) ...[
                const Text("📜 Durum Geçmişi", style: TextStyle(fontWeight: FontWeight.bold)),
                ...gecmis.map((g) {
                  final t = g['tarih'] ?? '';
                  final o = g['eski_durum'] ?? '-';
                  final y = g['yeni_durum'] ?? '-';
                  return Text("📅 $t | $o ➜ $y");
                }).toList()
              ]
            ],
          ),
        ),
      ),
    );
  }
}
