import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/ops_history_repository.dart';

class OpsHistoryPage extends ConsumerStatefulWidget {
  const OpsHistoryPage({super.key});

  @override
  ConsumerState<OpsHistoryPage> createState() => _OpsHistoryPageState();
}

class _OpsHistoryPageState extends ConsumerState<OpsHistoryPage> {
  List<OpsHistoryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = ref.read(authStateProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = '请先登录';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await OpsHistoryRepository(token: token).list();
      if (!mounted) return;
      setState(() {
        _items = list;
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

  Future<void> _delete(OpsHistoryItem item) async {
    final token = ref.read(authStateProvider).token;
    if (token == null) return;
    try {
      await OpsHistoryRepository(token: token).delete(item.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  String _toolLabel(String t) {
    switch (t) {
      case 'port_scan':
        return '端口扫描';
      case 'network_diag':
        return '网络诊断';
      case 'http_check':
        return 'HTTP 探测';
      case 'ping':
        return 'Ping';
      case 'dns':
        return 'DNS';
      default:
        return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('运维历史'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: colors.danger)))
              : _items.isEmpty
                  ? Center(
                      child: Text('暂无记录', style: TextStyle(color: colors.secondaryText)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Card(
                          child: ListTile(
                            title: Text('${_toolLabel(item.tool)} · ${item.target}'),
                            subtitle: Text(
                              '${item.summary}\n${item.createdAt}',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(item),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(_toolLabel(item.tool)),
                                  content: SingleChildScrollView(
                                    child: SelectableText(
                                      '${item.summary}\n\n${item.detail}'.trim(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('关闭'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
