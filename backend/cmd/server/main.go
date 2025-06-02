package main

import (
	"fmt"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/handlers"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

func main() {
	// 1. Charger la config (variables d’environnement)
	config.LoadEnv()

	// 2. Initialiser la base de données (GORM + AutoMigrate)
	database.Init()

	// 3. Créer le AuthService *après* que database.DB soit initialisé
	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc) // injection dans les handlers

	// 4. Créer le router Gin
	r := gin.New()
	r.Use(gin.Recovery())

	// 5. Endpoint healthcheck
	r.GET("/health", handlers.HealthCheck)

	// 6. Routes Auth (public)
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}
	// 7. Démarrer le serveur sur le port configuré
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Démarrage du serveur sur %s…\n", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur au lancement du serveur : %v", err)
	}
}
