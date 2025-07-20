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
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/middleware"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/sentry"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

func main() {

	config.LoadEnv()
	database.Init()

	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	subRepo := repositories.NewSubscriptionRepository()
	publicContentRepo := repositories.NewPublicContentRepository()
	handlers.SetCreatorRepos(userRepo, subRepo, publicContentRepo)

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

	messageRepo := repositories.NewMessageRepository()
	messageSvc := services.NewMessageService(messageRepo, userRepo)
	messageHandler := handlers.NewMessageHandler(messageSvc)

	adminStatsHandler := handlers.NewAdminStatsHandler()
	adminCommentHandler := handlers.NewAdminCommentHandler(commentSvc)

	if err := sentry.InitSentry(); err != nil {
		log.Printf("⚠️ Impossible d'initialiser Sentry: %v", err)
	}

	r := gin.New()
	r.Use(sentry.Middleware())
	r.Use(logger.GinLogger(), gin.Recovery())
	r.Use(middleware.PrometheusMiddleware())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	if os.Getenv("ENV") != "production" {
		r.GET("/test/sentry", handlers.TestSentryHandler)
		r.GET("/test/sentry-panic", handlers.TestSentryPanicHandler)
		r.GET("/test/sentry-error", handlers.TestSentryErrorHandler)
		r.GET("/test/sentry-payment", handlers.TestSentryPaymentHandler)
	}

	r.Static("/uploads", uploadPath)

	r.GET("/health", handlers.HealthCheck)

	{
		auth := r.Group("/api/auth")
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	r.GET("/api/contents", contentHandler.GetAllContents)
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))
	r.POST("/api/metrics/client", handlers.ClientMetricsHandler)
	r.GET("/api/creators/:username", handlers.GetPublicCreatorProfileHandler)

	protected := r.Group("/api", middleware.JWTAuth())
	{
		protected.GET("/users/me", handlers.CurrentUserHandler)
		protected.POST("/contents", contentHandler.CreateContent)
		protected.GET("/search", searchHandler.Search)
		protected.GET("/contents/:id/download", contentHandler.DownloadContent)
		protected.GET("/contents/:id/image", contentHandler.GetContentImage)
		protected.GET("/contents/:id", contentHandler.GetContentByID)
		protected.PUT("/contents/:id", contentHandler.UpdateContent)
		protected.DELETE("/contents/:id", contentHandler.DeleteContent)
		protected.POST("/contents/:id/like", contentHandler.LikeContent)
		protected.DELETE("/contents/:id/like", contentHandler.UnlikeContent)
		protected.GET("/feed", contentHandler.GetFeed)
		protected.POST("/subscriptions/:creatorID", subscriptionHandler.Subscribe)
		protected.DELETE("/subscriptions/:creatorID", subscriptionHandler.Unsubscribe)
		protected.GET("/subscriptions/:creatorID", subscriptionHandler.IsSubscribed)
		protected.GET("/subscriptions", subscriptionHandler.GetFollowedCreatorIDs)
		protected.GET("/subscriptions/my", subscriptionHandler.GetMySubscriptions)
		protected.GET("/creator/stats", subscriptionHandler.GetCreatorStats)
		protected.GET("/subscriptions/:creatorID/status", subscriptionHandler.CheckSubscriptionStatus)
		protected.GET("/contents/:id/comments", commentHandler.GetComments)
		protected.POST("/contents/:id/comments", commentHandler.PostComment)
		protected.POST("/comments/:commentID/like", commentHandler.LikeComment)
		protected.DELETE("/comments/:commentID/like", commentHandler.UnlikeComment)

		protected.POST("/messages", messageHandler.SendMessage)
		protected.GET("/messages", messageHandler.GetConversations)
		protected.GET("/messages/:userId", messageHandler.GetConversation)

		protected.POST("/contents/:id/report", handlers.ReportContentHandler)
	}

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
		admin.GET("/features", handlers.ListFeaturesHandler)
		admin.PUT("/features/:key", handlers.UpdateFeatureHandler)
		admin.GET("/comments", adminCommentHandler.ListComments)
		admin.DELETE("/comments/:id", adminCommentHandler.DeleteComment)
		admin.GET("/reports", handlers.ListReportsHandler)
	}

	logger.LogBusinessEvent("application_started", map[string]interface{}{
		"port":        config.C.Port,
		"environment": os.Getenv("ENV"),
	})

	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Serveur sur %s…", addr)
	if err := r.Run(addr); err != nil {
		logger.LogError(err, "server_failed", nil)
		log.Fatalf("❌ Erreur serveur : %v", err)
	}
}
