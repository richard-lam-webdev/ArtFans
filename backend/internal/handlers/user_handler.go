package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

// CurrentUserHandler retourne les informations du user récupéré par son ID dans le contexte.
func CurrentUserHandler(c *gin.Context) {
	userIDstr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token invalide"})
		return
	}

	id, err := uuid.Parse(userIDstr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID utilisateur invalide"})
		return
	}

	userRepo := repositories.NewUserRepository()
	user, err := userRepo.FindByID(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "erreur interne"})
		return
	}
	if user == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "utilisateur non trouvé"})
		return
	}

	resp := models.User{
		ID:        user.ID,
		Username:  user.Username,
		Email:     user.Email,
		Role:      user.Role,
		CreatedAt: user.CreatedAt,
	}

	c.JSON(http.StatusOK, gin.H{"user": resp})
}
