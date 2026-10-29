import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';

/// 阶段 2：网络诊断汇总（本机网卡 + DNS + 关键端口探测）
class NetworkDiagPage extends ConsumerStatefulWidget {
  const NetworkDiagPage({super.key});

  @override
  ConsumerState<NetworkDiagPage> createState() => _NetworkDiagPageState();
}

class _NetworkDiagPageState extends ConsumerState<NetworkDiagPage> {
  final _hostCtrl = TextEditingController(text: 'baidu.com');
  bool _running = false;
  final List<String> _logs = [];

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  void _log(String line) {
    setState(() => _logs.add(line));
  }

  Future<void> _run() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) return;
    setState(() {
      _running = true;
      _logs.clear();
    });

    _log('— 本机网络接口 —');
    try {
      final ifaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.any,
      );
      if (ifaces.isEmpty) {
        _log('未获取到接口（模拟器或权限限制时常见）');
      } else {
        for (final iface in ifaces) {
          final addrs = iface.addresses.map((a) => a.address).join(', ');
          _log('${iface.name}: $addrs');
        }
      }
    } catch (e) {
      _log('接口枚举失败: $e');
    }

    _log('');
    _log('— DNS 解析 $host —');
    List<InternetAddress> addrs = [];
    try {
      final sw = Stopwatch()..start();
      addrs = await InternetAddress.lookup(host);
      sw.stop();
      for (final a in addrs) {
        _log('${a.address} (${a.type == InternetAddressType.IPv6 ? 'v6' : 'v4'})');
      }
      _log('解析耗时 ${sw.elapsedMilliseconds} ms');
    } catch (e) {
      _log('解析失败: $e');
    }

    _log('');
    _log('— TCP 探测 —');
    final targets = <({String h, int p})>[
      (h: host, p: 80),
      (h: host, p: 443),
    ];
    // 若解析到 IP，额外对第一个 IP 测 80
    if (addrs.isNotEmpty) {
      targets.add((h: addrs.first.address, p: 80));
    }
    for (final t in targets) {
      final sw = Stopwatch()..start();
      try {
        final s = await Socket.connect(
          t.h,
          t.p,
          timeout: const Duration(seconds: 3),
        );
        sw.stop();
        s.destroy();
        _log('${t.h}:${t.p} 开放 ${sw.elapsedMilliseconds} ms');
      } catch (e) {
        sw.stop();
        _log('${t.h}:${t.p} 不可达 (${sw.elapsedMilliseconds} ms)');
      }
    }

    _log('');
    _log('诊断完成');
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('网络诊断')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _hostCtrl,
                  decoration: const InputDecoration(
                    labelText: '目标主机',
                    hintText: '域名或 IP',
                  ),
                  enabled: !_running,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _running ? null : _run,
                    child: Text(_running ? '诊断中…' : '开始诊断'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (_, i) {
                final line = _logs[i];
                final isHeader = line.startsWith('—');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line.isEmpty ? ' ' : line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isHeader ? 13 : 12,
                      fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                      color: isHeader ? colors.onSurface : colors.secondaryText,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
