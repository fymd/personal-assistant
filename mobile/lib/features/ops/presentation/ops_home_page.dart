import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import 'dns_lookup_page.dart';
import 'network_diag_page.dart';
import 'ping_page.dart';
import 'port_scan_page.dart';
import 'remote_desktop_page.dart';
import 'scanner_page.dart';
import 'ssh_connect_page.dart';

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
        subtitle: '外置 · 网关 · WebRTC',
        color: colors.tagBlue,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RemoteDesktopPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.network_ping,
        title: 'Ping 工具',
        subtitle: 'TCP 连通性与延迟',
        color: colors.tagGreen,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PingPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.radar_outlined,
        title: '端口扫描',
        subtitle: '常用端口 TCP 探测',
        color: colors.tagOrange,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PortScanPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.dns_outlined,
        title: 'DNS 查询',
        subtitle: '域名解析 A/AAAA',
        color: colors.tagPurple,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DnsLookupPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.terminal,
        title: 'SSH 连接',
        subtitle: '唤起系统 SSH 客户端',
        color: colors.tagBlue,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SshConnectPage()),
        ),
      ),
      _ToolItem(
        icon: Icons.troubleshoot_outlined,
        title: '网络诊断',
        subtitle: '网卡 · DNS · 关键端口',
        color: colors.tagGreen,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NetworkDiagPage()),
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
