package membership

// Tier 会员等级
const (
	TierFree    = "free"
	TierPro     = "pro"
	TierPremium = "premium"
)

// Status 当前用户会员状态
type Status struct {
	Phone      string  `json:"phone"`
	Tier       string  `json:"tier"`
	ExpireAt   *string `json:"expire_at,omitempty"` // RFC3339 或 SQLite datetime，未开通为空
	Active     bool    `json:"active"`              // 是否在有效期内
	ThemePref  string  `json:"theme_preference"`
}

// ActivateRequest 开发期激活占位（后续可改为支付回调）
type ActivateRequest struct {
	Tier     string `json:"tier"`      // pro | premium
	Days     int    `json:"days"`      // 开通天数，默认 30
}
