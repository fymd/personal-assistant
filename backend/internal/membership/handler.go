package membership

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/fymd/personal-assistant/backend/internal/auth"
)

type Handler struct {
	store   *Store
	authSvc *auth.Service
}

func NewHandler(store *Store, authSvc *auth.Service) *Handler {
	return &Handler{store: store, authSvc: authSvc}
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

// ServeHTTP 挂载 /api/v1/membership 与 /api/v1/membership/
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	phone, ok := h.phoneFromRequest(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, apiResponse{Code: 401, Message: "unauthorized"})
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/v1/membership")
	path = strings.Trim(path, "/")

	switch {
	case path == "" && r.Method == http.MethodGet:
		h.get(w, phone)
	case path == "activate" && r.Method == http.MethodPost:
		h.activate(w, r, phone)
	default:
		writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
	}
}

func (h *Handler) get(w http.ResponseWriter, phone string) {
	st, err := h.store.GetStatus(phone)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, apiResponse{Code: 500, Message: err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: st})
}

func (h *Handler) activate(w http.ResponseWriter, r *http.Request, phone string) {
	var req ActivateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
		return
	}
	st, err := h.store.Activate(phone, req.Tier, req.Days)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{
		Code:    0,
		Message: "ok",
		Data: map[string]interface{}{
			"status":  st,
			"note":    "开发占位接口，未对接真实支付",
		},
	})
}
