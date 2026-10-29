package auth

import (
	"crypto/rand"
	"database/sql"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/fymd/personal-assistant/backend/internal/auth/sms"
)

const (
	sendInterval   = 60 * time.Second
	codeTTL        = 5 * time.Minute
	maxAttempts    = 5
	defaultCodeLen = 6
)

// Service 验证码 + JWT 签发/校验
type Service struct {
	db         *sql.DB
	jwtSecret  string
	accessTTL  time.Duration
	sms        sms.Provider
	fixedCode  string // 仅 mock 使用；空则随机

	mu    sync.RWMutex
	codes map[string]codeEntry
}

type codeEntry struct {
	Code      string
	ExpiresAt time.Time
	Attempts  int
	SentAt    time.Time
}

// NewService jwtSecret 用于 HS256；sms 为短信通道；fixedCode 仅 mock 下有效
func NewService(db *sql.DB, jwtSecret string, smsProvider sms.Provider, fixedCode string) *Service {
	return &Service{
		db:        db,
		jwtSecret: jwtSecret,
		accessTTL: 2 * time.Hour,
		sms:       smsProvider,
		fixedCode: fixedCode,
		codes:     make(map[string]codeEntry),
	}
}

func (s *Service) AccessTTL() time.Duration {
	return s.accessTTL
}

func (s *Service) SMSProviderName() string {
	if s.sms == nil {
		return "mock"
	}
	return s.sms.Name()
}

func (s *Service) SendCode(phone string) (string, error) {
	if len(phone) < 11 {
		return "", fmt.Errorf("invalid phone")
	}

	now := time.Now()

	s.mu.Lock()
	if entry, ok := s.codes[phone]; ok {
		if now.Sub(entry.SentAt) < sendInterval {
			wait := sendInterval - now.Sub(entry.SentAt)
			s.mu.Unlock()
			return "", fmt.Errorf("发送过于频繁，请 %d 秒后再试", int(wait.Seconds())+1)
		}
	}
	s.mu.Unlock()

	code, err := s.makeCode()
	if err != nil {
		return "", err
	}

	if err := s.sms.Send(phone, code); err != nil {
		return "", fmt.Errorf("发送失败: %w", err)
	}

	s.mu.Lock()
	s.codes[phone] = codeEntry{
		Code:      code,
		ExpiresAt: now.Add(codeTTL),
		Attempts:  0,
		SentAt:    now,
	}
	s.mu.Unlock()

	return code, nil
}

func (s *Service) makeCode() (string, error) {
	// mock 且配置了固定码时使用固定码
	if s.sms != nil && s.sms.Name() == "mock" && s.fixedCode != "" {
		return s.fixedCode, nil
	}
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func (s *Service) Login(phone, code string) (string, error) {
	s.mu.Lock()
	entry, ok := s.codes[phone]
	if !ok {
		s.mu.Unlock()
		return "", fmt.Errorf("请先获取验证码")
	}
	if time.Now().After(entry.ExpiresAt) {
		delete(s.codes, phone)
		s.mu.Unlock()
		return "", fmt.Errorf("验证码已过期")
	}
	if entry.Attempts >= maxAttempts {
		delete(s.codes, phone)
		s.mu.Unlock()
		return "", fmt.Errorf("错误次数过多，请重新获取验证码")
	}
	if entry.Code != code {
		entry.Attempts++
		s.codes[phone] = entry
		s.mu.Unlock()
		return "", fmt.Errorf("验证码错误")
	}
	delete(s.codes, phone)
	s.mu.Unlock()

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
