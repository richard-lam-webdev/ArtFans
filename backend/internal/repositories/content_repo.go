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

func (r *ContentRepository) FindAll() ([]models.Content, error) {
	var list []models.Content
	if err := database.DB.Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

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

func (r *ContentRepository) IsUserSubscribedToCreator(userID, creatorID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.
		Model(&models.Subscription{}).
		Where("subscriber_id = ? AND creator_id = ? AND end_date > now()", userID, creatorID).
		Count(&count).Error
	return count > 0, err
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
