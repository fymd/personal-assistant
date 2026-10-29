# Backend（Go）

## 本地运行

```bash
cd backend
go mod tidy
go run ./cmd/server
```

首次运行会自动：
- 创建 `./data/assistant.db`（可用环境变量 `DB_PATH` 修改）
- 建表：`users` / `sessions` / `memos`（`sessions` 表保留兼容，新登录不再写入）

服务默认监听 `:8080`

- 健康检查：`GET /health`
- 发送验证码：`POST /api/v1/auth/send-code`  `{ "phone": "13800138000" }`
- 登录：`POST /api/v1/auth/login`  `{ "phone": "13800138000", "code": "123456" }`
- 备忘录：`GET/POST /api/v1/memos`（需 `Authorization: Bearer <jwt>`）

### 登录响应示例

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "token": "<JWT>",
    "phone": "13800138000",
    "expires_in": 7200
  }
}
```

Token 为 HS256 JWT，默认有效期 2 小时。

## 短信验证码

| SMS_PROVIDER | 行为 |
|--------------|------|
| `mock`（默认） | 不真实发送，验证码打印在服务端日志；可用 `SMS_FIXED_CODE` 固定（默认 123456） |
| `aliyun` | 阿里云 Dysmsapi SendSms |
| `tencent` | 占位，尚未实现 |

防护：
- 同一手机号发送间隔 ≥ 60 秒
- 验证码 5 分钟有效
- 最多试错 5 次，超限需重新获取

## 持久化说明

| 数据 | 存储 |
|------|------|
| 用户 | SQLite `users` |
| 登录凭证 | JWT（无状态，密钥为 `JWT_SECRET`） |
| 备忘录 | SQLite `memos`（重启不丢失） |
| 验证码 | 内存（5 分钟过期） |

依赖：`modernc.org/sqlite`、`github.com/golang-jwt/jwt/v5`

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| SERVER_PORT | 8080 | 服务端口 |
| DB_PATH | ./data/assistant.db | SQLite 路径 |
| JWT_SECRET | change-me-in-production | **生产必须改为强随机串** |
| SMS_PROVIDER | mock | mock / aliyun / tencent |
| SMS_FIXED_CODE | 123456 | 仅 mock：固定验证码；留空则随机 |
| SMS_ACCESS_KEY | | 短信 AccessKey |
| SMS_ACCESS_SECRET | | 短信 Secret |
| SMS_SIGN_NAME | | 短信签名 |
| SMS_TEMPLATE_CODE | | 短信模板 CODE |

## 下一步

1. ✅ SQLite 持久化
2. ✅ 正式 JWT
3. ✅ 短信 Provider 抽象（mock + 阿里云；腾讯云占位）
4. 运维 / AI 相关 API 完善
