# 远程桌面方案说明

## 分阶段状态

| 阶段 | 模式 `connect_mode` | 能力 | 状态 |
|------|---------------------|------|------|
| 1 | `external` | 配置云同步；唤起系统 RDP/VNC/SSH 客户端 | ✅ |
| 2 | `gateway` | 配置网关 URL；App 内 WebView（Guacamole/RustDesk Web） | ✅ |
| 3 | `native` | App 内 WebRTC 观看端 + 后端信令；主机 Agent 推流 | ✅ 骨架（需 Agent） |

服务端**不存储密码**。

## 阶段 2：网关模式

1. 部署 Guacamole / RustDesk Web 等  
2. 连接模式选「网关」，填写 `gateway_url`  
3. App 内 WebView 打开  

## 阶段 3：WebRTC 内置会话

### 架构

```
[主机 Agent] --offer/candidates--> [Go 信令 Hub] <--answer/candidates-- [Flutter 观看端]
       |                              内存会话                              |
       +----------------------- WebRTC 媒体面（P2P/中继）-------------------+
```

### 信令 API（需 JWT）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/ops/remote-desktop/sessions` | 创建会话，返回 `session_id` |
| GET | `/api/v1/ops/remote-desktop/sessions/{id}` | 会话元数据 |
| POST | `/api/v1/ops/remote-desktop/sessions/{id}/signal?role=viewer\|agent` | 上报 SDP/ICE |
| GET | `/api/v1/ops/remote-desktop/sessions/{id}/signal?role=...&since=` | 拉取对端信令 |

消息体示例：

```json
{ "type": "offer", "sdp": "v=0..." }
{ "type": "answer", "sdp": "v=0..." }
{ "type": "candidate", "candidate": "candidate:...", "sdp_mid": "0", "sdp_m_line_index": 0 }
```

会话内存保存，约 30 分钟过期；多实例部署需改为 Redis 等共享存储。

### 客户端

- 依赖：`flutter_webrtc`
- 观看端：`NativeRdSessionPage`（RecvOnly transceiver，轮询信令）
- 复制 Session ID 供 Agent 加入

### 主机 Agent（本仓库未实现）

需自行或后续实现：采集屏幕 → WebRTC 发送轨 → 以 `role=agent` 发 offer，并处理 viewer 的 answer/candidates。

在无 Agent 前，实用方案仍是 **阶段 1 外置客户端** 或 **阶段 2 网关**。

## API 配置字段

```json
{
  "name": "办公机",
  "protocol": "RDP",
  "host": "192.168.1.10",
  "port": 3389,
  "connect_mode": "native",
  "gateway_url": ""
}
```
