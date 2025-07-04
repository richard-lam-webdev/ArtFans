// backend/internal/services/subscription_service.go
package services

import (
	"time"

	"github.com/google/uuid"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/models"
	"github.com/richard-lam-webdev/ArtFans/backend/internal/repositories"
)

type SubscriptionService struct {
	repo *repositories.SubscriptionRepository
}

func NewSubscriptionService(repo *repositories.SubscriptionRepository) *SubscriptionService {
	return &SubscriptionService{repo: repo}
}

// Subscribe permet à un abonné de s’abonner à un créateur (gratuit ou payant)
func (s *SubscriptionService) Subscribe(creatorID, userID uuid.UUID) error {
	sub := &models.Subscription{
		CreatorID:    creatorID,
		SubscriberID: userID,
		StartDate:    time.Now(),
		EndDate:      time.Now().AddDate(0, 1, 0),
		PaymentID:    uuid.Nil,
	}
	if err := s.repo.Create(sub); err != nil {
		return err
	}
	return nil
}

// Unsubscribe met fin à un abonnement
func (s *SubscriptionService) Unsubscribe(subscriberID, creatorID uuid.UUID) error {
	return s.repo.Delete(subscriberID, creatorID)
}

// IsSubscribed retourne true si l’utilisateur est déjà abonné au créateur
func (s *SubscriptionService) IsSubscribed(subscriberID, creatorID uuid.UUID) (bool, error) {
	return s.repo.IsSubscribed(subscriberID, creatorID)
}

// GetFollowedCreatorIDs retourne la liste des créateurs suivis
func (s *SubscriptionService) GetFollowedCreatorIDs(subscriberID uuid.UUID) ([]uuid.UUID, error) {
	return s.repo.ListCreatorIDsBySubscriber(subscriberID)
}
