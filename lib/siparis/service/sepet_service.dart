import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SepetService {
  static Future<int?> getKullaniciId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('kullanici_id');
  }

  static Future<String?> sepeteEkle(int urunId, int adet) async {
    final kullaniciId = await getKullaniciId();
    if (kullaniciId == null) return "Kullanıcı bulunamadı";

    try {
      final response = await http.post(
        Uri.parse("https://www.yakauretimi.com/islemler/fl_urun_adet_guncelle_api.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'kullanici_id': kullaniciId,
          'urun_id': urunId,
          'adet': adet,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? "İşlem tamamlandı.";
      } else {
        return "Sunucu hatası";
      }
    } catch (e) {
      return "İstek hatası: $e";
    }
  }

  static Future<double> toplamFiyatiGetir() async {
    final kullaniciId = await getKullaniciId();
    if (kullaniciId == null) return 0.0;

    try {
      final response = await http.post(
        Uri.parse("https://www.yakauretimi.com/sepet/api/fl_sepet_toplam_api.php"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'kullanici_id': kullaniciId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.tryParse(data['toplam'].toString()) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  static Future<bool> urunSil(int kullaniciId, String urunId) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.yakauretimi.com/sepet/api/fl_sepet_urun_sil_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'kullanici_id': kullaniciId, 'urun_id': urunId}),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> adetGuncelle(int kullaniciId, String urunId, int adet) async {
    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/islemler/fl_urun_adet_guncelle_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_id': kullaniciId,
        'urun_id': urunId,
        'adet': adet,
        'mod': 'set', // ❗️burayı ekliyoruz
      }),
    );
    return response.statusCode == 200;
  }

}
