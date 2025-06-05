// chemin : backend/internal/handlers/auth_handler.go

package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

var authService *services.AuthService

// SetAuthService permet d’injecter l’instance d’AuthService depuis main()
func SetAuthService(s *services.AuthService) {
	authService = s
}

// RegisterHandler gère POST /api/auth/register
func RegisterHandler(c *gin.Context) {
	// Struct de binding incluant "Role" uniquement pour détecter sa présence
	var payload struct {
		Username string `json:"username" binding:"required"`
		Email    string `json:"email"    binding:"required,email"`
		Password string `json:"password" binding:"required,min=6"`
		Role     string `json:"role"     binding:"omitempty,oneof=creator subscriber"`
	}

	// 1. Liaison JSON → payload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 2. Refuser si le champ "role" est présent dans le JSON
	if payload.Role != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "le champ 'role' n'est pas autorisé lors de l'inscription"})
		return
	}

	// 3. On force toujours le rôle à subscriber
	role := models.RoleSubscriber

	// 4. Appel au service d'inscription
	user, err := authService.Register(
		payload.Username,
		payload.Email,
		payload.Password,
		role,
	)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 5. Succès → 201 Created
	c.JSON(http.StatusCreated, gin.H{"user": user})
}

// LoginHandler gère POST /api/auth/login
func LoginHandler(c *gin.Context) {
	var payload struct {
		Email    string `json:"email"    binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	token, err := authService.Login(payload.Email, payload.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": token})
}
