package handlers

import (
	"encoding/json"
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

// Struct de binding dédié à l’inscription
type RegisterPayload struct {
	Username        string `json:"username" binding:"required"`
	Email           string `json:"email" binding:"required,email"`
	Password        string `json:"password" binding:"required,min=6"`
	ConfirmPassword string `json:"confirmPassword" binding:"required,eqfield=Password"`
}

// RegisterHandler gère POST /api/auth/register
func RegisterHandler(c *gin.Context) {
	var payload RegisterPayload

	// 1. Liaison JSON → payload
	decoder := json.NewDecoder(c.Request.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Champ non autorisé : " + err.Error()})
		return
	}

	// 2. Forcer toujours le rôle à "subscriber"
	role := models.RoleSubscriber

	// 3. Appel au service d'inscription
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

	// 4. Succès → 201 Created
	c.JSON(http.StatusCreated, gin.H{"user": user})
}

// Struct de binding dédié au login
type LoginPayload struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// LoginHandler gère POST /api/auth/login
func LoginHandler(c *gin.Context) {
	var payload LoginPayload

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
