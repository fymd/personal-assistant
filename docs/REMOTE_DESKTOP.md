# 远程桌面方案说明

## 分阶段状态

| 阶段 | 模式 `connect_mode` | 能力 | 状态 |
|------|---------------------|------|------|
| 1 | `external` | 配置云同步；唤起系统 RDP/VNC/SSH 客户端 | ✅ |
| 2 | `gateway` | 配置网关 URL；App 内 WebView 打开 Guacamole/RustDesk Web 等 | ✅ |
| 3 | `native` | App 内嵌远程画面（WebRTC 等） | 占位，未实现 |

服务端**不存储密码**，仅存连接元数据与网关入口 URL。

## 阶段 2：网关模式怎么用

1. 自行部署远程桌面网关（任选）：
   - [Apache Guacamole](https://guacamole.apache.org/)：浏览器访问 RDP/VNC/SSH
   - [RustDesk](https://rustdesk.com/) 自建：Web 客户端或中继
   - 其他提供 HTTPS Web 控制台的方案
2. 在 App「远程桌面」中新建连接：
   - **连接模式**选「网关」
   - **网关 URL** 填完整地址，例如 `https://guac.example.com/#/client/...`
3. 点击连接 → App 内 WebView 打开该地址并登录网关

也可将网关 URL 设为门户首页，在网关内再选择具体主机。

## API 字段

```json
{
  "name": "办公机-Guacamole",
  "protocol": "RDP",
  "host": "192.168.1.10",
  "port": 3389,
  "connect_mode": "gateway",
  "gateway_url": "https://guac.example.com/"
}
```

- `external`：可只填 host/port，用系统客户端
- `gateway`：必须填 `gateway_url`
- `native`：客户端展示占位页

## 阶段 3 说明

内置 WebRTC/RDP 栈工作量大（编码、输入注入、剪贴板、多平台），需单独立项。在此之前请使用阶段 1 或 2。
