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

## 目录规划

```
lib/
├── main.dart
├── app/                    # App 级别配置、路由
├── core/
│   ├── theme/
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

1. 完善主题与基础组件（按钮、卡片、输入框等苹果风格）
2. 实现登录页（手机号 + 验证码）
3. 实现备忘录列表与详情
4. 接入扫码功能与 Excel 导出
