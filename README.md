# Personal Assistant（个人助理）

> 个人效率 + 运维工具一体化的私有助理 App  
> 客户端：Flutter（优先移动端） | 后端：Go | UI：极简现代 · 苹果风格

## 项目定位

- 备忘录 / 待办事项管理
- AI 任务辅助（总结、生成待办、润色、对话）
- 运维工具集合（远程桌面、Ping、扫码 + Excel 导出）
- 自建后端多设备同步
- 账号体系 + 预留订阅会员接口
- 后期扩展：工作信息归集（邮件/微信/飞书）、Web 端

## 技术栈

| 层级 | 技术 |
|------|------|
| 客户端 | Flutter (iOS + Android) |
| 后端 | Go |
| 数据库 | SQLite（本地开发）→ 可迁移 PostgreSQL/MySQL |
| 认证 | 手机号 + 验证码 |
| 同步 | 自建后端 |
| UI 风格 | 极简现代，参考苹果设计语言 |

## 仓库结构

```
personal-assistant/
├── README.md
├── .gitignore
├── docs/                       # 文档
│   └── ARCHITECTURE.md
├── backend/                    # Go 后端
│   ├── cmd/
│   │   └── server/
│   │       └── main.go
│   ├── internal/
│   │   ├── auth/               # 登录 / 验证码
│   │   ├── user/               # 用户
│   │   ├── memo/               # 备忘录 / 待办
│   │   ├── ai/                 # AI 调用封装
│   │   ├── ops/                # 运维相关（扫码记录等）
│   │   └── config/
│   ├── pkg/
│   ├── go.mod
│   └── go.sum
├── mobile/                     # Flutter 客户端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   ├── core/               # 主题、路由、网络、存储
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── memo/
│   │   │   ├── ai/
│   │   │   ├── ops/            # 远程桌面、Ping、扫码
│   │   │   └── profile/
│   │   └── shared/
│   ├── pubspec.yaml
│   └── ...
└── scripts/                    # 辅助脚本
```

## 快速开始（本地开发）

### 后端

```bash
cd backend
go mod tidy
go run ./cmd/server
```

### 客户端

```bash
cd mobile
flutter pub get
flutter run
```

> 注意：首次使用请先在 `mobile/` 目录执行 `flutter create . --org com.yourname.personalassistant` 补全平台文件（ios/android），再开发业务代码。

## MVP 功能清单（第一阶段）

- [ ] 手机号 + 验证码登录 / 注册
- [ ] 备忘录 & 待办（增删改查、完成状态）
- [ ] AI 任务辅助（调用云端 API）
- [ ] 远程桌面入口
- [ ] Ping 工具
- [ ] 扫码（二维码/条形码）+ 导出 Excel
- [ ] 基础账号与数据同步
- [ ] 极简苹果风格 UI + 深色模式

## 后续规划

- 工作信息归集（邮件 / 微信 / 飞书）
- 会员订阅接口预留
- Web 端简单查看
- 更多运维工具

## License

Private
