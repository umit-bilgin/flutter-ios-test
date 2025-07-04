import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../siparis/fl_siparis_ver_sonuc.dart';
import '../siparis/widget/sepet_urun_karti.dart';
import '../siparis/service/sepet_service.dart';

class FlSepetSayfasi extends StatefulWidget {
  const FlSepetSayfasi({super.key});

  @override
  State<FlSepetSayfasi> createState() => _FlSepetSayfasiState();
}

class _FlSepetSayfasiState extends State<FlSepetSayfasi> {
  List<dynamic> sepetUrunleri = [];
  bool loading = true;
  int? kullaniciId;
  double toplamFiyat = 0.0;
  TextEditingController notController = TextEditingController();
  String odemeTipi = "Nakit";

  @override
  void initState() {
    super.initState();
    _loadKullaniciId();
  }

  Future<void> _loadKullaniciId() async {
    final prefs = await SharedPreferences.getInstance();
    kullaniciId = prefs.getInt('kullanici_id');
    if (kullaniciId != null) {
      await _sepetiGetir();
    }
  }

  Future<void> _sepetiGetir() async {
    if (kullaniciId == null) return;
    setState(() {
      loading = true;
    });

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_listele_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'kullanici_id': kullaniciId}),
    );

    if (response.statusCode == 200) {
      final veri = jsonDecode(response.body);
      if (veri['success']) {
        setState(() {
          sepetUrunleri = veri['sepet'];
          toplamFiyat = _toplamFiyatHesapla();
        });
      }
    }
    setState(() {
      loading = false;
    });
  }

  double _toplamFiyatHesapla() {
    double toplam = 0.0;
    for (var urun in sepetUrunleri) {
      final fiyat = double.tryParse(urun['price']?.toString() ?? urun['fiyat']?.toString() ?? "0") ?? 0.0;
      final adet = int.tryParse(urun['adet']?.toString() ?? "1") ?? 1;
      toplam += fiyat * adet;
    }
    return toplam;
  }

  Future<void> _adetGuncelle(String productId, int yeniAdet) async {
    if (kullaniciId == null) return;

    final basarili = await SepetService.adetGuncelle(kullaniciId!, productId, yeniAdet);
    if (basarili) {
      await _sepetiGetir();
    }
  }

  Future<void> _urunSil(String productId) async {
    if (kullaniciId == null) return;

    final basarili = await SepetService.urunSil(kullaniciId!, productId);
    if (basarili) {
      await _sepetiGetir();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : sepetUrunleri.isEmpty
                ? const Center(child: Text("Sepetiniz boş"))
                : ListView.builder(
              itemCount: sepetUrunleri.length,
              itemBuilder: (context, index) {
                final urun = sepetUrunleri[index];
                final urunId = urun['urun_id']?.toString() ?? urun['product_id'].toString();

                return SepetUrunKarti(
                  urun: urun,
                  onAdetGuncelle: (yeniAdet) async {
                    await _adetGuncelle(urunId, yeniAdet);
                  },
                  onUrunSil: () async {
                    await _urunSil(urunId);
                  },
                );
              },
            ),
          ),
          if (!loading && sepetUrunleri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  Text(
                    "Toplam Tutar: ₺${toplamFiyat.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Sipariş Notu",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Ödeme Tipi: "),
                      DropdownButton<String>(
                        value: odemeTipi,
                        items: const [
                          DropdownMenuItem(value: "Nakit", child: Text("Nakit")),
                          DropdownMenuItem(value: "Banka Kartı", child: Text("Banka Kartı")),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              odemeTipi = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Geri
                        },
                        child: const Text("Alışverişe Devam Et"),
                      ),
                      ElevatedButton(
                        onPressed: kullaniciId == null || sepetUrunleri.isEmpty
                            ? null
                            : () async {
                          final response = await http.post(
                            Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_siparis_ver_api.php'),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode({
                              'musteri_id': kullaniciId,
                              'urunler': sepetUrunleri.map((urun) => {
                                'urun_id': urun['urun_id'],
                                'adet': urun['adet'],
                                'fiyat': urun['price'] ?? urun['fiyat'],
                              }).toList(),
                              'toplam_tutar': toplamFiyat,
                              'odeme_tipi': odemeTipi,
                              'not': notController.text,
                            }),
                          );

                          final jsonData = jsonDecode(response.body);
                          if (jsonData['success']) {
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FlSiparisVerSonuc(refKodu: jsonData['ref']),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(jsonData['message'] ?? "Bir hata oluştu"),
                              ),
                            );
                          }
                        },
                        child: const Text("Siparişi Tamamla"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
