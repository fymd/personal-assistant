package ops

// RemoteDesktopProfile 远程桌面连接配置（不含密码，安全起见第一版不存口令）
type RemoteDesktopProfile struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Protocol  string `json:"protocol"` // RDP | VNC | SSH
	Host      string `json:"host"`
	Port      int    `json:"port"`
	Username  string `json:"username"`
	Note      string `json:"note"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type CreateProfileRequest struct {
	Name     string `json:"name"`
	Protocol string `json:"protocol"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Username string `json:"username"`
	Note     string `json:"note"`
}

type UpdateProfileRequest struct {
	Name     *string `json:"name"`
	Protocol *string `json:"protocol"`
	Host     *string `json:"host"`
	Port     *int    `json:"port"`
	Username *string `json:"username"`
	Note     *string `json:"note"`
}
