package ai

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/fymd/personal-assistant/backend/internal/auth"
)

type Handler struct {
	client  *Client
	authSvc *auth.Service
}

func NewHandler(client *Client, authSvc *auth.Service) *Handler {
	return &Handler{client: client, authSvc: authSvc}
}

type apiResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

type chatBody struct {
	Messages []Message `json:"messages"`
	// 快捷动作：general | summarize | polish | todos
	Action string `json:"action"`
}

func writeJSON(w http.ResponseWriter, status int, resp apiResponse) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(resp)
}

func (h *Handler) phoneFromRequest(r *http.Request) (string, bool) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return "", false
	}
	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return "", false
	}
	return h.authSvc.PhoneByToken(parts[1])
}

// Chat POST /api/v1/ai/chat
func (h *Handler) Chat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		return
	}
	if _, ok := h.phoneFromRequest(r); !ok {
		writeJSON(w, http.StatusUnauthorized, apiResponse{Code: 401, Message: "unauthorized"})
		return
	}

	var body chatBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
		return
	}
	if len(body.Messages) == 0 {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "messages required"})
		return
	}

	msgs := body.Messages
	// 根据快捷动作强化最后一条 user 提示
	if body.Action != "" && body.Action != "general" {
		last := msgs[len(msgs)-1]
		if last.Role == "user" {
			switch body.Action {
			case "summarize":
				last.Content = "请总结以下内容，给出要点列表：\n\n" + last.Content
			case "polish":
				last.Content = "请润色以下文字，保持原意，使表达更清晰专业：\n\n" + last.Content
			case "todos":
				last.Content = "请根据以下描述生成清晰的待办列表（编号）：\n\n" + last.Content
			}
			msgs[len(msgs)-1] = last
		}
	}

	reply, err := h.client.Chat(msgs)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, apiResponse{Code: 502, Message: err.Error()})
		return
	}

	writeJSON(w, http.StatusOK, apiResponse{
		Code:    0,
		Message: "ok",
		Data: map[string]interface{}{
			"reply":   reply,
			"mock":    !h.client.Enabled(),
			"model":   h.client.model,
		},
	})
}
