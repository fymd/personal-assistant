import 'package:flutter/material.dart';

import 'native_rd_session_page.dart';

/// 阶段 3 入口：说明 + 进入 WebRTC 观看会话
class NativeRdPlaceholderPage extends StatelessWidget {
  final String name;
  final String protocol;
  final String host;
  final int port;
  final String profileId;

  const NativeRdPlaceholderPage({
    super.key,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    this.profileId = '',
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
              '阶段 3：WebRTC 内置会话',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '目标：$protocol://$host:$port\n\n'
              'App 作为观看端：创建信令会话、交换 SDP/ICE、渲染远端视频轨。\n'
              '桌面采集与编码需在主机端 Agent 完成（本仓库暂不包含 Agent）。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => NativeRdSessionPage(
                        title: name,
                        protocol: protocol,
                        host: host,
                        port: port,
                        profileId: profileId,
                      ),
                    ),
                  );
                },
                child: const Text('创建 WebRTC 会话'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '无 Agent 时会话会停留在「等待主机加入」。也可继续使用外置客户端或网关模式。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
