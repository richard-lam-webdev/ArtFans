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
	// 1) Config + DB
	config.LoadEnv()
	database.Init()

	// 2) AuthService
	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	// 3) ContentService (si déjà en place)
	contentRepo := repositories.NewContentRepository()
	contentSvc := services.NewContentService(contentRepo, config.C.UploadPath)
	contentHandler := handlers.NewHandler(contentSvc)

	// 4) Gin + CORS + middlewares globaux
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// 5) Healthcheck
	r.GET("/health", handlers.HealthCheck)

	// 6) Auth public
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	r.GET("/api/contents", contentHandler.GetAllContents)

	// 7) Routes protégées par JWT
	protected := r.Group("/api", middleware.JWTAuth())
	{
		protected.GET("/users/me", handlers.CurrentUserHandler)
		protected.POST("/contents", contentHandler.CreateContent)
		// CRUD du créateur
		protected.GET("/contents/:id", contentHandler.GetContentByID)
		protected.PUT("/contents/:id", contentHandler.UpdateContent)
		protected.DELETE("/contents/:id", contentHandler.DeleteContent)
	}

	// 8) Back-office Admin : **TOUTES** les routes /api/admin, avec JWT + AdminMiddleware
	admin := r.Group("/api/admin",
		middleware.JWTAuth(),
		handlers.AdminMiddleware(),
	)
	{
		admin.GET("/contents", handlers.ListContentsHandler)
		admin.GET("/users", handlers.ListUsersHandler)
		admin.PUT("/users/:id/role", handlers.ChangeUserRoleHandler)
		admin.DELETE("/contents/:id", handlers.DeleteContentHandler)
		admin.PUT("/contents/:id/approve", handlers.ApproveContentHandler)
		admin.PUT("/contents/:id/reject", handlers.RejectContentHandler)
	}

	// 9) Lancement
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Démarrage du serveur sur %s…\n", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur au lancement du serveur : %v", err)
	}
}
