import 'dart:convert';

import 'package:flutter/material.dart';

import '../blockchain/blockchain_screen.dart';
import '../files/file_messages_screen.dart';
import '../images/image_messages_screen.dart';
import '../messages/text_messages_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.username,
    required this.token,
    required this.onLogout,
    super.key,
  });

  final String username;
  final String token;
  final VoidCallback onLogout;

  String get _role {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'Tidak diketahui';
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is Map && payload['role'] is String) {
        return payload['role'] as String;
      }
    } on FormatException {
      return 'Tidak diketahui';
    }
    return 'Tidak diketahui';
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        title: 'Pesan Teks',
        subtitle: 'Kirim dan buka pesan terenkripsi',
        icon: Icons.chat_bubble_outline,
        page: TextMessagesScreen(currentUsername: username),
      ),
      (
        title: 'Pesan Berkas',
        subtitle: 'Upload dan download berkas terenkripsi',
        icon: Icons.insert_drive_file_outlined,
        page: const FileMessagesScreen(),
      ),
      (
        title: 'Pesan Gambar',
        subtitle: 'Sembunyikan dan ekstrak pesan dari gambar',
        icon: Icons.image_outlined,
        page: const ImageMessagesScreen(),
      ),
      (
        title: 'Blockchain',
        subtitle: 'Lihat dan verifikasi rantai aktivitas',
        icon: Icons.account_tree_outlined,
        page: const BlockchainScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduSafe'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.verified_user_outlined),
                    ),
                    title: Text(username),
                    subtitle: Text('Peran: $_role'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fitur EduSafe',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final entry in entries)
                  Card(
                    child: ListTile(
                      leading: Icon(entry.icon),
                      title: Text(entry.title),
                      subtitle: Text(entry.subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => entry.page),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
