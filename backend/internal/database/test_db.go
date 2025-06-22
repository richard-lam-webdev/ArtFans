package database

import (
	"log"
	"testing"

	"github.com/glebarez/sqlite"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"

	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
)

// InitTest initialise DB en mémoire et auto‐migrate tous les modèles.
// À appeler uniquement depuis les tests d’intégration.
func InitTest() *gorm.DB {
	var err error
	DB, err = gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		log.Fatalf("[InitTest] impossible d’ouvrir SQLite en mémoire : %v", err)
	}

	// Ne migrer que le modèle User
	if err := DB.AutoMigrate(&models.User{}); err != nil {
		log.Fatalf("[InitTest] AutoMigrate User a échoué : %v", err)
	}

	return DB
}

func ResetTables(db *gorm.DB) {
	tables := []string{
		"reports", "messages", "likes", "comments", "contents",
		"payments", "subscriptions", "users",
	}
	for _, table := range tables {
		db.Exec("DELETE FROM " + table)
	}
}

func TestInitTest(t *testing.T) {
	db := InitTest()
	assert.NotNil(t, db)
}
