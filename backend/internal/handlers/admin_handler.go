package handlers

import (
	"net/http"
	"strings"

	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

// AdminMiddleware vérifie que le JWT appartient à un utilisateur de rôle "admin"
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		auth := c.GetHeader("Authorization")
		if auth == "" || !strings.HasPrefix(auth, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization manquante"})
			c.Abort()
			return
		}
		tokenString := strings.TrimPrefix(auth, "Bearer ")

		// Parse le token
		claims := &jwt.StandardClaims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.C.JwtSecret), nil
		})
		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token invalide"})
			c.Abort()
			return
		}

		// Récupère l'utilisateur depuis la DB
		userID, err := uuid.Parse(claims.Subject)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token invalide"})
			c.Abort()
			return
		}
		userRepo := repositories.NewUserRepository()
		user, err := userRepo.FindByID(userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erreur serveur"})
			c.Abort()
			return
		}
		if user == nil || user.Role != models.RoleAdmin {
			c.JSON(http.StatusForbidden, gin.H{"error": "Accès réservé aux admins"})
			c.Abort()
			return
		}

		// Tout est ok, on stocke l'user dans le contexte si besoin
		c.Set("currentUser", user)
		c.Next()
	}
}

// PromoteUserHandler gère PUT /api/admin/users/:id/role
// Corps attendu : { "role": "creator" }
func PromoteUserHandler(c *gin.Context) {
	// Valide le JSON
	var payload struct {
		Role string `json:"role" binding:"required,eq=creator"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payload invalide (seul rôle=creator autorisé)"})
		return
	}

	// Paramètre : ID de l'utilisateur à promouvoir
	idStr := c.Param("id")
	userID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	// Mets à jour le rôle
	userRepo := repositories.NewUserRepository()
	if err := userRepo.UpdateRole(userID, models.RoleCreator); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Utilisateur non trouvé"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de promouvoir l'utilisateur"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Utilisateur promu en creator"})
}
