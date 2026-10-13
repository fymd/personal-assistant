package auth

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"
	"sync"
	"time"
)

// Service 验证码内存 + session SQLite 持久化
type Service struct {
	db    *sql.DB
	mu    sync.RWMutex
	codes map[string]codeEntry // phone -> entry（验证码仍内存，短时有效）
}

type codeEntry struct {
	Code      string
	ExpiresAt time.Time
}

func NewService(db *sql.DB) *Service {
	return &Service{
		db:    db,
		codes: make(map[string]codeEntry),
	}
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

	token, err := generateToken()
	if err != nil {
		return "", err
	}

	if _, err := s.db.Exec(`INSERT INTO sessions (token, phone) VALUES (?, ?)`, token, phone); err != nil {
		return "", err
	}

	return token, nil
}

func (s *Service) PhoneByToken(token string) (string, bool) {
	var phone string
	err := s.db.QueryRow(`SELECT phone FROM sessions WHERE token = ?`, token).Scan(&phone)
	if err != nil {
		return "", false
	}
	return phone, true
}

func generateToken() (string, error) {
	b := make([]byte, 24)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
