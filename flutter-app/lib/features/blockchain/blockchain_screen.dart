import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

class BlockchainScreen extends ConsumerStatefulWidget {
  const BlockchainScreen({super.key});

  @override
  ConsumerState<BlockchainScreen> createState() => _BlockchainScreenState();
}

class _BlockchainScreenState extends ConsumerState<BlockchainScreen> {
  List<Map<String, dynamic>> _chain = [];
  bool? _isValid;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyChain();
  }

  Future<void> _verifyChain() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(featureApiProvider).fetchBlockchain();
      final chain = result['chain'];
      if (chain is! List) {
        throw Exception('Data rantai blockchain tidak valid.');
      }
      if (!mounted) return;
      setState(() {
        _chain = chain.whereType<Map<String, dynamic>>().toList();
        _isValid =
            result['is_valid'] == true ||
            result['is_valid'] == 1 ||
            result['is_valid'] == '1';
      });
    } catch (error) {
      if (mounted)
        setState(() => _error = 'Verifikasi blockchain gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _blockData(dynamic value) {
    if (value is! String || value.isEmpty) return value?.toString() ?? '-';
    try {
      final decoded = jsonDecode(value);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } on FormatException {
      return value;
    }
  }

  String _timestamp(dynamic value) {
    final seconds = int.tryParse(value.toString());
    if (seconds == null) return value?.toString() ?? '-';
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal().toString();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _isValid == null
        ? Theme.of(context).colorScheme.onSurface
        : _isValid!
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain'),
        actions: [
          IconButton(
            tooltip: 'Verifikasi ulang',
            onPressed: _busy ? null : _verifyChain,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Aktivitas penting dicatat di blockchain_ledger. Verifikasi '
              'menghitung ulang hash setiap blok dan mencocokkan previous_hash.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _verifyChain,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verifikasi rantai'),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_isValid != null)
              Card(
                child: ListTile(
                  leading: Icon(
                    _isValid! ? Icons.check_circle : Icons.error,
                    color: statusColor,
                  ),
                  title: Text(
                    _isValid! ? 'Rantai valid' : 'Rantai tidak valid',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${_chain.length} blok'),
                ),
              ),
            if (_chain.isEmpty && !_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada blok pada rantai.'),
              ),
            for (final block in _chain)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.link),
                  title: Text(
                    'Blok ${block['block_index'] ?? '?'} · '
                    '${block['action_type'] ?? 'Aktivitas'}',
                  ),
                  subtitle: Text(_timestamp(block['timestamp'])),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _hashRow('Previous hash', block['previous_hash']),
                    _hashRow('Hash', block['hash']),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Data',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(_blockData(block['data'])),
                  ],
                ),
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

  Widget _hashRow(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        SelectableText(value?.toString() ?? '-'),
      ],
    ),
  );
}
