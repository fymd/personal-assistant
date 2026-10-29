# Personal Assistant（个人助理）

> 个人效率 + 运维工具一体化的私有助理 App  
> 客户端：Flutter（优先移动端） | 后端：Go | Web：静态轻量页 | UI：多主题（默认 Notion 风格）

## 项目定位

- 备忘录 / 待办事项管理
- AI 任务辅助（总结、生成待办、润色、对话）
- 运维工具集合（远程桌面、Ping、扫码 + Excel 导出）
- 自建后端多设备同步
- 账号体系 + 预留订阅会员接口
- Web 端简单查看
- 后期扩展：工作信息归集（邮件/微信/飞书）

## 技术栈

| 层级 | 技术 |
|------|------|
| 客户端 | Flutter (iOS + Android) |
| Web | 静态 HTML/JS（由后端托管） |
| 后端 | Go |
| 数据库 | SQLite（本地开发）→ 可迁移 PostgreSQL/MySQL |
| 认证 | 手机号 + 验证码（JWT） |
| 同步 | 自建后端 |
| UI 风格 | **多主题支持**（用户可切换） |

## 仓库结构

```
personal-assistant/
├── README.md
├── docs/
├── backend/          # Go 后端
├── mobile/           # Flutter 客户端
├── web/              # Web 简单查看（登录 + 备忘录）
└── scripts/
```

## 快速开始（本地开发）

### 后端 + Web

```bash
cd backend
go mod tidy
go run ./cmd/server
```

- API：http://127.0.0.1:8080  
- Web：http://127.0.0.1:8080/ （自动挂载仓库内 `web/`）

开发环境验证码默认见 `SMS_FIXED_CODE`（mock 下多为 `123456`）。

### 客户端

```bash
cd mobile
flutter pub get
flutter run
```

> 首次请在 `mobile/` 执行 `flutter create . --org com.fymd.personalassistant` 补全平台文件。

## MVP 功能清单（第一阶段）

- [x] 手机号 + 验证码登录 / 注册
- [x] 备忘录 & 待办（增删改查、完成状态）
- [x] AI 任务辅助（调用云端 API）
- [x] 远程桌面入口（配置同步 + 外置客户端）
- [x] Ping 工具
- [x] 扫码（二维码/条形码）+ 导出 Excel
- [x] 基础账号与数据同步
- [x] 多主题支持（默认 Notion 风格）+ 深色模式
- [x] Web 端简单查看（骨架）

## 后续规划

- 工作信息归集（邮件 / 微信 / 飞书）
- 会员真实支付对接
- 远程桌面阶段 2/3（网关 / 内置画面）
- 更多运维工具

## License

Private
