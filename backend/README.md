# Backend（Go）

## 本地运行

```bash
cd backend
go mod tidy
go run ./cmd/server
```

首次运行会自动：
- 创建 `./data/assistant.db`（可用环境变量 `DB_PATH` 修改）
- 建表：`users` / `sessions` / `memos`

服务默认监听 `:8080`

- 健康检查：`GET /health`
- 发送验证码：`POST /api/v1/auth/send-code`  `{ "phone": "13800138000" }`
- 登录：`POST /api/v1/auth/login`  `{ "phone": "13800138000", "code": "123456" }`
- 备忘录：`GET/POST /api/v1/memos`（需 `Authorization: Bearer <token>`）

**开发环境验证码固定为 `123456`**

## 持久化说明

| 数据 | 存储 |
|------|------|
| 用户 | SQLite `users` |
| 登录 session | SQLite `sessions`（重启后 token 仍有效） |
| 备忘录 | SQLite `memos`（重启不丢失） |
| 验证码 | 内存（5 分钟过期） |

依赖：`modernc.org/sqlite`（纯 Go，无需 CGO）

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| SERVER_PORT | 8080 | 服务端口 |
| DB_PATH | ./data/assistant.db | SQLite 路径 |
| JWT_SECRET | change-me-in-production | 预留 |
| SMS_PROVIDER | mock | 短信服务商 |

## 下一步

1. ✅ SQLite 持久化
2. 正式 JWT
3. 运维 / AI 相关 API
