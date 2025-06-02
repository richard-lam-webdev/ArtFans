package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"your_module_path/backend/internal/models"
	"your_module_path/backend/internal/repositories"
	"your_module_path/backend/internal/services"
)

var authService *services.AuthService

func init() {
	userRepo := repositories.NewUserRepository()
	authService = services.NewAuthService(userRepo)
}

// RegisterHandler gère POST /api/auth/register
func RegisterHandler(c *gin.Context) {
	var payload struct {
		Username string `json:"username" binding:"required"`
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=6"`
		Role     string `json:"role" binding:"required,oneof=creator subscriber"`
	}
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Convertir le rôle en models.Role
	role := models.Role(payload.Role)
	if role != models.RoleCreator && role != models.RoleSubscriber {
		c.JSON(http.StatusBadRequest, gin.H{"error": "rôle invalide"})
		return
	}

	user, err := authService.Register(payload.Username, payload.Email, payload.Password, role)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"user": user})
}

// LoginHandler gère POST /api/auth/login
func LoginHandler(c *gin.Context) {
	var payload struct {
		Email    string `json:"email" binding:"required,email"`
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
