package memo

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

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	phone, ok := h.phoneFromRequest(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, apiResponse{Code: 401, Message: "unauthorized"})
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/v1/memos")
	path = strings.Trim(path, "/")

	if path == "" {
		switch r.Method {
		case http.MethodGet:
			h.list(w, r, phone)
		case http.MethodPost:
			h.create(w, r, phone)
		default:
			writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		}
		return
	}

	if strings.HasSuffix(path, "/complete") {
		id := strings.TrimSuffix(path, "/complete")
		id = strings.Trim(id, "/")
		if r.Method == http.MethodPatch || r.Method == http.MethodPost {
			h.toggleComplete(w, r, phone, id)
			return
		}
	}

	id := path
	switch r.Method {
	case http.MethodGet:
		h.get(w, r, phone, id)
	case http.MethodPut, http.MethodPatch:
		h.update(w, r, phone, id)
	case http.MethodDelete:
		h.delete(w, r, phone, id)
	default:
		writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
	}
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request, phone string) {
	filter := r.URL.Query().Get("filter")
	list, err := h.store.List(phone, filter)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, apiResponse{Code: 500, Message: err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: list})
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request, phone string) {
	var req CreateMemoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
		return
	}
	m, err := h.store.Create(phone, req)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: m})
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request, phone, id string) {
	m, err := h.store.Get(phone, id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: m})
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request, phone, id string) {
	var req UpdateMemoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
		return
	}
	m, err := h.store.Update(phone, id, req)
	if err != nil {
		writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: m})
}

func (h *Handler) delete(w http.ResponseWriter, r *http.Request, phone, id string) {
	if err := h.store.Delete(phone, id); err != nil {
		writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok"})
}

func (h *Handler) toggleComplete(w http.ResponseWriter, r *http.Request, phone, id string) {
	m, err := h.store.ToggleComplete(phone, id)
	if err != nil {
		writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
		return
	}
	writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: m})
}
