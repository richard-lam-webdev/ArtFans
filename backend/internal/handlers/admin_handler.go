package handlers

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/getsentry/sentry-go"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		auth := c.GetHeader("Authorization")
		if auth == "" || !strings.HasPrefix(auth, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization manquante"})
			c.Abort()
			return
		}
		tokenString := strings.TrimPrefix(auth, "Bearer ")

		claims := &jwt.StandardClaims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.C.JwtSecret), nil
		})
		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Token invalide"})
			c.Abort()
			return
		}

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

		c.Set("currentUser", user)
		c.Next()
	}
}

// ListUsersHandler GET /api/admin/users
func ListUsersHandler(c *gin.Context) {
	userRepo := repositories.NewUserRepository()
	users, err := userRepo.FindAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les utilisateurs"})
		return
	}

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

// ChangeUserRoleHandler PUT /api/admin/users/:id/role
func ChangeUserRoleHandler(c *gin.Context) {
	var payload struct {
		Role string `json:"role" binding:"required,oneof=creator subscriber"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payload invalide (must be creator or subscriber)"})
		return
	}
	idStr := c.Param("id")
	userID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}
	var newRole models.Role
	if payload.Role == "creator" {
		newRole = models.RoleCreator
	} else {
		newRole = models.RoleSubscriber
	}
	userRepo := repositories.NewUserRepository()
	if err := userRepo.UpdateRole(userID, newRole); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Utilisateur non trouvé"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de changer le rôle"})
		}
		return
	}
	action := "promu"
	if newRole == models.RoleSubscriber {
		action = "rétrogradé"
	}
	c.JSON(http.StatusOK, gin.H{"message": "Utilisateur " + action})
}

// ListContentsHandler GET /api/admin/contents
func ListContentsHandler(c *gin.Context) {
	repo := repositories.NewContentRepository()
	contents, err := repo.FindAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les contenus"})
		return
	}

	var out []gin.H
	for _, ct := range contents {
		out = append(out, gin.H{
			"ID":        ct.ID,
			"Title":     ct.Title,
			"AuthorID":  ct.CreatorID,
			"Status":    ct.Status,
			"CreatedAt": ct.CreatedAt.Format(time.RFC3339),
		})
	}
	c.JSON(http.StatusOK, gin.H{"contents": out})
}

func DeleteContentHandler(c *gin.Context) {
	idStr := c.Param("id")
	contentID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}

	reportRepo := repositories.NewReportRepository()
	if err := reportRepo.DeleteByContentID(contentID); err != nil {
		logger.LogError(err, "delete_reports_failed", map[string]interface{}{
			"content_id": contentID,
		})
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de supprimer les signalements"})
		return
	}

	contentRepo := repositories.NewContentRepository()
	uploadPath := config.C.UploadPath
	if err := contentRepo.Delete(contentID, uploadPath); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		} else {
			logger.LogError(err, "delete_content_failed", map[string]interface{}{
				"content_id": contentID,
			})
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de supprimer le contenu"})
		}
		return
	}

	sentry.WithScope(func(scope *sentry.Scope) {
		scope.SetLevel(sentry.LevelInfo)
		scope.SetContext("admin_action", map[string]any{
			"admin_id":   idStr,
			"action":     "delete_content",
			"content_id": contentID.String(),
		})
		sentry.CaptureMessage(fmt.Sprintf("Admin deleted content %s", contentID))
	})

	c.JSON(http.StatusOK, gin.H{"message": "Contenu supprimé"})
}

// ApproveContentHandler PUT /api/admin/contents/:id/approve
func ApproveContentHandler(c *gin.Context) {
	idStr := c.Param("id")
	contentID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}
	repo := repositories.NewContentRepository()
	if err := repo.UpdateStatus(contentID, models.ContentStatusApproved); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible d’approuver le contenu"})
		}
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Contenu approuvé"})
}

// RejectContentHandler PUT /api/admin/contents/:id/reject
func RejectContentHandler(c *gin.Context) {
	idStr := c.Param("id")
	contentID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalide"})
		return
	}
	repo := repositories.NewContentRepository()
	if err := repo.UpdateStatus(contentID, models.ContentStatusRejected); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Contenu non trouvé"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de rejeter le contenu"})
		}
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Contenu rejeté"})
}

// ListFeaturesHandler GET /api/admin/features
func ListFeaturesHandler(c *gin.Context) {
	featRepo := repositories.NewFeatureRepository(database.DB)
	feats, err := featRepo.List(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les features"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"features": feats})
}

// UpdateFeatureHandler PUT /api/admin/features/:key
func UpdateFeatureHandler(c *gin.Context) {
	key := c.Param("key")
	var body struct {
		Enabled bool `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Payload invalide"})
		return
	}

	featRepo := repositories.NewFeatureRepository(database.DB)
	if err := featRepo.Update(c.Request.Context(), key, body.Enabled); err != nil {
		switch err.Error() {
		case "feature not found":
			c.JSON(http.StatusNotFound, gin.H{"error": "Feature non trouvée"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de mettre à jour la feature"})
		}
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Feature mise à jour"})
}
