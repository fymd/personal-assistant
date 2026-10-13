package memo

import "time"

// Memo 备忘录 / 待办
type Memo struct {
	ID        string    `json:"id"`
	UserPhone string    `json:"-"` // 归属用户
	Title     string    `json:"title"`
	Content   string    `json:"content,omitempty"`
	Tag       string    `json:"tag,omitempty"` // 灵感 / 工作 / 学习 / 生活 等
	Completed bool      `json:"completed"`
	Starred   bool      `json:"starred"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type CreateMemoRequest struct {
	Title   string `json:"title"`
	Content string `json:"content"`
	Tag     string `json:"tag"`
}

type UpdateMemoRequest struct {
	Title     *string `json:"title"`
	Content   *string `json:"content"`
	Tag       *string `json:"tag"`
	Completed *bool   `json:"completed"`
	Starred   *bool   `json:"starred"`
}
