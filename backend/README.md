# Backend（Go）

## 本地运行

```bash
cd backend
go mod tidy
go run ./cmd/server
```

首次运行会自动建库建表。服务默认 `:8080`。若存在仓库内 `web/`，会同时托管 Web UI：http://127.0.0.1:8080/

## 主要 API

| 路径 | 说明 |
|------|------|
| `GET /health` | 健康检查 |
| `POST /api/v1/auth/send-code` | 发送验证码 |
| `POST /api/v1/auth/login` | 登录，返回 JWT |
| `GET/POST /api/v1/memos` | 备忘录 |
| `GET /api/v1/membership` | 会员状态 |
| `POST /api/v1/membership/activate` | 开发期开通会员 |
| `GET/POST /api/v1/ops/remote-desktop` | 远程桌面配置列表 / 新建 |
| `GET/PUT/DELETE /api/v1/ops/remote-desktop/{id}` | 单条查询 / 更新 / 删除 |
| `POST /api/v1/ai/chat` | AI 对话 |

受保护接口需：`Authorization: Bearer <jwt>`。

开发环境验证码见 `SMS_FIXED_CODE`（mock 默认 `123456`）。

### 远程桌面配置示例

```bash
# 新建
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"办公机","protocol":"RDP","host":"192.168.1.10","port":3389}' \
  http://127.0.0.1:8080/api/v1/ops/remote-desktop

# 更新
curl -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"办公机-改","protocol":"RDP","host":"192.168.1.10","port":3389}' \
  http://127.0.0.1:8080/api/v1/ops/remote-desktop/<id>
```

不存密码，仅元数据同步。

## 短信

| SMS_PROVIDER | 行为 |
|--------------|------|
| mock | 日志打印验证码 |
| aliyun | 阿里云 SendSms |
| tencent | 占位 |

## 环境变量

见 `.env.example`。生产务必设置强随机 `JWT_SECRET`。

## 依赖

`modernc.org/sqlite`、`github.com/golang-jwt/jwt/v5`、`github.com/google/uuid`
