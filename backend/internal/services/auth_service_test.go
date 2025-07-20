package services_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/services"
)

func setupAuthService(t *testing.T) *services.AuthService {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.User{}); err != nil {
		t.Fatal(err)
	}
	repositories.SetTestDB(db)
	repo := repositories.NewUserRepository()
	return services.NewAuthService(repo)
}

func TestRegister_DuplicateEmail(t *testing.T) {
	auth := setupAuthService(t)

	_, err := auth.Register("user1", "test@exemple.com", "password123", models.RoleSubscriber)
	assert.NoError(t, err)

	_, err2 := auth.Register("user2", "test@exemple.com", "autrepass", models.RoleSubscriber)
	assert.Error(t, err2)
}
