package handlers

import (
	"encoding/json"
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/sentry"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

var authService *services.AuthService
var loginAttempts = make(map[string]int)
var mu sync.Mutex

// SetAuthService permet d’injecter l’instance d’AuthService depuis main()
func SetAuthService(s *services.AuthService) {
	authService = s
}

type RegisterPayload struct {
	Username        string `json:"username" binding:"required"`
	Email           string `json:"email" binding:"required,email"`
	Password        string `json:"password" binding:"required,min=6"`
	ConfirmPassword string `json:"confirmPassword" binding:"required,eqfield=Password"`
}

// RegisterHandler gère POST /api/auth/register
func RegisterHandler(c *gin.Context) {
	var payload RegisterPayload

	decoder := json.NewDecoder(c.Request.Body)
	decoder.DisallowUnknownFields()
	if decodeErr := decoder.Decode(&payload); decodeErr != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Champ non autorisé : " + decodeErr.Error()})
		return
	}

	role := models.RoleSubscriber

	user, registerErr := authService.Register(
		payload.Username,
		payload.Email,
		payload.Password,
		role,
	)
	if registerErr != nil {
		logger.LogBusinessEvent("registration_failed", map[string]interface{}{
			"email": payload.Email,
			"ip":    c.ClientIP(),
			"error": registerErr.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"error": registerErr.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"user": user})

	logger.LogBusinessEvent("user_registered", map[string]interface{}{
		"user_id": user.ID,
		"email":   user.Email,
		"role":    user.Role,
	})
}

type LoginPayload struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func LoginHandler(c *gin.Context) {
	var payload LoginPayload

	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	email := payload.Email
	ip := c.ClientIP()

	mu.Lock()
	attempts := loginAttempts[email]
	loginAttempts[email] = attempts + 1
	mu.Unlock()

	if attempts >= 5 {
		sentry.CaptureAuthError("multiple_failed_logins", email, ip, "too_many_attempts")
		logger.LogSecurity("login_blocked", map[string]any{
			"email":    email,
			"ip":       ip,
			"attempts": attempts + 1,
		})
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many attempts"})
		return
	}

	token, loginErr := authService.Login(email, payload.Password)
	if loginErr != nil {
		logger.LogBusinessEvent("login_failed", map[string]any{
			"email": email,
			"ip":    ip,
			"error": loginErr.Error(),
		})
		c.JSON(http.StatusUnauthorized, gin.H{"error": loginErr.Error()})
		return
	}

	success := true

	c.JSON(http.StatusOK, gin.H{"token": token})

	logger.LogBusinessEvent("user_logged_in", map[string]any{
		"email": email,
		"ip":    ip,
	})

	if success {
		mu.Lock()
		delete(loginAttempts, email)
		mu.Unlock()
	}
}
