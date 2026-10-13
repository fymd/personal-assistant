import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_type.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/memo_model.dart';
import 'memo_provider.dart';

class MemoListPage extends ConsumerWidget {
  const MemoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final filter = ref.watch(memoFilterProvider);
    final memosAsync = ref.watch(memoListProvider);
    final themeType = ref.watch(themeTypeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('备忘录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: '切换主题',
            onPressed: () => _showThemePicker(context, ref, themeType),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选 Chip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: MemoFilter.values.map((f) {
                final selected = f == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) {
                      ref.read(memoFilterProvider.notifier).state = f;
                    },
                    selectedColor: colors.primary.withOpacity(0.12),
                    checkmarkColor: colors.primary,
                    labelStyle: TextStyle(
                      color: selected ? colors.primary : colors.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? colors.primary.withOpacity(0.4) : colors.border,
                    ),
                    backgroundColor: colors.surface,
                  ),
                );
              }).toList(),
            ),
          ),

          // 列表
          Expanded(
            child: memosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('加载失败', style: TextStyle(color: colors.danger)),
                    const SizedBox(height: 8),
                    Text('$e', style: TextStyle(color: colors.secondaryText, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.read(memoListProvider.notifier).load(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_add_outlined, size: 48, color: colors.secondaryText),
                        const SizedBox(height: 12),
                        Text(
                          '暂无备忘录',
                          style: TextStyle(color: colors.secondaryText, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击右下角 + 添加第一条',
                          style: TextStyle(color: colors.secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(memoListProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _MemoCard(
                        memo: list[index],
                        colors: colors,
                        onToggle: () => ref
                            .read(memoListProvider.notifier)
                            .toggleComplete(list[index].id),
                        onDelete: () => _confirmDelete(context, ref, list[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref, colors),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: '工具'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, AppColors colors) {
    final titleCtrl = TextEditingController();
    String selectedTag = '工作';
    final tags = ['工作', '灵感', '学习', '生活'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('新建备忘录', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '输入标题…',
                    ),
                    onSubmitted: (_) async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      await ref.read(memoListProvider.notifier).create(
                            title: titleCtrl.text.trim(),
                            tag: selectedTag,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: tags.map((t) {
                      final selected = t == selectedTag;
                      return ChoiceChip(
                        label: Text(t),
                        selected: selected,
                        onSelected: (_) => setModalState(() => selectedTag = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      try {
                        await ref.read(memoListProvider.notifier).create(
                              title: titleCtrl.text.trim(),
                              tag: selectedTag,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('创建失败：$e')),
                          );
                        }
                      }
                    },
                    child: const Text('创建'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Memo memo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除备忘录'),
        content: Text('确定删除「${memo.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(memoListProvider.notifier).delete(memo.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败：$e')),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, AppThemeType currentType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('选择主题', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...AppThemeType.values.map((type) {
                final selected = type == currentType;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(type.displayName),
                  subtitle: Text(type.description),
                  onTap: () {
                    ref.read(themeTypeProvider.notifier).setTheme(type);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _MemoCard extends StatelessWidget {
  final Memo memo;
  final AppColors colors;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MemoCard({
    required this.memo,
    required this.colors,
    required this.onToggle,
    required this.onDelete,
  });

  Color _tagColor() {
    switch (memo.tag) {
      case '灵感':
        return colors.tagPurple;
      case '工作':
        return colors.tagBlue;
      case '学习':
        return colors.tagOrange;
      case '生活':
        return colors.tagGreen;
      default:
        return colors.tagGray;
    }
  }

  IconData _tagIcon() {
    switch (memo.tag) {
      case '灵感':
        return Icons.lightbulb_outline;
      case '工作':
        return Icons.work_outline;
      case '学习':
        return Icons.menu_book_outlined;
      case '生活':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.note_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('HH:mm').format(dt);
    if (d == today) return '今天 · $time';
    if (d == today.subtract(const Duration(days: 1))) return '昨天 · $time';
    return DateFormat('M月d日 · HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _tagColor();

    return Dismissible(
      key: Key(memo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.danger.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // 由确认对话框处理真正删除
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tagColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_tagIcon(), size: 18, color: tagColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memo.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      decoration: memo.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(memo.updatedAt),
                    style: TextStyle(fontSize: 12, color: colors.secondaryText),
                  ),
                  if (memo.tag.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        memo.tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: tagColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                memo.completed ? Icons.check_circle : Icons.circle_outlined,
                color: memo.completed ? colors.success : colors.secondaryText,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
