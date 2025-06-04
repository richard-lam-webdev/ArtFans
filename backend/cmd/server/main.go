// chemin : backend/cmd/server/main.go

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

	// 4. Créer le router Gin (mode Release par défaut)
	r := gin.New()
	r.Use(gin.Recovery())

	// 5. Configurer le middleware CORS
	//
	// Ici, pour le développement local, on autorise toutes les origines ("*").
	// En production, remplacez "*" par vos domaines front (ex. "https://votre-front.com").
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// 6. Endpoint healthcheck (public)
	r.GET("/health", handlers.HealthCheck)

	// 7. Routes Auth (public)
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	// 8. (Exemple) Routes protégées après JWT, si vous en avez
	//    protected := r.Group("/api")
	//    protected.Use(middleware.JWTAuth())
	//    {
	//        protected.GET("/user/me", handlers.GetCurrentUser)
	//        // ... etc.
	//    }

	// 9. Démarrer le serveur sur le port configuré
	addr := fmt.Sprintf(":%s", config.C.Port)
	log.Printf("🚀 Démarrage du serveur sur %s…\n", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("❌ Erreur au lancement du serveur : %v", err)
	}
}
