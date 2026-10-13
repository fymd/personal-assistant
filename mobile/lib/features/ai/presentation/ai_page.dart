import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/ai_repository.dart';

class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});

  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  String _action = 'general';
  bool _mockHintShown = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send({String? preset, String? action}) async {
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;

    final act = action ?? _action;
    final token = ref.read(authStateProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _loading = true;
      if (preset == null) _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final repo = AiRepository(token: token);
      // 只传近期上下文，避免过长
      final history = _messages.length > 12
          ? _messages.sublist(_messages.length - 12)
          : List<ChatMessage>.from(_messages);
      final result = await repo.chat(messages: history, action: act);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: result.reply));
        _loading = false;
        if (result.mock && !_mockHintShown) {
          _mockHintShown = true;
        }
      });
      _scrollToBottom();
      if (result.mock && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('当前为演示模式：服务端未配置 AI_API_KEY'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messages.add(ChatMessage(
          role: 'assistant',
          content: '请求失败：$e',
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _applyAction(String action, String hint) {
    setState(() => _action = action);
    if (_inputCtrl.text.trim().isEmpty) {
      _inputCtrl.text = hint;
      _inputCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _inputCtrl.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('AI 助手'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: '清空',
              onPressed: () => setState(() => _messages.clear()),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyHint(colors: colors)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_loading && i == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: colors.border.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('思考中…',
                                    style: TextStyle(
                                        color: colors.secondaryText,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }
                      final m = _messages[i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser
                                ? colors.primary.withOpacity(0.12)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: colors.border.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                m.content,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: colors.onSurface,
                                ),
                              ),
                              if (!isUser) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      iconSize: 18,
                                      tooltip: '复制',
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: m.content));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('已复制'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.copy_outlined,
                                          size: 16,
                                          color: colors.secondaryText),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 快捷动作
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _ActionChip(
                  label: '生成待办',
                  selected: _action == 'todos',
                  onTap: () => _applyAction(
                      'todos', '帮我生成今天的工作待办：'),
                ),
                _ActionChip(
                  label: '润色文字',
                  selected: _action == 'polish',
                  onTap: () =>
                      _applyAction('polish', '请润色以下文字：\n'),
                ),
                _ActionChip(
                  label: '总结内容',
                  selected: _action == 'summarize',
                  onTap: () =>
                      _applyAction('summarize', '请总结以下内容：\n'),
                ),
                _ActionChip(
                  label: '自由对话',
                  selected: _action == 'general',
                  onTap: () => setState(() => _action = 'general'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 输入区
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '输入任务，例如：帮我总结这段文字',
                        filled: true,
                        fillColor: colors.surface,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : () => _send(),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final dynamic colors;

  const _EmptyHint({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 48, color: colors.secondaryText),
            const SizedBox(height: 12),
            Text(
              '任务辅助 · 总结 · 润色 · 生成待办',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '选择下方快捷能力，或直接输入问题',
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
