import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/memo_model.dart';
import '../data/memo_repository.dart';

enum MemoFilter { all, uncompleted, completed, starred }

extension MemoFilterX on MemoFilter {
  String get apiValue {
    switch (this) {
      case MemoFilter.all:
        return 'all';
      case MemoFilter.uncompleted:
        return 'uncompleted';
      case MemoFilter.completed:
        return 'completed';
      case MemoFilter.starred:
        return 'starred';
    }
  }

  String get label {
    switch (this) {
      case MemoFilter.all:
        return '全部';
      case MemoFilter.uncompleted:
        return '未完成';
      case MemoFilter.completed:
        return '已完成';
      case MemoFilter.starred:
        return '收藏';
    }
  }
}

final memoFilterProvider = StateProvider<MemoFilter>((ref) => MemoFilter.all);

final memoListProvider =
    StateNotifierProvider<MemoListNotifier, AsyncValue<List<Memo>>>((ref) {
  final auth = ref.watch(authStateProvider);
  final filter = ref.watch(memoFilterProvider);
  return MemoListNotifier(
    token: auth.token,
    filter: filter,
  );
});

class MemoListNotifier extends StateNotifier<AsyncValue<List<Memo>>> {
  final String? token;
  final MemoFilter filter;
  MemoRepository? _repo;

  MemoListNotifier({required this.token, required this.filter})
      : super(const AsyncValue.loading()) {
    if (token != null && token!.isNotEmpty) {
      _repo = MemoRepository(token: token!);
      load();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> load() async {
    if (_repo == null) return;
    state = const AsyncValue.loading();
    try {
      final list = await _repo!.fetchList(filter: filter.apiValue);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({required String title, String tag = ''}) async {
    if (_repo == null) return;
    try {
      final memo = await _repo!.create(title: title, tag: tag);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([memo, ...current]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleComplete(String id) async {
    if (_repo == null) return;
    try {
      final updated = await _repo!.toggleComplete(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([
        for (final m in current)
          if (m.id == id) updated else m,
      ]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    if (_repo == null) return;
    try {
      await _repo!.delete(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((m) => m.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }
}
