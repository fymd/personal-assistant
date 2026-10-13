import 'package:flutter/material.dart';

import 'theme_type.dart';

/// 各主题的颜色 Token
class AppColors {
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color onBackground;
  final Color onSurface;
  final Color secondaryText;
  final Color border;
  final Color success;
  final Color danger;
  final Color cardShadow;

  // 标签/分类常用色（Notion 风格会用到）
  final Color tagPurple;
  final Color tagBlue;
  final Color tagGreen;
  final Color tagOrange;
  final Color tagGray;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onBackground,
    required this.onSurface,
    required this.secondaryText,
    required this.border,
    required this.success,
    required this.danger,
    required this.cardShadow,
    required this.tagPurple,
    required this.tagBlue,
    required this.tagGreen,
    required this.tagOrange,
    required this.tagGray,
  });

  /// Notion 风格（默认）
  static const notion = AppColors(
    primary: Color(0xFF2383E2),          // Notion 蓝
    onPrimary: Colors.white,
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF7F6F3),   // Notion 浅灰背景
    onBackground: Color(0xFF37352F),     // Notion 近黑文字
    onSurface: Color(0xFF37352F),
    secondaryText: Color(0xFF787774),
    border: Color(0xFFE3E2DE),
    success: Color(0xFF0F7B6C),
    danger: Color(0xFFE03E3E),
    cardShadow: Color(0x0A000000),
    tagPurple: Color(0xFF9B59B6),
    tagBlue: Color(0xFF3498DB),
    tagGreen: Color(0xFF27AE60),
    tagOrange: Color(0xFFE67E22),
    tagGray: Color(0xFF95A5A6),
  );

  /// Apple 极简
  static const appleMinimal = AppColors(
    primary: Color(0xFF007AFF),
    onPrimary: Colors.white,
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE5E5EA),
    onBackground: Color(0xFF000000),
    onSurface: Color(0xFF000000),
    secondaryText: Color(0xFF8E8E93),
    border: Color(0xFFC6C6C8),
    success: Color(0xFF34C759),
    danger: Color(0xFFFF3B30),
    cardShadow: Color(0x0D000000),
    tagPurple: Color(0xFFAF52DE),
    tagBlue: Color(0xFF007AFF),
    tagGreen: Color(0xFF34C759),
    tagOrange: Color(0xFFFF9500),
    tagGray: Color(0xFF8E8E93),
  );

  /// Linear 深色
  static const linearDark = AppColors(
    primary: Color(0xFF5E6AD2),          // Linear indigo
    onPrimary: Colors.white,
    background: Color(0xFF0F1011),
    surface: Color(0xFF191A1B),
    surfaceVariant: Color(0xFF232426),
    onBackground: Color(0xFFF7F8F8),
    onSurface: Color(0xFFF7F8F8),
    secondaryText: Color(0xFF8A8F98),
    border: Color(0xFF2E2F30),
    success: Color(0xFF4CB782),
    danger: Color(0xFFEB5757),
    cardShadow: Color(0x40000000),
    tagPurple: Color(0xFFA78BFA),
    tagBlue: Color(0xFF60A5FA),
    tagGreen: Color(0xFF4ADE80),
    tagOrange: Color(0xFFFB923C),
    tagGray: Color(0xFF9CA3AF),
  );

  /// Craft / Bear 风格
  static const craft = AppColors(
    primary: Color(0xFF5B6AE0),
    onPrimary: Colors.white,
    background: Color(0xFFFAF9F7),       // 暖白
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3F1EC),
    onBackground: Color(0xFF2C2C2C),
    onSurface: Color(0xFF2C2C2C),
    secondaryText: Color(0xFF8B8680),
    border: Color(0xFFE8E4DC),
    success: Color(0xFF3D8B6E),
    danger: Color(0xFFD64545),
    cardShadow: Color(0x0A000000),
    tagPurple: Color(0xFF8B7EC8),
    tagBlue: Color(0xFF6B9BD1),
    tagGreen: Color(0xFF6BAF8D),
    tagOrange: Color(0xFFD4A574),
    tagGray: Color(0xFFA09B93),
  );

  static AppColors of(AppThemeType type) {
    switch (type) {
      case AppThemeType.notion:
        return notion;
      case AppThemeType.appleMinimal:
        return appleMinimal;
      case AppThemeType.linearDark:
        return linearDark;
      case AppThemeType.craft:
        return craft;
    }
  }
}
