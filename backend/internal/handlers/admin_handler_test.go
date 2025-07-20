package handlers_test

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/handlers"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
	"golang.org/x/crypto/bcrypt"
)

// setupAdminTest initialise DB en mémoire, crée un admin et un subscriber,
// génère leurs tokens, et retourne le router configuré ainsi que les tokens et IDs.
func setupAdminTest(t *testing.T) (router *gin.Engine, db *gorm.DB, adminToken, subToken string, subID uuid.UUID) {
	d, err := gorm.Open(sqlite.Open("file::memory:?cache=private"), &gorm.Config{})
	if err != nil {
		t.Fatalf("Échec ouverture DB mémoire: %v", err)
	}
	if err := d.AutoMigrate(&models.User{}); err != nil {
		t.Fatalf("Échec migration: %v", err)
	}
	database.DB = d

	userRepo := repositories.NewUserRepository()
	authSvc := services.NewAuthService(userRepo)
	handlers.SetAuthService(authSvc)

	pass := "Password123!"
	hashedPass, _ := bcrypt.GenerateFromPassword([]byte(pass), bcrypt.DefaultCost)

	admin := models.User{
		ID:             uuid.New(),
		Username:       "admin",
		Email:          "admin@example.com",
		HashedPassword: string(hashedPass),
		Role:           models.RoleAdmin,
	}
	sub := models.User{
		ID:             uuid.New(),
		Username:       "subscriber",
		Email:          "sub@example.com",
		HashedPassword: string(hashedPass),
		Role:           models.RoleSubscriber,
	}
	if err := d.Create(&admin).Error; err != nil {
		t.Fatalf("échec création admin: %v", err)
	}
	if err := d.Create(&sub).Error; err != nil {
		t.Fatalf("échec création subscriber: %v", err)
	}

	var errLogin error
	adminToken, errLogin = authSvc.Login(admin.Email, pass)
	if errLogin != nil {
		t.Fatalf("login admin échoué: %v", errLogin)
	}
	subToken, errLogin = authSvc.Login(sub.Email, pass)
	if errLogin != nil {
		t.Fatalf("login sub échoué: %v", errLogin)
	}

	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.Use(gin.Recovery())
	adminGroup := r.Group("/api/admin")
	adminGroup.Use(handlers.AdminMiddleware())
	adminGroup.PUT("/users/:id/role", handlers.ChangeUserRoleHandler)

	return r, d, adminToken, subToken, sub.ID
}

func TestPromote_Success(t *testing.T) {
	router, db, adminToken, _, subID := setupAdminTest(t)

	reqBody := []byte(`{"role":"creator"}`)
	req, _ := http.NewRequest("PUT", "/api/admin/users/"+subID.String()+"/role", bytes.NewBuffer(reqBody))
	req.Header.Set("Authorization", "Bearer "+adminToken)
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	var u models.User
	err := db.First(&u, "id = ?", subID).Error
	assert.NoError(t, err)
	assert.Equal(t, models.RoleCreator, u.Role)
}

func TestPromote_ForbiddenNonAdmin(t *testing.T) {
	router, _, _, subToken, subID := setupAdminTest(t)

	reqBody := []byte(`{"role":"creator"}`)
	req, _ := http.NewRequest("PUT", "/api/admin/users/"+subID.String()+"/role", bytes.NewBuffer(reqBody))
	req.Header.Set("Authorization", "Bearer "+subToken)
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestPromote_NotFound(t *testing.T) {
	router, _, adminToken, _, _ := setupAdminTest(t)
	fakeID := uuid.New()

	reqBody := []byte(`{"role":"creator"}`)
	req, _ := http.NewRequest("PUT", "/api/admin/users/"+fakeID.String()+"/role", bytes.NewBuffer(reqBody))
	req.Header.Set("Authorization", "Bearer "+adminToken)
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestPromote_DowngradeToSubscriber(t *testing.T) {
	router, db, adminToken, _, subID := setupAdminTest(t)

	reqBody := []byte(`{"role":"subscriber"}`)
	req, _ := http.NewRequest("PUT", "/api/admin/users/"+subID.String()+"/role", bytes.NewBuffer(reqBody))
	req.Header.Set("Authorization", "Bearer "+adminToken)
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	var u models.User
	err := db.First(&u, "id = ?", subID).Error
	assert.NoError(t, err)
	assert.Equal(t, models.RoleSubscriber, u.Role)
}
