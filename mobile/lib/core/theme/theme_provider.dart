import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'theme_type.dart';

const _kThemeKey = 'app_theme_type';

/// 当前主题类型（可读写）
final themeTypeProvider =
    StateNotifierProvider<ThemeTypeNotifier, AppThemeType>((ref) {
  return ThemeTypeNotifier();
});

/// 当前 ThemeData
final themeDataProvider = Provider((ref) {
  final type = ref.watch(themeTypeProvider);
  return AppTheme.build(type);
});

/// 当前颜色 Token（方便业务代码直接取色）
final appColorsProvider = Provider<AppColors>((ref) {
  final type = ref.watch(themeTypeProvider);
  return AppColors.of(type);
});

class ThemeTypeNotifier extends StateNotifier<AppThemeType> {
  ThemeTypeNotifier() : super(AppThemeType.notion) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kThemeKey);
      if (name != null) {
        final matched = AppThemeType.values.where((e) => e.name == name);
        if (matched.isNotEmpty) {
          state = matched.first;
        }
      }
    } catch (_) {
      // 忽略加载失败，使用默认 Notion
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeKey, type.name);
    } catch (_) {
      // 持久化失败不影响当前切换
    }
  }

  /// 循环切换（调试/演示用）
  void cycle() {
    final values = AppThemeType.values;
    final next = (state.index + 1) % values.length;
    setTheme(values[next]);
  }
}
