package auth

import (
	"database/sql"
	"fmt"
	"sync"
	"time"
)

// Service 验证码内存 + JWT 签发/校验
type Service struct {
	db        *sql.DB
	jwtSecret string
	accessTTL time.Duration

	mu    sync.RWMutex
	codes map[string]codeEntry // phone -> entry（验证码仍内存，短时有效）
}

type codeEntry struct {
	Code      string
	ExpiresAt time.Time
}

// NewService jwtSecret 用于 HS256 签名；accessTTL 默认 2 小时
func NewService(db *sql.DB, jwtSecret string) *Service {
	return &Service{
		db:        db,
		jwtSecret: jwtSecret,
		accessTTL: 2 * time.Hour,
		codes:     make(map[string]codeEntry),
	}
}

// AccessTTL 返回 Access Token 有效期，供 Login 响应 expires_in
func (s *Service) AccessTTL() time.Duration {
	return s.accessTTL
}

func (s *Service) SendCode(phone string) (string, error) {
	if len(phone) < 11 {
		return "", fmt.Errorf("invalid phone")
	}

	code := "123456"

	s.mu.Lock()
	s.codes[phone] = codeEntry{
		Code:      code,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}
	s.mu.Unlock()

	fmt.Printf("[MOCK SMS] phone=%s code=%s\n", phone, code)
	return code, nil
}

func (s *Service) Login(phone, code string) (string, error) {
	s.mu.RLock()
	entry, ok := s.codes[phone]
	s.mu.RUnlock()

	if !ok {
		return "", fmt.Errorf("请先获取验证码")
	}
	if time.Now().After(entry.ExpiresAt) {
		return "", fmt.Errorf("验证码已过期")
	}
	if entry.Code != code {
		return "", fmt.Errorf("验证码错误")
	}

	s.mu.Lock()
	delete(s.codes, phone)
	s.mu.Unlock()

	// 确保用户存在
	if _, err := s.db.Exec(`INSERT OR IGNORE INTO users (phone) VALUES (?)`, phone); err != nil {
		return "", err
	}

	return s.issueToken(phone)
}

// PhoneByToken 解析 JWT，返回手机号；无效或过期返回 false
func (s *Service) PhoneByToken(token string) (string, bool) {
	phone, err := s.parseToken(token)
	if err != nil {
		return "", false
	}
	return phone, true
}
