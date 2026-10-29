package sms

import (
	"log"
)

// Mock 开发用：仅打印日志，不真实发送
type Mock struct{}

func NewMock() *Mock {
	return &Mock{}
}

func (m *Mock) Name() string { return "mock" }

func (m *Mock) Send(phone, code string) error {
	log.Printf("[MOCK SMS] phone=%s code=%s", phone, code)
	return nil
}
