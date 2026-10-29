package sms

import (
	"fmt"
	"strings"

	"github.com/fymd/personal-assistant/backend/internal/config"
)

// Provider 短信发送抽象
type Provider interface {
	// Send 发送验证码短信；code 为已生成的 6 位数字
	Send(phone, code string) error
	Name() string
}

// NewProvider 根据配置创建短信 Provider
func NewProvider(cfg *config.Config) (Provider, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.SMSProvider)) {
	case "", "mock":
		return NewMock(), nil
	case "aliyun":
		return NewAliyun(cfg)
	case "tencent":
		return NewTencent(cfg)
	default:
		return nil, fmt.Errorf("unknown SMS_PROVIDER: %s (use mock|aliyun|tencent)", cfg.SMSProvider)
	}
}
