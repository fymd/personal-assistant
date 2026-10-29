import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/ops_history_repository.dart';

/// 阶段 3：HTTP(S) 状态码与耗时探测
class HttpCheckPage extends ConsumerStatefulWidget {
  const HttpCheckPage({super.key});

  @override
  ConsumerState<HttpCheckPage> createState() => _HttpCheckPageState();
}

class _HttpCheckPageState extends ConsumerState<HttpCheckPage> {
  final _urlCtrl = TextEditingController(text: 'https://www.baidu.com');
  String _method = 'GET';
  bool _running = false;
  String? _result;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    setState(() {
      _running = true;
      _result = null;
    });
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: true,
      validateStatus: (_) => true,
    ));
    final sw = Stopwatch()..start();
    try {
      final res = _method == 'HEAD'
          ? await dio.head(url)
          : await dio.get(url);
      sw.stop();
      final text =
          '$_method $url\n状态: ${res.statusCode}\n耗时: ${sw.elapsedMilliseconds} ms\n'
          '长度: ${res.headers.value('content-length') ?? (res.data is List ? (res.data as List).length : '-')}';
      if (!mounted) return;
      setState(() {
        _running = false;
        _result = text;
      });
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _running = false;
        _result = '失败 (${sw.elapsedMilliseconds} ms)\n$e';
      });
    }
  }

  Future<void> _saveHistory() async {
    if (_result == null) return;
    final token = ref.read(authStateProvider).token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再同步历史')),
      );
      return;
    }
    try {
      await OpsHistoryRepository(token: token).create(
        tool: 'http_check',
        target: _urlCtrl.text.trim(),
        summary: _result!.split('\n').take(2).join(' · '),
        detail: _result!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已同步到运维历史')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('HTTP 探测')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['GET', 'HEAD'].map((m) {
              return ChoiceChip(
                label: Text(m),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _running ? null : _check,
              child: Text(_running ? '请求中…' : '开始探测'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_result!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saveHistory,
              child: const Text('同步到运维历史'),
            ),
          ],
        ],
      ),
    );
  }
}
