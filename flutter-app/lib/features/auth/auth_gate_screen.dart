import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/api/auth_api.dart';
import 'auth_providers.dart';
import '../dashboard/dashboard_screen.dart';
import 'onboarding_screen.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _dongleContent;
  String? _message;
  bool _isBusy = false;
  bool _dongleVerified = false;
  bool _isAuthenticated = false;
  String? _sessionToken;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDongle() async {
    setState(() {
      _message = null;
      _dongleContent = null;
      _dongleVerified = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['key'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.name.toLowerCase() != 'edusafe_dongle.key') {
        throw const FormatException(
          'Pilih file dengan nama edusafe_dongle.key.',
        );
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('File dongle kosong atau tidak terbaca.');
      }

      final content = utf8.decode(bytes, allowMalformed: false).trim();
      if (content.isEmpty) {
        throw const FormatException('Isi file dongle kosong.');
      }

      setState(() {
        _dongleContent = content;
        _dongleVerified = false;
        _message = 'File kunci dipilih. Masukkan username lalu verifikasi.';
      });
    } on FormatException catch (error) {
      setState(() => _message = error.message);
    } catch (error) {
      setState(() => _message = 'Gagal membaca file dongle: $error');
    }
  }

  Future<void> _verifyDongle({String? onboardingContent}) async {
    final username = _usernameController.text.trim();
    final content = onboardingContent ?? _dongleContent;
    if (username.isEmpty) {
      setState(() => _message = 'Masukkan username terlebih dahulu.');
      return;
    }
    if (content == null || content.isEmpty) {
      setState(() => _message = 'Pilih file dongle terlebih dahulu.');
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await ref
          .read(authApiProvider)
          .verifyDongle(username: username, dongleContent: content);
      if (!mounted) return;
      setState(() {
        _dongleContent = content;
        _dongleVerified = true;
        _message =
            'Dongle tervalidasi. Lanjutkan dengan password dan biometric.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = 'Verifikasi dongle gagal: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// DEMO ONLY: reads a local key file; this does not emulate or replace a
  /// physical USB dongle. The normal server verification is still required.
  Future<void> _useDemoFallback() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });

    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw const FileSystemException(
          'Folder eksternal aplikasi tidak tersedia.',
        );
      }

      final file = File(
        '${directory.path}${Platform.pathSeparator}edusafe_dongle.key',
      );
      if (!await file.exists()) {
        throw FileSystemException(
          'File fallback belum ada. Letakkan edusafe_dongle.key di: '
          '${directory.path}',
        );
      }

      final content = (await file.readAsString()).trim();
      if (content.isEmpty) {
        throw const FormatException('File fallback dongle kosong.');
      }

      if (!mounted) return;
      setState(() {
        _dongleContent = content;
        _dongleVerified = false;
        _message =
            'Fallback DEMO dipilih (bukan dongle fisik). '
            'Verifikasi server tetap wajib.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _startOnboarding() async {
    final registered = await Navigator.of(context).push<RegisteredAccount>(
      MaterialPageRoute<RegisteredAccount>(
        builder: (_) => const OnboardingScreen(),
      ),
    );
    if (!mounted || registered == null) return;

    _usernameController.text = registered.username;
    await _verifyDongle(onboardingContent: registered.dongleContent);
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final dongleContent = _dongleContent;
    if (dongleContent == null) {
      setState(() => _message = 'Dongle harus divalidasi sebelum login.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _message = 'Masukkan password.');
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      final authenticated = await ref
          .read(biometricServiceProvider)
          .authenticate();
      if (!authenticated) {
        setState(() => _message = 'Autentikasi biometric dibatalkan.');
        return;
      }

      final token = await ref
          .read(authApiProvider)
          .login(
            username: username,
            password: password,
            dongleContent: dongleContent,
          );
      await ref.read(tokenStorageProvider).save(token);
      if (!mounted) return;
      setState(() {
        _sessionToken = token;
        _isAuthenticated = true;
        _passwordController.clear();
        _message = null;
      });
    } on StateError catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } catch (error) {
      if (mounted) setState(() => _message = 'Login gagal: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(tokenStorageProvider).clear();
    if (!mounted) return;
    setState(() {
      _sessionToken = null;
      _isAuthenticated = false;
      _dongleContent = null;
      _passwordController.clear();
      _message = 'Sesi ditutup. Verifikasi dongle lagi untuk masuk.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return DashboardScreen(
        username: _usernameController.text.trim(),
        token: _sessionToken ?? '',
        onLogout: _logout,
      );
    }

    final dongleVerified = _dongleVerified;
    return Scaffold(
      appBar: AppBar(title: const Text('EduSafe')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 16),
                Text(
                  dongleVerified ? 'Dongle tervalidasi' : 'Akses dengan dongle',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih edusafe_dongle.key dari USB OTG atau penyimpanan '
                  'perangkat. Login dan dashboard tetap terkunci sampai '
                  'server memvalidasi kunci ini.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  enabled: !dongleVerified && !_isBusy,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                if (!dongleVerified) ...[
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _pickDongle,
                    icon: const Icon(Icons.usb),
                    label: const Text('Pilih file dongle'),
                  ),
                  TextButton(
                    onPressed: _isBusy ? null : _useDemoFallback,
                    child: const Text('DEMO ONLY: gunakan file lokal'),
                  ),
                  Text(
                    _dongleContent == null
                        ? 'Belum ada file kunci dipilih'
                        : 'File edusafe_dongle.key siap diverifikasi',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _isBusy || _dongleContent == null
                        ? null
                        : _verifyDongle,
                    child: _isBusy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verifikasi dongle'),
                  ),
                ] else ...[
                  TextField(
                    controller: _passwordController,
                    enabled: !_isBusy,
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.password),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isBusy ? null : _login,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(
                      _isBusy ? 'Memproses...' : 'Login dengan biometric',
                    ),
                  ),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => setState(() {
                            _dongleContent = null;
                            _dongleVerified = false;
                            _message = null;
                          }),
                    child: const Text('Ganti file dongle'),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          _message!.contains('gagal') ||
                              _message!.contains('kosong') ||
                              _message!.contains('Pilih')
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const Divider(height: 32),
                TextButton(
                  onPressed: _isBusy ? null : _startOnboarding,
                  child: const Text('Pengguna baru? Buat akun dan dongle'),
                ),
                const Text(
                  'Onboarding hanya untuk membuat akun dan kunci pertama. '
                  'Fallback folder aplikasi adalah DEMO ONLY: tidak '
                  'menggunakan atau menggantikan dongle fisik. Semua jalur '
                  'tetap memerlukan validasi server.',
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
