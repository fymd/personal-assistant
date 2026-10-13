package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()

	// 健康检查
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"status":"ok"}`)
	})

	// TODO: 后续挂载路由
	// - /api/v1/auth/send-code
	// - /api/v1/auth/login
	// - /api/v1/memos
	// - /api/v1/ops/scans
	// - /api/v1/membership (预留)

	addr := ":8080"
	log.Printf("Personal Assistant backend starting on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
