import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../data/ops_favorite_target.dart';

class OpsFavoritesPage extends ConsumerStatefulWidget {
  const OpsFavoritesPage({super.key});

  @override
  ConsumerState<OpsFavoritesPage> createState() => _OpsFavoritesPageState();
}

class _OpsFavoritesPageState extends ConsumerState<OpsFavoritesPage> {
  final _store = OpsFavoriteTargetStore();
  List<OpsFavoriteTarget> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await _store.list();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _addOrEdit([OpsFavoriteTarget? existing]) async {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final hostCtrl = TextEditingController(text: existing?.host ?? '');
    final portCtrl = TextEditingController(
      text: existing?.defaultPort?.toString() ?? '',
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '添加收藏' : '编辑收藏'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: '显示名')),
              TextField(controller: hostCtrl, decoration: const InputDecoration(labelText: '主机')),
              TextField(
                controller: portCtrl,
                decoration: const InputDecoration(labelText: '默认端口（可选）'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: '备注')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    final host = hostCtrl.text.trim();
    if (host.isEmpty) return;
    final port = int.tryParse(portCtrl.text.trim());
    if (existing != null) {
      await _store.delete(existing.id);
    }
    await _store.add(
      label: labelCtrl.text.trim().isEmpty ? host : labelCtrl.text.trim(),
      host: host,
      defaultPort: port,
      note: noteCtrl.text.trim(),
    );
    await _reload();
  }

  Future<void> _delete(OpsFavoriteTarget t) async {
    await _store.delete(t.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('收藏目标'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _addOrEdit()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('暂无收藏', style: TextStyle(color: colors.secondaryText)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = _items[i];
                    return Card(
                      child: ListTile(
                        title: Text(t.label),
                        subtitle: Text(
                          [
                            t.host,
                            if (t.defaultPort != null) '端口 ${t.defaultPort}',
                            if (t.note.isNotEmpty) t.note,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _addOrEdit(t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(t),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
