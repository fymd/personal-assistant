import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/theme_provider.dart';

class _ScanItem {
  final String value;
  final String format;
  final DateTime time;

  _ScanItem({required this.value, required this.format, required this.time});
}

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final List<_ScanItem> _items = [];
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _torch = false;
  String? _lastRaw;
  DateTime? _lastAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final b = barcodes.first;
    final raw = b.rawValue;
    if (raw == null || raw.isEmpty) return;

    // 防抖：同一内容 2 秒内不重复
    final now = DateTime.now();
    if (_lastRaw == raw &&
        _lastAt != null &&
        now.difference(_lastAt!).inSeconds < 2) {
      return;
    }
    _lastRaw = raw;
    _lastAt = now;

    final format = b.format.name;
    setState(() {
      _items.insert(
        0,
        _ScanItem(value: raw, format: format, time: now),
      );
    });
  }

  Future<void> _exportExcel() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无扫码记录可导出')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Scans'];
    // 删除默认 Sheet1
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('序号'),
      TextCellValue('内容'),
      TextCellValue('格式'),
      TextCellValue('时间'),
    ]);

    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(it.value),
        TextCellValue(it.format),
        TextCellValue(fmt.format(it.time)),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出失败')),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final name =
        'scans_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已导出：${file.path}'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('扫码工具'),
        actions: [
          IconButton(
            tooltip: '手电筒',
            onPressed: () {
              setState(() => _torch = !_torch);
              _controller.toggleTorch();
            },
            icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            tooltip: '导出 Excel',
            onPressed: _exportExcel,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 280,
            child: ClipRRect(
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '扫码记录（${_items.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_items.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _items.clear()),
                    child: const Text('清空'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      '将二维码 / 条形码对准取景框',
                      style: TextStyle(color: colors.secondaryText),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: colors.border.withOpacity(0.6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${it.format}  ·  ${DateFormat('HH:mm:ss').format(it.time)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
