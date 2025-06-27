import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FlKampanyaListesi extends StatefulWidget {
  @override
  _FlKampanyaListesiState createState() => _FlKampanyaListesiState();
}

class _FlKampanyaListesiState extends State<FlKampanyaListesi> {
  List<dynamic> kampanyalar = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _kampanyalariGetir();
  }

  Future<void> _kampanyalariGetir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? kullaniciId = prefs.getInt("kullanici_id");

    if (kullaniciId == null) return;

    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/kampanyalar/api/fl_kampanya_listesi_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"kullanici_id": kullaniciId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        setState(() {
          kampanyalar = data["kampanyalar"];
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kampanyalarım')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: kampanyalar.length,
        itemBuilder: (context, index) {
          final kampanya = kampanyalar[index];
          return Card(
            margin: EdgeInsets.all(10),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kampanya["gorsel"] != null && kampanya["gorsel"] != "")
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      "https://www.yakauretimi.com/kampanyalar/uploads/images/${kampanya["gorsel"]}",
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kampanya["baslik"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text(kampanya["aciklama"]),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Göster sayfasına yönlendir (detaya gidilecek)
                              Navigator.pushNamed(context, '/fl_kampanya_detay', arguments: kampanya["id"]);
                            },
                            child: Text('Göster'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Düzenle işlemi (ileride eklenecek)
                            },
                            child: Text('Düzenle'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Yayın durumu toggle edilecek (API gerekirse sonra yapılır)
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kampanya["yayinda"] == 1 ? Colors.green : Colors.grey,
                            ),
                            child: Text(kampanya["yayinda"] == 1 ? "Yayında" : "Yayınla"),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
