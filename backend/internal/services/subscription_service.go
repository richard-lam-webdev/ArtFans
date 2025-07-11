// backend/internal/services/subscription_service.go

package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/database"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/logger"
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
	// Log structuré pour Grafana
	logger.LogBusinessEvent("subscription_attempt", map[string]interface{}{
		"subscriber_id": userID.String(),
		"creator_id":    creatorID.String(),
		"price_euros":   30,
	})

	// Vérifier si l'utilisateur n'est pas déjà abonné
	isSubscribed, err := s.IsSubscribed(userID, creatorID)
	if err != nil {
		logger.LogError(err, "subscription_check_failed", map[string]interface{}{
			"subscriber_id": userID.String(),
			"creator_id":    creatorID.String(),
		})
		return err
	}
	if isSubscribed {
		logger.LogBusinessEvent("subscription_already_exists", map[string]interface{}{
			"subscriber_id": userID.String(),
			"creator_id":    creatorID.String(),
		})
		return errors.New("vous êtes déjà abonné à ce créateur")
	}

	// Vérifier que l'utilisateur ne s'abonne pas à lui-même
	if userID == creatorID {
		logger.LogBusinessEvent("self_subscription_attempt", map[string]interface{}{
			"user_id": userID.String(),
		})
		return errors.New("impossible de s'abonner à soi-même")
	}

	now := time.Now()

	// Transaction pour éviter les doubles entrées
	tx := database.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			logger.LogError(errors.New("transaction panic"), "subscription_transaction_panic", map[string]interface{}{
				"subscriber_id": userID.String(),
				"creator_id":    creatorID.String(),
				"panic":         r,
			})
		}
	}()

	// Créer l'abonnement
	sub := &models.Subscription{
		CreatorID:    creatorID,
		SubscriberID: userID,
		StartDate:    now,
		EndDate:      now.AddDate(0, 0, models.SubscriptionDurationDays),
		Price:        models.SubscriptionPriceCents,
		Status:       models.SubscriptionStatusActive,
	}

	if err := tx.Create(sub).Error; err != nil {
		tx.Rollback()
		logger.LogError(err, "subscription_creation_failed", map[string]interface{}{
			"subscriber_id": userID.String(),
			"creator_id":    creatorID.String(),
		})
		return err
	}

	// Créer le paiement
	payment := &models.Payment{
		SubscriptionID: sub.ID,
		Amount:         models.SubscriptionPriceCents,
		PaidAt:         now,
		Status:         "succeeded",
	}

	if err := tx.Create(payment).Error; err != nil {
		tx.Rollback()
		logger.LogError(err, "payment_creation_failed", map[string]interface{}{
			"subscription_id": sub.ID.String(),
			"amount_cents":    models.SubscriptionPriceCents,
		})
		return err
	}

	// Valider la transaction
	if err := tx.Commit().Error; err != nil {
		logger.LogError(err, "transaction_commit_failed", map[string]interface{}{
			"subscription_id": sub.ID.String(),
			"payment_id":      payment.ID.String(),
		})
		return err
	}

	// Log de succès pour Grafana
	logger.LogBusinessEvent("subscription_created", map[string]interface{}{
		"subscription_id": sub.ID.String(),
		"payment_id":      payment.ID.String(),
		"subscriber_id":   userID.String(),
		"creator_id":      creatorID.String(),
		"amount_euros":    30,
		"duration_days":   models.SubscriptionDurationDays,
		"end_date":        sub.EndDate,
	})

	// Log payment spécifique
	logger.LogPayment("subscription_payment_success", userID.String(), 30.00, true, map[string]interface{}{
		"creator_id":      creatorID.String(),
		"subscription_id": sub.ID.String(),
		"payment_id":      payment.ID.String(),
		"payment_method":  "internal",
	})

	return nil
}

func (s *SubscriptionService) Unsubscribe(subscriberID, creatorID uuid.UUID) error {
	logger.LogBusinessEvent("unsubscription_attempt", map[string]interface{}{
		"subscriber_id": subscriberID.String(),
		"creator_id":    creatorID.String(),
	})

	result := database.DB.
		Where("subscriber_id = ? AND creator_id = ? AND status = ?",
			subscriberID, creatorID, models.SubscriptionStatusActive).
		Delete(&models.Subscription{})

	if result.Error != nil {
		logger.LogError(result.Error, "unsubscription_failed", map[string]interface{}{
			"subscriber_id": subscriberID.String(),
			"creator_id":    creatorID.String(),
		})
		return result.Error
	}

	if result.RowsAffected == 0 {
		logger.LogBusinessEvent("unsubscription_not_found", map[string]interface{}{
			"subscriber_id": subscriberID.String(),
			"creator_id":    creatorID.String(),
		})
		return errors.New("aucun abonnement actif trouvé")
	}

	logger.LogBusinessEvent("unsubscription_success", map[string]interface{}{
		"subscriber_id": subscriberID.String(),
		"creator_id":    creatorID.String(),
		"rows_affected": result.RowsAffected,
	})

	return nil
}

// IsSubscribed retourne true si l'utilisateur est abonné ET que l'abonnement est actif
func (s *SubscriptionService) IsSubscribed(subscriberID, creatorID uuid.UUID) (bool, error) {
	var count int64
	now := time.Now()

	err := database.DB.Model(&models.Subscription{}).
		Where("subscriber_id = ? AND creator_id = ? AND status = ? AND start_date <= ? AND end_date > ?",
			subscriberID, creatorID, models.SubscriptionStatusActive, now, now).
		Count(&count).Error

	if err != nil {
		logger.LogError(err, "subscription_check_error", map[string]interface{}{
			"subscriber_id": subscriberID.String(),
			"creator_id":    creatorID.String(),
		})
		return false, err
	}

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

	if err != nil {
		logger.LogError(err, "get_followed_creators_error", map[string]interface{}{
			"subscriber_id": subscriberID.String(),
		})
	}

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

	if err != nil {
		logger.LogError(err, "get_user_subscriptions_error", map[string]interface{}{
			"user_id": userID.String(),
		})
	} else {
		logger.LogBusinessEvent("user_subscriptions_retrieved", map[string]interface{}{
			"user_id":     userID.String(),
			"count":       len(subscriptions),
			"total_value": len(subscriptions) * 30,
		})
	}

	return subscriptions, err
}

// GetCreatorStats retourne les statistiques d'un créateur
func (s *SubscriptionService) GetCreatorStats(creatorID uuid.UUID) (map[string]interface{}, error) {
	var activeSubscriptions int64
	var totalRevenue int64
	now := time.Now()

	// Compter les abonnements actifs
	err := database.DB.Model(&models.Subscription{}).
		Where("creator_id = ? AND status = ? AND start_date <= ? AND end_date > ?",
			creatorID, models.SubscriptionStatusActive, now, now).
		Count(&activeSubscriptions).Error

	if err != nil {
		logger.LogError(err, "get_creator_stats_error", map[string]interface{}{
			"creator_id": creatorID.String(),
		})
		return nil, err
	}

	// Calculer le revenu total
	totalRevenue = activeSubscriptions * 30

	stats := map[string]interface{}{
		"active_subscriptions": activeSubscriptions,
		"monthly_revenue":      totalRevenue,
		"currency":             "EUR",
	}

	logger.LogBusinessEvent("creator_stats_retrieved", map[string]interface{}{
		"creator_id":           creatorID.String(),
		"active_subscriptions": activeSubscriptions,
		"monthly_revenue":      totalRevenue,
	})

	return stats, nil
}
