import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../data/memo_model.dart';
import 'memo_provider.dart';

class MemoDetailPage extends ConsumerStatefulWidget {
  final Memo memo;

  const MemoDetailPage({super.key, required this.memo});

  @override
  ConsumerState<MemoDetailPage> createState() => _MemoDetailPageState();
}

class _MemoDetailPageState extends ConsumerState<MemoDetailPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late String _tag;
  late bool _starred;
  late bool _completed;
  bool _saving = false;
  bool _dirty = false;

  static const _tags = ['工作', '灵感', '学习', '生活'];

  @override
  void initState() {
    super.initState();
    final m = widget.memo;
    _titleCtrl = TextEditingController(text: m.title);
    _contentCtrl = TextEditingController(text: m.content);
    _tag = m.tag.isEmpty ? '工作' : m.tag;
    _starred = m.starred;
    _completed = m.completed;

    _titleCtrl.addListener(_markDirty);
    _contentCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标题不能为空')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(memoListProvider.notifier).update(
            widget.memo.id,
            title: title,
            content: _contentCtrl.text.trim(),
            tag: _tag,
            starred: _starred,
            completed: _completed,
          );
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已保存'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的修改'),
        content: const Text('要保存后再离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      return !_dirty;
    }
    return result == 'discard';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (ok && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('详情'),
          actions: [
            IconButton(
              tooltip: _starred ? '取消收藏' : '收藏',
              onPressed: () {
                setState(() {
                  _starred = !_starred;
                  _dirty = true;
                });
              },
              icon: Icon(
                _starred ? Icons.star : Icons.star_border,
                color: _starred ? colors.tagOrange : null,
              ),
            ),
            IconButton(
              tooltip: _completed ? '标为未完成' : '标为完成',
              onPressed: () {
                setState(() {
                  _completed = !_completed;
                  _dirty = true;
                });
              },
              icon: Icon(
                _completed ? Icons.check_circle : Icons.circle_outlined,
                color: _completed ? colors.success : null,
              ),
            ),
            TextButton(
              onPressed: _saving || !_dirty ? null : _save,
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Text(
                      '保存',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _dirty ? colors.primary : colors.secondaryText,
                      ),
                    ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // 时间信息
            Text(
              '创建于 ${DateFormat('yyyy-MM-dd HH:mm').format(widget.memo.createdAt)}'
              '  ·  更新于 ${DateFormat('MM-dd HH:mm').format(widget.memo.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),

            // 标题
            TextField(
              controller: _titleCtrl,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 8),

            // 标签
            Text('标签', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _tags.map((t) {
                final selected = t == _tag;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _tag = t;
                      _dirty = true;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Divider(color: colors.border),
            const SizedBox(height: 12),

            // 正文
            TextField(
              controller: _contentCtrl,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              decoration: InputDecoration(
                hintText: '写点什么…',
                hintStyle: TextStyle(color: colors.secondaryText),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              minLines: 8,
            ),
          ],
        ),
      ),
    );
  }
}
