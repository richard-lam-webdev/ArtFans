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

	// 1. Liaison JSON → payload, interdiction des champs inconnus
	decoder := json.NewDecoder(c.Request.Body)
	decoder.DisallowUnknownFields()
	if decodeErr := decoder.Decode(&payload); decodeErr != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Champ non autorisé : " + decodeErr.Error()})
		return
	}

	// 2. Forcer toujours le rôle à "subscriber"
	role := models.RoleSubscriber

	// 3. Appel au service d'inscription
	user, registerErr := authService.Register(
		payload.Username,
		payload.Email,
		payload.Password,
		role,
	)
	if registerErr != nil {
		// Log de l’échec d’inscription
		logger.LogBusinessEvent("registration_failed", map[string]interface{}{
			"email": payload.Email,
			"ip":    c.ClientIP(),
			"error": registerErr.Error(),
		})
		c.JSON(http.StatusBadRequest, gin.H{"error": registerErr.Error()})
		return
	}

	// 4. Succès → 201 Created
	c.JSON(http.StatusCreated, gin.H{"user": user})

	// Log de la réussite d’inscription
	logger.LogBusinessEvent("user_registered", map[string]interface{}{
		"user_id": user.ID,
		"email":   user.Email,
		"role":    user.Role,
	})
}

// Struct de binding dédié au login
type LoginPayload struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func LoginHandler(c *gin.Context) {
	var payload LoginPayload

	// 1. Liaison du JSON
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	email := payload.Email
	ip := c.ClientIP()

	// 2. Vérification des tentatives de connexion
	mu.Lock()
	attempts := loginAttempts[email]
	loginAttempts[email] = attempts + 1
	mu.Unlock()

	if attempts >= 5 {
		// trop de tentatives → bloquer
		sentry.CaptureAuthError("multiple_failed_logins", email, ip, "too_many_attempts")
		logger.LogSecurity("login_blocked", map[string]any{
			"email":    email,
			"ip":       ip,
			"attempts": attempts + 1,
		})
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many attempts"})
		return
	}

	// 3. Tentative d’authentification
	token, loginErr := authService.Login(email, payload.Password)
	if loginErr != nil {
		// Log de l’échec de connexion
		logger.LogBusinessEvent("login_failed", map[string]any{
			"email": email,
			"ip":    ip,
			"error": loginErr.Error(),
		})
		c.JSON(http.StatusUnauthorized, gin.H{"error": loginErr.Error()})
		return
	}

	// 4. Si on arrive ici, l'authent est réussie
	success := true

	// 5. Réponse JSON de succès
	c.JSON(http.StatusOK, gin.H{"token": token})

	// 6. Log de la réussite de connexion
	logger.LogBusinessEvent("user_logged_in", map[string]any{
		"email": email,
		"ip":    ip,
	})

	// 7. Si c’était une réussite, on réinitialise le compteur
	if success {
		mu.Lock()
		delete(loginAttempts, email)
		mu.Unlock()
	}
}
