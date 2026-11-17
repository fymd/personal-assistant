import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'ops_inspect_template.dart';

class InspectStepResult {
  final String kind;
  final String label;
  final bool ok;
  final String message;
  final int? ms;
  final Map<String, dynamic> raw;

  InspectStepResult({
    required this.kind,
    required this.label,
    required this.ok,
    required this.message,
    this.ms,
    this.raw = const {},
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'label': label,
        'ok': ok,
        'message': message,
        if (ms != null) 'ms': ms,
        ...raw,
      };
}

class OpsInspectRunner {
  Future<List<InspectStepResult>> run(
    OpsInspectTemplate t, {
    void Function(InspectStepResult step)? onStep,
  }) async {
    final results = <InspectStepResult>[];
    final host = t.host.trim();
    if (host.isEmpty) return results;

    Future<void> emit(InspectStepResult r) async {
      results.add(r);
      onStep?.call(r);
    }

    if (t.doDns) {
      final sw = Stopwatch()..start();
      try {
        final list = await InternetAddress.lookup(host, type: InternetAddressType.any);
        sw.stop();
        final addrs = list.map((a) => a.address).join(', ');
        await emit(InspectStepResult(
          kind: 'dns',
          label: 'DNS $host',
          ok: list.isNotEmpty,
          message: list.isEmpty ? '无结果' : addrs,
          ms: sw.elapsedMilliseconds,
          raw: {
            'addresses': list
                .map((a) => {
                      'address': a.address,
                      'type': a.type == InternetAddressType.IPv6 ? 'IPv6' : 'IPv4',
                    })
                .toList(),
          },
        ));
      } catch (e) {
        sw.stop();
        await emit(InspectStepResult(
          kind: 'dns',
          label: 'DNS $host',
          ok: false,
          message: '$e',
          ms: sw.elapsedMilliseconds,
        ));
      }
    }

    if (t.doPing) {
      final port = t.pingPort;
      final sw = Stopwatch()..start();
      try {
        final s = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
        sw.stop();
        s.destroy();
        await emit(InspectStepResult(
          kind: 'ping',
          label: 'Ping $host:$port',
          ok: true,
          message: '连通',
          ms: sw.elapsedMilliseconds,
          raw: {'port': port},
        ));
      } catch (e) {
        sw.stop();
        await emit(InspectStepResult(
          kind: 'ping',
          label: 'Ping $host:$port',
          ok: false,
          message: '$e',
          ms: sw.elapsedMilliseconds,
          raw: {'port': port},
        ));
      }
    }

    if (t.doPorts) {
      final ports = t.ports.take(32).toList();
      for (final port in ports) {
        final sw = Stopwatch()..start();
        try {
          final s = await Socket.connect(
            host,
            port,
            timeout: const Duration(milliseconds: 1500),
          );
          sw.stop();
          s.destroy();
          await emit(InspectStepResult(
            kind: 'port',
            label: '端口 $port',
            ok: true,
            message: '开放',
            ms: sw.elapsedMilliseconds,
            raw: {'port': port, 'open': true},
          ));
        } catch (_) {
          sw.stop();
          await emit(InspectStepResult(
            kind: 'port',
            label: '端口 $port',
            ok: false,
            message: '关闭/过滤',
            ms: sw.elapsedMilliseconds,
            raw: {'port': port, 'open': false},
          ));
        }
      }
    }

    if (t.doHttp) {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        followRedirects: true,
        validateStatus: (_) => true,
      ));
      for (final rawUrl in t.httpUrls.take(16)) {
        var url = rawUrl.trim();
        if (url.isEmpty) continue;
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          if (url.startsWith('/')) {
            url = 'https://$host$url';
          } else {
            url = 'https://$url';
          }
        }
        final sw = Stopwatch()..start();
        try {
          final res = await dio.get(url);
          sw.stop();
          final code = res.statusCode ?? 0;
          final ok = code >= 200 && code < 400;
          await emit(InspectStepResult(
            kind: 'http',
            label: 'HTTP $url',
            ok: ok,
            message: '状态 $code',
            ms: sw.elapsedMilliseconds,
            raw: {'url': url, 'status': code},
          ));
        } catch (e) {
          sw.stop();
          await emit(InspectStepResult(
            kind: 'http',
            label: 'HTTP $url',
            ok: false,
            message: '$e',
            ms: sw.elapsedMilliseconds,
            raw: {'url': url},
          ));
        }
      }
    }

    return results;
  }
}
