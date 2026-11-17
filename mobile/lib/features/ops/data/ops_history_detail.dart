import 'dart:convert';

/// Ops history detail schema (version=1).
class OpsHistoryDetail {
  static const int version = 1;

  static String ping({
    required int port,
    required int count,
    required int success,
    required List<Map<String, dynamic>> samples,
  }) {
    final latencies = samples
        .where((e) => e['ok'] == true && e['ms'] is int)
        .map((e) => e['ms'] as int)
        .toList();
    int? minMs, maxMs;
    double? avgMs;
    if (latencies.isNotEmpty) {
      minMs = latencies.reduce((a, b) => a < b ? a : b);
      maxMs = latencies.reduce((a, b) => a > b ? a : b);
      avgMs = latencies.reduce((a, b) => a + b) / latencies.length;
    }
    return jsonEncode({
      'version': version,
      'port': port,
      'count': count,
      'success': success,
      'fail': count - success,
      if (minMs != null) 'min_ms': minMs,
      if (maxMs != null) 'max_ms': maxMs,
      if (avgMs != null) 'avg_ms': double.parse(avgMs.toStringAsFixed(1)),
      'samples': samples,
    });
  }

  static String dns({
    required int elapsedMs,
    required List<Map<String, String>> addresses,
    String? error,
  }) {
    return jsonEncode({
      'version': version,
      'elapsed_ms': elapsedMs,
      'addresses': addresses,
      if (error != null && error.isNotEmpty) 'error': error,
    });
  }

  static String portScan({required List<Map<String, dynamic>> ports}) {
    return jsonEncode({'version': version, 'ports': ports});
  }

  static String httpCheck({
    required String method,
    required String url,
    int? status,
    required int elapsedMs,
    String? contentLength,
    String? error,
  }) {
    return jsonEncode({
      'version': version,
      'method': method,
      'url': url,
      if (status != null) 'status': status,
      'elapsed_ms': elapsedMs,
      if (contentLength != null) 'content_length': contentLength,
      if (error != null && error.isNotEmpty) 'error': error,
    });
  }

  static String networkDiag({required String host, required List<String> logs}) {
    return jsonEncode({'version': version, 'host': host, 'logs': logs});
  }
}
