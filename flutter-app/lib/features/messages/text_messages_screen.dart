import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

class TextMessagesScreen extends ConsumerStatefulWidget {
  const TextMessagesScreen({required this.currentUsername, super.key});

  final String currentUsername;

  @override
  ConsumerState<TextMessagesScreen> createState() => _TextMessagesScreenState();
}

class _TextMessagesScreenState extends ConsumerState<TextMessagesScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _messages = [];
  int? _receiverId;
  bool _busy = false;
  String? _error;
  final Map<int, String> _decryptedMessages = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(featureApiProvider);
      final results = await Future.wait([
        api.fetchUsers(),
        api.fetchMessages(),
      ]);
      if (!mounted) return;
      setState(() {
        _users = results[0];
        _messages = results[1];
        if (_receiverId != null &&
            !_users.any(
              (user) => int.tryParse(user['id'].toString()) == _receiverId,
            )) {
          _receiverId = null;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Gagal memuat pesan: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (_receiverId == null || message.isEmpty) {
      setState(() => _error = 'Pilih penerima dan isi pesan.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(featureApiProvider)
          .sendMessage(receiverId: _receiverId!, message: message);
      _messageController.clear();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = 'Pesan gagal dikirim: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMessage(Map<String, dynamic> message) async {
    final id = int.tryParse(message['id'].toString());
    if (id == null) {
      setState(() => _error = 'ID pesan tidak valid.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final plaintext = await ref.read(featureApiProvider).decryptMessage(id);
      if (mounted) setState(() => _decryptedMessages[id] = plaintext);
    } catch (error) {
      if (mounted) setState(() => _error = 'Pesan gagal dibuka: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Teks'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pesan dienkripsi server dengan Affine + Vigenere + AES-256-GCM. '
              'Kunci tidak disimpan di aplikasi.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _receiverId,
              decoration: const InputDecoration(labelText: 'Penerima'),
              items: [
                for (final user in _users)
                  if (int.tryParse(user['id'].toString()) case final int id)
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        '${user['username'] ?? 'Pengguna'} '
                        '(${user['role'] ?? '-'})',
                      ),
                    ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _receiverId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              enabled: !_busy,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Tulis pesan',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _send,
              icon: const Icon(Icons.send),
              label: const Text('Kirim pesan'),
            ),
            const SizedBox(height: 20),
            Text(
              'Pesan masuk dan keluar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_messages.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada pesan.'),
              ),
            for (final message in _messages) _messageCard(context, message),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(BuildContext context, Map<String, dynamic> message) {
    final id = int.tryParse(message['id'].toString());
    final plaintext = id == null ? null : _decryptedMessages[id];
    final sender = message['sender_name'] ?? 'Pengirim';
    final receiver = message['receiver_name'] ?? 'Penerima';
    final isIncoming = sender != widget.currentUsername;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isIncoming ? 'Dari: $sender' : 'Kepada: $receiver'),
            if (message['created_at'] != null)
              Text(
                message['created_at'].toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            if (plaintext != null)
              SelectableText(plaintext)
            else
              const Text('Isi terenkripsi'),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _busy || id == null
                    ? null
                    : () => _openMessage(message),
                icon: const Icon(Icons.lock_open),
                label: Text(
                  plaintext == null ? 'Buka & dekripsi' : 'Dekripsi ulang',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
