# Architecture Overview

## 高层架构

```
┌─────────────────┐       HTTPS / JSON        ┌─────────────────┐
│  Flutter App    │ ◄──────────────────────► │   Go Backend    │
│  (iOS/Android)  │                           │                 │
│  + Web 静态页   │                           │  Auth / Memo    │
│                 │                           │  AI / Ops / Mem │
└─────────────────┘                           └────────┬────────┘
                                                       │
                                                       ▼
                                                 ┌───────────┐
                                                 │  SQLite   │
                                                 └───────────┘
```

## 远程桌面（分阶段）

详见 [REMOTE_DESKTOP.md](./REMOTE_DESKTOP.md)。

| 阶段 | `connect_mode` | 能力 | 状态 |
|------|----------------|------|------|
| **1** | `external` | 配置同步 + 系统客户端 URL Scheme | ✅ |
| **2** | `gateway` | 网关 URL + App 内 WebView | ✅ |
| **3** | `native` | 内置 WebRTC/专用协议画面 | 占位 |

安全：服务端不存密码；网关鉴权由网关自身完成。

## 认证

手机号验证码 → JWT（HS256）→ `Authorization: Bearer`

## 其他模块

- 会员：`/api/v1/membership`
- 短信：`SMS_PROVIDER=mock\|aliyun\|tencent`
- Web：`web/` 静态页由后端托管
