import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FlKampanyaOlustur extends StatefulWidget {
  @override
  _FlKampanyaOlusturState createState() => _FlKampanyaOlusturState();
}

class _FlKampanyaOlusturState extends State<FlKampanyaOlustur> {
  final TextEditingController _baslikController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _aramaController = TextEditingController();
  List<dynamic> aramaSonuclari = [];
  List<int> secilenUrunler = [];
  File? secilenGorsel;
  String? yuklenenGorselAdi;
  bool loading = false;

  Future<void> _urunAra(String query) async {
    print("🟡 Arama başlıyor: $query");

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/kampanyalar/api/fl_kampanya_olustur_urun_ara_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"query": query}),
    );

    print("🔵 StatusCode: ${response.statusCode}");
    print("🔵 Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true && data["urunler"] != null) {
        setState(() {
          aramaSonuclari = data["urunler"];
        });
        print("✅ ${aramaSonuclari.length} ürün bulundu");
      } else {
        setState(() {
          aramaSonuclari = [];
        });
        print("⚠️ Başarısız cevap ya da ürün yok");
      }
    } else {
      print("🔴 Arama isteği başarısız: ${response.statusCode}");
    }
  }


  Future<void> _gorselSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        secilenGorsel = File(picked.path);
      });
    }
  }

  Future<String?> _gorselYukle(File dosya) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://www.yakauretimi.com/kampanyalar/api/fl_kampanya_gorsel_yukle_api.php'),
    );
    request.files.add(await http.MultipartFile.fromPath('gorsel', dosya.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    if (data["success"] == true) {
      return data["filename"];
    } else {
      return null;
    }
  }

  Future<void> _kampanyaKaydet() async {
    setState(() => loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? kullaniciId = prefs.getInt("kullanici_id");

    if (kullaniciId == null || secilenUrunler.isEmpty) {
      setState(() => loading = false); // 💡 loader'ı durdur
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eksik bilgi!")));
      return;
    }


    // Görseli önce yükle
    if (secilenGorsel != null) {
      yuklenenGorselAdi = await _gorselYukle(secilenGorsel!);
    }

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/kampanyalar/api/fl_kampanya_olustur_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "satici_id": kullaniciId,
        "baslik": _baslikController.text,
        "aciklama": _aciklamaController.text,
        "gorsel": yuklenenGorselAdi ?? "",
        "urunler": secilenUrunler,
      }),
    );

    final data = jsonDecode(response.body);
    setState(() => loading = false);

    if (data["success"] == true) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Kampanya Oluşturuldu"),
          content: Text("İşlem başarıyla tamamlandı."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog kapat
                Navigator.pushReplacementNamed(context, '/fl_kampanya_listesi');
              },
              child: Text("Kampanyalara Git"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // dialog kapat
                setState(() {
                  _baslikController.clear();
                  _aciklamaController.clear();
                  aramaSonuclari = [];
                  secilenUrunler = [];
                  secilenGorsel = null;
                });
              },
              child: Text("Yeni Oluştur"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kampanya Oluştur")),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: ListView(
          children: [
            TextField(
              controller: _baslikController,
              decoration: InputDecoration(labelText: "Başlık"),
            ),
            TextField(
              controller: _aciklamaController,
              decoration: InputDecoration(labelText: "Açıklama"),
              maxLines: 3,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _gorselSec,
              icon: Icon(Icons.image),
              label: Text("Görsel Seç"),
            ),
            if (secilenGorsel != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Image.file(secilenGorsel!, height: 100),
              ),
            SizedBox(height: 20),
            TextField(
              controller: _aramaController,
              decoration: InputDecoration(labelText: "Ürün Ara"),
              onChanged: (text) {
                if (text.length >= 2) _urunAra(text);
              },
            ),
            ...aramaSonuclari.map((urun) {
              final String? image = urun['image'];

              return ListTile(
                leading: Image.network(
                  "https://www.yakauretimi.com/products/$image",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
                title: Text(urun["title"]),
                subtitle: Text("₺ ${urun["price"]}"),
                trailing: Checkbox(
                  value: secilenUrunler.contains(urun["id"]),
                  onChanged: (bool? secildi) {
                    setState(() {
                      if (secildi == true) {
                        secilenUrunler.add(urun["id"]);
                      } else {
                        secilenUrunler.remove(urun["id"]);
                      }
                    });
                  },
                ),
              );
            }),

            SizedBox(height: 20),
            loading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _kampanyaKaydet,
              child: Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
