package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/fymd/personal-assistant/backend/internal/ai"
	"github.com/fymd/personal-assistant/backend/internal/auth"
	"github.com/fymd/personal-assistant/backend/internal/config"
	"github.com/fymd/personal-assistant/backend/internal/db"
	"github.com/fymd/personal-assistant/backend/internal/memo"
)

func main() {
	cfg := config.Load()

	database, err := db.Open(cfg.DBPath)
	if err != nil {
		log.Fatalf("open database: %v", err)
	}
	defer database.Close()
	log.Printf("SQLite ready: %s", cfg.DBPath)

	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"status":"ok"}`)
	})

	authSvc := auth.NewService(database)
	authHandler := auth.NewHandler(authSvc)
	mux.HandleFunc("/api/v1/auth/send-code", authHandler.SendCode)
	mux.HandleFunc("/api/v1/auth/login", authHandler.Login)

	memoStore := memo.NewStore(database)
	memoHandler := memo.NewHandler(memoStore, authSvc)
	mux.Handle("/api/v1/memos", memoHandler)
	mux.Handle("/api/v1/memos/", memoHandler)

	aiClient := ai.NewClient(cfg.AIAPIKey, cfg.AIBaseURL, cfg.AIModel)
	aiHandler := ai.NewHandler(aiClient, authSvc)
	mux.HandleFunc("/api/v1/ai/chat", aiHandler.Chat)
	if aiClient.Enabled() {
		log.Printf("AI: enabled model=%s base=%s", cfg.AIModel, cfg.AIBaseURL)
	} else {
		log.Printf("AI: mock mode (set AI_API_KEY to enable cloud API)")
	}

	addr := ":" + cfg.ServerPort
	log.Printf("Personal Assistant backend starting on %s", addr)
	log.Printf("Auth:  POST /api/v1/auth/send-code , POST /api/v1/auth/login")
	log.Printf("Memos: GET/POST /api/v1/memos")
	log.Printf("AI:    POST /api/v1/ai/chat")
	log.Printf("Dev verification code is always 123456")

	if err := http.ListenAndServe(addr, corsMiddleware(mux)); err != nil {
		log.Fatal(err)
	}
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
