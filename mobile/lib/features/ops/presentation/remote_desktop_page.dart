import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/remote_desktop_repository.dart';

/// 远程桌面：连接配置管理 + 唤起系统客户端（阶段 1）
class RemoteDesktopPage extends ConsumerStatefulWidget {
  const RemoteDesktopPage({super.key});

  @override
  ConsumerState<RemoteDesktopPage> createState() => _RemoteDesktopPageState();
}

class _RemoteDesktopPageState extends ConsumerState<RemoteDesktopPage> {
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '3389');
  final _userCtrl = TextEditingController();
  String _protocol = 'RDP';

  List<RemoteDesktopProfile> _profiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  RemoteDesktopRepository? _repo() {
    final token = ref.read(authStateProvider).token;
    if (token == null || token.isEmpty) return null;
    return RemoteDesktopRepository(token: token);
  }

  Future<void> _load() async {
    final repo = _repo();
    if (repo == null) {
      setState(() {
        _loading = false;
        _error = '请先登录以同步连接配置';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await repo.list();
      if (!mounted) return;
      setState(() {
        _profiles = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入主机地址')),
      );
      return;
    }
    final repo = _repo();
    if (repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }
    final port = int.tryParse(_portCtrl.text.trim()) ?? 3389;
    final name =
        _nameCtrl.text.trim().isEmpty ? host : _nameCtrl.text.trim();
    try {
      await repo.create(
        name: name,
        protocol: _protocol,
        host: host,
        port: port,
        username: _userCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
      _nameCtrl.clear();
      _hostCtrl.clear();
      _userCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  Future<void> _delete(RemoteDesktopProfile p) async {
    final repo = _repo();
    if (repo == null) return;
    try {
      await repo.delete(p.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  Future<void> _connect({String? protocol, String? host, int? port}) async {
    final p = protocol ?? _protocol;
    final h = host ?? _hostCtrl.text.trim();
    final pt = port ?? int.tryParse(_portCtrl.text.trim()) ?? 3389;
    if (h.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入主机地址')),
      );
      return;
    }

    Uri? uri;
    if (p == 'RDP') {
      uri = Uri.parse('rdp://full%20address=s:$h:$pt');
    } else if (p == 'VNC') {
      uri = Uri.parse('vnc://$h:$pt');
    } else {
      uri = Uri.parse('ssh://$h:$pt');
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
              '目标：$p://$h:$pt\n\n'
              '阶段 1：保存配置并尝试唤起系统远程桌面 / SSH / VNC 客户端。\n'
              '内置画面传输（WebRTC 网关等）将在后续版本提供。',
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
      appBar: AppBar(
        title: const Text('远程桌面'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
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
              '阶段 1：多设备同步连接配置，并尝试唤起系统客户端（RDP/VNC/SSH）。'
              '不在服务端存储密码。内置远程画面见后续版本。',
              style: TextStyle(
                  fontSize: 13, color: colors.secondaryText, height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          Text('已保存', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            )
          else if (_profiles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('暂无保存的连接', style: TextStyle(color: colors.secondaryText)),
            )
          else
            ..._profiles.map((p) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text('${p.protocol} · ${p.host}:${p.port}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _connect(
                          protocol: p.protocol,
                          host: p.host,
                          port: p.port,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(p),
                      ),
                    ],
                  ),
                  onTap: () => _connect(
                    protocol: p.protocol,
                    host: p.host,
                    port: p.port,
                  ),
                ),
              );
            }),
          const Divider(height: 32),
          Text('新建连接', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '名称（可选）',
              hintText: '如 公司办公机',
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: '用户名（可选，仅备注）',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _save,
                  child: const Text('保存配置'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _connect(),
                  child: const Text('连接'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
