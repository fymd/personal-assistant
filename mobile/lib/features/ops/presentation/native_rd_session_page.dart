import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/webrtc_signal_repository.dart';

/// 阶段 3：内置 WebRTC 观看端会话
/// 远端桌面需主机 Agent 加入同一 session 并推送媒体轨。
class NativeRdSessionPage extends ConsumerStatefulWidget {
  final String title;
  final String protocol;
  final String host;
  final int port;
  final String profileId;

  const NativeRdSessionPage({
    super.key,
    required this.title,
    required this.protocol,
    required this.host,
    required this.port,
    this.profileId = '',
  });

  @override
  ConsumerState<NativeRdSessionPage> createState() => _NativeRdSessionPageState();
}

class _NativeRdSessionPageState extends ConsumerState<NativeRdSessionPage> {
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  WebRTCSignalRepository? _repo;
  String? _sessionId;
  String _status = '初始化…';
  int _since = 0;
  Timer? _pollTimer;
  bool _disposed = false;

  static const _role = 'viewer';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _remoteRenderer.initialize();
    final token = ref.read(authStateProvider).token;
    if (token == null || token.isEmpty) {
      setState(() => _status = '未登录');
      return;
    }
    _repo = WebRTCSignalRepository(token: token);
    try {
      setState(() => _status = '创建信令会话…');
      final session = await _repo!.createSession(
        profileId: widget.profileId,
        hostHint: '${widget.host}:${widget.port}',
        protocol: widget.protocol,
      );
      _sessionId = session['id'] as String?;
      setState(() => _status = '等待主机 Agent 加入（session 已创建）');

      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      };
      _pc = await createPeerConnection(config);
      _pc!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteRenderer.srcObject = event.streams[0];
          setState(() => _status = '已收到远端媒体流');
        }
      };
      _pc!.onIceCandidate = (c) async {
        if (c.candidate == null || _sessionId == null || _repo == null) return;
        await _repo!.postSignal(
          _sessionId!,
          _role,
          SignalMessage(
            type: 'candidate',
            role: _role,
            candidate: c.candidate,
            sdpMid: c.sdpMid,
            sdpMLineIndex: c.sdpMLineIndex,
          ),
        );
      };
      _pc!.onConnectionState = (state) {
        if (!_disposed) {
          setState(() => _status = '连接状态: $state');
        }
      };

      // 观看端先准备接收（不发本地媒体）
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e) {
      setState(() => _status = '错误: $e');
    }
  }

  Future<void> _poll() async {
    if (_repo == null || _sessionId == null || _pc == null || _disposed) return;
    try {
      final msgs = await _repo!.poll(_sessionId!, _role, _since);
      for (final m in msgs) {
        if (m.at > _since) _since = m.at;
        if (m.type == 'offer' && m.sdp != null) {
          setState(() => _status = '收到 Agent Offer，生成 Answer…');
          await _pc!.setRemoteDescription(RTCSessionDescription(m.sdp, 'offer'));
          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);
          await _repo!.postSignal(
            _sessionId!,
            _role,
            SignalMessage(type: 'answer', role: _role, sdp: answer.sdp),
          );
          setState(() => _status = '已发送 Answer，等待 ICE…');
        } else if (m.type == 'candidate' && m.candidate != null) {
          await _pc!.addCandidate(RTCIceCandidate(
            m.candidate,
            m.sdpMid,
            m.sdpMLineIndex,
          ));
        }
      }
    } catch (e) {
      // 轮询失败不打断，下次重试
      if (!_disposed) {
        setState(() => _status = '轮询: $e');
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _pc?.close();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title.isEmpty ? '内置远程桌面' : widget.title),
        actions: [
          if (_sessionId != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: '复制 Session ID',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _sessionId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session ID 已复制，供主机 Agent 加入')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF1a1a1a),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (_sessionId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Session: $_sessionId',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '目标 ${widget.protocol}://${widget.host}:${widget.port}\n'
                  '主机需运行兼容 Agent，向同一 session 发送 WebRTC offer 与桌面轨道。',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
