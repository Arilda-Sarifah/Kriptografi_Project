import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

class ImageMessagesScreen extends ConsumerStatefulWidget {
  const ImageMessagesScreen({super.key});

  @override
  ConsumerState<ImageMessagesScreen> createState() =>
      _ImageMessagesScreenState();
}

class _ImageMessagesScreenState extends ConsumerState<ImageMessagesScreen> {
  final _studentController = TextEditingController();
  final _courseController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _certificates = [];
  String? _imageName;
  Uint8List? _imageBytes;
  Uint8List? _latestImage;
  String? _latestExtractedMessage;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void dispose() {
    _studentController.dispose();
    _courseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final certificates = await ref
          .read(featureApiProvider)
          .fetchCertificates();
      if (mounted) setState(() => _certificates = certificates);
    } catch (error) {
      if (mounted) setState(() => _error = 'Gagal memuat gambar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw const FormatException('Gambar kosong atau tidak dapat dibaca.');
      }
      setState(() {
        _imageName = file.name;
        _imageBytes = file.bytes;
        _latestImage = null;
        _latestExtractedMessage = null;
        _error = null;
        _info = 'Gambar ${file.name} dipilih.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Gagal memilih gambar: $error');
    }
  }

  Future<void> _createCertificate() async {
    final imageBytes = _imageBytes;
    final imageName = _imageName;
    if (imageBytes == null || imageName == null) {
      setState(() => _error = 'Pilih gambar terlebih dahulu.');
      return;
    }
    if (_studentController.text.trim().isEmpty ||
        _courseController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      setState(() => _error = 'Nama, mata kuliah, dan pesan wajib diisi.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
      _latestExtractedMessage = null;
    });
    try {
      final api = ref.read(featureApiProvider);
      final certificateId = await api.generateCertificate(
        studentName: _studentController.text.trim(),
        courseName: _courseController.text.trim(),
        hiddenMessage: _messageController.text.trim(),
        imageName: imageName,
        imageBytes: imageBytes,
      );
      final image = await api.downloadCertificateImage(certificateId);
      if (!mounted) return;
      setState(() {
        _latestImage = image;
        _info =
            'Pesan disembunyikan dan sertifikat tersimpan (ID $certificateId).';
      });
      await _loadCertificates();
    } catch (error) {
      if (mounted) setState(() => _error = 'Pembuatan gambar gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extract(Map<String, dynamic> certificate) async {
    final id = int.tryParse(certificate['id'].toString());
    if (id == null) {
      setState(() => _error = 'ID sertifikat tidak valid.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final message = await ref
          .read(featureApiProvider)
          .extractCertificateMessage(id);
      if (mounted) setState(() => _latestExtractedMessage = message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Ekstraksi pesan gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveImage(Map<String, dynamic> certificate) async {
    final id = int.tryParse(certificate['id'].toString());
    if (id == null) {
      setState(() => _error = 'ID sertifikat tidak valid.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final bytes = await ref
          .read(featureApiProvider)
          .downloadCertificateImage(id);
      final imageUrl = certificate['stego_image_url']?.toString() ?? '';
      final pathSegments = Uri.tryParse(imageUrl)?.pathSegments ?? const [];
      final imageName = pathSegments.isEmpty ? null : pathSegments.last;
      final path = await FilePicker.platform.saveFile(
        fileName: imageName == null || imageName.isEmpty
            ? 'edusafe_certificate_$id.png'
            : imageName,
        bytes: bytes,
      );
      if (mounted) {
        setState(
          () => _info = path == null
              ? 'Penyimpanan dibatalkan.'
              : 'Gambar PNG berhasil disimpan.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Download gambar gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Gambar'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _busy ? null : _loadCertificates,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pilih gambar JPEG/PNG dan isi detail sertifikat. Server '
              'mengenkripsi pesan, menyisipkannya ke piksel, lalu menyimpan '
              'hasil PNG lossless ke certificates.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickImage,
              icon: const Icon(Icons.image_search),
              label: Text(_imageName ?? 'Pilih gambar'),
            ),
            TextField(
              controller: _studentController,
              decoration: const InputDecoration(labelText: 'Nama mahasiswa'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Mata kuliah'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Pesan rahasia',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _createCertificate,
              icon: const Icon(Icons.lock),
              label: const Text('Sembunyikan dan simpan'),
            ),
            if (_latestImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _latestImage!,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (_latestExtractedMessage != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: const Text('Pesan hasil ekstraksi'),
                  subtitle: SelectableText(_latestExtractedMessage!),
                ),
              ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Gambar tersimpan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_certificates.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada gambar/sertifikat tersimpan.'),
              ),
            for (final certificate in _certificates)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(
                    '${certificate['student_name'] ?? 'Mahasiswa'} · '
                    '${certificate['course_name'] ?? ''}',
                  ),
                  subtitle: Text(certificate['created_at']?.toString() ?? ''),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Ekstrak pesan',
                        onPressed: _busy ? null : () => _extract(certificate),
                        icon: const Icon(Icons.lock_open),
                      ),
                      IconButton(
                        tooltip: 'Simpan gambar PNG',
                        onPressed: _busy ? null : () => _saveImage(certificate),
                        icon: const Icon(Icons.download),
                      ),
                    ],
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
