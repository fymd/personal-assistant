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
| 历史页 | App 内查看/删除云端记录；按工具筛选 |

**可同步历史的工具**：`ping` · `port_scan` · `dns` · `http_check` · `network_diag`  
（登录后各探测页提供「同步到运维历史」）

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

`tool` 取值：`port_scan` | `network_diag` | `http_check` | `ping` | `dns`

### detail JSON schema（version = 1）

客户端统一经 `OpsHistoryDetail` 生成；历史页会对 JSON 做缩进展示。

**ping**

```json
{
  "version": 1,
  "port": 80,
  "count": 4,
  "success": 3,
  "fail": 1,
  "min_ms": 12,
  "max_ms": 45,
  "avg_ms": 20.5,
  "samples": [{ "ok": true, "ms": 12, "message": "连通" }]
}
```

**port_scan**

```json
{
  "version": 1,
  "ports": [{ "port": 22, "open": true, "ms": 8 }]
}
```

**dns**

```json
{
  "version": 1,
  "elapsed_ms": 15,
  "addresses": [{ "address": "1.2.3.4", "type": "IPv4" }],
  "error": "可选"
}
```

**http_check**

```json
{
  "version": 1,
  "method": "GET",
  "url": "https://example.com",
  "status": 200,
  "elapsed_ms": 120,
  "content_length": "1234",
  "error": "可选"
}
```

**network_diag**

```json
{
  "version": 1,
  "host": "example.com",
  "logs": ["— 本机网卡 —", "wlan0 192.168.1.2", "..."]
}
```

## 客户端结构

```
mobile/lib/features/ops/
├── data/
│   ├── ops_history_repository.dart   # API
│   ├── ops_history_detail.dart       # detail schema 构建
│   └── ops_history_sync.dart         # 统一同步 + SnackBar
└── presentation/
    ├── ops_home_page.dart
    ├── ops_history_page.dart         # 工具筛选 FilterChip
    ├── ping_page.dart
    ├── port_scan_page.dart
    ├── dns_lookup_page.dart
    ├── http_check_page.dart
    ├── network_diag_page.dart
    └── ...
```
