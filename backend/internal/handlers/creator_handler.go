package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

var (
	creatorUserRepo   *repositories.UserRepository
	subscriptionRepo  *repositories.SubscriptionRepository
	publicContentRepo *repositories.PublicContentRepository
)

// SetCreatorRepos injecte les repositories nécessaires.
func SetCreatorRepos(
	userRepo *repositories.UserRepository,
	subRepo *repositories.SubscriptionRepository,
	contentRepo *repositories.PublicContentRepository,
) {
	creatorUserRepo = userRepo
	subscriptionRepo = subRepo
	publicContentRepo = contentRepo
}

// GetPublicCreatorProfileHandler gère GET /api/creators/:username
func GetPublicCreatorProfileHandler(c *gin.Context) {
	username := c.Param("username")

	user, err := creatorUserRepo.FindByUsername(username)
	if err != nil || user == nil || user.Role != models.RoleCreator {
		c.JSON(http.StatusNotFound, gin.H{"error": "Créateur introuvable"})
		return
	}

	subCount, err := subscriptionRepo.CountByCreatorID(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de compter les abonnés"})
		return
	}

	contents, err := publicContentRepo.FindPreviewByCreator(user.ID, 3)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les contenus"})
		return
	}

	response := gin.H{
		"username":         user.Username,
		"created_at":       user.CreatedAt,
		"subscriber_count": subCount,
		"content_preview":  contents,
		"bio":              user.Bio,
		"avatar_url":       user.AvatarURL,
	}

	c.JSON(http.StatusOK, response)
}
