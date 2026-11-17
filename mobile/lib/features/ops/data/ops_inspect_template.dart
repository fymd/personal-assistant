import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 巡检模板：对固定目标批量跑 Ping / 端口 / HTTP / DNS。
class OpsInspectTemplate {
  final String id;
  final String name;
  final String host;
  final List<int> ports;
  final List<String> httpUrls;
  final bool doPing;
  final bool doDns;
  final bool doPorts;
  final bool doHttp;
  final int pingPort;
  final String createdAt;
  final String updatedAt;

  const OpsInspectTemplate({
    required this.id,
    required this.name,
    required this.host,
    this.ports = const [],
    this.httpUrls = const [],
    this.doPing = true,
    this.doDns = true,
    this.doPorts = true,
    this.doHttp = true,
    this.pingPort = 80,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'ports': ports,
        'http_urls': httpUrls,
        'do_ping': doPing,
        'do_dns': doDns,
        'do_ports': doPorts,
        'do_http': doHttp,
        'ping_port': pingPort,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory OpsInspectTemplate.fromJson(Map<String, dynamic> j) {
    return OpsInspectTemplate(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      host: j['host'] as String? ?? '',
      ports: (j['ports'] as List<dynamic>? ?? [])
          .map((e) => int.tryParse('$e') ?? 0)
          .where((e) => e > 0 && e <= 65535)
          .toList(),
      httpUrls: (j['http_urls'] as List<dynamic>? ?? [])
          .map((e) => '$e')
          .where((e) => e.isNotEmpty)
          .toList(),
      doPing: j['do_ping'] as bool? ?? true,
      doDns: j['do_dns'] as bool? ?? true,
      doPorts: j['do_ports'] as bool? ?? true,
      doHttp: j['do_http'] as bool? ?? true,
      pingPort: int.tryParse('${j['ping_port'] ?? 80}') ?? 80,
      createdAt: j['created_at'] as String? ?? '',
      updatedAt: j['updated_at'] as String? ?? '',
    );
  }

  OpsInspectTemplate copyWith({
    String? name,
    String? host,
    List<int>? ports,
    List<String>? httpUrls,
    bool? doPing,
    bool? doDns,
    bool? doPorts,
    bool? doHttp,
    int? pingPort,
    String? updatedAt,
  }) {
    return OpsInspectTemplate(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      ports: ports ?? this.ports,
      httpUrls: httpUrls ?? this.httpUrls,
      doPing: doPing ?? this.doPing,
      doDns: doDns ?? this.doDns,
      doPorts: doPorts ?? this.doPorts,
      doHttp: doHttp ?? this.doHttp,
      pingPort: pingPort ?? this.pingPort,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OpsInspectTemplateStore {
  static const _key = 'ops_inspect_templates_v1';

  Future<List<OpsInspectTemplate>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OpsInspectTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<OpsInspectTemplate> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> upsert(OpsInspectTemplate t) async {
    final list = await list();
    final i = list.indexWhere((e) => e.id == t.id);
    if (i >= 0) {
      list[i] = t;
    } else {
      list.insert(0, t);
    }
    await saveAll(list);
  }

  Future<void> delete(String id) async {
    final list = await list();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }
}
