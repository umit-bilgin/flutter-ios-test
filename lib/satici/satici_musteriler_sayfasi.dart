import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaticiMusterilerSayfasi extends StatefulWidget {
  const SaticiMusterilerSayfasi({super.key});

  @override
  State<SaticiMusterilerSayfasi> createState() => _SaticiMusterilerSayfasiState();
}

class _SaticiMusterilerSayfasiState extends State<SaticiMusterilerSayfasi> {
  List<Map<String, dynamic>> musteriListesi = [];
  bool yukleniyor = true;

  // Yardımcı fonksiyon: aktif alanını int'e dönüştür
  int _parseAktif(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0; // null veya beklenmedik türler için varsayılan
  }

  Future<void> musterileriGetir() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.yakauretimi.com/api/app_satici_musteri_listesi_api.php'),
      );
      final data = json.decode(response.body) as List<dynamic>;

      // Veriyi standartlaştır
      final processedData = data.map((item) {
        return {
          ...item as Map<String, dynamic>,
          'aktif': _parseAktif(item['aktif']),
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        musteriListesi = List.from(processedData)
          ..sort((a, b) => (a['aktif'] as int).compareTo(b['aktif'] as int));
        yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        yukleniyor = false;
      });
      debugPrint("❌ Veri çekme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Müşteri verileri alınamadı.")),
      );
    }
  }

  Future<void> musteriOnayla(String kullaniciId) async {
    try {
      print("Gönderilen: {'kullanici_id': '$kullaniciId'}");
      final response = await http.post(
        Uri.parse('https://www.yakauretimi.com/api/app_musteri_onayla.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'kullanici_id': kullaniciId}),
      );
      // 🔍 Hata ayıklama satırları (buraya EKLE)

      final result = json.decode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'İşlem tamamlandı.')),
      );
      await musterileriGetir();
    } catch (e) {
      print("Hata: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    musterileriGetir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Listesi')),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : musteriListesi.isEmpty
          ? const Center(child: Text('Müşteri bulunamadı.'))
          : ListView.builder(
        itemCount: musteriListesi.length,
        itemBuilder: (context, index) {
          final musteri = musteriListesi[index];
          final onayli = musteri['aktif'] == 1; // int karşılaştırması

          return Dismissible(
            key: Key(musteri['id']?.toString() ?? index.toString()),
            direction: onayli ? DismissDirection.none : DismissDirection.endToStart,
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Onayla"),
                  content: const Text("Bu müşteriyi onaylamak istiyor musunuz?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("İptal"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Onayla"),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await musteriOnayla(musteri['id'].toString());
              }
              return confirmed ?? false;
            },
            onDismissed: (_) {
              setState(() {
                musteriListesi.removeAt(index); // onaylandıktan sonra listeden sil
              });
            },
            child: Card(
              color: onayli ? Colors.green.shade50 : null,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(musteri['ad'] ?? 'İsimsiz'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Telefon: ${musteri['telefon'] ?? 'Bilinmiyor'}'),
                    Text('Adres: ${musteri['adres'] ?? 'Bilinmiyor'}'),
                  ],
                ),
                trailing: onayli
                    ? const Icon(Icons.verified, color: Colors.green)
                    : const Icon(Icons.pending, color: Colors.orange),
              ),
            ),
          );

        },
      ),
    );
  }
}