package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/config"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/handlers"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/middleware"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

func setupTestServer() (*gin.Engine, *gorm.DB) {
	os.Setenv("DATABASE_URL", "memory")
	os.Setenv("JWT_SECRET", "testsecret")
	config.LoadEnv()

	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		panic(err)
	}
	database.DB = db
	if err := db.AutoMigrate(&models.User{}); err != nil {
		panic(err)
	}

	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(gin.Recovery())

	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	r.POST("/api/auth/register", handlers.RegisterHandler)
	r.POST("/api/auth/login", handlers.LoginHandler)

	protected := r.Group("/api")
	protected.Use(middleware.JWTAuth())
	protected.GET("/users/me", handlers.CurrentUserHandler)

	admin := r.Group("/api/admin")
	admin.Use(middleware.JWTAuth(), handlers.AdminMiddleware())
	admin.PUT("/users/:id/role", handlers.ChangeUserRoleHandler)

	return r, db
}

func TestRegisterLoginGetProfile(t *testing.T) {
	router, _ := setupTestServer()

	regBody := map[string]string{
		"username":        "bob",
		"email":           "bob@test.com",
		"password":        "password123",
		"confirmPassword": "password123",
	}
	rb, _ := json.Marshal(regBody)
	req1 := httptest.NewRequest("POST", "/api/auth/register", bytes.NewReader(rb))
	req1.Header.Set("Content-Type", "application/json")
	w1 := httptest.NewRecorder()
	router.ServeHTTP(w1, req1)
	assert.Equal(t, http.StatusCreated, w1.Code)

	loginBody := map[string]string{
		"email":    "bob@test.com",
		"password": "password123",
	}
	lb, _ := json.Marshal(loginBody)
	req2 := httptest.NewRequest("POST", "/api/auth/login", bytes.NewReader(lb))
	req2.Header.Set("Content-Type", "application/json")
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)
	assert.Equal(t, http.StatusOK, w2.Code)

	var lr map[string]string
	json.Unmarshal(w2.Body.Bytes(), &lr)
	token := lr["token"]
	assert.NotEmpty(t, token)

	req3 := httptest.NewRequest("GET", "/api/users/me", nil)
	req3.Header.Set("Authorization", "Bearer "+token)
	w3 := httptest.NewRecorder()
	router.ServeHTTP(w3, req3)
	assert.Equal(t, http.StatusOK, w3.Code)

	var pr map[string]map[string]interface{}
	json.Unmarshal(w3.Body.Bytes(), &pr)
	userData := pr["user"]
	assert.Equal(t, "bob", userData["Username"])
	assert.Equal(t, "bob@test.com", userData["Email"])
}

func TestAdminPromoteFlow(t *testing.T) {
	router, db := setupTestServer()

	unique := uuid.New().String()
	hashed, _ := bcrypt.GenerateFromPassword([]byte("adminpass"), bcrypt.DefaultCost)
	adminUser := models.User{
		ID:             uuid.New(),
		Username:       "admin-" + unique,
		Email:          fmt.Sprintf("admin+%s@example.com", unique),
		HashedPassword: string(hashed),
		Role:           models.RoleAdmin,
		CreatedAt:      time.Now(),
	}
	if err := db.Create(&adminUser).Error; err != nil {
		t.Fatalf("❌ seed admin user: %v", err)
	}

	userID := uuid.New()
	user := models.User{
		ID:             userID,
		Username:       "user-" + uuid.New().String(),
		Email:          fmt.Sprintf("user+%s@example.com", uuid.New().String()),
		HashedPassword: string(hashed),
		Role:           models.RoleSubscriber,
		CreatedAt:      time.Now(),
	}
	if err := db.Create(&user).Error; err != nil {
		t.Fatalf("❌ seed normal user: %v", err)
	}

	loginBody := map[string]string{
		"email":    adminUser.Email,
		"password": "adminpass",
	}
	b, _ := json.Marshal(loginBody)
	req := httptest.NewRequest("POST", "/api/auth/login", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	var loginResp map[string]string
	json.Unmarshal(w.Body.Bytes(), &loginResp)
	token := loginResp["token"]
	assert.NotEmpty(t, token)

	promoteBody := map[string]string{"role": "creator"}
	pb, _ := json.Marshal(promoteBody)
	req2 := httptest.NewRequest(
		"PUT",
		"/api/admin/users/"+userID.String()+"/role",
		bytes.NewReader(pb),
	)
	req2.Header.Set("Content-Type", "application/json")
	req2.Header.Set("Authorization", "Bearer "+token)
	w2 := httptest.NewRecorder()
	router.ServeHTTP(w2, req2)
	assert.Equal(t, http.StatusOK, w2.Code)

	var updated models.User
	if err := db.First(&updated, "id = ?", userID).Error; err != nil {
		t.Fatalf("❌ fetch updated user: %v", err)
	}
	assert.Equal(t, models.RoleCreator, updated.Role)
}
