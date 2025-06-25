import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SiparisVerWebview extends StatefulWidget {
  const SiparisVerWebview({super.key});

  @override
  State<SiparisVerWebview> createState() => _SiparisVerWebviewState();
}

class _SiparisVerWebviewState extends State<SiparisVerWebview> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    const token = "abc123"; // ✅ Giriş sonrası aldığın gerçek token gelecek

    final uri = Uri.parse('https://www.yakauretimi.com/cart.php?token=$token');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sipariş Ver')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
