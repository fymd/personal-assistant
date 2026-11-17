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

**可同步历史的工具**：`ping` · `port_scan` · `dns` · `http_check` · `network_diag` · `inspect`

### detail JSON schema（version = 1）

见仓库 `OpsHistoryDetail`；含 ping / port_scan / dns / http_check / network_diag / inspect。

## 巡检模板（本地）

一键对固定主机批量执行 DNS / TCP Ping / 端口 / HTTP，结果可同步（`tool=inspect`）。

- 存储：`SharedPreferences`（`ops_inspect_templates_v1`）
- 入口：运维首页 → 巡检模板
- 限制：端口 ≤32、HTTP URL ≤16

## 收藏目标（本地）

常用主机快捷填充，存于 `SharedPreferences`（`ops_favorite_targets_v1`）。

- 运维首页 → **收藏目标** 管理
- 各探测页主机输入下方芯片条：「收藏当前」/「管理」
- 最多 50 条；选择后自动 touch 排序
