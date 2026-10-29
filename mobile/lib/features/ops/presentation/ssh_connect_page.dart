import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_provider.dart';

/// 阶段 2：SSH 快速连接（唤起系统 SSH / Termius 等）
class SshConnectPage extends ConsumerStatefulWidget {
  const SshConnectPage({super.key});

  @override
  ConsumerState<SshConnectPage> createState() => _SshConnectPageState();
}

class _SshConnectPageState extends ConsumerState<SshConnectPage> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '22');
  final _userCtrl = TextEditingController();

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入主机')),
      );
      return;
    }
    final port = int.tryParse(_portCtrl.text.trim()) ?? 22;
    final user = _userCtrl.text.trim();
    final authority = user.isEmpty ? host : '$user@$host';
    final uri = Uri(
      scheme: 'ssh',
      path: authority,
      // ssh://user@host:port 在部分客户端对 port 支持不一致，附带 query 作兼容提示
    );
    // 优先带端口的形式
    final withPort = user.isEmpty
        ? Uri.parse('ssh://$host:$port')
        : Uri.parse('ssh://$user@$host:$port');

    try {
      var target = withPort;
      if (!await canLaunchUrl(target)) {
        target = uri;
      }
      if (await canLaunchUrl(target)) {
        await launchUrl(target, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('未找到 SSH 客户端'),
            content: Text(
              '目标：ssh://${user.isEmpty ? '' : '$user@'}$host:$port\n\n'
              '请安装系统终端、Termius、Prompt 等支持 ssh:// 的应用。',
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
      appBar: AppBar(title: const Text('SSH 连接')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '通过 URL Scheme 唤起本机 SSH 客户端，不在 App 内建立加密隧道，也不保存密码。',
            style: TextStyle(fontSize: 13, color: colors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: '主机',
              hintText: 'IP 或域名',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portCtrl,
            decoration: const InputDecoration(labelText: '端口'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: '用户名（可选）',
              hintText: 'root',
            ),
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
