package main

import (
	"fmt"
	"log"

	"your_module_path/backend/internal/config"
	"your_module_path/backend/internal/database"
	"your_module_path/backend/internal/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// 1. Charger la config
	config.LoadEnv()

	// 2. Initialiser la base
	database.Init()

	// 3. Créer le router
	r := gin.New()
	r.Use(gin.Recovery())

	// 4. Healthcheck
	r.GET("/health", handlers.HealthCheck)

	// 5. Groupe Auth (public)
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	// 6. À venir : groupe /api protégé par un middleware JWT

	// 7. Lancer le serveur
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Démarrage du serveur sur %s…\n", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur au lancement du serveur : %v", err)
	}
}
