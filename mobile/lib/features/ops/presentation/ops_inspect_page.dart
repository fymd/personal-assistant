import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../data/ops_history_detail.dart';
import '../data/ops_history_sync.dart';
import '../data/ops_inspect_runner.dart';
import '../data/ops_inspect_template.dart';
import 'ops_inspect_edit_page.dart';

/// 巡检模板列表 + 一键执行
class OpsInspectPage extends ConsumerStatefulWidget {
  const OpsInspectPage({super.key});

  @override
  ConsumerState<OpsInspectPage> createState() => _OpsInspectPageState();
}

class _OpsInspectPageState extends ConsumerState<OpsInspectPage> {
  final _store = OpsInspectTemplateStore();
  List<OpsInspectTemplate> _items = [];
  bool _loading = true;
  bool _running = false;
  String? _runningId;
  List<InspectStepResult> _steps = [];
  OpsInspectTemplate? _lastRan;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await _store.list();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _edit([OpsInspectTemplate? t]) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OpsInspectEditPage(existing: t)),
    );
    if (ok == true) await _reload();
  }

  Future<void> _delete(OpsInspectTemplate t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定删除「${t.name}」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true) return;
    await _store.delete(t.id);
    await _reload();
  }

  Future<void> _run(OpsInspectTemplate t) async {
    if (_running) return;
    setState(() {
      _running = true;
      _runningId = t.id;
      _steps = [];
      _lastRan = t;
    });
    final runner = OpsInspectRunner();
    await runner.run(
      t,
      onStep: (step) {
        if (!mounted) return;
        setState(() => _steps = List.from(_steps)..add(step));
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _runningId = null;
    });
  }

  Future<void> _syncHistory() async {
    final t = _lastRan;
    if (t == null || _steps.isEmpty) return;
    final okCount = _steps.where((e) => e.ok).length;
    final failCount = _steps.length - okCount;
    final detail = OpsHistoryDetail.inspect(
      templateName: t.name,
      host: t.host,
      steps: _steps.map((e) => e.toJson()).toList(),
      okCount: okCount,
      failCount: failCount,
    );
    await syncOpsHistory(
      context,
      ref,
      tool: 'inspect',
      target: t.host,
      summary: '${t.name} · 通过 $okCount / ${_steps.length}',
      detail: detail,
    );
  }

  String _summaryOf(OpsInspectTemplate t) {
    final parts = <String>[];
    if (t.doDns) parts.add('DNS');
    if (t.doPing) parts.add('Ping:${t.pingPort}');
    if (t.doPorts && t.ports.isNotEmpty) parts.add('端口×${t.ports.length}');
    if (t.doHttp && t.httpUrls.isNotEmpty) parts.add('HTTP×${t.httpUrls.length}');
    return parts.isEmpty ? '未选择检查项' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final okCount = _steps.where((e) => e.ok).length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('巡检模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _running ? null : () => _edit(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('暂无模板', style: TextStyle(color: colors.secondaryText)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _edit(),
                                icon: const Icon(Icons.add),
                                label: const Text('新建巡检模板'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final t = _items[i];
                            final isRunning = _running && _runningId == t.id;
                            return Card(
                              child: ListTile(
                                title: Text(t.name),
                                subtitle: Text('${t.host}\n${_summaryOf(t)}'),
                                isThreeLine: true,
                                trailing: isRunning
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'run') _run(t);
                                          if (v == 'edit') _edit(t);
                                          if (v == 'delete') _delete(t);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'run', child: Text('执行')),
                                          const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                          const PopupMenuItem(value: 'delete', child: Text('删除')),
                                        ],
                                      ),
                                onTap: _running ? null : () => _run(t),
                              ),
                            );
                          },
                        ),
                ),
                if (_steps.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _running
                                ? '巡检中… ${_steps.length} 步'
                                : '结果：通过 $okCount / ${_steps.length}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (!_running)
                          TextButton.icon(
                            onPressed: _syncHistory,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: const Text('同步历史'),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _steps.length,
                      itemBuilder: (_, i) {
                        final s = _steps[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            s.ok ? Icons.check_circle : Icons.cancel,
                            color: s.ok ? colors.success : colors.danger,
                            size: 20,
                          ),
                          title: Text(s.label, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            s.ms != null ? '${s.message} · ${s.ms} ms' : s.message,
                            style: TextStyle(color: colors.secondaryText, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
