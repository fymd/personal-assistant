package memo

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"
	"time"
)

// Store SQLite 持久化
type Store struct {
	db *sql.DB
}

func NewStore(db *sql.DB) *Store {
	return &Store{db: db}
}

func (s *Store) List(userPhone string, filter string) ([]*Memo, error) {
	q := `SELECT id, user_phone, title, content, tag, completed, starred, created_at, updated_at
		FROM memos WHERE user_phone = ?`
	args := []interface{}{userPhone}

	switch filter {
	case "uncompleted":
		q += ` AND completed = 0`
	case "completed":
		q += ` AND completed = 1`
	case "starred":
		q += ` AND starred = 1`
	}
	q += ` ORDER BY updated_at DESC`

	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []*Memo
	for rows.Next() {
		m, err := scanMemo(rows)
		if err != nil {
			return nil, err
		}
		result = append(result, m)
	}
	if result == nil {
		result = []*Memo{}
	}
	return result, rows.Err()
}

func (s *Store) Create(userPhone string, req CreateMemoRequest) (*Memo, error) {
	if req.Title == "" {
		return nil, fmt.Errorf("title is required")
	}
	if err := ensureUser(s.db, userPhone); err != nil {
		return nil, err
	}
	id, err := genID()
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
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
	_, err = s.db.Exec(
		`INSERT INTO memos (id, user_phone, title, content, tag, completed, starred, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?)`,
		m.ID, m.UserPhone, m.Title, m.Content, m.Tag,
		m.CreatedAt.Format(time.RFC3339Nano),
		m.UpdatedAt.Format(time.RFC3339Nano),
	)
	if err != nil {
		return nil, err
	}
	return m, nil
}

func (s *Store) Get(userPhone, id string) (*Memo, error) {
	row := s.db.QueryRow(
		`SELECT id, user_phone, title, content, tag, completed, starred, created_at, updated_at
		 FROM memos WHERE id = ? AND user_phone = ?`, id, userPhone,
	)
	return scanMemoRow(row)
}

func (s *Store) Update(userPhone, id string, req UpdateMemoRequest) (*Memo, error) {
	m, err := s.Get(userPhone, id)
	if err != nil {
		return nil, err
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
	m.UpdatedAt = time.Now().UTC()

	_, err = s.db.Exec(
		`UPDATE memos SET title=?, content=?, tag=?, completed=?, starred=?, updated_at=?
		 WHERE id=? AND user_phone=?`,
		m.Title, m.Content, m.Tag, boolToInt(m.Completed), boolToInt(m.Starred),
		m.UpdatedAt.Format(time.RFC3339Nano), id, userPhone,
	)
	if err != nil {
		return nil, err
	}
	return m, nil
}

func (s *Store) Delete(userPhone, id string) error {
	res, err := s.db.Exec(`DELETE FROM memos WHERE id=? AND user_phone=?`, id, userPhone)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("not found")
	}
	return nil
}

func (s *Store) ToggleComplete(userPhone, id string) (*Memo, error) {
	m, err := s.Get(userPhone, id)
	if err != nil {
		return nil, err
	}
	m.Completed = !m.Completed
	m.UpdatedAt = time.Now().UTC()
	_, err = s.db.Exec(
		`UPDATE memos SET completed=?, updated_at=? WHERE id=? AND user_phone=?`,
		boolToInt(m.Completed), m.UpdatedAt.Format(time.RFC3339Nano), id, userPhone,
	)
	if err != nil {
		return nil, err
	}
	return m, nil
}

func ensureUser(db *sql.DB, phone string) error {
	_, err := db.Exec(`INSERT OR IGNORE INTO users (phone) VALUES (?)`, phone)
	return err
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

type rowScanner interface {
	Scan(dest ...interface{}) error
}

func scanMemo(rows *sql.Rows) (*Memo, error) {
	return scanMemoRow(rows)
}

func scanMemoRow(row rowScanner) (*Memo, error) {
	var (
		m          Memo
		completed  int
		starred    int
		createdStr string
		updatedStr string
	)
	err := row.Scan(
		&m.ID, &m.UserPhone, &m.Title, &m.Content, &m.Tag,
		&completed, &starred, &createdStr, &updatedStr,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("not found")
	}
	if err != nil {
		return nil, err
	}
	m.Completed = completed == 1
	m.Starred = starred == 1
	m.CreatedAt, _ = time.Parse(time.RFC3339Nano, createdStr)
	m.UpdatedAt, _ = time.Parse(time.RFC3339Nano, updatedStr)
	return &m, nil
}

func genID() (string, error) {
	b := make([]byte, 8)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
