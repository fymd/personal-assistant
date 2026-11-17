import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/theme_provider.dart';
import '../data/ops_inspect_template.dart';

class OpsInspectEditPage extends ConsumerStatefulWidget {
  final OpsInspectTemplate? existing;

  const OpsInspectEditPage({super.key, this.existing});

  @override
  ConsumerState<OpsInspectEditPage> createState() => _OpsInspectEditPageState();
}

class _OpsInspectEditPageState extends ConsumerState<OpsInspectEditPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portsCtrl;
  late final TextEditingController _httpCtrl;
  late final TextEditingController _pingPortCtrl;
  late bool _doPing;
  late bool _doDns;
  late bool _doPorts;
  late bool _doHttp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _hostCtrl = TextEditingController(text: e?.host ?? '');
    _portsCtrl = TextEditingController(
      text: e?.ports.isNotEmpty == true ? e!.ports.join(',') : '22,80,443',
    );
    _httpCtrl = TextEditingController(
      text: e?.httpUrls.isNotEmpty == true ? e!.httpUrls.join('\n') : 'https://',
    );
    _pingPortCtrl = TextEditingController(text: '${e?.pingPort ?? 80}');
    _doPing = e?.doPing ?? true;
    _doDns = e?.doDns ?? true;
    _doPorts = e?.doPorts ?? true;
    _doHttp = e?.doHttp ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portsCtrl.dispose();
    _httpCtrl.dispose();
    _pingPortCtrl.dispose();
    super.dispose();
  }

  List<int> _parsePorts(String s) {
    return s
        .split(RegExp(r'[,，\s]+'))
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0 && e <= 65535)
        .toSet()
        .take(32)
        .toList();
  }

  List<String> _parseUrls(String s) {
    return s
        .split(RegExp(r'[\n,，]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'https://' && e != 'http://')
        .take(16)
        .toList();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final host = _hostCtrl.text.trim();
    if (name.isEmpty || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称与主机')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = widget.existing;
    final t = OpsInspectTemplate(
      id: existing?.id ?? const Uuid().v4(),
      name: name,
      host: host,
      ports: _parsePorts(_portsCtrl.text),
      httpUrls: _parseUrls(_httpCtrl.text),
      doPing: _doPing,
      doDns: _doDns,
      doPorts: _doPorts,
      doHttp: _doHttp,
      pingPort: int.tryParse(_pingPortCtrl.text.trim()) ?? 80,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await OpsInspectTemplateStore().upsert(t);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(isEdit ? '编辑巡检模板' : '新建巡检模板'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '模板名称',
              hintText: '如：办公机日常巡检',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: '目标主机',
              hintText: '域名或 IP',
            ),
          ),
          const SizedBox(height: 16),
          Text('检查项', style: TextStyle(color: colors.secondaryText, fontSize: 13)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('DNS 解析'),
            value: _doDns,
            onChanged: (v) => setState(() => _doDns = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('TCP Ping'),
            value: _doPing,
            onChanged: (v) => setState(() => _doPing = v),
          ),
          if (_doPing)
            TextField(
              controller: _pingPortCtrl,
              decoration: const InputDecoration(labelText: 'Ping 端口'),
              keyboardType: TextInputType.number,
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('端口扫描'),
            value: _doPorts,
            onChanged: (v) => setState(() => _doPorts = v),
          ),
          if (_doPorts)
            TextField(
              controller: _portsCtrl,
              decoration: const InputDecoration(
                labelText: '端口列表',
                hintText: '逗号分隔，最多 32 个',
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('HTTP 探测'),
            value: _doHttp,
            onChanged: (v) => setState(() => _doHttp = v),
          ),
          if (_doHttp)
            TextField(
              controller: _httpCtrl,
              decoration: const InputDecoration(
                labelText: 'HTTP URL',
                hintText: '每行一个，或 /path 相对主机',
              ),
              minLines: 2,
              maxLines: 6,
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: const Text('保存模板'),
            ),
          ),
        ],
      ),
    );
  }
}
