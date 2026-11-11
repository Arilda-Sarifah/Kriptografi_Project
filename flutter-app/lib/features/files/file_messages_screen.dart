import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

class FileMessagesScreen extends ConsumerStatefulWidget {
  const FileMessagesScreen({super.key});

  @override
  ConsumerState<FileMessagesScreen> createState() => _FileMessagesScreenState();
}

class _FileMessagesScreenState extends ConsumerState<FileMessagesScreen> {
  List<Map<String, dynamic>> _files = [];
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await ref.read(featureApiProvider).fetchFiles();
      if (mounted) setState(() => _files = files);
    } catch (error) {
      if (mounted) setState(() => _error = 'Gagal memuat berkas: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('File kosong atau tidak dapat dibaca.');
      }

      setState(() {
        _busy = true;
        _error = null;
        _info = null;
      });
      await ref
          .read(featureApiProvider)
          .uploadFile(name: file.name, bytes: bytes);
      if (!mounted) return;
      setState(() => _info = 'Berkas berhasil dienkripsi dan diunggah.');
      await _loadFiles();
    } catch (error) {
      if (mounted) setState(() => _error = 'Upload berkas gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(Map<String, dynamic> file) async {
    final id = int.tryParse(file['id'].toString());
    if (id == null) {
      setState(() => _error = 'ID berkas tidak valid.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final Uint8List bytes = await ref
          .read(featureApiProvider)
          .downloadFile(id);
      final savedPath = await FilePicker.platform.saveFile(
        fileName: file['original_filename']?.toString() ?? 'edusafe_file',
        bytes: bytes,
      );
      if (!mounted) return;
      setState(
        () => _info = savedPath == null
            ? 'Penyimpanan dibatalkan.'
            : 'Berkas terdekripsi dan disimpan.',
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Download/dekripsi gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Berkas'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _busy ? null : _loadFiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Berkas disimpan terenkripsi di server menggunakan '
              'ChaCha20-Poly1305 + HMAC-SHA3-512. Saat diunduh, server '
              'memvalidasi sesi lalu mendekripsinya.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Pilih dan upload berkas'),
            ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text('Berkas saya', style: Theme.of(context).textTheme.titleLarge),
            if (_files.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada berkas yang diunggah.'),
              ),
            for (final file in _files)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    file['original_filename']?.toString() ?? 'Berkas',
                  ),
                  subtitle: Text(
                    '${file['size_kb'] ?? '-'} KB · '
                    '${file['created_at'] ?? ''}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Download dan dekripsi',
                    onPressed: _busy ? null : () => _download(file),
                    icon: const Icon(Icons.download),
                  ),
                ),
              ),
            if (_info != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_info!),
              ),
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
}
