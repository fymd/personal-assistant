package auth

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"sync"
	"time"
)

// Service 处理验证码与登录逻辑（当前为内存 mock，后续可换真实短信 + DB）
type Service struct {
	mu     sync.RWMutex
	codes  map[string]codeEntry // phone -> entry
	tokens map[string]string    // token -> phone
}

type codeEntry struct {
	Code      string
	ExpiresAt time.Time
}

func NewService() *Service {
	return &Service{
		codes:  make(map[string]codeEntry),
		tokens: make(map[string]string),
	}
}

// SendCode 生成并「发送」验证码（开发环境固定返回 123456）
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

// Login 校验验证码并返回 token
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

	token, err := generateToken()
	if err != nil {
		return "", err
	}

	s.mu.Lock()
	s.tokens[token] = phone
	s.mu.Unlock()

	return token, nil
}

// PhoneByToken 根据 token 查手机号
func (s *Service) PhoneByToken(token string) (string, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	phone, ok := s.tokens[token]
	return phone, ok
}

func generateToken() (string, error) {
	b := make([]byte, 24)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
