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

- `core/`：主题系统、路由、网络层、本地存储、工具类
- `features/`：按业务模块划分（auth / memo / ai / ops / profile）
- 每个 feature 内部可再分 `data` / `domain` / `presentation`（轻量 Clean Architecture）

### UI 主题系统

支持多主题，用户可自由切换，偏好同步到账号：

| 主题 | 默认 | 特点 |
|------|------|------|
| **Notion** | ✅ | 结构化、卡片分明、信息密度适中、内容优先 |
| Apple Minimal | | 极简、大量留白、系统级质感 |
| Linear Dark | | 深色、高对比、锋利、专业工具感 |
| Craft / Bear | | 柔和、字体质感强、编辑气质 |

实现方式：
- `core/theme/` 下定义多套 `ThemeData` + 颜色 token
- 使用 Riverpod / Provider 管理当前主题
- 本地持久化 + 登录后同步到后端用户偏好

## 后端（Go）

- `cmd/server`：入口
- `internal/`：业务逻辑（按领域划分）
- `pkg/`：可复用公共库
- 使用标准库 + 少量成熟依赖（如 chi/gin、gorm 或 sqlx、jwt 等）
- 接口设计预留会员订阅相关路由与中间件
- 用户表预留 `theme_preference` 字段

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
