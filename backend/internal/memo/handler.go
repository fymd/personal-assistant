package memo

// TODO: 备忘录 / 待办 CRUD
//
// 预期接口：
// GET    /api/v1/memos
// POST   /api/v1/memos
// GET    /api/v1/memos/{id}
// PUT    /api/v1/memos/{id}
// DELETE /api/v1/memos/{id}
// PATCH  /api/v1/memos/{id}/complete

type Handler struct {}

func NewHandler() *Handler {
	return &Handler{}
}
