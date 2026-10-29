import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 阶段 2：在 App 内打开远程桌面网关（Guacamole / RustDesk Web 等）
class GatewayWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const GatewayWebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<GatewayWebViewPage> createState() => _GatewayWebViewPageState();
}

class _GatewayWebViewPageState extends State<GatewayWebViewPage> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _error = '网关地址无效，请使用 http(s):// 开头的 URL';
      _loading = false;
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (e) => setState(() {
            _loading = false;
            _error = e.description;
          }),
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_error == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const LinearProgressIndicator(minHeight: 2),
              ],
            ),
    );
  }
}
