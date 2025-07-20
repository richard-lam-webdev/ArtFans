package repositories

import (
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

type PublicContentRepository struct {
	db *gorm.DB
}

// NewPublicContentRepository instancie le repo pour les contenus publics.
func NewPublicContentRepository() *PublicContentRepository {
	return &PublicContentRepository{db: database.DB}
}

// FindPreviewByCreator renvoie un aperçu (limit) des derniers contenus d’un créateur.
func (r *PublicContentRepository) FindPreviewByCreator(creatorID uuid.UUID, limit int) ([]models.Content, error) {
	var list []models.Content
	err := r.db.
		Where("creator_id = ?", creatorID).
		Order("created_at DESC").
		Limit(limit).
		Find(&list).Error
	return list, err
}
