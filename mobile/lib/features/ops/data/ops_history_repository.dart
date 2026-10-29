import '../../../core/network/api_client.dart';

class OpsHistoryItem {
  final String id;
  final String tool;
  final String target;
  final String summary;
  final String detail;
  final String createdAt;

  OpsHistoryItem({
    required this.id,
    required this.tool,
    required this.target,
    required this.summary,
    required this.detail,
    required this.createdAt,
  });

  factory OpsHistoryItem.fromJson(Map<String, dynamic> json) {
    return OpsHistoryItem(
      id: json['id'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      target: json['target'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class OpsHistoryRepository {
  final ApiClient _client;

  OpsHistoryRepository({required String token})
      : _client = ApiClient(token: token);

  Future<List<OpsHistoryItem>> list({String tool = '', int limit = 50}) async {
    final q = <String>[];
    if (tool.isNotEmpty) q.add('tool=$tool');
    if (limit > 0) q.add('limit=$limit');
    final path = '/api/v1/ops/history${q.isEmpty ? '' : '?${q.join('&')}'}';
    final res = await _client.get(path);
    if (res['code'] != 0) throw Exception(res['message'] ?? '加载失败');
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => OpsHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OpsHistoryItem> create({
    required String tool,
    required String target,
    required String summary,
    String detail = '',
  }) async {
    final res = await _client.post('/api/v1/ops/history', data: {
      'tool': tool,
      'target': target,
      'summary': summary,
      'detail': detail,
    });
    if (res['code'] != 0) throw Exception(res['message'] ?? '保存失败');
    return OpsHistoryItem.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<void> delete(String id) async {
    final res = await _client.delete('/api/v1/ops/history/$id');
    if (res['code'] != 0) throw Exception(res['message'] ?? '删除失败');
  }
}
