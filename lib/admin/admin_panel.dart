import 'package:flutter/material.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Paneli')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Bilgileri'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Satıcı Listesi'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Müşteri Listesi'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Siparişler'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
