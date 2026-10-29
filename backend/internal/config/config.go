package config

import (
	"os"
)

// Config 应用配置
type Config struct {
	ServerPort  string
	DBPath      string
	JWTSecret   string
	SMSProvider string

	// 短信（aliyun / tencent）
	SMSAccessKey    string
	SMSAccessSecret string
	SMSSignName     string
	SMSTemplateCode string
	SMSFixedCode    string // 仅 mock：固定验证码；空则 mock 也随机

	// AI（OpenAI 兼容接口）
	AIAPIKey  string
	AIBaseURL string
	AIModel   string
}

func Load() *Config {
	return &Config{
		ServerPort:  getEnv("SERVER_PORT", "8080"),
		DBPath:      getEnv("DB_PATH", "./data/assistant.db"),
		JWTSecret:   getEnv("JWT_SECRET", "change-me-in-production"),
		SMSProvider: getEnv("SMS_PROVIDER", "mock"),

		SMSAccessKey:    getEnv("SMS_ACCESS_KEY", ""),
		SMSAccessSecret: getEnv("SMS_ACCESS_SECRET", ""),
		SMSSignName:     getEnv("SMS_SIGN_NAME", ""),
		SMSTemplateCode: getEnv("SMS_TEMPLATE_CODE", ""),
		SMSFixedCode:    getEnv("SMS_FIXED_CODE", "123456"),

		AIAPIKey:  getEnv("AI_API_KEY", ""),
		AIBaseURL: getEnv("AI_BASE_URL", "https://api.openai.com/v1"),
		AIModel:   getEnv("AI_MODEL", "gpt-4o-mini"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
