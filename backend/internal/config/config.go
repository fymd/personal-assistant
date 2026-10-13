package config

import (
	"os"
)

// Config 应用配置（后续可扩展为从环境变量 / 配置文件加载）
type Config struct {
	ServerPort string
	DBPath     string
	JWTSecret  string
	// SMS 相关（开发阶段可 mock）
	SMSProvider string
}

func Load() *Config {
	return &Config{
		ServerPort:  getEnv("SERVER_PORT", "8080"),
		DBPath:      getEnv("DB_PATH", "./data/assistant.db"),
		JWTSecret:   getEnv("JWT_SECRET", "change-me-in-production"),
		SMSProvider: getEnv("SMS_PROVIDER", "mock"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
