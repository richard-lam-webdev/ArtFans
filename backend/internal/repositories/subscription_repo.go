// backend/internal/repositories/subscription_repo.go
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

// Create enregistre un nouvel abonnement
func (r *SubscriptionRepository) Create(sub *models.Subscription) error {
	return r.db.Create(sub).Error
}

// Delete supprime un abonnement existant
func (r *SubscriptionRepository) Delete(subscriberID, creatorID uuid.UUID) error {
	return r.db.
		Where("subscriber_id = ? AND creator_id = ?", subscriberID, creatorID).
		Delete(&models.Subscription{}).Error
}

// IsSubscribed vérifie si subscriber est abonné à creator
func (r *SubscriptionRepository) IsSubscribed(subscriberID, creatorID uuid.UUID) (bool, error) {
	var count int64
	err := r.db.
		Model(&models.Subscription{}).
		Where("subscriber_id = ? AND creator_id = ?", subscriberID, creatorID).
		Count(&count).Error
	return count > 0, err
}

// ListCreatorIDsBySubscriber renvoie les UUID des créateurs auxquels l’utilisateur est abonné
func (r *SubscriptionRepository) ListCreatorIDsBySubscriber(subscriberID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.
		Model(&models.Subscription{}).
		Where("subscriber_id = ?", subscriberID).
		Pluck("creator_id", &ids).Error
	return ids, err
}

func (r *SubscriptionRepository) GetAllSubscriptions(subscriberID uuid.UUID) ([]models.Subscription, error) {
	var subs []models.Subscription
	err := r.db.
		Where("subscriber_id = ? AND end_date IS NULL", subscriberID).
		Find(&subs).Error
	return subs, err
}

// CountByCreatorID renvoie le nombre d'abonnés pour un créateur donné.
func (r *SubscriptionRepository) CountByCreatorID(creatorID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.Model(&models.Subscription{}).
		Where("creator_id = ?", creatorID).
		Count(&count).Error
	return count, err
}
