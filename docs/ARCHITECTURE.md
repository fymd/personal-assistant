# Architecture Overview

## 高层架构

```
┌─────────────────┐       HTTPS / JSON        ┌─────────────────┐
│  Flutter App    │ ◄──────────────────────► │   Go Backend    │
│  (iOS/Android)  │                           │                 │
│                 │                           │  - Auth         │
│  - Auth         │                           │  - User         │
│  - Memo/Todo    │                           │  - Memo         │
│  - AI Assist    │                           │  - AI Proxy     │
│  - Ops Tools    │                           │  - Ops Data     │
│  - Profile      │                           │  - Membership   │
└─────────────────┘                           └────────┬────────┘
                                                       │
                                                       ▼
                                                 ┌───────────┐
                                                 │  SQLite   │
                                                 │ (可迁移)  │
                                                 └───────────┘
```

## 客户端（Flutter）

采用 **Feature-first** 目录结构：

- `core/`：主题（苹果风格）、路由、网络层、本地存储、工具类
- `features/`：按业务模块划分（auth / memo / ai / ops / profile）
- 每个 feature 内部可再分 `data` / `domain` / `presentation`（轻量 Clean Architecture）

UI 原则：
- 极简、大量留白、系统级圆角与阴影
- 支持深色模式（跟随系统）
- 使用 Material 3 + 自定义 Theme 模拟苹果质感，或 Cupertino 组件混合

## 后端（Go）

- `cmd/server`：入口
- `internal/`：业务逻辑（按领域划分）
- `pkg/`：可复用公共库
- 使用标准库 + 少量成熟依赖（如 chi/gin、gorm 或 sqlx、jwt 等）
- 接口设计预留会员订阅相关路由与中间件

## 认证流程（手机号 + 验证码）

1. 客户端请求发送验证码 → 后端调用短信服务商（开发阶段可 mock）
2. 用户提交手机号 + 验证码 → 后端校验 → 签发 JWT / Session
3. 后续请求携带 Token

## 数据同步

- 备忘录、扫码记录等通过 REST API 同步
- 冲突策略：后续可扩展（目前以服务端为准或 last-write-wins）

## 安全与扩展

- 所有敏感配置通过环境变量注入
- 预留 `/api/v1/membership` 等接口
- 远程桌面功能初期可先做入口 + 跳转第三方或 WebRTC 方案调研
