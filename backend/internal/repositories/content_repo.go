package repositories

import (
	"github.com/google/uuid"
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

// FindAll renvoie tous les contenus.
func (r *ContentRepository) FindAll() ([]models.Content, error) {
	var list []models.Content
	if err := database.DB.Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// Delete supprime un contenu par son ID.
func (r *ContentRepository) Delete(id uuid.UUID) error {
	return database.DB.
		Where("id = ?", id).
		Delete(&models.Content{}).
		Error
}

func (r *ContentRepository) UpdateStatus(id uuid.UUID, status string) error {
	return r.db.Model(&models.Content{}).
		Where("id = ?", id).
		Update("status", status).
		Error
}

func (r *ContentRepository) FindByID(id uuid.UUID) (*models.Content, error) {
	var content models.Content
	if err := r.db.First(&content, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &content, nil
}

func (r *ContentRepository) Update(content *models.Content) error {
	return r.db.Save(content).Error
}
