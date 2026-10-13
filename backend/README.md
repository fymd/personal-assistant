# Backend（Go）

## 本地运行

```bash
cd backend
go mod tidy
go run ./cmd/server
```

服务默认监听 `:8080`，健康检查：`GET /health`

## 目录说明

```
backend/
├── cmd/server/          # 入口
├── internal/
│   ├── auth/            # 手机号验证码登录
│   ├── user/
│   ├── memo/            # 备忘录 / 待办
│   ├── ai/              # AI 代理（调用云端 API）
│   ├── ops/             # 扫码记录等
│   └── config/
└── pkg/                 # 公共库（后续添加）
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| SERVER_PORT | 8080 | 服务端口 |
| DB_PATH | ./data/assistant.db | SQLite 路径 |
| JWT_SECRET | change-me-in-production | JWT 密钥 |
| SMS_PROVIDER | mock | 短信服务商（开发用 mock） |

## 下一步

1. 接入 SQLite + 用户表 / 备忘录表
2. 实现验证码发送与登录（开发阶段 mock 验证码）
3. 实现 JWT 中间件
4. 备忘录 CRUD API
5. 预留 membership 相关路由
