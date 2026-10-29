import '../../../core/network/api_client.dart';

class SignalMessage {
  final String type;
  final String role;
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;
  final int at;

  SignalMessage({
    required this.type,
    required this.role,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
    this.at = 0,
  });

  factory SignalMessage.fromJson(Map<String, dynamic> json) {
    return SignalMessage(
      type: json['type'] as String? ?? '',
      role: json['role'] as String? ?? '',
      sdp: json['sdp'] as String?,
      candidate: json['candidate'] as String?,
      sdpMid: json['sdp_mid'] as String?,
      sdpMLineIndex: (json['sdp_m_line_index'] as num?)?.toInt(),
      at: (json['at'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
        if (sdpMid != null) 'sdp_mid': sdpMid,
        if (sdpMLineIndex != null) 'sdp_m_line_index': sdpMLineIndex,
      };
}

class WebRTCSignalRepository {
  final ApiClient _client;

  WebRTCSignalRepository({required String token})
      : _client = ApiClient(token: token);

  Future<Map<String, dynamic>> createSession({
    String profileId = '',
    String hostHint = '',
    String protocol = 'RDP',
  }) async {
    final res = await _client.post('/api/v1/ops/remote-desktop/sessions', data: {
      'profile_id': profileId,
      'host_hint': hostHint,
      'protocol': protocol,
    });
    if (res['code'] != 0) throw Exception(res['message'] ?? '创建会话失败');
    return Map<String, dynamic>.from(res['data'] as Map);
  }

  Future<void> postSignal(String sessionId, String role, SignalMessage msg) async {
    final res = await _client.post(
      '/api/v1/ops/remote-desktop/sessions/$sessionId/signal?role=$role',
      data: msg.toJson(),
    );
    if (res['code'] != 0) throw Exception(res['message'] ?? '发送信令失败');
  }

  Future<List<SignalMessage>> poll(String sessionId, String role, int since) async {
    final res = await _client.get(
      '/api/v1/ops/remote-desktop/sessions/$sessionId/signal?role=$role&since=$since',
    );
    if (res['code'] != 0) throw Exception(res['message'] ?? '轮询失败');
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => SignalMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
