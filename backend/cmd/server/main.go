package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/fymd/personal-assistant/backend/internal/auth"
	"github.com/fymd/personal-assistant/backend/internal/memo"
)

func main() {
	mux := http.NewServeMux()

	// 健康检查
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"status":"ok"}`)
	})

	// Auth
	authSvc := auth.NewService()
	authHandler := auth.NewHandler(authSvc)
	mux.HandleFunc("/api/v1/auth/send-code", authHandler.SendCode)
	mux.HandleFunc("/api/v1/auth/login", authHandler.Login)

	// Memos
	memoStore := memo.NewStore()
	memoHandler := memo.NewHandler(memoStore, authSvc)
	mux.Handle("/api/v1/memos", memoHandler)
	mux.Handle("/api/v1/memos/", memoHandler)

	addr := ":8080"
	log.Printf("Personal Assistant backend starting on %s", addr)
	log.Printf("Auth:  POST /api/v1/auth/send-code , POST /api/v1/auth/login")
	log.Printf("Memos: GET/POST /api/v1/memos , GET/PUT/DELETE /api/v1/memos/{id}")
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
