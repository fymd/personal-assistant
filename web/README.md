# Web 端（简单查看）

轻量静态页，复用 Go 后端 API，用于电脑浏览器快速查看/轻量编辑备忘录。

## 能力（骨架）

- 手机号 + 验证码登录（JWT）
- 备忘录列表（筛选：全部 / 未完成 / 已完成 / 星标）
- 新建备忘录、切换完成状态
- 展示会员等级（若已开通）
- 可配置 API Base URL（右下角齿轮）

## 启动方式

### 方式 A：后端一并托管（推荐）

在仓库根目录启动后端时，会自动尝试挂载 `web/`：

```bash
cd backend
go run ./cmd/server
```

浏览器打开：http://127.0.0.1:8080/

也可显式指定：

```bash
export WEB_STATIC_DIR=/path/to/personal-assistant/web
go run ./cmd/server
```

### 方式 B：单独打开静态文件

用任意静态服务器打开 `web/`，并在页面设置里把 API 指到 `http://127.0.0.1:8080`（需后端已开 CORS）。

## 说明

- 非 Flutter Web，便于零构建预览；后续若统一技术栈可再迁 Flutter Web。
- 开发环境验证码见后端 mock / `SMS_FIXED_CODE`。
