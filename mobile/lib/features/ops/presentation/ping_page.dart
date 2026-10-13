import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

class PingPage extends ConsumerStatefulWidget {
  const PingPage({super.key});

  @override
  ConsumerState<PingPage> createState() => _PingPageState();
}

class _PingPageState extends ConsumerState<PingPage> {
  final _hostCtrl = TextEditingController(text: 'baidu.com');
  final _portCtrl = TextEditingController(text: '80');
  final _countCtrl = TextEditingController(text: '4');

  bool _running = false;
  final List<_PingResult> _results = [];
  String? _summary;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) return;

    final port = int.tryParse(_portCtrl.text.trim()) ?? 80;
    final count = (int.tryParse(_countCtrl.text.trim()) ?? 4).clamp(1, 20);

    setState(() {
      _running = true;
      _results.clear();
      _summary = null;
    });

    final latencies = <int>[];
    for (var i = 0; i < count; i++) {
      if (!mounted || !_running) break;
      final r = await _tcpPing(host, port);
      if (!mounted) return;
      setState(() => _results.add(r));
      if (r.ok && r.ms != null) latencies.add(r.ms!);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      if (latencies.isEmpty) {
        _summary = '全部失败，无法连通 $host:$port';
      } else {
        final avg = latencies.reduce((a, b) => a + b) / latencies.length;
        final min = latencies.reduce((a, b) => a < b ? a : b);
        final max = latencies.reduce((a, b) => a > b ? a : b);
        _summary =
            '成功 ${latencies.length}/$count  ·  最小 ${min}ms  ·  最大 ${max}ms  ·  平均 ${avg.toStringAsFixed(1)}ms';
      }
    });
  }

  Future<_PingResult> _tcpPing(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      sw.stop();
      socket.destroy();
      return _PingResult(ok: true, ms: sw.elapsedMilliseconds, message: '连通');
    } on SocketException catch (e) {
      sw.stop();
      return _PingResult(ok: false, message: e.message);
    } on TimeoutException {
      sw.stop();
      return _PingResult(ok: false, message: '超时');
    } catch (e) {
      sw.stop();
      return _PingResult(ok: false, message: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Ping 工具')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: '主机 / 域名',
              hintText: '例如 8.8.8.8 或 baidu.com',
            ),
            enabled: !_running,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portCtrl,
                  decoration: const InputDecoration(labelText: '端口'),
                  keyboardType: TextInputType.number,
                  enabled: !_running,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _countCtrl,
                  decoration: const InputDecoration(labelText: '次数'),
                  keyboardType: TextInputType.number,
                  enabled: !_running,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '说明：使用 TCP 连接测延迟（非 ICMP），适合检测服务端口是否可达。',
            style: TextStyle(fontSize: 12, color: colors.secondaryText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _running ? null : _start,
              child: _running
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('开始检测'),
            ),
          ),
          if (_summary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border.withOpacity(0.5)),
              ),
              child: Text(_summary!, style: const TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          ..._results.asMap().entries.map((e) {
            final i = e.key + 1;
            final r = e.value;
            return ListTile(
              dense: true,
              leading: Icon(
                r.ok ? Icons.check_circle : Icons.cancel,
                color: r.ok ? colors.success : colors.danger,
                size: 20,
              ),
              title: Text(
                r.ok ? '#$i  ${r.ms} ms' : '#$i  失败',
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(r.message, style: TextStyle(color: colors.secondaryText)),
            );
          }),
        ],
      ),
    );
  }
}

class _PingResult {
  final bool ok;
  final int? ms;
  final String message;

  _PingResult({required this.ok, this.ms, required this.message});
}
