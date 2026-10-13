import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme_provider.dart';
import '../core/theme/theme_type.dart';
import '../features/ai/presentation/ai_page.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/memo/presentation/memo_list_page.dart';
import '../features/ops/presentation/ops_home_page.dart';

/// 登录后主框架：底部导航
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MemoListPage(showBottomBar: false),
      const AiPage(),
      const OpsHomePage(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: '工具',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final colors = ref.watch(appColorsProvider);
    final themeType = ref.watch(themeTypeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primary.withOpacity(0.15),
                  child: Icon(Icons.person, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.phone ?? '未登录',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '个人账号',
                      style: TextStyle(fontSize: 13, color: colors.secondaryText),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题'),
            subtitle: Text(themeType.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, themeType),
          ),
          ListTile(
            leading: const Icon(Icons.card_membership_outlined),
            title: const Text('会员'),
            subtitle: const Text('即将开放'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('会员功能预留中')),
              );
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.logout, color: colors.danger),
            title: Text('退出登录', style: TextStyle(color: colors.danger)),
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, AppThemeType currentType) {
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
              const SizedBox(height: 16),
              Text('选择主题', style: Theme.of(context).textTheme.titleMedium),
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
