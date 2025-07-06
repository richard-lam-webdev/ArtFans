package repositories

import (
	"fmt"
	"os"
	"path/filepath"

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

func (r *ContentRepository) Delete(id uuid.UUID, uploadPath string) error {
	var content models.Content
	if err := r.db.First(&content, "id = ?", id).Error; err != nil {
		return err
	}
	if content.FilePath != "" {
		fullPath := filepath.Join(uploadPath, content.FilePath)
		if err := os.Remove(fullPath); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("erreur suppression fichier : %v", err)
		}
	}
	return r.db.
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

func (r *ContentRepository) GetContentsByUser(userID uuid.UUID) ([]*models.Content, error) {
	var contents []*models.Content
	if err := r.db.Where("creator_id = ?", userID).Find(&contents).Error; err != nil {
		return nil, err
	}
	return contents, nil
}

func (r *ContentRepository) FindAllWithCreators() ([]models.Content, error) {
	var contents []models.Content
	if err := r.db.Order("created_at DESC").Find(&contents).Error; err != nil {
		return nil, err
	}
	return contents, nil
}

// CreateLike ajoute un like pour un utilisateur sur un contenu
func (r *ContentRepository) CreateLike(userID, contentID uuid.UUID) error {
	like := models.Like{
		UserID:    userID,
		ContentID: contentID,
	}
	return r.db.Create(&like).Error
}

// DeleteLike supprime un like existant
func (r *ContentRepository) DeleteLike(userID, contentID uuid.UUID) error {
	return r.db.
		Where("user_id = ? AND content_id = ?", userID, contentID).
		Delete(&models.Like{}).
		Error
}

// CountContentLikes renvoie le nombre total de likes sur un content
func (r *ContentRepository) CountContentLikes(contentID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.
		Model(&models.Like{}).
		Where("content_id = ?", contentID).
		Count(&count).Error
	return count, err
}

// IsContentLikedBy renvoie true si l'user a déjà liké ce content
func (r *ContentRepository) IsContentLikedBy(userID, contentID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.
		Model(&models.Like{}).
		Where("user_id = ? AND content_id = ?", userID, contentID).
		Count(&count).Error
	return count > 0, err
}
