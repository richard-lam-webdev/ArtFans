// chemin : backend/internal/handlers/auth_handler_test.go

package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite" // Driver SQLite pure Go, sans CGO
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/handlers"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
	"github.com/stretchr/testify/assert"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// setupRouterWithMemoryDB crée un router Gin et une DB SQLite en mémoire.
// Les migrations et le service d'authentification sont initialisés.
func setupRouterWithMemoryDB(t *testing.T) (*gin.Engine, *gorm.DB) {
	// Ouvre une base SQLite en mémoire (pure Go)
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatalf("❌ Échec ouverture DB en mémoire : %v", err)
	}

	// AutoMigrate sur le modèle User uniquement
	if err := db.AutoMigrate(&models.User{}); err != nil {
		t.Fatalf("❌ Échec AutoMigrate en mémoire : %v", err)
	}

	// Remplace la DB globale de notre package database
	database.DB = db

	// Instancier UserRepository et AuthService, puis injecter dans le handler
	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	// Configurer Gin en mode test
	gin.SetMode(gin.TestMode)
	router := gin.New()
	// Routes à tester
	router.POST("/api/auth/register", handlers.RegisterHandler)
	router.POST("/api/auth/login", handlers.LoginHandler)

	return router, db
}

// TestRegister_IgnoreRoleField vérifie qu'envoyer "role":"creator" n'affecte pas le rôle final.
func TestRegister_IgnoreRoleField(t *testing.T) {
	router, db := setupRouterWithMemoryDB(t)

	payload := map[string]interface{}{
		"username": "charlie",
		"email":    "charlie@example.com",
		"password": "password123",
		"role":     "creator", // Tentative de forcer le rôle
	}
	bodyBytes, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(bodyBytes))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusCreated, w.Code)

	var user models.User
	err := db.Where("email = ?", "charlie@example.com").First(&user).Error
	assert.NoError(t, err)
	assert.Equal(t, models.RoleSubscriber, user.Role)
}

// TestRegister_DuplicateEmail vérifie qu'on ne peut pas s'inscrire deux fois avec le même email.
func TestRegister_DuplicateEmail(t *testing.T) {
	router, _ := setupRouterWithMemoryDB(t)

	// Première inscription
	payload1 := map[string]interface{}{
		"username": "alice",
		"email":    "alice@example.com",
		"password": "password123",
		"role":     "subscriber",
	}
	body1, _ := json.Marshal(payload1)
	req1, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(body1))
	req1.Header.Set("Content-Type", "application/json")
	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)
	assert.Equal(t, http.StatusCreated, w1.Code)

	// Seconde inscription avec le même email
	payload2 := map[string]interface{}{
		"username": "alice2",
		"email":    "alice@example.com",
		"password": "anotherPass",
		"role":     "subscriber",
	}
	body2, _ := json.Marshal(payload2)
	req2, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(body2))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)

	assert.Equal(t, http.StatusBadRequest, w2.Code)
}

// TestLogin_SuccessAndFailure couvre un login valide puis un login invalide.
func TestLogin_SuccessAndFailure(t *testing.T) {
	router, db := setupRouterWithMemoryDB(t)

	// Créer l'utilisateur en mémoire avec mot de passe hashé "password123"
	hashed, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	user := models.User{
		ID:       uuid.New(),
		Username: "bob",
		Email:    "bob@example.com",
		Password: string(hashed),
		Role:     models.RoleSubscriber,
	}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("❌ Échec création user en mémoire : %v", err)
	}

	// Login valide
	loginPayload := map[string]string{
		"email":    "bob@example.com",
		"password": "password123",
	}
	bodyOk, _ := json.Marshal(loginPayload)
	reqOk, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(bodyOk))
	reqOk.Header.Set("Content-Type", "application/json")
	wOk := httptest.NewRecorder()
	router.ServeHTTP(wOk, reqOk)

	assert.Equal(t, http.StatusOK, wOk.Code)
	var respOk map[string]string
	err := json.Unmarshal(wOk.Body.Bytes(), &respOk)
	assert.NoError(t, err)
	_, exists := respOk["token"]
	assert.True(t, exists)

	// Login invalide (mauvais mot de passe)
	loginPayloadBad := map[string]string{
		"email":    "bob@example.com",
		"password": "wrongpass",
	}
	bodyBad, _ := json.Marshal(loginPayloadBad)
	reqBad, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(bodyBad))
	reqBad.Header.Set("Content-Type", "application/json")
	wBad := httptest.NewRecorder()
	router.ServeHTTP(wBad, reqBad)

	assert.Equal(t, http.StatusUnauthorized, wBad.Code)
}
