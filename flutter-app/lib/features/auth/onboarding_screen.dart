import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/api/auth_api.dart';
import 'auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = 'mahasiswa';
  String? _error;
  bool _isBusy = false;
  RegisteredAccount? _pendingAccount;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Username dan password wajib diisi.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _error = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final account =
          _pendingAccount ??
          await ref
              .read(authApiProvider)
              .register(username: username, password: password, role: _role);
      _pendingAccount = account;

      final savedPath = await FilePicker.platform.saveFile(
        fileName: account.dongleFileName,
        bytes: Uint8List.fromList(utf8.encode(account.dongleContent)),
      );
      if (savedPath == null) {
        throw const ApiException(
          'Penyimpanan dibatalkan. Akun sudah dibuat; coba lagi atau gunakan '
          'penyimpanan fallback demo.',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(account);
    } catch (error) {
      if (mounted)
        setState(() => _error = 'Registrasi/onboarding gagal: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _saveDemoFallback() async {
    final account = _pendingAccount;
    if (account == null) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw const FileSystemException(
          'Folder eksternal aplikasi tidak tersedia.',
        );
      }
      final file = File(
        '${directory.path}${Platform.pathSeparator}${account.dongleFileName}',
      );
      await file.writeAsString(account.dongleContent, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(account);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal menyimpan dongle fallback: $error');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding pengguna baru')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Buat akun dan simpan dongle pertama. Setelah file '
                  'edusafe_dongle.key tersimpan, server akan memvalidasinya '
                  'sebelum login dibuka.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  enabled: !_isBusy,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  enabled: !_isBusy,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isBusy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi password',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Peran'),
                  items: const [
                    DropdownMenuItem(
                      value: 'mahasiswa',
                      child: Text('Mahasiswa'),
                    ),
                    DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
                  ],
                  onChanged: _isBusy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _role = value);
                        },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isBusy ? null : _register,
                  child: _isBusy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Daftar dan simpan dongle'),
                ),
                if (_pendingAccount != null)
                  TextButton(
                    onPressed: _isBusy ? null : _saveDemoFallback,
                    child: const Text(
                      'Gunakan fallback demo di folder aplikasi',
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Simpan file ke flashdisk OTG atau lokasi aman. Jangan '
                  'bagikan isi file kunci.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
