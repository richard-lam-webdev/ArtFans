package repositories

import (
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

type ContentRepository struct {
	db *gorm.DB
}

func NewContentRepository() *ContentRepository {
	return &ContentRepository{db: database.DB}
}

func (r *ContentRepository) Create(content *models.Content) error {
	return r.db.Create(content).Error
}
