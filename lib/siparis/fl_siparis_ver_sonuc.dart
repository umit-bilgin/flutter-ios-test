import 'package:flutter/material.dart';

class FlSiparisVerSonuc extends StatelessWidget {
  final String refKodu;

  const FlSiparisVerSonuc({super.key, required this.refKodu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Başarılı")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Siparişiniz başarıyla alındı!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Referans Kodu: $refKodu",
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, "/fl_musteri_siparislerim");
              },
              icon: const Icon(Icons.list),
              label: const Text("Siparişlerime Git"),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, "/musteri_panel", (route) => false);
              },
              icon: const Icon(Icons.home),
              label: const Text("Ana Sayfaya Dön"),
            ),
          ],
        ),
      ),
    );
  }
}
