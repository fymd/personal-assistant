import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/remote_desktop_repository.dart';
import 'gateway_webview_page.dart';
import 'native_rd_placeholder_page.dart';

/// 远程桌面：阶段 1 外置 / 阶段 2 网关 / 阶段 3 内置占位
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
  final _gatewayCtrl = TextEditingController();
  String _protocol = 'RDP';
  String _connectMode = 'external';
  String? _editingId;

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
    _gatewayCtrl.dispose();
    super.dispose();
  }

  RemoteDesktopRepository? _repo() {
    final token = ref.read(authStateProvider).token;
    if (token == null || token.isEmpty) return null;
    return RemoteDesktopRepository(token: token);
  }

  void _clearForm() {
    _editingId = null;
    _nameCtrl.clear();
    _hostCtrl.clear();
    _userCtrl.clear();
    _gatewayCtrl.clear();
    _protocol = 'RDP';
    _connectMode = 'external';
    _portCtrl.text = '3389';
  }

  void _fillForm(RemoteDesktopProfile p) {
    setState(() {
      _editingId = p.id;
      _nameCtrl.text = p.name;
      _hostCtrl.text = p.host == '-' ? '' : p.host;
      _portCtrl.text = '${p.port}';
      _userCtrl.text = p.username;
      _protocol = p.protocol;
      _connectMode = p.connectMode;
      _gatewayCtrl.text = p.gatewayUrl;
    });
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
    final mode = _connectMode;
    final host = _hostCtrl.text.trim();
    final gateway = _gatewayCtrl.text.trim();
    if (mode == 'gateway') {
      if (gateway.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网关模式请填写网关 URL')),
        );
        return;
      }
    } else if (host.isEmpty) {
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
    final name = _nameCtrl.text.trim().isEmpty
        ? (host.isEmpty ? '网关连接' : host)
        : _nameCtrl.text.trim();
    try {
      if (_editingId != null) {
        await repo.update(
          _editingId!,
          name: name,
          protocol: _protocol,
          host: host.isEmpty ? '-' : host,
          port: port,
          username: _userCtrl.text.trim(),
          connectMode: mode,
          gatewayUrl: gateway,
        );
      } else {
        await repo.create(
          name: name,
          protocol: _protocol,
          host: host.isEmpty ? '-' : host,
          port: port,
          username: _userCtrl.text.trim(),
          connectMode: mode,
          gatewayUrl: gateway,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editingId != null ? '已更新' : '已保存')),
      );
      setState(_clearForm);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确定删除「${p.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.delete(p.id);
      if (_editingId == p.id) setState(_clearForm);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  Future<void> _connectProfile(RemoteDesktopProfile p) async {
    await _connect(
      mode: p.connectMode,
      protocol: p.protocol,
      host: p.host == '-' ? '' : p.host,
      port: p.port,
      gatewayUrl: p.gatewayUrl,
      title: p.name,
    );
  }

  Future<void> _connect({
    String? mode,
    String? protocol,
    String? host,
    int? port,
    String? gatewayUrl,
    String? title,
  }) async {
    final m = mode ?? _connectMode;
    final p = protocol ?? _protocol;
    final h = host ?? _hostCtrl.text.trim();
    final pt = port ?? int.tryParse(_portCtrl.text.trim()) ?? 3389;
    final gw = gatewayUrl ?? _gatewayCtrl.text.trim();
    final name = title ?? _nameCtrl.text.trim();

    if (m == 'gateway') {
      if (gw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写网关 URL')),
        );
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GatewayWebViewPage(
            title: name.isEmpty ? '远程网关' : name,
            url: gw,
          ),
        ),
      );
      return;
    }

    if (m == 'native') {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NativeRdPlaceholderPage(
            name: name,
            protocol: p,
            host: h.isEmpty ? '-' : h,
            port: pt,
          ),
        ),
      );
      return;
    }

    // external
    if (h.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入主机地址')),
      );
      return;
    }
    Uri uri;
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
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('暂无可用客户端'),
            content: Text(
              '目标：$p://$h:$pt\n\n'
              '请安装系统客户端，或改用「网关」模式打开 Guacamole/RustDesk Web。',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
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

  String _modeLabel(String m) {
    switch (m) {
      case 'gateway':
        return '网关';
      case 'native':
        return '内置';
      default:
        return '外置';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final formTitle = _editingId != null ? '编辑连接' : '新建连接';
    final saveLabel = _editingId != null ? '更新配置' : '保存配置';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('远程桌面'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
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
              '外置：系统 RDP/VNC/SSH　·　网关：WebView 打开 Guacamole/RustDesk　·　内置：阶段 3 占位\n'
              '详见 docs/REMOTE_DESKTOP.md。服务端不存密码。',
              style: TextStyle(fontSize: 13, color: colors.secondaryText, height: 1.4),
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
              final selected = _editingId == p.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: selected ? colors.surfaceVariant : null,
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    '${_modeLabel(p.connectMode)} · ${p.protocol}'
                    '${p.connectMode == 'gateway' ? '' : ' · ${p.host}:${p.port}'}'
                    '${p.connectMode == 'gateway' && p.gatewayUrl.isNotEmpty ? ' · 网关' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _fillForm(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _connectProfile(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(p),
                      ),
                    ],
                  ),
                  onTap: () => _connectProfile(p),
                  onLongPress: () => _fillForm(p),
                ),
              );
            }),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(formTitle, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (_editingId != null)
                TextButton(
                  onPressed: () => setState(_clearForm),
                  child: const Text('取消编辑'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('连接模式', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ('external', '外置客户端'),
              ('gateway', '网关 WebView'),
              ('native', '内置(占位)'),
            ].map((e) {
              return ChoiceChip(
                label: Text(e.$2),
                selected: _connectMode == e.$1,
                onSelected: (_) => setState(() => _connectMode = e.$1),
              );
            }).toList(),
          ),
          if (_connectMode == 'gateway') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _gatewayCtrl,
              decoration: const InputDecoration(
                labelText: '网关 URL',
                hintText: 'https://guac.example.com/',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
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
          if (_connectMode != 'gateway') ...[
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
          ],
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
                  child: Text(saveLabel),
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
