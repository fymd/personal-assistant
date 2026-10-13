package auth

// TODO: 实现手机号 + 验证码登录相关 Handler
//
// 预期接口：
// POST /api/v1/auth/send-code   { "phone": "13800138000" }
// POST /api/v1/auth/login       { "phone": "13800138000", "code": "123456" }
//
// 返回 JWT Token，后续请求使用 Authorization: Bearer <token>

type Handler struct {
	// service *Service
}

func NewHandler() *Handler {
	return &Handler{}
}
