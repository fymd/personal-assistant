package ops

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// ToolHistory 运维工具执行记录
type ToolHistory struct {
	ID        string `json:"id"`
	Tool      string `json:"tool"` // port_scan | network_diag | http_check | ping | dns
	Target    string `json:"target"`
	Summary   string `json:"summary"`
	Detail    string `json:"detail"` // JSON 或纯文本
	CreatedAt string `json:"created_at"`
}

type CreateHistoryRequest struct {
	Tool    string `json:"tool"`
	Target  string `json:"target"`
	Summary string `json:"summary"`
	Detail  string `json:"detail"`
}

func (s *Store) ListHistory(phone string, tool string, limit int) ([]ToolHistory, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	q := `SELECT id, tool, target, summary, detail, created_at FROM ops_tool_history WHERE user_phone = ?`
	args := []interface{}{phone}
	if tool != "" {
		q += ` AND tool = ?`
		args = append(args, tool)
	}
	q += ` ORDER BY created_at DESC LIMIT ?`
	args = append(args, limit)

	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []ToolHistory
	for rows.Next() {
		var h ToolHistory
		if err := rows.Scan(&h.ID, &h.Tool, &h.Target, &h.Summary, &h.Detail, &h.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, h)
	}
	if list == nil {
		list = []ToolHistory{}
	}
	return list, rows.Err()
}

func (s *Store) CreateHistory(phone string, req CreateHistoryRequest) (*ToolHistory, error) {
	if req.Tool == "" {
		return nil, fmt.Errorf("tool is required")
	}
	id := uuid.NewString()
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := s.db.Exec(
		`INSERT INTO ops_tool_history (id, user_phone, tool, target, summary, detail, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		id, phone, req.Tool, req.Target, req.Summary, req.Detail, now,
	)
	if err != nil {
		return nil, err
	}
	return &ToolHistory{
		ID: id, Tool: req.Tool, Target: req.Target,
		Summary: req.Summary, Detail: req.Detail, CreatedAt: now,
	}, nil
}

func (s *Store) DeleteHistory(phone, id string) error {
	res, err := s.db.Exec(`DELETE FROM ops_tool_history WHERE id = ? AND user_phone = ?`, id, phone)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("not found")
	}
	return nil
}
