import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// 发送验证码
  Future<void> sendCode(String phone) async {
    final res = await _client.post('/api/v1/auth/send-code', data: {
      'phone': phone,
    });
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '发送失败');
    }
  }

  /// 登录，返回 token
  Future<String> login(String phone, String code) async {
    final res = await _client.post('/api/v1/auth/login', data: {
      'phone': phone,
      'code': code,
    });
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '登录失败');
    }
    final data = res['data'] as Map<String, dynamic>?;
    final token = data?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('未返回 token');
    }
    return token;
  }
}
