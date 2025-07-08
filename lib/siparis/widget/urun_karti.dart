import 'package:flutter/material.dart';
import '../service/sepet_service.dart';

class UrunKarti extends StatefulWidget {
  final Map urun;
  final VoidCallback onSepeteEklendi;

  const UrunKarti({
    super.key,
    required this.urun,
    required this.onSepeteEklendi,
  });

  @override
  State<UrunKarti> createState() => _UrunKartiState();
}

class _UrunKartiState extends State<UrunKarti> {
  int adet = 0;
  String? bildirimMesaji;
  Color _bildirimRenk(String mesaj) {
    if (mesaj.contains("eklen") || mesaj.contains("güncellendi")) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  void arttir() {
    setState(() {
      adet++;
    });
  }

  void azalt() {
    if (adet > 0) {
      setState(() {
        adet--;
      });
    }
  }

  Future<void> sepeteEkle() async {
    if (adet == 0) {
      setState(() {
        bildirimMesaji = "Lütfen adet seçin";
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            bildirimMesaji = null;
          });
        }
      });
      return;
    }

    final mesaj = await SepetService.sepeteEkle(widget.urun['id'], adet);

    setState(() {
      bildirimMesaji = "$mesaj ($adet)";
      adet = 0;
    });

    widget.onSepeteEklendi();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          bildirimMesaji = null;
        });
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    final int stok = widget.urun['in_stock'] ?? 0;
    final double fiyat = double.tryParse(widget.urun['price']?.toString() ?? "0") ?? 0.0;
    final String ad = widget.urun['title']?.toString() ?? "Ürün";
    // Görsel alanı
    final dynamic gorsel = widget.urun['image'] ?? widget.urun['resim_url'] ?? widget.urun['gorsel'];
    final bool gorselVar = gorsel != null && gorsel.toString().isNotEmpty && gorsel.toString().toLowerCase() != 'null';
    final String? gorselUrl = gorselVar ? 'https://www.yakauretimi.com/products/$gorsel' : null;


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📦 Ürün görseli
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.urun['image'] != null &&
                      widget.urun['image'].toString().isNotEmpty &&
                      widget.urun['image'].toString().toLowerCase() != "null"
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      "https://www.yakauretimi.com/products/${widget.urun['image']}",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey);
                      },
                    ),
                  )
                      : const Icon(Icons.image_not_supported,
                      size: 40, color: Colors.grey),
                ),

                const SizedBox(width: 8),

                // 📄 Ürün bilgileri ve butonlar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("₺${fiyat.toStringAsFixed(2)}"),
                      const SizedBox(height: 6),
                      stok == 0
                          ? const Text("Stokta yok", style: TextStyle(color: Colors.red))
                          : Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove), onPressed: azalt),
                          Text('$adet'),
                          IconButton(icon: const Icon(Icons.add), onPressed: arttir),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: sepeteEkle,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Sepete Ekle'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🟠 Alt Bilgilendirme Kutusu
            if (bildirimMesaji != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bildirimMesaji!,
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );


  }
}
