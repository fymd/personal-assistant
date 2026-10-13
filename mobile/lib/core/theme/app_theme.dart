import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'theme_type.dart';

/// 根据主题类型构建完整 ThemeData
class AppTheme {
  static ThemeData build(AppThemeType type) {
    final colors = AppColors.of(type);
    final isDark = type.isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: _fontFamily(type),

      // 核心颜色
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.surface,
      dividerColor: colors.border,

      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.primary,
        onSecondary: colors.onPrimary,
        error: colors.danger,
        onError: colors.onPrimary,
        surface: colors.surface,
        onSurface: colors.onSurface,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: type == AppThemeType.appleMinimal,
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        titleTextStyle: TextStyle(
          fontSize: type == AppThemeType.notion ? 28 : 20,
          fontWeight: FontWeight.w700,
          color: colors.onBackground,
          letterSpacing: type == AppThemeType.notion ? -0.6 : -0.3,
          fontFamily: _fontFamily(type),
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // 卡片
      cardTheme: CardTheme(
        elevation: 0,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius(type)),
          side: BorderSide(
            color: colors.border.withOpacity(type == AppThemeType.notion ? 0.6 : 0.0),
            width: type == AppThemeType.notion ? 1 : 0,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: colors.secondaryText, fontSize: 15),
      ),

      // 按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(type == AppThemeType.appleMinimal ? 12 : 8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // 底部导航
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // 分割线
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      // 文字主题
      textTheme: _buildTextTheme(colors, type),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: colors.primary.withOpacity(0.12),
        labelStyle: TextStyle(
          fontSize: 13,
          color: colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border.withOpacity(0.5)),
        ),
      ),
    );
  }

  static String? _fontFamily(AppThemeType type) {
    // 后续可按主题加载不同字体
    return null;
  }

  static double _cardRadius(AppThemeType type) {
    switch (type) {
      case AppThemeType.notion:
        return 8;
      case AppThemeType.appleMinimal:
        return 12;
      case AppThemeType.linearDark:
        return 6;
      case AppThemeType.craft:
        return 10;
    }
  }

  static TextTheme _buildTextTheme(AppColors colors, AppThemeType type) {
    final base = type == AppThemeType.notion
        ? -0.3
        : (type == AppThemeType.linearDark ? -0.2 : -0.4);

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.onBackground,
        letterSpacing: base - 0.4,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.onBackground,
        letterSpacing: base - 0.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.onBackground,
        letterSpacing: base,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.onBackground,
        letterSpacing: base,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.onBackground,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colors.onBackground,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colors.secondaryText,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colors.onBackground,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colors.secondaryText,
      ),
    );
  }
}
