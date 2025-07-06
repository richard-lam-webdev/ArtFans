// backend/cmd/server/main.go
package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/handlers"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/middleware"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

func main() {
	/* ---------- 1) Config + DB ---------- */
	config.LoadEnv()
	database.Init()

	/* ---------- 2) Auth ---------- */
	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	/* ---------- 3) ContentService ---------- */
	contentRepo := repositories.NewContentRepository()
	uploadPath := config.C.UploadPath
	if err := os.MkdirAll(uploadPath, 0o755); err != nil {
		log.Fatalf("Impossible de créer UPLOAD_PATH %s: %v", uploadPath, err)
	}
	contentSvc := services.NewContentService(contentRepo, uploadPath)
	contentHandler := handlers.NewHandler(contentSvc)
	subscriptionRepo := repositories.NewSubscriptionRepository()
	subscriptionSvc := services.NewSubscriptionService(subscriptionRepo)
	subscriptionHandler := handlers.NewSubscriptionHandler(subscriptionSvc)

	/* ---------- 4) Gin ---------- */
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

	/* ---------- 5) Statique pour les uploads ---------- */
	r.Static("/uploads", uploadPath)

	/* ---------- 6) Health ---------- */
	r.GET("/health", handlers.HealthCheck)

	/* ---------- 7) Auth public ---------- */
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	/* ---------- 8) Contenus publics ---------- */
	r.GET("/api/contents", contentHandler.GetAllContents)
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	/* ---------- 9) Routes protégées JWT ---------- */
	protected := r.Group("/api", middleware.JWTAuth())
	{
		protected.GET("/users/me", handlers.CurrentUserHandler)
		protected.POST("/contents", contentHandler.CreateContent)

		protected.GET("/contents/:id/image", contentHandler.GetContentImage)
		protected.GET("/contents/:id", contentHandler.GetContentByID)
		protected.PUT("/contents/:id", contentHandler.UpdateContent)
		protected.DELETE("/contents/:id", contentHandler.DeleteContent)

		protected.GET("/feed", contentHandler.GetFeed)
		protected.POST("/subscriptions/:creatorID", subscriptionHandler.Subscribe)
		protected.DELETE("/subscriptions/:creatorID", subscriptionHandler.Unsubscribe)
		protected.GET("/subscriptions/:creatorID", subscriptionHandler.IsSubscribed)
		protected.GET("/subscriptions", subscriptionHandler.GetFollowedCreatorIDs)

	}

	/* ---------- 10) Admin ---------- */
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

	/* ---------- 11) Start ---------- */
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Serveur sur %s…", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur serveur : %v", err)
	}
}
