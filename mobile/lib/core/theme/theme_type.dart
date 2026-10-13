/// 支持的主题类型
enum AppThemeType {
  /// Notion 风格（默认）- 结构化、卡片分明、内容优先
  notion,

  /// 苹果极简风格 - 大量留白、系统级质感
  appleMinimal,

  /// Linear 深色风格 - 高对比、专业工具感
  linearDark,

  /// Craft / Bear 风格 - 柔和、字体质感、编辑气质
  craft,
}

extension AppThemeTypeX on AppThemeType {
  String get displayName {
    switch (this) {
      case AppThemeType.notion:
        return 'Notion';
      case AppThemeType.appleMinimal:
        return 'Apple 极简';
      case AppThemeType.linearDark:
        return 'Linear 深色';
      case AppThemeType.craft:
        return 'Craft';
    }
  }

  String get description {
    switch (this) {
      case AppThemeType.notion:
        return '结构化、卡片分明、内容优先';
      case AppThemeType.appleMinimal:
        return '极简、大量留白、系统质感';
      case AppThemeType.linearDark:
        return '深色、高对比、专业工具感';
      case AppThemeType.craft:
        return '柔和、字体质感、编辑气质';
    }
  }

  /// 是否天然偏深色
  bool get isDark {
    return this == AppThemeType.linearDark;
  }
}
