package auth

import (
	"encoding/json"
	"net/http"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

type sendCodeRequest struct {
	Phone string `json:"phone"`
}

type loginRequest struct {
	Phone string `json:"phone"`
	Code  string `json:"code"`
}

type apiResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func writeJSON(w http.ResponseWriter, status int, resp apiResponse) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(resp)
}

// SendCode POST /api/v1/auth/send-code
func (h *Handler) SendCode(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		return
	}

	var req sendCodeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Phone == "" {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "phone is required"})
		return
	}

	if _, err := h.svc.SendCode(req.Phone); err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: err.Error()})
		return
	}

	data := map[string]string{}
	if h.svc.SMSProviderName() == "mock" {
		data["hint"] = "开发环境 mock 短信，请查看服务端日志中的验证码"
	}

	writeJSON(w, http.StatusOK, apiResponse{
		Code:    0,
		Message: "ok",
		Data:    data,
	})
}

// Login POST /api/v1/auth/login
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		return
	}

	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Phone == "" || req.Code == "" {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "phone and code are required"})
		return
	}

	token, err := h.svc.Login(req.Phone, req.Code)
	if err != nil {
		writeJSON(w, http.StatusUnauthorized, apiResponse{Code: 401, Message: err.Error()})
		return
	}

	writeJSON(w, http.StatusOK, apiResponse{
		Code:    0,
		Message: "ok",
		Data: map[string]interface{}{
			"token":      token,
			"phone":      req.Phone,
			"expires_in": int(h.svc.AccessTTL().Seconds()),
		},
	})
}
