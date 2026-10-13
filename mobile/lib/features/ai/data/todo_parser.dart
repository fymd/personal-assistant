/// 从 AI 回复中提取待办条目
List<String> parseTodoItems(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  final items = <String>[];

  // 1. 1) 1、 - * • 【】 等常见列表格式
  final patterns = [
    RegExp(r'^\s*\d+[.)、．]\s*(.+)$'),
    RegExp(r'^\s*[-*•]\s+(.+)$'),
    RegExp(r'^\s*[□☐]\s*(.+)$'),
    RegExp(r'^\s*[【\[]\s*\d+\s*[】\]]\s*(.+)$'),
  ];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    // 跳过过短的标题行
    if (trimmed.length < 2) continue;

    for (final p in patterns) {
      final m = p.firstMatch(trimmed);
      if (m != null) {
        var item = m.group(1)!.trim();
        // 去掉末尾标点冗余
        item = item.replaceAll(RegExp(r'[。；;]+$'), '');
        if (item.length >= 2 && item.length <= 120) {
          items.add(item);
        }
        break;
      }
    }
  }

  // 若未识别到列表，但全文像「待办」单行，不强行拆
  return items;
}
