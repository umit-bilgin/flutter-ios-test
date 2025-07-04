import 'package:flutter/material.dart';

class SepetUrunKarti extends StatefulWidget {
  final Map urun;
  final Function(int yeniAdet) onAdetGuncelle;
  final VoidCallback onUrunSil;

  const SepetUrunKarti({
    super.key,
    required this.urun,
    required this.onAdetGuncelle,
    required this.onUrunSil,
  });

  @override
  State<SepetUrunKarti> createState() => _SepetUrunKartiState();
}

class _SepetUrunKartiState extends State<SepetUrunKarti> {
  late int adet;
  bool degisti = false;

  @override
  void initState() {
    super.initState();
    adet = int.tryParse(widget.urun['adet']?.toString() ?? "1") ?? 1;
  }

  void arttir() {
    setState(() {
      adet++;
      degisti = true;
    });
  }

  void azalt() {
    if (adet > 1) {
      setState(() {
        adet--;
        degisti = true;
      });
    }
  }

  void onaylaAdetGuncelle() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adet Güncelle"),
        content: Text("Bu ürün adedini $adet olarak güncellemek istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet")),
        ],
      ),
    );

    if (onay == true) {
      widget.onAdetGuncelle(adet);
      setState(() => degisti = false);
    }
  }

  void onaylaSilme() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ürünü Sil"),
        content: const Text("Bu ürünü sepetten silmek istiyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hayır")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet")),
        ],
      ),
    );

    if (onay == true) {
      widget.onUrunSil();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gorsel = widget.urun['image'] != null && widget.urun['image'].toString().isNotEmpty
        ? 'https://www.yakauretimi.com/products/${widget.urun['image']}'
        : null;

    final double fiyat = double.tryParse(widget.urun['price']?.toString() ?? widget.urun['fiyat']?.toString() ?? "0") ?? 0.0;
    final toplamFiyat = (adet * fiyat).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                gorsel != null
                    ? Image.network(gorsel, width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 60, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.urun['title'] ?? widget.urun['urun_adi'] ?? "Ürün adı",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("$adet x ${fiyat.toStringAsFixed(2)} ₺ = $toplamFiyat ₺"),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onaylaSilme,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: azalt,
                ),
                Text('$adet', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: arttir,
                ),
                const Spacer(),
                if (degisti)
                  ElevatedButton.icon(
                    onPressed: onaylaAdetGuncelle,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Güncelle", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
