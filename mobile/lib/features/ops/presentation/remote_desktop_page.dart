import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_provider.dart';

/// 远程桌面入口（第一版：配置与跳转占位，后续可接 WebRTC / 第三方协议）
class RemoteDesktopPage extends ConsumerStatefulWidget {
  const RemoteDesktopPage({super.key});

  @override
  ConsumerState<RemoteDesktopPage> createState() => _RemoteDesktopPageState();
}

class _RemoteDesktopPageState extends ConsumerState<RemoteDesktopPage> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '3389');
  String _protocol = 'RDP';

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入主机地址')),
      );
      return;
    }
    final port = _portCtrl.text.trim();

    // 第一版：尝试用系统 URL scheme 打开（若设备有对应 App）
    // RDP: rdp:// 或 ms-rd:
    // 否则提示后续接入内置客户端
    Uri? uri;
    if (_protocol == 'RDP') {
      uri = Uri.parse('rdp://full%20address=s:$host:$port');
    } else if (_protocol == 'VNC') {
      uri = Uri.parse('vnc://$host:$port');
    } else {
      uri = Uri.parse('ssh://$host:$port');
    }

    try {
      final ok = await canLaunchUrl(uri);
      if (ok) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('暂无可用客户端'),
            content: Text(
              '已记录目标：$_protocol://$host:$port\n\n'
              '当前版本为入口占位。请安装系统远程桌面客户端，'
              '或等待后续内置 WebRTC / 协议支持。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('远程桌面')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border.withOpacity(0.5)),
            ),
            child: Text(
              '第一版为入口占位：填写目标后尝试唤起系统客户端。'
              '后续可接入内置远程桌面（WebRTC 等）。',
              style: TextStyle(fontSize: 13, color: colors.secondaryText, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          Text('协议', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['RDP', 'VNC', 'SSH'].map((p) {
              return ChoiceChip(
                label: Text(p),
                selected: _protocol == p,
                onSelected: (_) => setState(() {
                  _protocol = p;
                  if (p == 'RDP') _portCtrl.text = '3389';
                  if (p == 'VNC') _portCtrl.text = '5900';
                  if (p == 'SSH') _portCtrl.text = '22';
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: '主机地址',
              hintText: 'IP 或域名',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portCtrl,
            decoration: const InputDecoration(labelText: '端口'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _connect,
              child: const Text('连接'),
            ),
          ),
        ],
      ),
    );
  }
}
