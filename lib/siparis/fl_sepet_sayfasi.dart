import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../siparis/fl_siparis_ver_sonuc.dart';

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

  @override
  void initState() {
    super.initState();
    _loadKullaniciId();
  }

  Future<void> _loadKullaniciId() async {
    final prefs = await SharedPreferences.getInstance();
    kullaniciId = prefs.getInt('kullanici_id');
    if (kullaniciId != null) {
      _sepetiGetir();
    }
  }

  Future<void> _sepetiGetir() async {
    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_listele_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'kullanici_id': kullaniciId}),
    );
    double toplamFiyat = 0;

    for (var urun in sepetUrunleri) {
      double fiyat = double.tryParse(urun['fiyat'].toString()) ?? 0;
      int adet = int.tryParse(urun['adet'].toString()) ?? 0;
      toplamFiyat += fiyat * adet;
    }

    if (response.statusCode == 200) {
      final veri = jsonDecode(response.body);
      if (veri['success']) {
        setState(() {
          sepetUrunleri = veri['urunler'];
          toplamFiyat = _toplamFiyatHesapla();
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    }
  }

  double _toplamFiyatHesapla() {
    double toplam = 0.0;
    for (var urun in sepetUrunleri) {
      final fiyat = double.tryParse(urun['price'].toString()) ?? 0.0;
      final adet = int.tryParse(urun['adet'].toString()) ?? 1;
      toplam += fiyat * adet;
    }
    return toplam;
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController notController = TextEditingController();
    String odemeTipi = "Nakit";

    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(

              itemCount: sepetUrunleri.length,
              itemBuilder: (context, index) {
                final urun = sepetUrunleri[index];
                return ListTile(
                  title: Text(urun['urun_adi']),
                  subtitle: Text("${urun['adet']} x ${urun['fiyat']} ₺"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Toplam Tutar: ₺${toplamFiyat.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          final yeniAdet = (int.tryParse(urun['adet'].toString()) ?? 1) - 1;
                          if (yeniAdet >= 1) {
                            await _adetGuncelle(urun['product_id'], yeniAdet);
                          } else {
                            await _urunSil(urun['product_id']);
                          }
                        },
                      ),

                      Text('${urun['adet']}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final yeniAdet = (int.tryParse(urun['adet'].toString()) ?? 1) + 1;
                          await _adetGuncelle(urun['product_id'], yeniAdet);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _urunSil(urun['product_id']);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: notController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Sipariş Notu",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
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
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_siparis_ver_api.php'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'kullanici_id': kullaniciId,
                  'not': notController.text,
                  'odeme_tipi': odemeTipi,
                }),
              );

              final jsonData = jsonDecode(response.body);
              if (jsonData['success']) {
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlSiparisVerSonuc(refKodu: jsonData['ref_kodu']),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(jsonData['message'] ?? "Bir hata oluştu")),
                );
              }
            },
            child: const Text("Siparişi Tamamla"),
          ),

        ],
      ),
    );
  }
  Future<void> _adetGuncelle(String productId, int yeniAdet) async {
    await http.post(
      Uri.parse('https://www.yakauretimi.com/islemler/fl_urun_adet_guncelle_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': productId,
        'adet': yeniAdet,
      }),
    );
    _sepetiGetir();
  }

  Future<void> _urunSil(String productId) async {
    await http.post(
      Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_urun_sil_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': productId,
      }),
    );
    _sepetiGetir();
  }
}
