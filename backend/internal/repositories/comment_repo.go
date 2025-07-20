package repositories

import (
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

type CommentRepository struct {
	db *gorm.DB
}

func NewCommentRepository() *CommentRepository {
	return &CommentRepository{db: database.DB}
}

// Get all comments for a given content, ordered by creation date asc
func (r *CommentRepository) FindAllByContent(contentID uuid.UUID) ([]models.Comment, error) {
	var comments []models.Comment
	if err := r.db.
		Where("content_id = ?", contentID).
		Order("created_at ASC").
		Find(&comments).Error; err != nil {
		return nil, err
	}
	return comments, nil
}

// Create a new comment
func (r *CommentRepository) Create(c *models.Comment) error {
	return r.db.Create(c).Error
}

// ListAll récupère tous les commentaires, triés par date décroissante, avec pagination.
func (r *CommentRepository) ListAll(offset, limit int) ([]models.Comment, error) {
	var comments []models.Comment
	err := database.DB.
		Preload("Author").
		Preload("Content").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&comments).Error
	if err != nil {
		return nil, err
	}
	return comments, nil
}

// DeleteByID supprime un commentaire selon son ID.
func (r *CommentRepository) DeleteByID(id uuid.UUID) error {
	return database.DB.
		Where("id = ?", id).
		Delete(&models.Comment{}).
		Error
}
