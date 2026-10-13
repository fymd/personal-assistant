import '../../../core/network/api_client.dart';
import 'memo_model.dart';

class MemoRepository {
  final ApiClient _client;

  MemoRepository({required String token})
      : _client = ApiClient(token: token);

  Future<List<Memo>> list({String filter = 'all'}) async {
    final query = filter == 'all' ? '' : '?filter=$filter';
    final res = await _client.post; // placeholder - fix below
    // ignore: dead_code
    return [];
  }

  Future<List<Memo>> fetchList({String filter = 'all'}) async {
    final path = filter == 'all' || filter.isEmpty
        ? '/api/v1/memos'
        : '/api/v1/memos?filter=$filter';
    final res = await _client.get(path);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '加载失败');
    }
    final data = res['data'] as List<dynamic>? ?? [];
    return data.map((e) => Memo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Memo> create({required String title, String content = '', String tag = ''}) async {
    final res = await _client.post('/api/v1/memos', data: {
      'title': title,
      'content': content,
      'tag': tag,
    });
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '创建失败');
    }
    return Memo.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<Memo> toggleComplete(String id) async {
    final res = await _client.patch('/api/v1/memos/$id/complete');
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '更新失败');
    }
    return Memo.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }

  Future<void> delete(String id) async {
    final res = await _client.delete('/api/v1/memos/$id');
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '删除失败');
    }
  }

  Future<Memo> update(String id, {String? title, String? content, String? tag, bool? starred}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (tag != null) body['tag'] = tag;
    if (starred != null) body['starred'] = starred;
    final res = await _client.put('/api/v1/memos/$id', data: body);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '更新失败');
    }
    return Memo.fromJson(Map<String, dynamic>.from(res['data'] as Map));
  }
}
