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
// – Retourne les infos publiques d’un créateur.
func GetPublicCreatorProfileHandler(c *gin.Context) {
	username := c.Param("username")

	// 1) On cherche l’utilisateur par username
	user, err := creatorUserRepo.FindByUsername(username)
	if err != nil || user == nil || user.Role != models.RoleCreator {
		c.JSON(http.StatusNotFound, gin.H{"error": "Créateur introuvable"})
		return
	}

	// 2) On compte ses abonnés
	subCount, err := subscriptionRepo.CountByCreatorID(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de compter les abonnés"})
		return
	}

	// 3) On récupère un aperçu de ses contenus (limite 3)
	contents, err := publicContentRepo.FindPreviewByCreator(user.ID, 3)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Impossible de récupérer les contenus"})
		return
	}

	// 4) On prépare la réponse
	response := gin.H{
		"id":               user.ID, // 🆕 Ajouté ici
		"username":         user.Username,
		"created_at":       user.CreatedAt,
		"subscriber_count": subCount,
		"content_preview":  contents,
		"bio":              user.Bio,
		"avatar_url":       user.AvatarURL,
	}

	c.JSON(http.StatusOK, response)
}
