// backend/internal/repositories/comment_repository.go
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
