import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 运维收藏目标：主机快捷填充。
class OpsFavoriteTarget {
  final String id;
  final String label;
  final String host;
  final int? defaultPort;
  final String note;
  final String updatedAt;

  const OpsFavoriteTarget({
    required this.id,
    required this.label,
    required this.host,
    this.defaultPort,
    this.note = '',
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'host': host,
        if (defaultPort != null) 'default_port': defaultPort,
        'note': note,
        'updated_at': updatedAt,
      };

  factory OpsFavoriteTarget.fromJson(Map<String, dynamic> j) {
    return OpsFavoriteTarget(
      id: j['id'] as String? ?? '',
      label: j['label'] as String? ?? '',
      host: j['host'] as String? ?? '',
      defaultPort: j['default_port'] == null
          ? null
          : int.tryParse('${j['default_port']}'),
      note: j['note'] as String? ?? '',
      updatedAt: j['updated_at'] as String? ?? '',
    );
  }
}

class OpsFavoriteTargetStore {
  static const _key = 'ops_favorite_targets_v1';

  Future<List<OpsFavoriteTarget>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) =>
              OpsFavoriteTarget.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.host.isNotEmpty)
          .toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<OpsFavoriteTarget> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<OpsFavoriteTarget> add({
    required String label,
    required String host,
    int? defaultPort,
    String note = '',
  }) async {
    final list = await this.list();
    final existing = list.where((e) => e.host == host).toList();
    final now = DateTime.now().toUtc().toIso8601String();
    if (existing.isNotEmpty) {
      final t = OpsFavoriteTarget(
        id: existing.first.id,
        label: label.isEmpty ? host : label,
        host: host,
        defaultPort: defaultPort ?? existing.first.defaultPort,
        note: note.isEmpty ? existing.first.note : note,
        updatedAt: now,
      );
      list.removeWhere((e) => e.id == t.id);
      list.insert(0, t);
      await saveAll(list);
      return t;
    }
    final t = OpsFavoriteTarget(
      id: const Uuid().v4(),
      label: label.isEmpty ? host : label,
      host: host,
      defaultPort: defaultPort,
      note: note,
      updatedAt: now,
    );
    list.insert(0, t);
    await saveAll(list.take(50).toList());
    return t;
  }

  Future<void> delete(String id) async {
    final list = await this.list();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  Future<void> touch(String id) async {
    final list = await this.list();
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final old = list[i];
    list[i] = OpsFavoriteTarget(
      id: old.id,
      label: old.label,
      host: old.host,
      defaultPort: old.defaultPort,
      note: old.note,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await saveAll(list);
  }
}
