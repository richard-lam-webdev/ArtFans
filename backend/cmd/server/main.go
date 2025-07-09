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

	/* ---------- 2b) Repos pour profil créateur ---------- */
	subRepo := repositories.NewSubscriptionRepository()
	publicContentRepo := repositories.NewPublicContentRepository()
	handlers.SetCreatorRepos(userRepo, subRepo, publicContentRepo)

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
	commentRepo := repositories.NewCommentRepository()
	commentLikeRepo := repositories.NewCommentLikeRepository()
	commentSvc := services.NewCommentService(commentRepo, commentLikeRepo, userRepo)
	commentHandler := handlers.NewCommentHandler(commentSvc)
	searchHandler := handlers.NewSearchHandler(database.DB)

	/* ---------- 4) Message Service ---------- */
	messageRepo := repositories.NewMessageRepository()
	messageSvc := services.NewMessageService(messageRepo, userRepo)
	messageHandler := handlers.NewMessageHandler(messageSvc)

	adminStatsHandler := handlers.NewAdminStatsHandler()
	adminCommentHandler := handlers.NewAdminCommentHandler(commentSvc)

	/* ---------- 5) Gin ---------- */
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

	/* ---------- 6) Statique pour les uploads ---------- */
	r.Static("/uploads", uploadPath)

	/* ---------- 7) Health ---------- */
	r.GET("/health", handlers.HealthCheck)

	/* ---------- 8) Auth public ---------- */
	{
		auth := r.Group("/api/auth")
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	/* ---------- 9) Contenus publics ---------- */
	r.GET("/api/contents", contentHandler.GetAllContents)
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	/* ---------- 8b) Profil créateur public ---------- */
	r.GET("/api/creators/:username", handlers.GetPublicCreatorProfileHandler)

	/* ---------- 9) Routes protégées JWT ---------- */
	protected := r.Group("/api", middleware.JWTAuth())
	{
		protected.GET("/users/me", handlers.CurrentUserHandler)
		protected.POST("/contents", contentHandler.CreateContent)
		protected.GET("/search", searchHandler.Search)

		protected.GET("/contents/:id/image", contentHandler.GetContentImage)
		protected.GET("/contents/:id", contentHandler.GetContentByID)
		protected.PUT("/contents/:id", contentHandler.UpdateContent)
		protected.DELETE("/contents/:id", contentHandler.DeleteContent)
		protected.POST("/contents/:id/like", contentHandler.LikeContent)
		protected.DELETE("/contents/:id/like", contentHandler.UnlikeContent)
		protected.GET("/feed", contentHandler.GetFeed)
		//subscriptions
		protected.POST("/subscriptions/:creatorID", subscriptionHandler.Subscribe)     // S'abonner (30€)
		protected.DELETE("/subscriptions/:creatorID", subscriptionHandler.Unsubscribe) // Se désabonner
		protected.GET("/subscriptions/:creatorID", subscriptionHandler.IsSubscribed)   // Vérifier abonnement
		protected.GET("/subscriptions", subscriptionHandler.GetFollowedCreatorIDs)     // Mes abonnements (IDs)
		protected.GET("/subscriptions/my", subscriptionHandler.GetMySubscriptions)     // ✨ NOUVEAU : Mes abonnements détaillés
		protected.GET("/creator/stats", subscriptionHandler.GetCreatorStats)
		// Comments
		protected.GET("/contents/:id/comments", commentHandler.GetComments)
		protected.POST("/contents/:id/comments", commentHandler.PostComment)
		protected.POST("/comments/:commentID/like", commentHandler.LikeComment)
		protected.DELETE("/comments/:commentID/like", commentHandler.UnlikeComment)

		// Messages
		protected.POST("/messages", messageHandler.SendMessage)
		protected.GET("/messages", messageHandler.GetConversations)
		protected.GET("/messages/:userId", messageHandler.GetConversation)

	}

	/* ---------- 11) Admin ---------- */
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

		admin.GET("/stats", adminStatsHandler.GetStats)
		admin.GET("/dashboard", adminStatsHandler.GetDashboard)
		admin.GET("/top-creators", adminStatsHandler.GetTopCreators)
		admin.GET("/top-contents", adminStatsHandler.GetTopContents)
		admin.GET("/flop-contents", adminStatsHandler.GetFlopContents)
		admin.GET("/revenue-chart", adminStatsHandler.GetRevenueChart)
		admin.GET("/quick-stats", adminStatsHandler.GetQuickStats)

		admin.GET("/comments", adminCommentHandler.ListComments)
		admin.DELETE("/comments/:id", adminCommentHandler.DeleteComment)
	}

	/* ---------- 12) Start ---------- */
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Serveur sur %s…", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur serveur : %v", err)
	}
}
