package repositories

import (
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

type CommentLikeRepository struct {
	db *gorm.DB
}

func NewCommentLikeRepository() *CommentLikeRepository {
	return &CommentLikeRepository{db: database.DB}
}

// CountByComment renvoie le nombre de likes pour un commentaire
func (r *CommentLikeRepository) CountByComment(commentID uuid.UUID) (int64, error) {
	var cnt int64
	err := r.db.
		Model(&models.CommentLike{}).
		Where("comment_id = ?", commentID).
		Count(&cnt).Error
	return cnt, err
}

// IsLiked vérifie si user a liké ce commentaire
func (r *CommentLikeRepository) IsLiked(userID, commentID uuid.UUID) (bool, error) {
	var cnt int64
	err := r.db.
		Model(&models.CommentLike{}).
		Where("user_id = ? AND comment_id = ?", userID, commentID).
		Count(&cnt).Error
	return cnt > 0, err
}

// Like ajoute un like
func (r *CommentLikeRepository) Like(userID, commentID uuid.UUID) error {
	cl := &models.CommentLike{UserID: userID, CommentID: commentID}
	return r.db.Create(cl).Error
}

// Unlike supprime un like
func (r *CommentLikeRepository) Unlike(userID, commentID uuid.UUID) error {
	return r.db.
		Where("user_id = ? AND comment_id = ?", userID, commentID).
		Delete(&models.CommentLike{}).Error
}
