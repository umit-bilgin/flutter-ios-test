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
      await _sepetiGetir();
    }
  }

  Future<void> _sepetiGetir() async {
    if (kullaniciId == null) return;
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
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        loading = false;
      });
    }
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
    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/islemler/fl_urun_adet_guncelle_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': productId,
        'adet': yeniAdet, // Mevcut adede ekleme için API'de düzenleme gerekli
      }),
    );
    if (response.statusCode == 200) {
      await _sepetiGetir();
    }
  }

  Future<void> _urunSil(String productId) async {
    if (kullaniciId == null) return;
    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_urun_sil_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': productId,
      }),
    );
    if (response.statusCode == 200) {
      await _sepetiGetir();
    }
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
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : sepetUrunleri.isEmpty
                ? const Center(child: Text("Sepetiniz boş"))
                : ListView.builder(
              itemCount: sepetUrunleri.length,
              itemBuilder: (context, index) {
                final urun = sepetUrunleri[index];
                final String? gorsel = urun['image'] != null && urun['image'].toString().isNotEmpty
                    ? 'https://www.yakauretimi.com/products/${urun['image']}'
                    : null;
                final double fiyat = double.tryParse(urun['price']?.toString() ?? urun['fiyat']?.toString() ?? "0") ?? 0.0;
                final int adet = int.tryParse(urun['adet']?.toString() ?? "1") ?? 1;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: gorsel != null
                        ? Image.network(gorsel, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image, size: 40, color: Colors.grey);
                    })
                        : const Icon(Icons.image, size: 40, color: Colors.grey),
                    title: Text(urun['title'] ?? urun['urun_adi'] ?? "Ürün adı"),
                    subtitle: Text("${adet} x ${fiyat.toStringAsFixed(2)} ₺ = ${(adet * fiyat).toStringAsFixed(2)} ₺"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () async {
                            if (adet > 1) {
                              await _adetGuncelle(urun['urun_id'] ?? urun['product_id'], adet - 1);
                            }
                          },
                        ),
                        Text('$adet'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            await _adetGuncelle(urun['urun_id'] ?? urun['product_id'], adet + 1);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _urunSil(urun['urun_id'] ?? urun['product_id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
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
              ],
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}