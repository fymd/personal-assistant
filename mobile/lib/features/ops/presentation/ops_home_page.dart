import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import 'ping_page.dart';
import 'remote_desktop_page.dart';
import 'scanner_page.dart';

/// 运维工具入口列表
class OpsHomePage extends ConsumerWidget {
  const OpsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);

    final tools = [
      _ToolItem(
        icon: Icons.desktop_windows_outlined,
        title: '远程桌面',
        subtitle: '连接远程主机（入口）',
        color: colors.tagBlue,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RemoteDesktopPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.network_ping,
        title: 'Ping 工具',
        subtitle: '检测主机连通性与延迟',
        color: colors.tagGreen,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PingPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.qr_code_scanner,
        title: '扫码工具',
        subtitle: '二维码 / 条形码 · 导出 Excel',
        color: colors.tagPurple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScannerPage()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('运维工具')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = tools[i];
          return Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: t.onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: t.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(t.icon, color: t.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.secondaryText),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
