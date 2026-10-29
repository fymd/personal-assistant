import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

/// 阶段 1：TCP 端口扫描（客户端本地探测）
class PortScanPage extends ConsumerStatefulWidget {
  const PortScanPage({super.key});

  @override
  ConsumerState<PortScanPage> createState() => _PortScanPageState();
}

class _PortScanPageState extends ConsumerState<PortScanPage> {
  final _hostCtrl = TextEditingController();
  final _portsCtrl = TextEditingController(
    text: '22,80,443,3306,3389,5432,6379,8080',
  );

  bool _running = false;
  final List<_PortResult> _results = [];

  static const _presets = {
    'Web': '80,443,8080,8443',
    '数据库': '3306,5432,1433,27017,6379',
    '远程': '22,3389,5900',
    '常用': '22,80,443,3306,3389,5432,6379,8080',
  };

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portsCtrl.dispose();
    super.dispose();
  }

  List<int> _parsePorts(String raw) {
    final set = <int>{};
    for (final part in raw.split(RegExp(r'[,\s]+'))) {
      final p = int.tryParse(part.trim());
      if (p != null && p > 0 && p <= 65535) set.add(p);
    }
    final list = set.toList()..sort();
    // 安全上限，避免误扫过大范围
    if (list.length > 64) return list.sublist(0, 64);
    return list;
  }

  Future<void> _scan() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入主机')),
      );
      return;
    }
    final ports = _parsePorts(_portsCtrl.text);
    if (ports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写有效端口列表')),
      );
      return;
    }

    setState(() {
      _running = true;
      _results.clear();
    });

    // 有限并发
    const concurrency = 8;
    var index = 0;
    Future<void> worker() async {
      while (true) {
        if (!_running || !mounted) return;
        final i = index++;
        if (i >= ports.length) return;
        final port = ports[i];
        final r = await _probe(host, port);
        if (!mounted || !_running) return;
        setState(() {
          _results.add(r);
          _results.sort((a, b) => a.port.compareTo(b.port));
        });
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
    if (!mounted) return;
    setState(() => _running = false);
  }

  Future<_PortResult> _probe(String host, int port) async {
    final sw = Stopwatch()..start();
    try {
      final s = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 1500),
      );
      sw.stop();
      s.destroy();
      return _PortResult(port: port, open: true, ms: sw.elapsedMilliseconds);
    } catch (_) {
      sw.stop();
      return _PortResult(port: port, open: false, ms: sw.elapsedMilliseconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final openCount = _results.where((e) => e.open).length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('端口扫描')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '对目标主机做 TCP 连通探测（非漏洞扫描）。单次最多 64 个端口。',
            style: TextStyle(fontSize: 13, color: colors.secondaryText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: '主机 / 域名',
              hintText: '192.168.1.1 或 example.com',
            ),
            enabled: !_running,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portsCtrl,
            decoration: const InputDecoration(
              labelText: '端口列表',
              hintText: '逗号分隔，如 22,80,443',
            ),
            enabled: !_running,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _presets.entries.map((e) {
              return ActionChip(
                label: Text(e.key),
                onPressed: _running
                    ? null
                    : () => setState(() => _portsCtrl.text = e.value),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _running
                  ? () => setState(() => _running = false)
                  : _scan,
              child: Text(_running ? '停止' : '开始扫描'),
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '开放 $openCount / ${_results.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._results.map((r) {
              return ListTile(
                dense: true,
                leading: Icon(
                  r.open ? Icons.check_circle : Icons.cancel_outlined,
                  color: r.open ? colors.success : colors.secondaryText,
                  size: 20,
                ),
                title: Text('端口 ${r.port}'),
                subtitle: Text(r.open ? '开放 · ${r.ms} ms' : '关闭/过滤 · ${r.ms} ms'),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _PortResult {
  final int port;
  final bool open;
  final int ms;
  _PortResult({required this.port, required this.open, required this.ms});
}
