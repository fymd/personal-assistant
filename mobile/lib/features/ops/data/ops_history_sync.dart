import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import 'ops_history_repository.dart';

Future<bool> syncOpsHistory(
  BuildContext context,
  WidgetRef ref, {
  required String tool,
  required String target,
  required String summary,
  required String detail,
}) async {
  final token = ref.read(authStateProvider).token;
  if (token == null || token.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再同步历史')),
      );
    }
    return false;
  }
  try {
    await OpsHistoryRepository(token: token).create(
      tool: tool,
      target: target,
      summary: summary,
      detail: detail,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已同步到运维历史')),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同步失败：$e')),
      );
    }
    return false;
  }
}
