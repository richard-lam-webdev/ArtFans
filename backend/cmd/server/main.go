// backend/cmd/server/main.go

package main

import (
	"fmt"
	"log"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/handlers"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/middleware"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

func main() {
	// Charger la config
	config.LoadEnv()

	// Initialiser la DB
	database.Init()

	// Créer AuthService et l’injecter dans les handlers d’auth
	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	// Créer le router Gin
	r := gin.New()
	r.Use(gin.Recovery())

	// Configurer CORS (exemple en dev en autorisant toutes origines)
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Healthcheck
	r.GET("/health", handlers.HealthCheck)

	// Routes publiques d’authentification
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	// Groupe protégé par JWT
	protected := r.Group("/api")
	protected.Use(middleware.JWTAuth())
	{
		protected.GET("/users/me", handlers.CurrentUserHandler)
	}

	// Démarrage
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Démarrage du serveur sur %s…\n", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur au lancement du serveur : %v", err)
	}
}
