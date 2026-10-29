package ops

import (
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
)

// SignalMessage WebRTC 信令载荷（SDP 或 ICE）
type SignalMessage struct {
	Type      string `json:"type"` // offer | answer | candidate
	Role      string `json:"role"` // viewer | agent
	SDP       string `json:"sdp,omitempty"`
	Candidate string `json:"candidate,omitempty"`
	SDPMid    string `json:"sdp_mid,omitempty"`
	SDPMLine  *int   `json:"sdp_m_line_index,omitempty"`
	At        int64  `json:"at"`
}

// RDSession 一次内置远程会话（内存，进程重启即失效）
type RDSession struct {
	ID        string `json:"id"`
	Owner     string `json:"owner"`
	ProfileID string `json:"profile_id,omitempty"`
	HostHint  string `json:"host_hint,omitempty"`
	Protocol  string `json:"protocol,omitempty"`
	CreatedAt int64  `json:"created_at"`
	ExpiresAt int64  `json:"expires_at"`

	mu       sync.Mutex
	messages []SignalMessage
}

type SignalHub struct {
	mu       sync.Mutex
	sessions map[string]*RDSession
}

func NewSignalHub() *SignalHub {
	h := &SignalHub{sessions: make(map[string]*RDSession)}
	go h.gcLoop()
	return h
}

func (h *SignalHub) gcLoop() {
	ticker := time.NewTicker(2 * time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		h.mu.Lock()
		now := time.Now().Unix()
		for id, s := range h.sessions {
			if now > s.ExpiresAt {
				delete(h.sessions, id)
			}
		}
		h.mu.Unlock()
	}
}

type CreateSessionRequest struct {
	ProfileID string `json:"profile_id"`
	HostHint  string `json:"host_hint"`
	Protocol  string `json:"protocol"`
}

func (h *SignalHub) Create(owner string, req CreateSessionRequest) *RDSession {
	now := time.Now()
	s := &RDSession{
		ID:        uuid.NewString(),
		Owner:     owner,
		ProfileID: req.ProfileID,
		HostHint:  req.HostHint,
		Protocol:  req.Protocol,
		CreatedAt: now.Unix(),
		ExpiresAt: now.Add(30 * time.Minute).Unix(),
		messages:  nil,
	}
	h.mu.Lock()
	h.sessions[s.ID] = s
	h.mu.Unlock()
	return s
}

func (h *SignalHub) Get(id string) (*RDSession, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	s, ok := h.sessions[id]
	if !ok || time.Now().Unix() > s.ExpiresAt {
		delete(h.sessions, id)
		return nil, fmt.Errorf("session not found or expired")
	}
	return s, nil
}

func (h *SignalHub) Post(id, role string, msg SignalMessage) error {
	s, err := h.Get(id)
	if err != nil {
		return err
	}
	msg.Role = role
	if msg.At == 0 {
		msg.At = time.Now().UnixMilli()
	}
	s.mu.Lock()
	s.messages = append(s.messages, msg)
	// 防止无限增长
	if len(s.messages) > 200 {
		s.messages = s.messages[len(s.messages)-100:]
	}
	s.mu.Unlock()
	return nil
}

// Poll 返回 since 之后、且非 selfRole 发出的消息（对端信令）
func (h *SignalHub) Poll(id, selfRole string, since int64) ([]SignalMessage, error) {
	s, err := h.Get(id)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	var out []SignalMessage
	for _, m := range s.messages {
		if m.At > since && m.Role != selfRole {
			out = append(out, m)
		}
	}
	if out == nil {
		out = []SignalMessage{}
	}
	return out, nil
}

func (s *RDSession) Public() map[string]interface{} {
	return map[string]interface{}{
		"id":         s.ID,
		"owner":      s.Owner,
		"profile_id": s.ProfileID,
		"host_hint":  s.HostHint,
		"protocol":   s.Protocol,
		"created_at": s.CreatedAt,
		"expires_at": s.ExpiresAt,
		"note":       "主机端 Agent 需加入同一 session_id 并发送 offer/answer",
	}
}
