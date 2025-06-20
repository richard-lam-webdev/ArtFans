package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
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

func setupRouterWithMemoryDB(t *testing.T) (*gin.Engine, *gorm.DB) {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatalf("❌ Échec ouverture DB en mémoire : %v", err)
	}
	if err := db.AutoMigrate(&models.User{}); err != nil {
		t.Fatalf("❌ Échec AutoMigrate en mémoire : %v", err)
	}
	database.DB = db

	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.POST("/api/auth/register", handlers.RegisterHandler)
	router.POST("/api/auth/login", handlers.LoginHandler)
	return router, db
}

func TestRegister_BlockOnRoleField(t *testing.T) {
	router, _ := setupRouterWithMemoryDB(t)

	payload := map[string]interface{}{
		"username":        "eviluser",
		"email":           "evil@example.com",
		"password":        "password123",
		"confirmPassword": "password123",
		"role":            "creator",
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Contains(t, w.Body.String(), `"error":"Champ non autorisé`)
	var resp map[string]string
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Contains(t, resp["error"], "json: unknown field \"role\"")
}

func TestRegister_ValidWithoutRole(t *testing.T) {
	router, db := setupRouterWithMemoryDB(t)

	payload := map[string]interface{}{
		"username":        "david",
		"email":           "david@example.com",
		"password":        "password123",
		"confirmPassword": "password123",
	}
	body, _ := json.Marshal(payload)

	req, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)

	var user models.User
	err := db.Where("email = ?", "david@example.com").First(&user).Error
	assert.NoError(t, err)
	assert.Equal(t, models.RoleSubscriber, user.Role)
}

func TestRegister_DuplicateEmail(t *testing.T) {
	router, _ := setupRouterWithMemoryDB(t)

	payload1 := map[string]interface{}{
		"username":        "alice",
		"email":           "alice@example.com",
		"password":        "password123",
		"confirmPassword": "password123",
	}
	body1, _ := json.Marshal(payload1)
	req1, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(body1))
	req1.Header.Set("Content-Type", "application/json")
	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)
	assert.Equal(t, http.StatusCreated, w1.Code)

	payload2 := map[string]interface{}{
		"username":        "alice2",
		"email":           "alice@example.com",
		"password":        "anotherPass",
		"confirmPassword": "anotherPass",
	}
	body2, _ := json.Marshal(payload2)
	req2, _ := http.NewRequest("POST", "/api/auth/register", bytes.NewBuffer(body2))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)

	assert.Equal(t, http.StatusBadRequest, w2.Code)
}

func TestLogin_SuccessAndFailure(t *testing.T) {
	router, db := setupRouterWithMemoryDB(t)

	hashed, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	user := models.User{
		ID:             uuid.New(),
		Username:       "bob",
		Email:          "bob@example.com",
		HashedPassword: string(hashed),
		Role:           models.RoleSubscriber,
	}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("❌ Échec création user en mémoire : %v", err)
	}

	loginOK := map[string]string{"email": "bob@example.com", "password": "password123"}
	bodyOK, _ := json.Marshal(loginOK)
	reqOK, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(bodyOK))
	reqOK.Header.Set("Content-Type", "application/json")
	wOK := httptest.NewRecorder()
	router.ServeHTTP(wOK, reqOK)
	assert.Equal(t, http.StatusOK, wOK.Code)

	var respOK map[string]string
	assert.NoError(t, json.Unmarshal(wOK.Body.Bytes(), &respOK))
	_, exists := respOK["token"]
	assert.True(t, exists)

	loginBad := map[string]string{"email": "bob@example.com", "password": "wrongpass"}
	bodyBad, _ := json.Marshal(loginBad)
	reqBad, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(bodyBad))
	reqBad.Header.Set("Content-Type", "application/json")
	wBad := httptest.NewRecorder()
	router.ServeHTTP(wBad, reqBad)
	assert.Equal(t, http.StatusUnauthorized, wBad.Code)
}
