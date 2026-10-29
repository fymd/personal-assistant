package ops

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/fymd/personal-assistant/backend/internal/auth"
)

type Handler struct {
	store   *Store
	authSvc *auth.Service
	hub     *SignalHub
}

func NewHandler(store *Store, authSvc *auth.Service) *Handler {
	return &Handler{
		store:   store,
		authSvc: authSvc,
		hub:     NewSignalHub(),
	}
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

// ServeHTTP 挂载 /api/v1/ops/...
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	phone, ok := h.phoneFromRequest(r)
	if !ok {
		writeJSON(w, http.StatusUnauthorized, apiResponse{Code: 401, Message: "unauthorized"})
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/v1/ops")
	path = strings.Trim(path, "/")

	if path == "remote-desktop" || strings.HasPrefix(path, "remote-desktop/") {
		h.handleRemoteDesktop(w, r, phone, path)
		return
	}
	if path == "history" || strings.HasPrefix(path, "history/") {
		h.handleHistory(w, r, phone, path)
		return
	}

	writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
}

func (h *Handler) handleHistory(w http.ResponseWriter, r *http.Request, phone, path string) {
	id := strings.TrimPrefix(path, "history")
	id = strings.Trim(id, "/")

	if id == "" {
		switch r.Method {
		case http.MethodGet:
			tool := r.URL.Query().Get("tool")
			limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
			list, err := h.store.ListHistory(phone, tool, limit)
			if err != nil {
				writeJSON(w, http.StatusInternalServerError, apiResponse{Code: 500, Message: err.Error()})
				return
			}
			writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: list})
		case http.MethodPost:
			var req CreateHistoryRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
				return
			}
			hist, err := h.store.CreateHistory(phone, req)
			if err != nil {
				writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: err.Error()})
				return
			}
			writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: hist})
		default:
			writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		}
		return
	}

	if r.Method == http.MethodDelete {
		if err := h.store.DeleteHistory(phone, id); err != nil {
			writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
			return
		}
		writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok"})
		return
	}
	writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
}

func (h *Handler) handleRemoteDesktop(w http.ResponseWriter, r *http.Request, phone, path string) {
	rest := strings.TrimPrefix(path, "remote-desktop")
	rest = strings.Trim(rest, "/")

	if rest == "sessions" || strings.HasPrefix(rest, "sessions/") {
		h.handleSessions(w, r, phone, rest)
		return
	}

	id := rest
	if id == "" {
		switch r.Method {
		case http.MethodGet:
			list, err := h.store.ListProfiles(phone)
			if err != nil {
				writeJSON(w, http.StatusInternalServerError, apiResponse{Code: 500, Message: err.Error()})
				return
			}
			writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: list})
		case http.MethodPost:
			var req CreateProfileRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
				return
			}
			p, err := h.store.CreateProfile(phone, req)
			if err != nil {
				writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: err.Error()})
				return
			}
			writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: p})
		default:
			writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		}
		return
	}

	switch r.Method {
	case http.MethodGet:
		p, err := h.store.GetProfile(phone, id)
		if err != nil {
			writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
			return
		}
		writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: p})
	case http.MethodPut, http.MethodPatch:
		var req UpdateProfileRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
			return
		}
		p, err := h.store.UpdateProfile(phone, id, req)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: p})
	case http.MethodDelete:
		if err := h.store.DeleteProfile(phone, id); err != nil {
			writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
			return
		}
		writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok"})
	default:
		writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
	}
}

func (h *Handler) handleSessions(w http.ResponseWriter, r *http.Request, phone, rest string) {
	parts := strings.Split(strings.Trim(rest, "/"), "/")
	if len(parts) == 1 {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
			return
		}
		var req CreateSessionRequest
		_ = json.NewDecoder(r.Body).Decode(&req)
		s := h.hub.Create(phone, req)
		writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: s.Public()})
		return
	}

	sessionID := parts[1]
	if len(parts) == 2 {
		if r.Method != http.MethodGet {
			writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
			return
		}
		s, err := h.hub.Get(sessionID)
		if err != nil {
			writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: s.Public()})
		return
	}

	if len(parts) == 3 && parts[2] == "signal" {
		role := r.URL.Query().Get("role")
		if role == "" {
			role = "viewer"
		}
		if role != "viewer" && role != "agent" {
			writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "role must be viewer or agent"})
			return
		}

		switch r.Method {
		case http.MethodPost:
			var msg SignalMessage
			if err := json.NewDecoder(r.Body).Decode(&msg); err != nil {
				writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "invalid body"})
				return
			}
			if msg.Type == "" {
				writeJSON(w, http.StatusBadRequest, apiResponse{Code: 400, Message: "type required"})
				return
			}
			if err := h.hub.Post(sessionID, role, msg); err != nil {
				writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: err.Error()})
				return
			}
			writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok"})
		case http.MethodGet:
			since, _ := strconv.ParseInt(r.URL.Query().Get("since"), 10, 64)
			msgs, err := h.hub.Poll(sessionID, role, since)
			if err != nil {
				writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: err.Error()})
				return
			}
			writeJSON(w, http.StatusOK, apiResponse{Code: 0, Message: "ok", Data: msgs})
		default:
			writeJSON(w, http.StatusMethodNotAllowed, apiResponse{Code: 405, Message: "method not allowed"})
		}
		return
	}

	writeJSON(w, http.StatusNotFound, apiResponse{Code: 404, Message: "not found"})
}
