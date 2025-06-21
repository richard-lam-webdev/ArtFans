// chemin : backend/internal/handlers/admin_handler.go
package handlers

import (
	"net/http"
	"strings"
	"time"

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

// ListUsersHandler gère GET /api/admin/users
// Renvoie { "users": [ {ID, Username, Email, Role, CreatedAt}, … ] }
func ListUsersHandler(c *gin.Context) {
	userRepo := repositories.NewUserRepository()
	users, err := userRepo.FindAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les utilisateurs"})
		return
	}

	// Préparer une version "safe" sans hashed_password
	var out []gin.H
	for _, u := range users {
		out = append(out, gin.H{
			"ID":        u.ID,
			"Username":  u.Username,
			"Email":     u.Email,
			"Role":      u.Role,
			"CreatedAt": u.CreatedAt.Format(time.RFC3339),
		})
	}

	c.JSON(http.StatusOK, gin.H{"users": out})
}

// ChangeUserRoleHandler gère PUT /api/admin/users/:id/role
// Accepte { "role": "creator" } ou { "role": "subscriber" }
func ChangeUserRoleHandler(c *gin.Context) {
	// 1. Liaison du JSON
	var payload struct {
		Role string `json:"role" binding:"required,oneof=creator subscriber"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payload invalide (rôle must be creator or subscriber)"})
		return
	}

	// 2. ID de l'utilisateur
	idStr := c.Param("id")
	userID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	// 3. Choix du nouveau rôle
	var newRole models.Role
	if payload.Role == "creator" {
		newRole = models.RoleCreator
	} else {
		newRole = models.RoleSubscriber
	}

	// 4. Mise à jour en base
	userRepo := repositories.NewUserRepository()
	if err := userRepo.UpdateRole(userID, newRole); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Utilisateur non trouvé"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de changer le rôle de l'utilisateur"})
		}
		return
	}

	// 5. Réponse
	action := "promu"
	if newRole == models.RoleSubscriber {
		action = "rétrogradé"
	}
	c.JSON(http.StatusOK, gin.H{"message": "Utilisateur " + action + " en " + payload.Role})
}

// ListContentsHandler gère GET /api/admin/contents
// Renvoie { "contents": [ {ID, Title, AuthorID, CreatedAt}, … ] }
func ListContentsHandler(c *gin.Context) {
	repo := repositories.NewContentRepository()
	contents, err := repo.FindAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les contenus"})
		return
	}

	// On prépare une version "safe"
	var out []gin.H
	for _, ct := range contents {
		out = append(out, gin.H{
			"ID":        ct.ID,
			"Title":     ct.Title,
			"AuthorID":  ct.CreatorID,
			"CreatedAt": ct.CreatedAt.Format(time.RFC3339),
		})
	}
	c.JSON(http.StatusOK, gin.H{"contents": out})
}

// DeleteContentHandler gère DELETE /api/admin/contents/:id
func DeleteContentHandler(c *gin.Context) {
	idStr := c.Param("id")
	contentID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	repo := repositories.NewContentRepository()
	if err := repo.Delete(contentID); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de supprimer le contenu"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Contenu supprimé"})
}
