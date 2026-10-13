import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_type.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: PersonalAssistantApp(),
    ),
  );
}

class PersonalAssistantApp extends ConsumerWidget {
  const PersonalAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final themeType = ref.watch(themeTypeProvider);

    return MaterialApp(
      title: 'Personal Assistant',
      debugShowCheckedModeBanner: false,
      theme: theme,
      // 当前主题已包含深浅，不再额外用 themeMode 切换
      home: ThemeDemoPage(currentType: themeType),
    );
  }
}

/// 临时演示页：展示当前主题 + 快速切换
/// 后续会被正式首页替换
class ThemeDemoPage extends ConsumerWidget {
  final AppThemeType currentType;

  const ThemeDemoPage({super.key, required this.currentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('备忘录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: '切换主题',
            onPressed: () => _showThemePicker(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前主题提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前主题：${currentType.displayName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  currentType.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 模拟备忘录卡片（Notion 风格预览）
          Text('示例备忘录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          _MemoCard(
            title: '产品灵感收集',
            subtitle: '今天 · 09:30',
            tag: '灵感',
            tagColor: colors.tagPurple,
            completed: false,
            colors: colors,
          ),
          const SizedBox(height: 10),
          _MemoCard(
            title: '团队周会',
            subtitle: '明天 · 10:00',
            tag: '工作',
            tagColor: colors.tagBlue,
            completed: false,
            colors: colors,
          ),
          const SizedBox(height: 10),
          _MemoCard(
            title: '读书笔记：《原子习惯》',
            subtitle: '5月24日 · 21:30',
            tag: '学习',
            tagColor: colors.tagOrange,
            completed: true,
            colors: colors,
          ),

          const SizedBox(height: 32),
          Text(
            '点击右上角调色盘可切换主题',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
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

  void _showThemePicker(BuildContext context, WidgetRef ref) {
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
              Text(
                '选择主题',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...AppThemeType.values.map((type) {
                final selected = type == currentType;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
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
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final bool completed;
  final AppColors colors;

  const _MemoCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.completed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          // 左侧色块图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              completed ? Icons.menu_book_outlined : Icons.lightbulb_outline,
              size: 18,
              color: tagColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      color: tagColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? colors.success : colors.secondaryText,
            size: 22,
          ),
        ],
      ),
    );
  }
}
