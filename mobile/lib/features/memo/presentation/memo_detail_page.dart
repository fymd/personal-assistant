import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme_provider.dart';
import '../data/memo_model.dart';
import 'memo_provider.dart';

/// Apple Notes 风格：即编辑即保存（防抖自动同步）。
class MemoDetailPage extends ConsumerStatefulWidget {
  final Memo memo;

  const MemoDetailPage({super.key, required this.memo});

  @override
  ConsumerState<MemoDetailPage> createState() => _MemoDetailPageState();
}

enum _SaveState { idle, dirty, saving, saved, error }

class _MemoDetailPageState extends ConsumerState<MemoDetailPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late String _tag;
  late bool _starred;
  late bool _completed;

  Timer? _debounce;
  _SaveState _saveState = _SaveState.idle;
  DateTime? _lastSavedAt;
  bool _disposed = false;

  static const _tags = ['工作', '灵感', '学习', '生活'];
  static const _debounceMs = 700;

  @override
  void initState() {
    super.initState();
    final m = widget.memo;
    _titleCtrl = TextEditingController(text: m.title);
    _contentCtrl = TextEditingController(text: m.content);
    _tag = m.tag.isEmpty ? '工作' : m.tag;
    _starred = m.starred;
    _completed = m.completed;
    _lastSavedAt = m.updatedAt;

    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    unawaited(_flushSave(silent: true));
    _titleCtrl.removeListener(_onTextChanged);
    _contentCtrl.removeListener(_onTextChanged);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_saveState != _SaveState.dirty) {
      setState(() => _saveState = _SaveState.dirty);
    }
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      unawaited(_flushSave());
    });
  }

  String _effectiveTitle() {
    final t = _titleCtrl.text.trim();
    if (t.isNotEmpty) return t;
    final firstLine = _contentCtrl.text
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (firstLine.isNotEmpty) {
      return firstLine.length > 40 ? '${firstLine.substring(0, 40)}…' : firstLine;
    }
    return '无标题';
  }

  Future<void> _flushSave({bool silent = false}) async {
    if (_disposed) return;
    _debounce?.cancel();

    final title = _effectiveTitle();
    final content = _contentCtrl.text;

    if (!silent && mounted) {
      setState(() => _saveState = _SaveState.saving);
    }

    try {
      await ref.read(memoListProvider.notifier).update(
            widget.memo.id,
            title: title,
            content: content,
            tag: _tag,
            starred: _starred,
            completed: _completed,
          );
      if (_disposed || !mounted) return;
      setState(() {
        _saveState = _SaveState.saved;
        _lastSavedAt = DateTime.now();
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!_disposed && mounted && _saveState == _SaveState.saved) {
          setState(() => _saveState = _SaveState.idle);
        }
      });
    } catch (e) {
      if (_disposed || !mounted) return;
      setState(() => _saveState = _SaveState.error);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleStar() async {
    setState(() {
      _starred = !_starred;
      _saveState = _SaveState.dirty;
    });
    await _flushSave();
  }

  Future<void> _toggleCompleted() async {
    setState(() {
      _completed = !_completed;
      _saveState = _SaveState.dirty;
    });
    await _flushSave();
  }

  void _setTag(String t) {
    if (t == _tag) return;
    setState(() {
      _tag = t;
      _saveState = _SaveState.dirty;
    });
    _scheduleSave();
  }

  Widget _buildStatus(Color secondary, Color success, Color danger) {
    final style = TextStyle(fontSize: 12, color: secondary, fontWeight: FontWeight.w400);
    switch (_saveState) {
      case _SaveState.dirty:
        return Text('编辑中…', style: style);
      case _SaveState.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: secondary),
            ),
            const SizedBox(width: 6),
            Text('正在保存', style: style),
          ],
        );
      case _SaveState.saved:
        return Text('已保存', style: style.copyWith(color: success));
      case _SaveState.error:
        return GestureDetector(
          onTap: () => _flushSave(),
          child: Text('保存失败 · 点按重试', style: style.copyWith(color: danger)),
        );
      case _SaveState.idle:
        if (_lastSavedAt == null) return const SizedBox.shrink();
        return Text(
          DateFormat('M月d日 HH:mm').format(_lastSavedAt!.toLocal()),
          style: style,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: colors.primary),
          onPressed: () async {
            await _flushSave(silent: true);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        title: _buildStatus(colors.secondaryText, colors.success, colors.danger),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _starred ? '取消收藏' : '收藏',
            onPressed: _toggleStar,
            icon: Icon(
              _starred ? CupertinoIcons.star_fill : CupertinoIcons.star,
              color: _starred ? const Color(0xFFFF9F0A) : colors.secondaryText,
              size: 22,
            ),
          ),
          IconButton(
            tooltip: _completed ? '标为未完成' : '标为完成',
            onPressed: _toggleCompleted,
            icon: Icon(
              _completed
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: _completed ? const Color(0xFF30D158) : colors.secondaryText,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottomInset),
              children: [
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tags.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = _tags[i];
                      final selected = t == _tag;
                      return ChoiceChip(
                        label: Text(t),
                        selected: selected,
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? colors.primary : colors.secondaryText,
                        ),
                        selectedColor: colors.primary.withOpacity(0.12),
                        backgroundColor: colors.surface,
                        side: BorderSide(
                          color: selected
                              ? colors.primary.withOpacity(0.35)
                              : colors.border.withOpacity(0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) => _setTag(t),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleCtrl,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.25,
                    color: colors.onSurface,
                  ),
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    hintText: '标题',
                    hintStyle: TextStyle(
                      color: colors.secondaryText.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.border.withOpacity(0.45)),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentCtrl,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    color: colors.onSurface,
                  ),
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    hintText: '开始写作…',
                    hintStyle: TextStyle(
                      color: colors.secondaryText.withOpacity(0.5),
                      fontSize: 17,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  minLines: 16,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
