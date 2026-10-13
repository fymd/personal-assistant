import '../../../core/network/api_client.dart';

class ChatMessage {
  final String role; // user | assistant
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiChatResult {
  final String reply;
  final bool mock;

  AiChatResult({required this.reply, required this.mock});
}

class AiRepository {
  final ApiClient _client;

  AiRepository({required String token}) : _client = ApiClient(token: token);

  Future<AiChatResult> chat({
    required List<ChatMessage> messages,
    String action = 'general',
  }) async {
    final res = await _client.post('/api/v1/ai/chat', data: {
      'messages': messages.map((m) => m.toJson()).toList(),
      'action': action,
    });
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? 'AI 请求失败');
    }
    final data = Map<String, dynamic>.from(res['data'] as Map);
    return AiChatResult(
      reply: data['reply'] as String? ?? '',
      mock: data['mock'] as bool? ?? false,
    );
  }
}
