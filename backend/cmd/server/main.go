package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/fymd/personal-assistant/backend/internal/ai"
	"github.com/fymd/personal-assistant/backend/internal/auth"
	"github.com/fymd/personal-assistant/backend/internal/auth/sms"
	"github.com/fymd/personal-assistant/backend/internal/config"
	"github.com/fymd/personal-assistant/backend/internal/db"
	"github.com/fymd/personal-assistant/backend/internal/membership"
	"github.com/fymd/personal-assistant/backend/internal/memo"
)

func main() {
	cfg := config.Load()

	if cfg.JWTSecret == "" || cfg.JWTSecret == "change-me-in-production" {
		log.Printf("WARNING: JWT_SECRET is weak or default; set a strong secret in production")
	}

	database, err := db.Open(cfg.DBPath)
	if err != nil {
		log.Fatalf("open database: %v", err)
	}
	defer database.Close()
	log.Printf("SQLite ready: %s", cfg.DBPath)

	smsProvider, err := sms.NewProvider(cfg)
	if err != nil {
		log.Fatalf("sms provider: %v", err)
	}
	log.Printf("SMS provider: %s", smsProvider.Name())

	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"status":"ok"}`)
	})

	fixedCode := ""
	if smsProvider.Name() == "mock" {
		fixedCode = cfg.SMSFixedCode
	}
	authSvc := auth.NewService(database, cfg.JWTSecret, smsProvider, fixedCode)
	authHandler := auth.NewHandler(authSvc)
	mux.HandleFunc("/api/v1/auth/send-code", authHandler.SendCode)
	mux.HandleFunc("/api/v1/auth/login", authHandler.Login)

	memoStore := memo.NewStore(database)
	memoHandler := memo.NewHandler(memoStore, authSvc)
	mux.Handle("/api/v1/memos", memoHandler)
	mux.Handle("/api/v1/memos/", memoHandler)

	memStore := membership.NewStore(database)
	memHandler := membership.NewHandler(memStore, authSvc)
	mux.Handle("/api/v1/membership", memHandler)
	mux.Handle("/api/v1/membership/", memHandler)

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
	log.Printf("Auth:        POST /api/v1/auth/send-code , POST /api/v1/auth/login (JWT)")
	log.Printf("Memos:       GET/POST /api/v1/memos")
	log.Printf("Membership:  GET /api/v1/membership , POST /api/v1/membership/activate")
	log.Printf("AI:          POST /api/v1/ai/chat")
	if smsProvider.Name() == "mock" {
		log.Printf("Dev SMS: mock (fixed code from SMS_FIXED_CODE or random if empty)")
	}

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
