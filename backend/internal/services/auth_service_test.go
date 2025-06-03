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
	// Base SQLite en mémoire pour les tests
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	// AutoMigrate pour User
	if err := db.AutoMigrate(&models.User{}); err != nil {
		t.Fatal(err)
	}
	// Remplacer le database.DB global par ce SQLite temporaire
	repositories.SetTestDB(db) // ajoute une fonction dans user_repo.go pour setter db
	repo := repositories.NewUserRepository()
	return services.NewAuthService(repo)
}

func TestRegister_DuplicateEmail(t *testing.T) {
	auth := setupAuthService(t)

	// Premiers inscrire avec email "test@exemple.com"
	_, err := auth.Register("user1", "test@exemple.com", "password123", models.RoleSubscriber)
	assert.NoError(t, err)

	// Deuxième tentative avec le même email
	_, err2 := auth.Register("user2", "test@exemple.com", "autrepass", models.RoleSubscriber)
	assert.Error(t, err2)
}
