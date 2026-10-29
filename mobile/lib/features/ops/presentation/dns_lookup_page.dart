import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

/// 阶段 1：DNS 查询
class DnsLookupPage extends ConsumerStatefulWidget {
  const DnsLookupPage({super.key});

  @override
  ConsumerState<DnsLookupPage> createState() => _DnsLookupPageState();
}

class _DnsLookupPageState extends ConsumerState<DnsLookupPage> {
  final _hostCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<InternetAddress> _addrs = [];
  Duration? _elapsed;

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _addrs = [];
      _elapsed = null;
    });
    final sw = Stopwatch()..start();
    try {
      final list = await InternetAddress.lookup(
        host,
        type: InternetAddressType.any,
      );
      sw.stop();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _addrs = list;
        _elapsed = sw.elapsed;
        if (list.isEmpty) _error = '无解析结果';
      });
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _elapsed = sw.elapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('DNS 查询')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: '域名',
              hintText: 'example.com',
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _lookup,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('解析'),
            ),
          ),
          if (_elapsed != null) ...[
            const SizedBox(height: 12),
            Text(
              '耗时 ${_elapsed!.inMilliseconds} ms',
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: colors.danger)),
          ],
          const SizedBox(height: 12),
          ..._addrs.map((a) {
            return Card(
              child: ListTile(
                title: Text(a.address),
                subtitle: Text(
                  '${a.type == InternetAddressType.IPv6 ? 'IPv6' : 'IPv4'}'
                  '${a.host.isNotEmpty ? ' · ${a.host}' : ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: a.address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制')),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
