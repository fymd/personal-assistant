import 'package:flutter/material.dart';

/// 阶段 3：内置远程画面占位（WebRTC / 专用协议尚未实现）
class NativeRdPlaceholderPage extends StatelessWidget {
  final String name;
  final String protocol;
  final String host;
  final int port;

  const NativeRdPlaceholderPage({
    super.key,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name.isEmpty ? '内置远程桌面' : name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.desktop_windows_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              '阶段 3：内置画面（规划中）',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '目标：$protocol://$host:$port\n\n'
              '计划通过 WebRTC 或专用网关协议在 App 内渲染远程画面。'
              '当前版本尚未实现，请改用「外置客户端」或「网关 WebView」模式。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('建议路线：'),
            const SizedBox(height: 8),
            const Text('1. 自建 Apache Guacamole / RustDesk，使用网关模式'),
            const Text('2. 安装系统 RDP/VNC/SSH 客户端，使用外置模式'),
            const Text('3. 内置 WebRTC 客户端单独立项开发'),
          ],
        ),
      ),
    );
  }
}
