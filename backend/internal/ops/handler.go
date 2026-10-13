package ops

// TODO: 运维相关数据接口
//
// 扫码记录：
// GET  /api/v1/ops/scans
// POST /api/v1/ops/scans
// 支持导出 Excel（可在客户端本地生成，或后端提供下载）
//
// Ping 历史记录（可选）
// 远程桌面连接配置（可选存储）

type Handler struct {}

func NewHandler() *Handler {
	return &Handler{}
}
