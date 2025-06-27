import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BildirimlerimPage extends StatefulWidget {
  final int kullaniciId;
  const BildirimlerimPage({required this.kullaniciId});

  @override
  State<BildirimlerimPage> createState() => _BildirimlerimPageState();
}

class _BildirimlerimPageState extends State<BildirimlerimPage> {
  List bildirimler = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    fetchBildirimler();
  }

  Future<void> fetchBildirimler() async {
    try {
      final url = Uri.parse("https://www.yakauretimi.com/api/app_bildirimlerim.php?kullanici_id=${widget.kullaniciId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            bildirimler = data;
            yukleniyor = false;
          });
        }
      } else {
        throw Exception("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("🔴 Hata oluştu: $e");
      if (mounted) {
        setState(() {
          yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📬 Bildirimlerim")),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : bildirimler.isEmpty
          ? const Center(child: Text("Hiç bildirimin yok 📭"))
          : ListView.builder(
        itemCount: bildirimler.length,
        itemBuilder: (context, index) {
          final item = bildirimler[index];
          return Dismissible(
            key: Key(item['title']),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              // Silme işlemi
              final response = await http.post(
                Uri.parse("https://www.yakauretimi.com/api/app_bildirim_sil.php"),
                headers: {"Content-Type": "application/json"},
                body: json.encode({
                  "kullanici_id": widget.kullaniciId,
                  "title": item['title'],
                }),
              );

              if (response.statusCode == 200) {
                setState(() {
                  bildirimler.removeAt(index);
                });
                return true;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Silinemedi")),
                );
                return false;
              }
            },
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                color: item['okundu'] == 0 ? Colors.blue : Colors.grey,
              ),
              title: Text(
                item['title'],
                style: TextStyle(
                  fontWeight: item['okundu'] == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(item['body']),
              trailing: Text(item['created_at'].toString().substring(0, 16)),
              onTap: () async {
                // Okundu bilgisi gibi kalabilir burada
              },
            ),
          );
        },
      ),
    );
  }
}
