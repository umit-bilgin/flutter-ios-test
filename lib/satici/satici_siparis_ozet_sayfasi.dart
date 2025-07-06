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
  String? bilgiMesaji; // ✅ Yeni: Durum mesajı göstermek için
  Color? bilgiRenk;

  final Map<String, String> durumlar = {
    'beklemede': 'Beklemede',
    'onaylandı': 'Onaylandı',
    'hazir_yolda': 'Hazır Yolda',
    'iptal': 'İptal',
  };

  @override
  void initState() {
    super.initState();
    print("🔄 initState çalıştı");
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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          siparis = data['siparis'];
          seciliDurum = data['siparis']['durum'];
          yukleniyor = false;
        });
        print("✅ Sipariş geldi: $seciliDurum");
      } else {
        print("❌ Sipariş getirme başarısız: ${data['message']}");
        setState(() => yukleniyor = false);
      }
    } else {
      print("❌ HTTP hatası: ${response.statusCode}");
      setState(() => yukleniyor = false);
    }
  }

  Future<void> _gecmisGetir() async {
    print("📜 Durum geçmişi getiriliyor...");
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/islemler/fl_siparis_durum_gecmisi_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.ref}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          gecmis = data['gecmis'];
        });
        print("✅ Geçmiş geldi: ${gecmis.length} kayıt");
      } else {
        print("❌ Geçmiş getirme başarısız: ${data['message']}");
      }
    } else {
      print("❌ Geçmiş HTTP hatası: ${response.statusCode}");
    }
  }

  Future<void> _durumGuncelle(String yeniDurum) async {
    print("📤 Güncelleniyor: $yeniDurum");
    setState(() {
      bilgiMesaji = null;
    });

    print("📜 Durum geçmişi getiriliyor...");
    final response = await http.post(
      Uri.parse("https://www.yakauretimi.com/islemler/fl_siparis_durum_gecmisi_api.php"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ref': widget.ref}),
    );


    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          seciliDurum = yeniDurum;
          siparis!['durum'] = yeniDurum;
          bilgiMesaji = "'${durumlar[yeniDurum]}' olarak güncellendi";
          bilgiRenk = Colors.green[100];
        });
        await _gecmisGetir();
        print("✅ Güncellendi ve geçmiş yeniden yüklendi.");
      } else {
        setState(() {
          bilgiMesaji = "❌ ${data['message']}";
          bilgiRenk = Colors.red[100];
        });
        print("❌ API: ${data['message']}");
      }
    } else {
      setState(() {
        bilgiMesaji = "❌ Sunucuya ulaşılamadı";
        bilgiRenk = Colors.red[100];
      });
      print("❌ HTTP: ${response.statusCode}");
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
              }),

              const Divider(height: 30),

              Row(
                children: [
                  const Text("📦 Sipariş Durumu:"),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: seciliDurum,
                    items: durumlar.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (yeni) {
                      if (yeni != null && yeni != seciliDurum) {
                        _durumGuncelle(yeni);
                      }
                    },
                  ),
                ],
              ),

              // ✅ Mesaj kutucuğu
              if (bilgiMesaji != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bilgiRenk ?? Colors.yellow[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bilgiMesaji!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),

              const SizedBox(height: 20),
              Text("🧾 Toplam Tutar: ₺${toplam.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 30),
              if (gecmis.isNotEmpty) ...[
                const Text("📜 Durum Geçmişi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...gecmis.map((g) {
                  final tarih = g['tarih'] ?? '';
                  final onceki = g['eski_durum'] ?? '-';
                  final yeni = g['yeni_durum'] ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("📅 $tarih | $onceki ➜ $yeni"),
                  );
                }).toList(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
