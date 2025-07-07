// backend/internal/services/subscription_service.go

package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type SubscriptionService struct {
	repo *repositories.SubscriptionRepository
}

func NewSubscriptionService(repo *repositories.SubscriptionRepository) *SubscriptionService {
	return &SubscriptionService{repo: repo}
}

// Subscribe permet à un abonné de s'abonner à un créateur (30€ fixe)
func (s *SubscriptionService) Subscribe(creatorID, userID uuid.UUID) error {
	// Vérifier si l'utilisateur n'est pas déjà abonné
	isSubscribed, err := s.IsSubscribed(userID, creatorID)
	if err != nil {
		return err
	}
	if isSubscribed {
		return errors.New("vous êtes déjà abonné à ce créateur")
	}

	// Vérifier que l'utilisateur ne s'abonne pas à lui-même
	if userID == creatorID {
		return errors.New("impossible de s'abonner à soi-même")
	}

	now := time.Now()

	// Créer le paiement d'abord
	payment := &models.Payment{
		Amount: models.SubscriptionPriceCents,
		PaidAt: now,
		Status: "succeeded",
	}

	if err := database.DB.Create(payment).Error; err != nil {
		return err
	}

	// Créer l'abonnement avec le prix fixe
	sub := &models.Subscription{
		CreatorID:    creatorID,
		SubscriberID: userID,
		StartDate:    now,
		EndDate:      now.AddDate(0, 0, models.SubscriptionDurationDays),
		PaymentID:    payment.ID,
		Price:        models.SubscriptionPriceCents,
		Status:       models.SubscriptionStatusActive,
	}

	// Mettre à jour le payment avec l'ID de subscription
	payment.SubscriptionID = sub.ID
	database.DB.Save(payment)

	return s.repo.Create(sub)
}

// Unsubscribe met fin à un abonnement (change le statut au lieu de supprimer)
func (s *SubscriptionService) Unsubscribe(subscriberID, creatorID uuid.UUID) error {
	return database.DB.
		Where("subscriber_id = ? AND creator_id = ? AND status = ?",
			subscriberID, creatorID, models.SubscriptionStatusActive).
		Delete(&models.Subscription{}).Error
}

// IsSubscribed retourne true si l'utilisateur est abonné ET que l'abonnement est actif
func (s *SubscriptionService) IsSubscribed(subscriberID, creatorID uuid.UUID) (bool, error) {
	var count int64
	now := time.Now()

	err := database.DB.Model(&models.Subscription{}).
		Where("subscriber_id = ? AND creator_id = ? AND status = ? AND start_date <= ? AND end_date > ?",
			subscriberID, creatorID, models.SubscriptionStatusActive, now, now).
		Count(&count).Error

	return count > 0, err
}

// GetActiveSubscription récupère l'abonnement actif entre un abonné et un créateur
func (s *SubscriptionService) GetActiveSubscription(subscriberID, creatorID uuid.UUID) (*models.Subscription, error) {
	var subscription models.Subscription
	now := time.Now()

	err := database.DB.Where(
		"subscriber_id = ? AND creator_id = ? AND status = ? AND start_date <= ? AND end_date > ?",
		subscriberID, creatorID, models.SubscriptionStatusActive, now, now,
	).First(&subscription).Error

	if err != nil {
		return nil, err
	}

	return &subscription, nil
}

// GetFollowedCreatorIDs retourne la liste des créateurs suivis (abonnements actifs uniquement)
func (s *SubscriptionService) GetFollowedCreatorIDs(subscriberID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	now := time.Now()

	err := database.DB.Model(&models.Subscription{}).
		Where("subscriber_id = ? AND status = ? AND start_date <= ? AND end_date > ?",
			subscriberID, models.SubscriptionStatusActive, now, now).
		Pluck("creator_id", &ids).Error

	return ids, err
}

// GetUserSubscriptions retourne tous les abonnements actifs d'un utilisateur
func (s *SubscriptionService) GetUserSubscriptions(userID uuid.UUID) ([]models.Subscription, error) {
	var subscriptions []models.Subscription
	now := time.Now()

	err := database.DB.Where(
		"subscriber_id = ? AND status = ? AND end_date > ?",
		userID, models.SubscriptionStatusActive, now,
	).Find(&subscriptions).Error

	return subscriptions, err
}

// GetCreatorStats retourne les statistiques d'un créateur
func (s *SubscriptionService) GetCreatorStats(creatorID uuid.UUID) (map[string]interface{}, error) {
	var activeSubscriptions int64
	var totalRevenue int64
	now := time.Now()

	// Compter les abonnements actifs
	database.DB.Model(&models.Subscription{}).
		Where("creator_id = ? AND status = ? AND start_date <= ? AND end_date > ?",
			creatorID, models.SubscriptionStatusActive, now, now).
		Count(&activeSubscriptions)

	// Calculer le revenu total
	database.DB.Model(&models.Subscription{}).
		Where("creator_id = ? AND status = ?", creatorID, models.SubscriptionStatusActive).
		Select("COALESCE(SUM(price), 0)").
		Scan(&totalRevenue)

	return map[string]interface{}{
		"active_subscribers": activeSubscriptions,
		"total_revenue":      totalRevenue,
		"monthly_revenue":    activeSubscriptions * models.SubscriptionPriceCents,
		"price_per_month":    models.SubscriptionPriceEuros,
	}, nil
}
