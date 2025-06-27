import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class SaticiSiparislerSayfasi extends StatefulWidget {
  const SaticiSiparislerSayfasi({super.key});

  @override
  State<SaticiSiparislerSayfasi> createState() => _SaticiSiparislerSayfasiState();
}

class _SaticiSiparislerSayfasiState extends State<SaticiSiparislerSayfasi> {
  List siparisler = [];
  bool yukleniyor = true;

  Future<void> siparisleriGetir() async {
    final prefs = await SharedPreferences.getInstance();
    final saticiId = prefs.getString('musteri_id') ?? '';
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('https://www.yakauretimi.com/api/app_satici_siparisler.php?satici_id=$saticiId'),
    );

    final data = json.decode(response.body);
    if (!mounted) return;
    setState(() {
      siparisler = data.map((siparis) {
        siparis['token'] = token; // her siparişe token ekliyoruz
        return siparis;
      }).toList();
      yukleniyor = false;
    });
  }

  @override
  void initState() {
    super.initState();
    siparisleriGetir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gelen Siparişler')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : siparisler.isEmpty
          ? const Center(child: Text('Hiç sipariş bulunamadı.'))
          : ListView.builder(
        itemCount: siparisler.length,
        itemBuilder: (context, index) {
          final siparis = siparisler[index];
          final ref = siparis['ref'];
          final token = siparis['token'];
          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 Müşteri: ${siparis['ad']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("📍 Adres: ${siparis['adres']}"),
                  const SizedBox(height: 4),
                  Text("💳 Tutar: ${siparis['toplam_tutar']} ₺"),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final detayUrl = 'https://www.yakauretimi.com/siparis-detay.php?ref=$ref&token=$token';

                        print("👉 DETAY URL: $detayUrl");


                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewSiparisDetay(url: detayUrl),
                          ),
                        );
                      },

                      child: const Text("Sipariş Detayı"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WebViewSiparisDetay extends StatelessWidget {
  final String url;

  const WebViewSiparisDetay({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Detayı")),
      body: WebViewWidget(controller: controller),
    );
  }
}
