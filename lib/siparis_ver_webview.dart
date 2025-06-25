import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SiparisVerWebview extends StatefulWidget {
  const SiparisVerWebview({super.key});

  @override
  State<SiparisVerWebview> createState() => _SiparisVerWebviewState();
}

class _SiparisVerWebviewState extends State<SiparisVerWebview> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool yetkisiz = false;

  @override
  void initState() {
    super.initState();
    _kontrolEtVeYukle();
  }

  Future<void> _kontrolEtVeYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    debugPrint("📦 Token kontrolü: $token");

    // ➕ Token üzerinden rol sorgulaması
    final response = await http.post(
      Uri.parse('https://www.yakauretimi.com/api/app_token_rol_kontrol.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token}),
    );

    final data = json.decode(response.body);
    debugPrint("🎯 Gelen rol kontrol cevabı: $data");

    if (data['success'] == true && data['rol'] == 'musteri') {
      final uri = Uri.parse('https://www.yakauretimi.com/urun-kategori.php?token=$token');
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(uri);
      setState(() => isLoading = false);
    } else {
      setState(() {
        yetkisiz = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (yetkisiz) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sipariş Erişimi')),
        body: const Center(
          child: Text(
            'Bu sayfaya sadece müşteri rolüne sahip kullanıcılar erişebilir.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sipariş Ver')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
