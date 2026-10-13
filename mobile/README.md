# Mobile（Flutter）

## 初始化平台文件（首次必做）

当前仓库只包含业务代码骨架，需要先生成 iOS / Android 平台文件：

```bash
cd mobile
flutter create . --org com.fymd.personalassistant --project-name personal_assistant
```

然后安装依赖：

```bash
flutter pub get
```

运行：

```bash
flutter run
```

## 多主题系统（已实现）

默认主题：**Notion**

支持切换：

| 主题 | 说明 |
|------|------|
| Notion（默认） | 结构化、卡片分明、内容优先 |
| Apple Minimal | 极简、大量留白、系统质感 |
| Linear Dark | 深色、高对比、专业工具感 |
| Craft | 柔和、字体质感、编辑气质 |

### 相关文件

```
lib/core/theme/
├── theme_type.dart        # 主题枚举
├── app_colors.dart        # 各主题颜色 Token
├── app_theme.dart         # ThemeData 构建器
├── theme_provider.dart    # Riverpod Provider + 本地持久化
└── theme.dart             # 统一导出
```

使用方式：

```dart
// 读取当前主题
final theme = ref.watch(themeDataProvider);
final colors = ref.watch(appColorsProvider);

// 切换主题
ref.read(themeTypeProvider.notifier).setTheme(AppThemeType.linearDark);
```

运行后点击右上角调色盘图标即可切换主题并实时预览。

## 目录规划

```
lib/
├── main.dart
├── app/                    # App 级别配置、路由
├── core/
│   ├── theme/              # ✅ 多主题系统
│   ├── network/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── memo/
│   ├── ai/
│   ├── ops/                # 远程桌面、Ping、扫码
│   └── profile/
└── shared/                 # 公共组件、模型
```

## 推荐状态管理

使用 **Riverpod**（已在 pubspec 中引入）。

## 下一步建议

1. ✅ 多主题系统（默认 Notion）
2. 实现登录页（手机号 + 验证码）
3. 实现备忘录列表与详情（按 Notion 风格）
4. 接入扫码功能与 Excel 导出
