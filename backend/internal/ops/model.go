package ops

// 连接模式
const (
	ConnectModeExternal = "external" // 阶段 1：唤起系统客户端
	ConnectModeGateway  = "gateway"  // 阶段 2：网关 WebView / 浏览器
	ConnectModeNative   = "native"   // 阶段 3：内置画面（占位）
)

// RemoteDesktopProfile 远程桌面连接配置（不含密码）
type RemoteDesktopProfile struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Protocol    string `json:"protocol"` // RDP | VNC | SSH
	Host        string `json:"host"`
	Port        int    `json:"port"`
	Username    string `json:"username"`
	Note        string `json:"note"`
	ConnectMode string `json:"connect_mode"` // external | gateway | native
	GatewayURL  string `json:"gateway_url"`  // 网关完整 URL（Guacamole/RustDesk Web 等）
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

type CreateProfileRequest struct {
	Name        string `json:"name"`
	Protocol    string `json:"protocol"`
	Host        string `json:"host"`
	Port        int    `json:"port"`
	Username    string `json:"username"`
	Note        string `json:"note"`
	ConnectMode string `json:"connect_mode"`
	GatewayURL  string `json:"gateway_url"`
}

type UpdateProfileRequest struct {
	Name        *string `json:"name"`
	Protocol    *string `json:"protocol"`
	Host        *string `json:"host"`
	Port        *int    `json:"port"`
	Username    *string `json:"username"`
	Note        *string `json:"note"`
	ConnectMode *string `json:"connect_mode"`
	GatewayURL  *string `json:"gateway_url"`
}
