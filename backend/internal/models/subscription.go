// backend/internal/models/subscription.go

package models

import (
	"time"

	"github.com/google/uuid"
)

const (
	// Prix fixe pour tous les abonnements
	SubscriptionPriceEuros   = 30
	SubscriptionPriceCents   = 3000 // 30€ en centimes
	SubscriptionDurationDays = 30   // Durée en jours
)

// Subscription représente un abonnement d'un abonné à un créateur
type Subscription struct {
	ID           uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	CreatorID    uuid.UUID `gorm:"not null" json:"creator_id"`
	SubscriberID uuid.UUID `gorm:"not null" json:"subscriber_id"`
	StartDate    time.Time `gorm:"not null" json:"start_date"`
	EndDate      time.Time `gorm:"not null" json:"end_date"`
	PaymentID    uuid.UUID `gorm:"type:uuid;not null" json:"payment_id"`
	Price        int       `gorm:"column:price;default:3000;not null" json:"price"`       // ✨ NOUVEAU
	Status       string    `gorm:"column:status;default:'active';not null" json:"status"` // ✨ NOUVEAU
	CreatedAt    time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`    // ✨ NOUVEAU
}

// Statuts d'abonnement
const (
	SubscriptionStatusActive   = "active"
	SubscriptionStatusExpired  = "expired"
	SubscriptionStatusCanceled = "canceled"
)

// IsActive vérifie si l'abonnement est actif
func (s *Subscription) IsActive() bool {
	now := time.Now()
	return s.Status == SubscriptionStatusActive &&
		s.StartDate.Before(now) &&
		s.EndDate.After(now)
}

// DaysRemaining retourne le nombre de jours restants
func (s *Subscription) DaysRemaining() int {
	if !s.IsActive() {
		return 0
	}
	duration := time.Until(s.EndDate)
	days := int(duration.Hours() / 24)
	if days < 0 {
		return 0
	}
	return days
}
