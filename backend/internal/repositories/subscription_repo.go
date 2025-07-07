package repositories

import (
	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"gorm.io/gorm"
)

type SubscriptionRepository struct {
	db *gorm.DB
}

func NewSubscriptionRepository() *SubscriptionRepository {
	return &SubscriptionRepository{db: database.DB}
}

// CountByCreatorID renvoie le nombre d'abonnés pour un créateur donné.
func (r *SubscriptionRepository) CountByCreatorID(creatorID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.Model(&models.Subscription{}).
		Where("creator_id = ?", creatorID).
		Count(&count).Error
	return count, err
}
