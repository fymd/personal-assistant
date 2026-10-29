# 运维工具说明（Issue #7）

## 阶段 1

| 工具 | 能力 |
|------|------|
| Ping | TCP 端口连通与延迟 |
| 端口扫描 | 预设/自定义端口，最多 64，有限并发 |
| DNS 查询 | A/AAAA 解析 |

## 阶段 2

| 工具 | 能力 |
|------|------|
| SSH 连接 | `ssh://` 唤起系统客户端 |
| 网络诊断 | 网卡 + DNS + 80/443 |

## 阶段 3

| 能力 | 说明 |
|------|------|
| 运维历史上云 | `ops_tool_history` 表；`GET/POST/DELETE /api/v1/ops/history` |
| HTTP 探测 | GET/HEAD 状态码与耗时；可同步历史 |
| 历史页 | App 内查看/删除云端记录 |

端口扫描完成后可「同步到运维历史」（登录后）。

### 历史上传示例

```json
POST /api/v1/ops/history
{
  "tool": "port_scan",
  "target": "192.168.1.1",
  "summary": "开放 3/8",
  "detail": "{...}"
}
```

`tool` 建议值：`port_scan` | `network_diag` | `http_check` | `ping` | `dns`
