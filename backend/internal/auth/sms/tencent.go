package sms

import (
	"fmt"

	"github.com/fymd/personal-assistant/backend/internal/config"
)

// Tencent 腾讯云短信（占位，待实现）
type Tencent struct {
	// 预留：secretId, secretKey, sdkAppId, signName, templateId
}

func NewTencent(cfg *config.Config) (*Tencent, error) {
	_ = cfg
	return &Tencent{}, nil
}

func (t *Tencent) Name() string { return "tencent" }

func (t *Tencent) Send(phone, code string) error {
	return fmt.Errorf("tencent sms provider is not implemented yet; use mock or aliyun")
}
