import '../../../core/network/api_client.dart';

class RemoteDesktopProfile {
  final String id;
  final String name;
  final String protocol;
  final String host;
  final int port;
  final String username;
  final String note;
  final String connectMode; // external | gateway | native
  final String gatewayUrl;

  RemoteDesktopProfile({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    this.username = '',
    this.note = '',
    this.connectMode = 'external',
    this.gatewayUrl = '',
  });

  factory RemoteDesktopProfile.fromJson(Map<String, dynamic> json) {
    return RemoteDesktopProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      protocol: json['protocol'] as String? ?? 'RDP',
      host: json['host'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 3389,
      username: json['username'] as String? ?? '',
      note: json['note'] as String? ?? '',
      connectMode: json['connect_mode'] as String? ?? 'external',
      gatewayUrl: json['gateway_url'] as String? ?? '',
    );
  }
}

class RemoteDesktopRepository {
  final ApiClient _client;

  RemoteDesktopRepository({required String token})
      : _client = ApiClient(token: token);

  Future<List<RemoteDesktopProfile>> list() async {
    final res = await _client.get('/api/v1/ops/remote-desktop');
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '加载失败');
    }
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) =>
            RemoteDesktopProfile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Map<String, dynamic> _body({
    required String name,
    required String protocol,
    required String host,
    required int port,
    String username = '',
    String note = '',
    required String connectMode,
    String gatewayUrl = '',
  }) =>
      {
        'name': name,
        'protocol': protocol,
        'host': host,
        'port': port,
        'username': username,
        'note': note,
        'connect_mode': connectMode,
        'gateway_url': gatewayUrl,
      };

  Future<RemoteDesktopProfile> create({
    required String name,
    required String protocol,
    required String host,
    required int port,
    String username = '',
    String note = '',
    required String connectMode,
    String gatewayUrl = '',
  }) async {
    final res = await _client.post(
      '/api/v1/ops/remote-desktop',
      data: _body(
        name: name,
        protocol: protocol,
        host: host,
        port: port,
        username: username,
        note: note,
        connectMode: connectMode,
        gatewayUrl: gatewayUrl,
      ),
    );
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '保存失败');
    }
    return RemoteDesktopProfile.fromJson(
        Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<RemoteDesktopProfile> update(
    String id, {
    required String name,
    required String protocol,
    required String host,
    required int port,
    String username = '',
    String note = '',
    required String connectMode,
    String gatewayUrl = '',
  }) async {
    final res = await _client.put(
      '/api/v1/ops/remote-desktop/$id',
      data: _body(
        name: name,
        protocol: protocol,
        host: host,
        port: port,
        username: username,
        note: note,
        connectMode: connectMode,
        gatewayUrl: gatewayUrl,
      ),
    );
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '更新失败');
    }
    return RemoteDesktopProfile.fromJson(
        Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<void> delete(String id) async {
    final res = await _client.delete('/api/v1/ops/remote-desktop/$id');
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '删除失败');
    }
  }
}
