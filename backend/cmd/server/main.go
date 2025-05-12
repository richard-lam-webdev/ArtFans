package main

import (
	"log"
	"net/http"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/api"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", api.Health)
	log.Println("API démarrée sur :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
