package memo

import (
	"fmt"
	"sync"
	"time"

	"crypto/rand"
	"encoding/hex"
)

// Store 内存存储（后续可换 SQLite）
type Store struct {
	mu    sync.RWMutex
	memos map[string]*Memo // id -> memo
}

func NewStore() *Store {
	return &Store{
		memos: make(map[string]*Memo),
	}
}

func (s *Store) List(userPhone string, filter string) []*Memo {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []*Memo
	for _, m := range s.memos {
		if m.UserPhone != userPhone {
			continue
		}
		switch filter {
		case "uncompleted":
			if m.Completed {
				continue
			}
		case "completed":
			if !m.Completed {
				continue
			}
		case "starred":
			if !m.Starred {
				continue
			}
		}
		result = append(result, m)
	}

	// 按更新时间倒序
	for i := 0; i < len(result); i++ {
		for j := i + 1; j < len(result); j++ {
			if result[j].UpdatedAt.After(result[i].UpdatedAt) {
				result[i], result[j] = result[j], result[i]
			}
		}
	}
	return result
}

func (s *Store) Create(userPhone string, req CreateMemoRequest) (*Memo, error) {
	if req.Title == "" {
		return nil, fmt.Errorf("title is required")
	}
	id, err := genID()
	if err != nil {
		return nil, err
	}
	now := time.Now()
	m := &Memo{
		ID:        id,
		UserPhone: userPhone,
		Title:     req.Title,
		Content:   req.Content,
		Tag:       req.Tag,
		Completed: false,
		Starred:   false,
		CreatedAt: now,
		UpdatedAt: now,
	}
	s.mu.Lock()
	s.memos[id] = m
	s.mu.Unlock()
	return m, nil
}

func (s *Store) Get(userPhone, id string) (*Memo, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	m, ok := s.memos[id]
	if !ok || m.UserPhone != userPhone {
		return nil, fmt.Errorf("not found")
	}
	return m, nil
}

func (s *Store) Update(userPhone, id string, req UpdateMemoRequest) (*Memo, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	m, ok := s.memos[id]
	if !ok || m.UserPhone != userPhone {
		return nil, fmt.Errorf("not found")
	}
	if req.Title != nil {
		m.Title = *req.Title
	}
	if req.Content != nil {
		m.Content = *req.Content
	}
	if req.Tag != nil {
		m.Tag = *req.Tag
	}
	if req.Completed != nil {
		m.Completed = *req.Completed
	}
	if req.Starred != nil {
		m.Starred = *req.Starred
	}
	m.UpdatedAt = time.Now()
	return m, nil
}

func (s *Store) Delete(userPhone, id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	m, ok := s.memos[id]
	if !ok || m.UserPhone != userPhone {
		return fmt.Errorf("not found")
	}
	delete(s.memos, id)
	return nil
}

func (s *Store) ToggleComplete(userPhone, id string) (*Memo, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	m, ok := s.memos[id]
	if !ok || m.UserPhone != userPhone {
		return nil, fmt.Errorf("not found")
	}
	m.Completed = !m.Completed
	m.UpdatedAt = time.Now()
	return m, nil
}

func genID() (string, error) {
	b := make([]byte, 8)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
