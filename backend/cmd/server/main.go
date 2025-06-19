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
	// Charger la config (.env)
	config.LoadEnv()

	// Initialiser la base de données
	database.Init()

	// Services et handlers pour les users/auth
	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	// Services et handlers pour le contenu
	contentRepo := repositories.NewContentRepository()
	contentService := services.NewContentService(contentRepo, config.C.UploadPath)
	contentHandler := handlers.NewHandler(contentService)

	// Création du routeur Gin
	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())

	// Configurer CORS (en dev : open bar)
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

	// Routes publiques (auth)
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	// Routes protégées (auth JWT)
	protected := r.Group("/api")
	protected.Use(middleware.JWTAuth())
	{
		protected.GET("/users/me", handlers.CurrentUserHandler)
		protected.POST("/contents", contentHandler.CreateContent)
	}

	admin := r.Group("/api/admin")
	admin.Use(handlers.AdminMiddleware())
	{
		admin.PUT("/users/:id/role", handlers.PromoteUserHandler)
	}

	// Démarrage du serveur
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Démarrage du serveur sur %s…\n", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur au lancement du serveur : %v", err)
	}
}
